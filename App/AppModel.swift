import AlarmKit
import EventKit
import Foundation
import Observation
import SwiftUI

/// Coordinador de la app: junta calendarios, ajustes y alarmas, y decide cuándo resincronizar.
@MainActor
@Observable
final class AppModel {

    let calendars = CalendarStore()
    let settingsStore = SettingsStore()

    private let scheduler: any AlarmScheduling = AlarmKitScheduler.shared

    private(set) var events: [EventSnapshot] = []
    private(set) var lastOutcome: SyncEngine.Outcome?
    private(set) var isSyncing = false
    private(set) var alarmAuthorization: AlarmManager.AuthorizationState = .notDetermined
    private(set) var lastSyncError: String?

    var settings: AlarmSettings { settingsStore.settings }

    /// `true` cuando ya tenemos los dos permisos y podemos trabajar.
    var isReady: Bool {
        calendars.access.canRead && alarmAuthorization == .authorized
    }

    private var observersInstalled = false

    // MARK: - Arranque

    func bootstrap() async {
        alarmAuthorization = AlarmKitScheduler.shared.authorizationState
        calendars.refreshAccessState()
        if calendars.access.canRead {
            calendars.loadCalendars()
        }
        installObservers()
        await sync()
    }

    @discardableResult
    func requestCalendarAccess() async -> CalendarStore.Access {
        let result = await calendars.requestAccess()
        await sync()
        return result
    }

    @discardableResult
    func requestAlarmAuthorization() async -> AlarmManager.AuthorizationState {
        alarmAuthorization = await AlarmKitScheduler.shared.requestAuthorization()
        await sync()
        return alarmAuthorization
    }

    // MARK: - Sincronización

    func sync() async {
        guard isReady, !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        calendars.loadCalendars()
        let settings = settingsStore.settings
        let fetched = calendars.fetchEvents(horizonDays: settings.horizonDays)
        events = fetched

        do {
            let engine = SyncEngine(scheduler: scheduler)
            lastOutcome = try await engine.reconcile(
                events: fetched,
                settings: settings,
                enabledCalendarIDs: calendars.enabledCalendarIDs(settings: settings)
            )
            lastSyncError = nil
        } catch {
            lastSyncError = String(describing: error)
        }
    }

    /// Motivo por el que un evento concreto no tiene alarma, para explicarlo en la lista.
    func skipReason(for event: EventSnapshot) -> EventFilter.Reason? {
        lastOutcome?.skipped[event.id]
    }

    func alarmDate(for event: EventSnapshot) -> Date {
        event.alarmDate(
            leadMinutes: settings.leadMinutes(calendarIdentifier: event.calendarIdentifier)
        )
    }

    // MARK: - Disparadores

    /// Resincroniza cuando el calendario cambia, cuando la app vuelve a primer plano y
    /// cuando salta la hora o la zona horaria: `Alarm.Schedule.fixed` guarda un instante
    /// absoluto, así que un cambio de huso obliga a recalcular y reprogramar.
    private func installObservers() {
        guard !observersInstalled else { return }
        observersInstalled = true

        let names: [Notification.Name] = [
            .EKEventStoreChanged,
            UIApplication.willEnterForegroundNotification,
            UIApplication.significantTimeChangeNotification,
            .NSSystemClockDidChange,
            .NSSystemTimeZoneDidChange
        ]

        for name in names {
            NotificationCenter.default.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    Task { await self.sync() }
                }
            }
        }
    }
}

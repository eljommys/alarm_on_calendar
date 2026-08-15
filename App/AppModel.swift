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

        // Las anulaciones de eventos ya pasados no sirven para nada y el ajuste
        // crecería indefinidamente si no se limpiaran.
        var pruned = settingsStore.settings
        if pruned.pruneEventOverrides(olderThan: Date()) {
            settingsStore.settings = pruned
        }

        let settings = settingsStore.settings
        let enabledIDs = calendars.enabledCalendarIDs(settings: settings)
        let fetched = calendars.fetchEvents(
            horizonDays: settings.horizonDays,
            calendarIDs: enabledIDs
        )
        events = fetched

        do {
            let engine = SyncEngine(scheduler: scheduler)
            lastOutcome = try await engine.reconcile(
                events: fetched,
                settings: settings,
                enabledCalendarIDs: enabledIDs
            )
            lastSyncError = nil
        } catch {
            lastSyncError = String(describing: error)
        }
    }

    // MARK: - Estado por evento

    /// Se resuelve en vivo, no desde el último `Outcome`, para que al pulsar el
    /// interruptor la fila responda al instante sin esperar a la resincronización.
    func decision(for event: EventSnapshot) -> EventFilter.Decision {
        EventFilter.decide(
            event,
            settings: settings,
            // La lista solo contiene eventos de calendarios monitorizados.
            calendarEnabled: true,
            now: Date()
        )
    }

    func hasAlarm(_ event: EventSnapshot) -> Bool {
        decision(for: event).isScheduled
    }

    /// Motivo por el que un evento concreto no tiene alarma, para explicarlo en la lista.
    func skipReason(for event: EventSnapshot) -> EventFilter.Reason? {
        decision(for: event).reason
    }

    /// `true` si el usuario ha decidido a mano sobre este evento.
    func isManual(_ event: EventSnapshot) -> Bool {
        settings.override(for: event) != nil
    }

    func setAlarm(_ isOn: Bool, for event: EventSnapshot) {
        settingsStore.settings.setOverride(isOn, for: event)
        Task { await sync() }
    }

    /// Antelación propia del evento; `nil` si sigue la cascada calendario → general.
    func leadOverride(for event: EventSnapshot) -> Int? {
        settings.leadOverride(for: event)
    }

    /// Da al evento su propia antelación, o `nil` para devolverlo a la cascada.
    func setEventLead(_ minutes: Int?, for event: EventSnapshot) {
        settingsStore.settings.setLeadOverride(minutes, for: event)
        Task { await sync() }
    }

    /// Borra todos los ajustes manuales del evento: encendido y antelación.
    func clearOverride(for event: EventSnapshot) {
        settingsStore.settings.clearOverrides(for: event)
        Task { await sync() }
    }

    func alarmDate(for event: EventSnapshot) -> Date {
        event.alarmDate(leadMinutes: settings.leadMinutes(for: event))
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

import EventKit
import Foundation
import Observation
import SwiftUI

/// Única puerta de entrada a EventKit.
///
/// Traduce el mundo de EventKit (`EKSource`, `EKCalendar`, `EKEvent`) a los tipos
/// planos de `Shared/`, para que el resto de la app no dependa del framework.
/// Nunca abre una conexión de red: Google y Microsoft llegan porque iOS ya los
/// sincroniza a través de las cuentas configuradas en Ajustes.
@MainActor
@Observable
final class CalendarStore {

    enum Access: Equatable, Sendable {
        case notDetermined
        case denied
        /// iOS 17+ permite conceder solo escritura; para nosotros es tan inútil como denegar.
        case writeOnly
        case full

        var canRead: Bool { self == .full }
    }

    struct CalendarInfo: Identifiable, Hashable, Sendable {
        let id: String
        let title: String
        let colorComponents: [Double]
        let provider: CalendarProvider
        let isEnabledByDefault: Bool

        var color: Color {
            guard colorComponents.count >= 3 else { return .gray }
            return Color(
                red: colorComponents[0],
                green: colorComponents[1],
                blue: colorComponents[2]
            )
        }
    }

    struct ProviderGroup: Identifiable, Hashable, Sendable {
        let id: String
        let provider: CalendarProvider
        let accountTitle: String
        let calendars: [CalendarInfo]
    }

    private let store = EKEventStore()

    private(set) var access: Access = .notDetermined
    private(set) var groups: [ProviderGroup] = []

    var allCalendars: [CalendarInfo] { groups.flatMap(\.calendars) }

    /// Proveedores que el usuario ya tiene vinculados, para marcarlos en la guía.
    var linkedProviders: Set<CalendarProvider> { Set(groups.map(\.provider)) }

    init() {
        refreshAccessState()
    }

    // MARK: - Permisos

    func refreshAccessState() {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess: access = .full
        case .writeOnly: access = .writeOnly
        case .denied, .restricted: access = .denied
        case .notDetermined: access = .notDetermined
        @unknown default: access = .notDetermined
        }
    }

    @discardableResult
    func requestAccess() async -> Access {
        do {
            _ = try await store.requestFullAccessToEvents()
        } catch {
            // Da igual el error concreto: el estado real lo dice el sistema.
        }
        refreshAccessState()
        if access.canRead { loadCalendars() }
        return access
    }

    // MARK: - Calendarios

    func loadCalendars() {
        guard access.canRead else {
            groups = []
            return
        }

        let calendars = store.calendars(for: .event)
        let bySource = Dictionary(grouping: calendars) { $0.source ?? EKSource() }

        groups = bySource.compactMap { source, calendars -> ProviderGroup? in
            guard !calendars.isEmpty else { return nil }
            let provider = Self.provider(for: source)
            return ProviderGroup(
                id: source.sourceIdentifier,
                provider: provider,
                accountTitle: source.title,
                calendars: calendars
                    .map { Self.info(for: $0, provider: provider) }
                    .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
            )
        }
        .sorted { $0.accountTitle.localizedStandardCompare($1.accountTitle) == .orderedAscending }
    }

    /// Resuelve qué calendarios están activos, combinando los ajustes explícitos del
    /// usuario con el valor por defecto de cada tipo de calendario.
    func enabledCalendarIDs(settings: AlarmSettings) -> Set<String> {
        var enabled: Set<String> = []
        for calendar in allCalendars
        where settings.isEnabled(
            calendarIdentifier: calendar.id,
            whenUnset: calendar.isEnabledByDefault
        ) {
            enabled.insert(calendar.id)
        }
        return enabled
    }

    // MARK: - Eventos

    /// Devuelve las ocurrencias de la ventana pedida, ya traducidas a `EventSnapshot`.
    /// EventKit expande las series recurrentes: cada repetición llega como un `EKEvent`
    /// distinto con el mismo `eventIdentifier` y distinta fecha de inicio.
    func fetchEvents(horizonDays: Int, from now: Date = Date()) -> [EventSnapshot] {
        guard access.canRead else { return [] }

        let calendars = store.calendars(for: .event)
        guard !calendars.isEmpty else { return [] }

        let end = Calendar.current.date(byAdding: .day, value: max(1, horizonDays), to: now) ?? now
        let predicate = store.predicateForEvents(withStart: now, end: end, calendars: calendars)

        return store.events(matching: predicate)
            .compactMap(Self.snapshot(for:))
            .sorted { $0.occurrenceStart < $1.occurrenceStart }
    }

    // MARK: - Traducción desde EventKit

    static func provider(for source: EKSource) -> CalendarProvider {
        switch source.sourceType {
        case .local:
            return .local
        case .exchange:
            return .microsoft
        case .birthdays:
            return .birthdays
        case .subscribed:
            return .subscribed
        case .mobileMe:
            return .apple
        case .calDAV:
            // iCloud y Google comparten tipo CalDAV; solo el título los distingue.
            let title = source.title.lowercased()
            if title.contains("icloud") || title.contains("me.com") || title.contains("mac.com") {
                return .apple
            }
            if title.contains("google") || title.contains("gmail") {
                return .google
            }
            return .otherCalDAV
        @unknown default:
            return .otherCalDAV
        }
    }

    private static func info(for calendar: EKCalendar, provider: CalendarProvider) -> CalendarInfo {
        // Los calendarios de cumpleaños y suscripciones se tratan como tales aunque
        // la cuenta padre sea, por ejemplo, iCloud.
        let effectiveProvider: CalendarProvider = switch calendar.type {
        case .birthday: .birthdays
        case .subscription: .subscribed
        default: provider
        }

        return CalendarInfo(
            id: calendar.calendarIdentifier,
            title: calendar.title,
            colorComponents: components(of: calendar.cgColor),
            provider: provider,
            isEnabledByDefault: effectiveProvider.isEnabledByDefault
        )
    }

    private static func components(of cgColor: CGColor?) -> [Double] {
        guard let converted = cgColor?.converted(
            to: CGColorSpace(name: CGColorSpace.sRGB)!,
            intent: .defaultIntent,
            options: nil
        ), let components = converted.components, components.count >= 3 else {
            return [0.5, 0.5, 0.5]
        }
        return components.prefix(3).map(Double.init)
    }

    static func snapshot(for event: EKEvent) -> EventSnapshot? {
        guard let start = event.startDate, let calendar = event.calendar else { return nil }
        // `eventIdentifier` puede venir vacío en algunos calendarios suscritos.
        let identifier = event.eventIdentifier ?? event.calendarItemIdentifier

        return EventSnapshot(
            eventIdentifier: identifier,
            occurrenceStart: start,
            occurrenceEnd: event.endDate ?? start,
            title: event.title ?? "Evento sin título",
            location: event.location,
            isAllDay: event.isAllDay,
            status: status(for: event.status),
            myResponse: myResponse(for: event),
            calendarIdentifier: calendar.calendarIdentifier,
            calendarTitle: calendar.title
        )
    }

    private static func status(for status: EKEventStatus) -> EventSnapshot.Status {
        switch status {
        case .confirmed: .confirmed
        case .tentative: .tentative
        case .canceled: .canceled
        case .none: .none
        @unknown default: .none
        }
    }

    /// Resuelve mi propia respuesta a la invitación.
    ///
    /// El orden importa: si aparezco entre los asistentes mando yo con mi RSVP, incluso
    /// siendo el organizador (puedo haber rechazado mi propia reunión). Solo si no me
    /// encuentro recurro a comprobar si la organizo.
    static func myResponse(for event: EKEvent) -> EventSnapshot.MyResponse {
        guard let attendees = event.attendees, !attendees.isEmpty else {
            return .notAnInvite
        }

        if let me = attendees.first(where: { $0.isCurrentUser }) {
            switch me.participantStatus {
            case .accepted: return .accepted
            case .declined: return .declined
            case .tentative: return .tentative
            case .pending: return .pending
            case .delegated, .completed, .inProcess, .unknown: return .unknown
            @unknown default: return .unknown
            }
        }

        if event.organizer?.isCurrentUser == true {
            return .organizer
        }

        return .unknown
    }
}

import Foundation

/// Decide qué eventos merecen alarma. Función pura, sin estado ni dependencias.
enum EventFilter {

    enum Reason: String, Equatable, Sendable {
        case calendarDisabled
        case turnedOff
        case canceled
        case declined
        case allDay
        case notConfirmed
        case alreadyPast

        var explanation: String {
            switch self {
            case .calendarDisabled: String(localized: "Su calendario está desactivado")
            case .turnedOff: String(localized: "La has desactivado para este evento")
            case .canceled: String(localized: "El evento está cancelado")
            case .declined: String(localized: "Has rechazado la invitación")
            case .allDay: String(localized: "Es un evento de todo el día")
            case .notConfirmed: String(localized: "Aún no has confirmado tu asistencia")
            case .alreadyPast: String(localized: "La hora de la alarma ya ha pasado")
            }
        }
    }

    enum Decision: Equatable, Sendable {
        case schedule
        case skip(Reason)

        var isScheduled: Bool { self == .schedule }
        var reason: Reason? {
            if case let .skip(reason) = self { return reason }
            return nil
        }
    }

    /// - Parameters:
    ///   - calendarEnabled: si el calendario del evento está activado en los ajustes.
    ///   - now: instante de referencia, inyectable para poder testear.
    static func decide(
        _ event: EventSnapshot,
        settings: AlarmSettings,
        calendarEnabled: Bool,
        now: Date
    ) -> Decision {
        guard calendarEnabled else { return .skip(.calendarDisabled) }

        let fireDate = event.alarmDate(leadMinutes: settings.leadMinutes(for: event))

        // La decisión manual manda sobre todas las reglas automáticas: si el usuario
        // ha puesto alarma a un evento que ha marcado como «quizá», la quiere.
        // Lo único que no se puede saltar es que la hora ya haya pasado.
        if let manual = settings.override(for: event) {
            guard manual else { return .skip(.turnedOff) }
            return fireDate > now ? .schedule : .skip(.alreadyPast)
        }

        // Un evento cancelado por el organizador no debe despertar a nadie.
        guard event.status != .canceled else { return .skip(.canceled) }

        // Rechazado se descarta en LOS DOS modos, incluido «todos los eventos»:
        // si has dicho que no vas, una alarma a las 7:00 es un error, no una función.
        guard event.myResponse != .declined else { return .skip(.declined) }

        if event.isAllDay && !settings.includeAllDayEvents {
            return .skip(.allDay)
        }

        if settings.mode == .confirmedOnly {
            switch event.myResponse {
            case .accepted, .organizer, .notAnInvite:
                break
            case .unknown:
                // Hay invitados pero no me localizo entre ellos. Prefiero avisar de más
                // que dejar a alguien tirado por un emparejamiento de correo fallido.
                break
            case .tentative, .pending:
                return .skip(.notConfirmed)
            case .declined:
                return .skip(.declined)  // ya cubierto arriba, aquí por exhaustividad
            }
        }

        guard fireDate > now else { return .skip(.alreadyPast) }

        return .schedule
    }
}

import Foundation

/// Decide qué eventos merecen alarma. Función pura, sin estado ni dependencias.
enum EventFilter {

    enum Reason: String, Equatable, Sendable {
        case calendarDisabled
        case canceled
        case declined
        case allDay
        case notConfirmed
        case alreadyPast

        var explanation: String {
            switch self {
            case .calendarDisabled: "Su calendario está desactivado"
            case .canceled: "El evento está cancelado"
            case .declined: "Has rechazado la invitación"
            case .allDay: "Es un evento de todo el día"
            case .notConfirmed: "Aún no has confirmado tu asistencia"
            case .alreadyPast: "La hora de la alarma ya ha pasado"
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

        let leadMinutes = settings.leadMinutes(calendarIdentifier: event.calendarIdentifier)
        guard event.alarmDate(leadMinutes: leadMinutes) > now else { return .skip(.alreadyPast) }

        return .schedule
    }
}

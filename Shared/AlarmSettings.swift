import Foundation

/// Preferencias del usuario. Se guardan como JSON en `UserDefaults`; nunca salen del dispositivo.
struct AlarmSettings: Codable, Equatable, Sendable {

    /// Los dos modos que pidió el usuario.
    enum Mode: String, Codable, Sendable, CaseIterable, Identifiable {
        /// Solo eventos que he aceptado (más los personales, que no llevan invitación).
        case confirmedOnly
        /// Todos los eventos, confirmados y sin confirmar.
        case all

        var id: String { rawValue }

        var title: String {
            switch self {
            case .confirmedOnly: "Solo confirmados"
            case .all: "Todos los eventos"
            }
        }

        var explanation: String {
            switch self {
            case .confirmedOnly:
                "Pone alarma solo en los eventos que has aceptado y en los tuyos personales. "
                    + "Los que están pendientes de responder o marcados como «quizá» se saltan."
            case .all:
                "Pone alarma en todos los eventos, los hayas confirmado o no. "
                    + "Los que has rechazado siguen sin alarma."
            }
        }
    }

    /// Ajustes específicos de un calendario concreto.
    struct CalendarSetting: Codable, Equatable, Sendable {
        var isEnabled: Bool
        /// Si es `nil`, se usa `defaultLeadMinutes`.
        var leadMinutesOverride: Int?

        init(isEnabled: Bool = true, leadMinutesOverride: Int? = nil) {
            self.isEnabled = isEnabled
            self.leadMinutesOverride = leadMinutesOverride
        }
    }

    var mode: Mode = .confirmedOnly
    var defaultLeadMinutes: Int = 10
    var snoozeMinutes: Int = 5
    var includeAllDayEvents: Bool = false
    /// Días hacia adelante que se recorren buscando eventos a los que poner alarma.
    var horizonDays: Int = 7

    /// Solo contiene los calendarios que el usuario ha tocado explícitamente.
    /// Para el resto se aplica el valor por defecto que propone `CalendarStore`.
    var perCalendar: [String: CalendarSetting] = [:]

    static let leadMinuteChoices = [0, 1, 2, 5, 10, 15, 20, 30, 45, 60, 90, 120]
    static let snoozeMinuteChoices = [1, 2, 5, 10, 15]
    static let horizonDayChoices = [1, 2, 3, 7, 14, 30]

    func isEnabled(calendarIdentifier: String, whenUnset fallback: Bool) -> Bool {
        perCalendar[calendarIdentifier]?.isEnabled ?? fallback
    }

    func leadMinutes(calendarIdentifier: String) -> Int {
        perCalendar[calendarIdentifier]?.leadMinutesOverride ?? defaultLeadMinutes
    }
}

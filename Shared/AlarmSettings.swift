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

    /// Decisión manual sobre un evento concreto, que manda sobre las reglas automáticas.
    struct EventOverride: Codable, Equatable, Sendable {
        var isEnabled: Bool
        /// Se guarda la fecha, y no se deduce de la clave, para poder purgar las
        /// anulaciones de eventos pasados sin depender del formato del identificador.
        var occurrenceStart: Date
    }

    /// Solo contiene los eventos que el usuario ha encendido o apagado a mano.
    /// El resto sigue las reglas automáticas del modo elegido.
    var perEvent: [String: EventOverride] = [:]

    static let leadMinuteChoices = [0, 1, 2, 5, 10, 15, 20, 30, 45, 60, 90, 120]
    static let snoozeMinuteChoices = [1, 2, 5, 10, 15]
    static let horizonDayChoices = [1, 2, 3, 7, 14, 30]

    func isEnabled(calendarIdentifier: String, whenUnset fallback: Bool) -> Bool {
        perCalendar[calendarIdentifier]?.isEnabled ?? fallback
    }

    func leadMinutes(calendarIdentifier: String) -> Int {
        perCalendar[calendarIdentifier]?.leadMinutesOverride ?? defaultLeadMinutes
    }

    // MARK: - Anulaciones por evento

    /// `nil` significa que el evento sigue la regla automática.
    func override(for event: EventSnapshot) -> Bool? {
        perEvent[event.id]?.isEnabled
    }

    /// Pasar `nil` devuelve el evento al comportamiento automático.
    mutating func setOverride(_ isEnabled: Bool?, for event: EventSnapshot) {
        if let isEnabled {
            perEvent[event.id] = EventOverride(
                isEnabled: isEnabled,
                occurrenceStart: event.occurrenceStart
            )
        } else {
            perEvent.removeValue(forKey: event.id)
        }
    }

    /// Descarta las anulaciones de eventos ya pasados para que el ajuste no crezca sin fin.
    /// Devuelve `true` si algo cambió, para no reescribir el disco sin motivo.
    @discardableResult
    mutating func pruneEventOverrides(olderThan date: Date) -> Bool {
        let kept = perEvent.filter { $0.value.occurrenceStart >= date }
        guard kept.count != perEvent.count else { return false }
        perEvent = kept
        return true
    }
}

// MARK: - Lectura tolerante

extension AlarmSettings {

    /// Decodificación que sobrevive a las claves que aún no existían.
    ///
    /// La síntesis automática de `Codable` lanza `keyNotFound` en cuanto se lee un
    /// ajuste guardado por una versión anterior que no tenía algún campo. Como
    /// `SettingsStore` interpreta el fallo como «no hay nada guardado», eso borraría
    /// TODAS las preferencias del usuario al actualizar la app. Cada campo ausente
    /// se resuelve aquí con su valor por defecto.
    init(from decoder: any Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)

        mode = try container.decodeIfPresent(Mode.self, forKey: .mode) ?? mode
        defaultLeadMinutes = try container.decodeIfPresent(Int.self, forKey: .defaultLeadMinutes)
            ?? defaultLeadMinutes
        snoozeMinutes = try container.decodeIfPresent(Int.self, forKey: .snoozeMinutes)
            ?? snoozeMinutes
        includeAllDayEvents = try container.decodeIfPresent(Bool.self, forKey: .includeAllDayEvents)
            ?? includeAllDayEvents
        horizonDays = try container.decodeIfPresent(Int.self, forKey: .horizonDays) ?? horizonDays
        perCalendar = try container.decodeIfPresent([String: CalendarSetting].self, forKey: .perCalendar)
            ?? perCalendar
        perEvent = try container.decodeIfPresent([String: EventOverride].self, forKey: .perEvent)
            ?? perEvent
    }
}

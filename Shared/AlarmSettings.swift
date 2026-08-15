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
            case .confirmedOnly: String(localized: "Solo confirmados")
            case .all: String(localized: "Todos los eventos")
            }
        }

        var explanation: String {
            switch self {
            case .confirmedOnly:
                String(localized: "Pone alarma solo en los eventos que has aceptado y en los tuyos personales. Los que están pendientes de responder o marcados como «quizá» se saltan.")
            case .all:
                String(localized: "Pone alarma en todos los eventos, los hayas confirmado o no. Los que has rechazado siguen sin alarma.")
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

    /// Ajustes manuales sobre un evento concreto, que mandan sobre las reglas automáticas.
    ///
    /// Los dos campos son independientes: se puede personalizar la antelación de un
    /// evento sin haber tocado su interruptor, y viceversa. Por eso `isEnabled` es
    /// opcional — `nil` significa «sigue la regla automática del modo».
    struct EventOverride: Codable, Equatable, Sendable {
        var isEnabled: Bool?
        /// Antelación propia en minutos; `nil` cae a la del calendario o a la general.
        var leadMinutesOverride: Int?
        /// Se guarda la fecha, y no se deduce de la clave, para poder purgar las
        /// anulaciones de eventos pasados sin depender del formato del identificador.
        var occurrenceStart: Date

        /// Una entrada sin contenido no aporta nada y debe eliminarse del diccionario.
        var isEmpty: Bool { isEnabled == nil && leadMinutesOverride == nil }
    }

    /// Solo contiene los eventos que el usuario ha encendido o apagado a mano.
    /// El resto sigue las reglas automáticas del modo elegido.
    var perEvent: [String: EventOverride] = [:]

    /// Etiqueta legible de una antelación. Vive aquí porque la usan dos pantallas.
    static func leadLabel(_ minutes: Int) -> String {
        switch minutes {
        case 0: String(localized: "Justo a la hora")
        case 60: String(localized: "1 hora antes")
        case 90: String(localized: "1 h 30 min antes")
        case 120: String(localized: "2 horas antes")
        default: String(localized: "\(minutes) min antes")
        }
    }

    static let leadMinuteChoices = [0, 1, 2, 5, 10, 15, 20, 30, 45, 60, 90, 120]
    static let snoozeMinuteChoices = [1, 2, 5, 10, 15]
    static let horizonDayChoices = [1, 2, 3, 7, 14, 30]

    func isEnabled(calendarIdentifier: String, whenUnset fallback: Bool) -> Bool {
        perCalendar[calendarIdentifier]?.isEnabled ?? fallback
    }

    func leadMinutes(calendarIdentifier: String) -> Int {
        perCalendar[calendarIdentifier]?.leadMinutesOverride ?? defaultLeadMinutes
    }

    /// Antelación efectiva de un evento: la suya propia si la tiene; si no, la de su
    /// calendario; y si el calendario tampoco tiene, la general de Ajustes.
    func leadMinutes(for event: EventSnapshot) -> Int {
        perEvent[event.id]?.leadMinutesOverride
            ?? leadMinutes(calendarIdentifier: event.calendarIdentifier)
    }

    /// Antelación propia del evento, sin resolver la cascada. Para pintar la selección.
    func leadOverride(for event: EventSnapshot) -> Int? {
        perEvent[event.id]?.leadMinutesOverride
    }

    // MARK: - Anulaciones por evento

    /// `nil` significa que el evento sigue la regla automática.
    func override(for event: EventSnapshot) -> Bool? {
        // El doble opcional se aplana: entrada ausente y entrada sin decisión de
        // encendido significan lo mismo hacia fuera.
        perEvent[event.id]?.isEnabled ?? nil
    }

    /// Enciende o apaga a mano la alarma del evento. Pasar `nil` lo devuelve a la
    /// regla automática sin tocar su antelación personalizada, si la tuviera.
    mutating func setOverride(_ isEnabled: Bool?, for event: EventSnapshot) {
        mutateOverride(for: event) { $0.isEnabled = isEnabled }
    }

    /// Da al evento una antelación propia. Pasar `nil` lo devuelve a la cascada
    /// calendario → general, sin tocar su encendido manual.
    mutating func setLeadOverride(_ minutes: Int?, for event: EventSnapshot) {
        mutateOverride(for: event) { $0.leadMinutesOverride = minutes }
    }

    /// Borra todos los ajustes manuales del evento de una vez.
    mutating func clearOverrides(for event: EventSnapshot) {
        perEvent.removeValue(forKey: event.id)
    }

    private mutating func mutateOverride(
        for event: EventSnapshot,
        _ change: (inout EventOverride) -> Void
    ) {
        var entry = perEvent[event.id]
            ?? EventOverride(occurrenceStart: event.occurrenceStart)
        change(&entry)
        // Una entrada vacía se retira: si se acumularan, la purga por fecha las
        // limpiaría igual, pero mejor no ensuciar los ajustes entre tanto.
        perEvent[event.id] = entry.isEmpty ? nil : entry
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

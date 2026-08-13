import Foundation

/// Copia inmutable de una ocurrencia concreta de un evento de calendario.
///
/// Deliberadamente no depende de EventKit: `CalendarStore` traduce cada `EKEvent`
/// a este tipo, y a partir de aquí el filtrado y la generación de identificadores
/// son lógica pura, comprobable sin permisos ni simulador.
struct EventSnapshot: Hashable, Sendable, Identifiable {

    /// Estado que fija el organizador del evento (`EKEventStatus`).
    enum Status: String, Codable, Hashable, Sendable {
        case none, confirmed, tentative, canceled
    }

    /// Mi propia respuesta a la invitación, ya resuelta a partir de los asistentes.
    enum MyResponse: String, Codable, Hashable, Sendable {
        /// El evento no tiene invitados: es una entrada personal de mi agenda.
        case notAnInvite
        /// Lo organizo yo.
        case organizer
        case accepted
        case declined
        case tentative
        case pending
        /// Hay invitados pero no consigo localizarme entre ellos.
        /// Pasa en calendarios suscritos o cuentas con el correo mal emparejado.
        case unknown
    }

    let eventIdentifier: String
    let occurrenceStart: Date
    let occurrenceEnd: Date
    let title: String
    let location: String?
    let isAllDay: Bool
    let status: Status
    let myResponse: MyResponse
    let calendarIdentifier: String
    let calendarTitle: String

    /// Identidad estable por ocurrencia, no por serie.
    var id: String { "\(eventIdentifier)|\(Int(occurrenceStart.timeIntervalSince1970))" }

    /// Instante en que debe sonar la alarma dada una antelación en minutos.
    func alarmDate(leadMinutes: Int) -> Date {
        occurrenceStart.addingTimeInterval(-Double(leadMinutes) * 60)
    }
}

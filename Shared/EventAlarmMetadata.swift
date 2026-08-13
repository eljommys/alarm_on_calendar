import AlarmKit
import Foundation

/// Datos del evento que viajan dentro de la Live Activity.
///
/// Vive en `Shared/` porque tanto la app (al programar la alarma) como la extensión
/// de widget (al dibujarla) deben compilar exactamente el mismo tipo: AlarmKit los
/// empareja por el tipo genérico de `AlarmAttributes<Metadata>`.
struct EventAlarmMetadata: AlarmMetadata {
    let eventTitle: String
    let eventStart: Date
    let calendarTitle: String
    let location: String?

    init(eventTitle: String, eventStart: Date, calendarTitle: String, location: String?) {
        self.eventTitle = eventTitle
        self.eventStart = eventStart
        self.calendarTitle = calendarTitle
        self.location = location
    }

    init(event: EventSnapshot) {
        self.init(
            eventTitle: event.title,
            eventStart: event.occurrenceStart,
            calendarTitle: event.calendarTitle,
            location: event.location
        )
    }
}

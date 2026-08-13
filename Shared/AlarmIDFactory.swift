import CryptoKit
import Foundation

/// Deriva el identificador de una alarma a partir de su contenido.
///
/// Es direccionamiento por contenido: el UUID resume *todo* lo que define la alarma
/// (qué evento, qué ocurrencia, cuándo suena, con qué texto y cuánto pospone). Así,
/// cualquier cambio relevante produce un identificador distinto, y la reconciliación
/// de `SyncEngine` —que es un simple diff de conjuntos— retira la alarma vieja y pone
/// la nueva sin necesidad de comparar campo a campo.
///
/// Si el identificador dependiera solo del evento, mover la antelación de 10 a 30
/// minutos dejaría el mismo UUID y la alarma seguiría sonando a la hora antigua.
enum AlarmIDFactory {

    static func alarmID(event: EventSnapshot, fireDate: Date, snoozeMinutes: Int) -> UUID {
        // La fecha de la ocurrencia es imprescindible: en un evento recurrente
        // `eventIdentifier` es el mismo para todas las repeticiones, así que sin ella
        // las 52 reuniones semanales colapsarían en una única alarma.
        let key = [
            event.eventIdentifier,
            String(Int(event.occurrenceStart.timeIntervalSince1970)),
            String(Int(fireDate.timeIntervalSince1970)),
            event.title,
            String(snoozeMinutes)
        ].joined(separator: "|")

        var bytes = Array(SHA256.hash(data: Data(key.utf8)).prefix(16))

        // Ajusta versión (4) y variante (RFC 4122) para que sea un UUID bien formado.
        bytes[6] = (bytes[6] & 0x0F) | 0x40
        bytes[8] = (bytes[8] & 0x3F) | 0x80

        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }
}

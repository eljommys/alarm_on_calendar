import Foundation

/// Petición de alarma ya resuelta: qué evento, cuándo debe sonar y cuánto pospone.
struct AlarmRequest: Equatable, Sendable, Identifiable {
    let id: UUID
    let event: EventSnapshot
    let fireDate: Date
    let snoozeMinutes: Int

    init(event: EventSnapshot, leadMinutes: Int, snoozeMinutes: Int) {
        let fireDate = event.alarmDate(leadMinutes: leadMinutes)
        self.id = AlarmIDFactory.alarmID(
            event: event,
            fireDate: fireDate,
            snoozeMinutes: snoozeMinutes
        )
        self.event = event
        self.fireDate = fireDate
        self.snoozeMinutes = snoozeMinutes
    }
}

enum AlarmSchedulingError: Error, Equatable {
    /// El sistema no admite más alarmas activas. AlarmKit lo señala con
    /// `AlarmManager.AlarmError.maximumLimitReached`; Apple no documenta el tope.
    case limitReached
    case notAuthorized
    case underlying(String)
}

/// Abstracción sobre AlarmKit. Existe para que `SyncEngine` sea lógica pura y se
/// pueda probar con un doble, sin tocar el sistema de alarmas real.
protocol AlarmScheduling: Sendable {
    func scheduledAlarmIDs() async throws -> Set<UUID>
    func schedule(_ request: AlarmRequest) async throws
    func cancel(id: UUID) async throws
}

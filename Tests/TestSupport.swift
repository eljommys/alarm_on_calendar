import Foundation

/// Instante fijo de referencia para que los tests no dependan del reloj real.
/// 1 de junio de 2026, 09:00 UTC.
let referenceNow = Date(timeIntervalSince1970: 1_780_038_000)

func makeEvent(
    id: String = "evt-1",
    startingIn minutes: Int = 120,
    title: String = "Reunión",
    isAllDay: Bool = false,
    status: EventSnapshot.Status = .confirmed,
    myResponse: EventSnapshot.MyResponse = .accepted,
    calendarIdentifier: String = "cal-trabajo",
    now: Date = referenceNow
) -> EventSnapshot {
    let start = now.addingTimeInterval(Double(minutes) * 60)
    return EventSnapshot(
        eventIdentifier: id,
        occurrenceStart: start,
        occurrenceEnd: start.addingTimeInterval(3600),
        title: title,
        location: nil,
        isAllDay: isAllDay,
        status: status,
        myResponse: myResponse,
        calendarIdentifier: calendarIdentifier,
        calendarTitle: "Trabajo"
    )
}

/// Doble de `AlarmScheduling` con tope configurable, para probar `SyncEngine`
/// sin tocar AlarmKit ni el sistema de alarmas real.
actor FakeScheduler: AlarmScheduling {

    private var scheduled: [UUID: AlarmRequest]
    private(set) var canceledIDs: [UUID] = []
    private let limit: Int

    init(preloaded: [UUID] = [], limit: Int = .max) {
        self.limit = limit
        // Se indexan por el UUID pedido, no por el que derivaría del evento:
        // SyncEngine solo compara identificadores, el contenido da igual.
        self.scheduled = Dictionary(uniqueKeysWithValues: preloaded.map { id in
            (id, AlarmRequest(event: makeEvent(id: id.uuidString), leadMinutes: 0, snoozeMinutes: 5))
        })
    }

    func scheduledAlarmIDs() async throws -> Set<UUID> {
        Set(scheduled.keys)
    }

    func schedule(_ request: AlarmRequest) async throws {
        guard scheduled.count < limit else { throw AlarmSchedulingError.limitReached }
        scheduled[request.id] = request
    }

    func cancel(id: UUID) async throws {
        scheduled[id] = nil
        canceledIDs.append(id)
    }

    func scheduledRequests() -> [AlarmRequest] {
        scheduled.values.sorted { $0.fireDate < $1.fireDate }
    }
}

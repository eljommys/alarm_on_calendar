import Foundation
import Testing

@Suite("Motor de sincronización")
struct SyncEngineTests {

    private let calendarID = "cal-trabajo"

    private func settings(
        mode: AlarmSettings.Mode = .confirmedOnly,
        lead: Int = 10
    ) -> AlarmSettings {
        var settings = AlarmSettings()
        settings.mode = mode
        settings.defaultLeadMinutes = lead
        return settings
    }

    private func reconcile(
        _ scheduler: FakeScheduler,
        events: [EventSnapshot],
        settings: AlarmSettings? = nil,
        enabled: Set<String>? = nil
    ) async throws -> SyncEngine.Outcome {
        try await SyncEngine(scheduler: scheduler).reconcile(
            events: events,
            settings: settings ?? self.settings(),
            enabledCalendarIDs: enabled ?? [calendarID],
            now: referenceNow
        )
    }

    @Test("Programa las alarmas de los eventos elegibles")
    func programaLoQueToca() async throws {
        let scheduler = FakeScheduler()
        let events = [
            makeEvent(id: "a", startingIn: 60),
            makeEvent(id: "b", startingIn: 120)
        ]

        let outcome = try await reconcile(scheduler, events: events)

        #expect(outcome.scheduled == 2)
        #expect(await scheduler.scheduledRequests().count == 2)
    }

    @Test("No reprograma una alarma que ya está puesta")
    func idempotente() async throws {
        let event = makeEvent(id: "a", startingIn: 60)
        let existing = AlarmRequest(event: event, leadMinutes: 10, snoozeMinutes: 5)
        let scheduler = FakeScheduler(preloaded: [existing.id])

        let outcome = try await reconcile(scheduler, events: [event])

        #expect(outcome.unchanged == 1)
        #expect(outcome.scheduled == 0)
        #expect(await scheduler.canceledIDs.isEmpty)
    }

    @Test("Cancela alarmas de eventos que ya no existen")
    func cancelaHuérfanas() async throws {
        let obsoleta = UUID()
        let scheduler = FakeScheduler(preloaded: [obsoleta])

        let outcome = try await reconcile(scheduler, events: [makeEvent(id: "a", startingIn: 60)])

        #expect(outcome.canceled == 1)
        #expect(await scheduler.canceledIDs == [obsoleta])
    }

    @Test("Cambiar la antelación mueve la alarma en vez de duplicarla")
    func cambioDeAntelacion() async throws {
        let event = makeEvent(id: "a", startingIn: 120)
        let vieja = AlarmRequest(event: event, leadMinutes: 10, snoozeMinutes: 5)
        let scheduler = FakeScheduler(preloaded: [vieja.id])

        let outcome = try await reconcile(scheduler, events: [event], settings: settings(lead: 30))

        #expect(outcome.canceled == 1, "la alarma con la antelación antigua debe retirarse")
        #expect(outcome.scheduled == 1)

        let restantes = await scheduler.scheduledRequests()
        #expect(restantes.count == 1)
        #expect(restantes[0].fireDate == event.occurrenceStart.addingTimeInterval(-30 * 60))
    }

    @Test("Apagar un calendario retira sus alarmas")
    func calendarioApagado() async throws {
        let event = makeEvent(id: "a", startingIn: 60)
        let existing = AlarmRequest(event: event, leadMinutes: 10, snoozeMinutes: 5)
        let scheduler = FakeScheduler(preloaded: [existing.id])

        let outcome = try await reconcile(scheduler, events: [event], enabled: [])

        #expect(outcome.canceled == 1)
        #expect(outcome.scheduled == 0)
        #expect(outcome.skipped[event.id] == .calendarDisabled)
    }

    @Test("Al tocar el tope del sistema conserva las alarmas más cercanas")
    func topeDelSistema() async throws {
        // AlarmKit expone `maximumLimitReached` pero Apple no documenta el número, así
        // que el motor debe comportarse bien sea cual sea: lo urgente entra primero.
        let scheduler = FakeScheduler(limit: 2)
        let events = (1...5).map { makeEvent(id: "e\($0)", startingIn: $0 * 60) }

        let outcome = try await reconcile(scheduler, events: events.shuffled())

        #expect(outcome.limitReached)
        #expect(outcome.scheduled == 2)

        let programadas = await scheduler.scheduledRequests()
        #expect(programadas.map(\.event.eventIdentifier) == ["e1", "e2"])
        #expect(outcome.coveredUntil == programadas.last?.fireDate)
    }

    @Test("Registra el motivo de cada evento descartado")
    func motivosDeDescarte() async throws {
        let scheduler = FakeScheduler()
        let rechazado = makeEvent(id: "a", startingIn: 60, myResponse: .declined)
        let pendiente = makeEvent(id: "b", startingIn: 60, myResponse: .pending)
        let cancelado = makeEvent(id: "c", startingIn: 60, status: .canceled)

        let outcome = try await reconcile(scheduler, events: [rechazado, pendiente, cancelado])

        #expect(outcome.scheduled == 0)
        #expect(outcome.skipped[rechazado.id] == .declined)
        #expect(outcome.skipped[pendiente.id] == .notConfirmed)
        #expect(outcome.skipped[cancelado.id] == .canceled)
    }

    @Test("El modo «todos» programa también lo no confirmado")
    func modoTodos() async throws {
        let scheduler = FakeScheduler()
        let events = [
            makeEvent(id: "a", startingIn: 60, myResponse: .pending),
            makeEvent(id: "b", startingIn: 90, myResponse: .tentative)
        ]

        let outcome = try await reconcile(scheduler, events: events, settings: settings(mode: .all))

        #expect(outcome.scheduled == 2)
    }
}

@Suite("Eventos movidos de hora")
struct MovedEventTests {

    /// Reproduce el caso real: el usuario mueve un evento en la app Calendario.
    @Test("Mover un evento retira la alarma vieja y pone otra a la hora nueva")
    func moverEventoMueveLaAlarma() async throws {
        let antes = makeEvent(id: "reunion", startingIn: 120)
        let vieja = AlarmRequest(event: antes, leadMinutes: 10, snoozeMinutes: 5)
        let scheduler = FakeScheduler(preloaded: [vieja.id])

        // El mismo evento, ahora una hora más tarde.
        let despues = makeEvent(id: "reunion", startingIn: 180)

        let outcome = try await SyncEngine(scheduler: scheduler).reconcile(
            events: [despues],
            settings: AlarmSettings(),
            enabledCalendarIDs: ["cal-trabajo"],
            now: referenceNow
        )

        #expect(outcome.canceled == 1, "la alarma de la hora antigua debe retirarse")
        #expect(outcome.scheduled == 1)
        let programadas = await scheduler.scheduledRequests()
        #expect(programadas.count == 1)
        #expect(programadas[0].fireDate == despues.occurrenceStart.addingTimeInterval(-600))
    }
}

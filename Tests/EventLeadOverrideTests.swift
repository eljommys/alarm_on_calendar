import Foundation
import Testing

@Suite("Antelación por evento")
struct EventLeadOverrideTests {

    private func settings(general: Int = 10, calendario: Int? = nil) -> AlarmSettings {
        var s = AlarmSettings()
        s.defaultLeadMinutes = general
        if let calendario {
            s.perCalendar["cal-trabajo"] = .init(isEnabled: true, leadMinutesOverride: calendario)
        }
        return s
    }

    // MARK: - La cascada

    @Test("Sin nada personalizado se aplica la antelación general")
    func general() {
        let s = settings(general: 10)
        #expect(s.leadMinutes(for: makeEvent()) == 10)
    }

    @Test("La del calendario pisa a la general")
    func calendario() {
        let s = settings(general: 10, calendario: 20)
        #expect(s.leadMinutes(for: makeEvent()) == 20)
    }

    @Test("La del evento pisa a la del calendario y a la general")
    func evento() {
        var s = settings(general: 10, calendario: 20)
        let event = makeEvent()
        s.setLeadOverride(45, for: event)

        #expect(s.leadMinutes(for: event) == 45)
        #expect(s.leadOverride(for: event) == 45)
    }

    @Test("Quitar la del evento vuelve a la del calendario, no a la general")
    func quitarVuelveAlCalendario() {
        var s = settings(general: 10, calendario: 20)
        let event = makeEvent()
        s.setLeadOverride(45, for: event)
        s.setLeadOverride(nil, for: event)

        #expect(s.leadMinutes(for: event) == 20)
        #expect(s.leadOverride(for: event) == nil)
    }

    @Test("Cada ocurrencia de una serie tiene su propia antelación")
    func porOcurrencia() {
        var s = settings()
        let semana1 = makeEvent(id: "serie", startingIn: 60)
        let semana2 = makeEvent(id: "serie", startingIn: 60 + 7 * 24 * 60)
        s.setLeadOverride(30, for: semana1)

        #expect(s.leadMinutes(for: semana1) == 30)
        #expect(s.leadMinutes(for: semana2) == 10)
    }

    // MARK: - Independencia de los dos ajustes manuales

    @Test("Personalizar la antelación no toca el encendido manual")
    func independenciaHaciaElToggle() {
        var s = settings()
        let event = makeEvent(myResponse: .pending)   // sin alarma en modo confirmados
        s.setLeadOverride(30, for: event)

        // Sigue sin alarma: la antelación no implica encendido.
        #expect(s.override(for: event) == nil)
        let d = EventFilter.decide(event, settings: s, calendarEnabled: true, now: referenceNow)
        #expect(d == .skip(.notConfirmed))
    }

    @Test("Apagar y volver a encender conserva la antelación personalizada")
    func independenciaHaciaLaAntelacion() {
        var s = settings()
        let event = makeEvent()
        s.setLeadOverride(30, for: event)
        s.setOverride(false, for: event)
        s.setOverride(true, for: event)

        #expect(s.leadOverride(for: event) == 30)
        #expect(s.override(for: event) == true)
    }

    @Test("Quitar ambos ajustes elimina la entrada del diccionario")
    func entradaVaciaSeRetira() {
        var s = settings()
        let event = makeEvent()
        s.setLeadOverride(30, for: event)
        s.setOverride(true, for: event)
        #expect(s.perEvent.count == 1)

        s.setOverride(nil, for: event)
        s.setLeadOverride(nil, for: event)

        #expect(s.perEvent.isEmpty)
    }

    @Test("«Volver al automático» borra encendido y antelación a la vez")
    func volverAlAutomatico() {
        var s = settings()
        let event = makeEvent()
        s.setLeadOverride(30, for: event)
        s.setOverride(false, for: event)

        s.clearOverrides(for: event)

        #expect(s.perEvent.isEmpty)
        #expect(s.leadMinutes(for: event) == 10)
    }

    // MARK: - Efecto en la alarma real

    @Test("El filtro calcula la hora de disparo con la antelación del evento")
    func filtroUsaLaDelEvento() {
        // Empieza en 25 min: con la general (10) entra; con la personalizada (30), ya pasó.
        var s = settings(general: 10)
        let event = makeEvent(startingIn: 25)
        #expect(EventFilter.decide(event, settings: s, calendarEnabled: true, now: referenceNow) == .schedule)

        s.setLeadOverride(30, for: event)

        let d = EventFilter.decide(event, settings: s, calendarEnabled: true, now: referenceNow)
        #expect(d == .skip(.alreadyPast))
    }

    @Test("Cambiar la antelación de un evento mueve su alarma en la reconciliación")
    func sincronizacionMueveLaAlarma() async throws {
        var s = settings(general: 10)
        let event = makeEvent(id: "a", startingIn: 120)
        let vieja = AlarmRequest(event: event, leadMinutes: 10, snoozeMinutes: s.snoozeMinutes)
        let scheduler = FakeScheduler(preloaded: [vieja.id])
        s.setLeadOverride(45, for: event)

        let outcome = try await SyncEngine(scheduler: scheduler).reconcile(
            events: [event],
            settings: s,
            enabledCalendarIDs: ["cal-trabajo"],
            now: referenceNow
        )

        #expect(outcome.canceled == 1, "la alarma con la antelación anterior se retira")
        #expect(outcome.scheduled == 1)
        let requests = await scheduler.scheduledRequests()
        #expect(requests.first?.fireDate == event.occurrenceStart.addingTimeInterval(-45 * 60))
    }

    // MARK: - Compatibilidad

    @Test("Una anulación guardada por la versión anterior sigue leyéndose")
    func compatibilidadHaciaAtras() throws {
        // Formato viejo: isEnabled era Bool obligatorio y no existía leadMinutesOverride.
        let json = """
        {"perEvent":{"evt-1|1780123456":{"isEnabled":true,"occurrenceStart":808430400}}}
        """
        let decoded = try JSONDecoder().decode(AlarmSettings.self, from: Data(json.utf8))

        let entry = try #require(decoded.perEvent["evt-1|1780123456"])
        #expect(entry.isEnabled == true)
        #expect(entry.leadMinutesOverride == nil)
    }
}

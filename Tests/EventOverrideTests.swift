import Foundation
import Testing

@Suite("Anulación manual por evento")
struct EventOverrideTests {

    private func settings(
        mode: AlarmSettings.Mode = .confirmedOnly,
        override: Bool? = nil,
        for event: EventSnapshot? = nil
    ) -> AlarmSettings {
        var settings = AlarmSettings()
        settings.mode = mode
        if let event { settings.setOverride(override, for: event) }
        return settings
    }

    private func decide(_ event: EventSnapshot, _ settings: AlarmSettings) -> EventFilter.Decision {
        EventFilter.decide(event, settings: settings, calendarEnabled: true, now: referenceNow)
    }

    // MARK: - Encender a mano

    @Test("Encender a mano gana a «aún no has confirmado»")
    func enciendeSobreNoConfirmado() {
        let event = makeEvent(myResponse: .pending)
        #expect(decide(event, settings()) == .skip(.notConfirmed))
        #expect(decide(event, settings(override: true, for: event)) == .schedule)
    }

    @Test("Encender a mano gana a «evento de todo el día»")
    func enciendeSobreTodoElDia() {
        let event = makeEvent(isAllDay: true)
        #expect(decide(event, settings()) == .skip(.allDay))
        #expect(decide(event, settings(override: true, for: event)) == .schedule)
    }

    @Test("Encender a mano gana incluso a rechazado o cancelado", arguments: [
        (EventSnapshot.Status.confirmed, EventSnapshot.MyResponse.declined),
        (.canceled, .accepted)
    ])
    func enciendeSobreRechazadoOCancelado(
        status: EventSnapshot.Status,
        response: EventSnapshot.MyResponse
    ) {
        // Si el usuario lo pide expresamente, se le hace caso: «a placer» significa eso.
        let event = makeEvent(status: status, myResponse: response)
        #expect(decide(event, settings()) != .schedule)
        #expect(decide(event, settings(override: true, for: event)) == .schedule)
    }

    // MARK: - Apagar a mano

    @Test("Apagar a mano quita la alarma de un evento que sí la tendría")
    func apagaSobreAceptado() {
        let event = makeEvent(myResponse: .accepted)
        #expect(decide(event, settings()) == .schedule)
        #expect(decide(event, settings(override: false, for: event)) == .skip(.turnedOff))
    }

    @Test("Apagar a mano manda también en modo «todos los eventos»")
    func apagaEnModoTodos() {
        let event = makeEvent(myResponse: .pending)
        var s = settings(mode: .all)
        s.setOverride(false, for: event)
        #expect(decide(event, s) == .skip(.turnedOff))
    }

    // MARK: - Límites

    @Test("Ni encendiendo a mano se puede programar una alarma cuya hora ya pasó")
    func noSePuedeViajarAlPasado() {
        // Empieza en 5 minutos y la antelación por defecto son 10.
        let event = makeEvent(startingIn: 5)
        #expect(decide(event, settings(override: true, for: event)) == .skip(.alreadyPast))
    }

    @Test("Un calendario apagado sigue mandando sobre la decisión manual")
    func calendarioApagadoManda() {
        // Coherente con ocultar esos eventos de la lista: si el calendario no se
        // monitoriza, no debe quedar viva una alarma suelta de un ajuste anterior.
        let event = makeEvent()
        var s = settings()
        s.setOverride(true, for: event)
        let decision = EventFilter.decide(event, settings: s, calendarEnabled: false, now: referenceNow)
        #expect(decision == .skip(.calendarDisabled))
    }

    // MARK: - Ciclo de vida de la anulación

    @Test("Volver al automático borra la anulación")
    func vueltaAlAutomatico() {
        let event = makeEvent(myResponse: .pending)
        var s = settings()
        s.setOverride(true, for: event)
        #expect(s.override(for: event) == true)

        s.setOverride(nil, for: event)

        #expect(s.override(for: event) == nil)
        #expect(decide(event, s) == .skip(.notConfirmed))
    }

    @Test("Cada repetición de una serie se decide por separado")
    func ocurrenciasIndependientes() {
        let semana1 = makeEvent(id: "serie", startingIn: 60)
        let semana2 = makeEvent(id: "serie", startingIn: 60 + 7 * 24 * 60)
        var s = settings()
        s.setOverride(false, for: semana1)

        #expect(decide(semana1, s) == .skip(.turnedOff))
        #expect(decide(semana2, s) == .schedule)
    }

    @Test("Las anulaciones de eventos pasados se purgan")
    func purgaDeAnulaciones() {
        // Sin purga, el ajuste crecería sin fin a razón de una entrada por evento tocado.
        let viejo = makeEvent(id: "viejo", startingIn: -60)
        let futuro = makeEvent(id: "futuro", startingIn: 60)
        var s = AlarmSettings()
        s.setOverride(true, for: viejo)
        s.setOverride(true, for: futuro)
        #expect(s.perEvent.count == 2)

        let cambió = s.pruneEventOverrides(olderThan: referenceNow)

        #expect(cambió)
        #expect(s.perEvent.count == 1)
        #expect(s.override(for: futuro) == true)
        #expect(s.override(for: viejo) == nil)
    }

    @Test("Purgar sin nada que purgar no toca los ajustes")
    func purgaSinCambios() {
        // Evita reescribir UserDefaults —y disparar otra resincronización— en cada ciclo.
        var s = AlarmSettings()
        s.setOverride(true, for: makeEvent(id: "futuro", startingIn: 60))
        let cambió = s.pruneEventOverrides(olderThan: referenceNow)
        #expect(cambió == false)
    }
}

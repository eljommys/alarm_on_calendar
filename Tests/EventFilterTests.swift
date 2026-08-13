import Foundation
import Testing

@Suite("Filtrado de eventos")
struct EventFilterTests {

    private let enabled = "cal-trabajo"

    private func decide(
        _ event: EventSnapshot,
        mode: AlarmSettings.Mode = .confirmedOnly,
        allDay: Bool = false,
        calendarEnabled: Bool = true
    ) -> EventFilter.Decision {
        var settings = AlarmSettings()
        settings.mode = mode
        settings.includeAllDayEvents = allDay
        return EventFilter.decide(
            event,
            settings: settings,
            calendarEnabled: calendarEnabled,
            now: referenceNow
        )
    }

    // MARK: - Modo «solo confirmados»

    @Test("Acepta lo que he confirmado")
    func aceptado() {
        #expect(decide(makeEvent(myResponse: .accepted)) == .schedule)
    }

    @Test("Acepta lo que organizo yo")
    func organizador() {
        #expect(decide(makeEvent(myResponse: .organizer)) == .schedule)
    }

    @Test("Acepta un evento personal sin invitados")
    func sinInvitados() {
        #expect(decide(makeEvent(myResponse: .notAnInvite)) == .schedule)
    }

    @Test("Descarta lo que está pendiente de responder")
    func pendiente() {
        #expect(decide(makeEvent(myResponse: .pending)) == .skip(.notConfirmed))
    }

    @Test("Descarta el «quizá»")
    func tentativo() {
        #expect(decide(makeEvent(myResponse: .tentative)) == .skip(.notConfirmed))
    }

    @Test("Ante la duda avisa: si no me localizo entre los asistentes, pone alarma")
    func desconocido() {
        // Pasa en calendarios suscritos y cuentas con el correo mal emparejado.
        // Preferimos avisar de más antes que perder un evento en silencio.
        #expect(decide(makeEvent(myResponse: .unknown)) == .schedule)
    }

    // MARK: - Modo «todos los eventos»

    @Test("En modo «todos» sí entra lo no confirmado", arguments: [
        EventSnapshot.MyResponse.pending,
        .tentative,
        .unknown,
        .accepted
    ])
    func modoTodos(response: EventSnapshot.MyResponse) {
        #expect(decide(makeEvent(myResponse: response), mode: .all) == .schedule)
    }

    @Test("Lo rechazado no lleva alarma ni siquiera en modo «todos»")
    func rechazadoEnAmbosModos() {
        // Si has dicho que no vas, una alarma es un error, no una función.
        #expect(decide(makeEvent(myResponse: .declined), mode: .all) == .skip(.declined))
        #expect(decide(makeEvent(myResponse: .declined), mode: .confirmedOnly) == .skip(.declined))
    }

    // MARK: - Descartes generales

    @Test("Un evento cancelado no despierta a nadie")
    func cancelado() {
        #expect(decide(makeEvent(status: .canceled), mode: .all) == .skip(.canceled))
    }

    @Test("Los de todo el día se saltan salvo que se activen")
    func todoElDia() {
        #expect(decide(makeEvent(isAllDay: true)) == .skip(.allDay))
        #expect(decide(makeEvent(isAllDay: true), allDay: true) == .schedule)
    }

    @Test("Un calendario apagado descarta sus eventos")
    func calendarioApagado() {
        #expect(decide(makeEvent(), calendarEnabled: false) == .skip(.calendarDisabled))
    }

    @Test("Si la hora de la alarma ya pasó, no se programa")
    func yaPasado() {
        // Empieza en 5 minutos y la antelación por defecto es de 10.
        #expect(decide(makeEvent(startingIn: 5)) == .skip(.alreadyPast))
    }

    @Test("Un evento que empieza justo después de la antelación sí entra")
    func justoEnElLimite() {
        #expect(decide(makeEvent(startingIn: 11)) == .schedule)
    }

    // MARK: - Prioridad entre reglas

    @Test("Cancelado gana a todo lo demás")
    func prioridadCancelado() {
        let event = makeEvent(isAllDay: true, status: .canceled, myResponse: .pending)
        #expect(decide(event) == .skip(.canceled))
    }
}

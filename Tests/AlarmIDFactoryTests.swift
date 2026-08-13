import Foundation
import Testing

@Suite("Identificadores de alarma")
struct AlarmIDFactoryTests {

    private func request(
        _ event: EventSnapshot,
        leadMinutes: Int = 10,
        snoozeMinutes: Int = 5
    ) -> AlarmRequest {
        AlarmRequest(event: event, leadMinutes: leadMinutes, snoozeMinutes: snoozeMinutes)
    }

    @Test("El mismo evento y los mismos ajustes producen siempre el mismo identificador")
    func esDeterminista() {
        let event = makeEvent()
        #expect(request(event).id == request(event).id)
    }

    @Test("Cada repetición de una serie recurrente tiene su propio identificador")
    func ocurrenciasSeparadas() {
        // En EventKit todas las repeticiones comparten `eventIdentifier`, así que sin
        // incluir la fecha las 52 reuniones semanales colapsarían en una sola alarma.
        let semana1 = makeEvent(id: "serie", startingIn: 60)
        let semana2 = makeEvent(id: "serie", startingIn: 60 + 7 * 24 * 60)

        #expect(semana1.eventIdentifier == semana2.eventIdentifier)
        #expect(request(semana1).id != request(semana2).id)
    }

    @Test("Eventos distintos a la misma hora no colisionan")
    func eventosDistintos() {
        #expect(request(makeEvent(id: "evt-a")).id != request(makeEvent(id: "evt-b")).id)
    }

    @Test("Cambiar la antelación cambia el identificador")
    func antelacionCambiaLaAlarma() {
        // Es lo que permite que SyncEngine, comparando solo conjuntos de identificadores,
        // se entere de que la alarma debe sonar a otra hora: retira la vieja y pone la nueva.
        let event = makeEvent()
        #expect(request(event, leadMinutes: 10).id != request(event, leadMinutes: 30).id)
    }

    @Test("Cambiar los minutos de posponer cambia el identificador")
    func posponerCambiaLaAlarma() {
        let event = makeEvent()
        #expect(request(event, snoozeMinutes: 5).id != request(event, snoozeMinutes: 15).id)
    }

    @Test("Renombrar el evento cambia el identificador")
    func renombrarCambiaLaAlarma() {
        // El título se muestra en la Live Activity, así que una alarma con el nombre
        // antiguo estaría mostrando información obsoleta en la pantalla de bloqueo.
        #expect(request(makeEvent(title: "Diseño")).id != request(makeEvent(title: "Diseño v2")).id)
    }

    @Test("Mover el evento de hora cambia el identificador")
    func moverElEventoCambiaLaAlarma() {
        #expect(request(makeEvent(startingIn: 120)).id != request(makeEvent(startingIn: 180)).id)
    }

    @Test("El identificador es un UUID versión 4 bien formado")
    func formatoValido() {
        let bytes = withUnsafeBytes(of: request(makeEvent()).id.uuid) { Array($0) }
        #expect(bytes[6] & 0xF0 == 0x40, "la versión debe ser 4")
        #expect(bytes[8] & 0xC0 == 0x80, "la variante debe ser RFC 4122")
    }
}

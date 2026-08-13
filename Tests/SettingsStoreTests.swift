import Foundation
import Testing

@MainActor
@Suite("Almacén de ajustes")
struct SettingsStoreTests {

    /// `UserDefaults` aislado por test para no pisar los ajustes reales.
    private func makeStore() -> (SettingsStore, UserDefaults) {
        let suiteName = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return (SettingsStore(defaults: defaults), defaults)
    }

    @Test("Una escritura en los ajustes se conserva")
    func mutacionSeConserva() {
        // Regresión: con `settings` como propiedad almacenada con `didSet`, el macro
        // `@Observable` no la instrumentaba y las escrituras desde la interfaz se
        // perdían — los interruptores volvían solos a su posición anterior.
        let (store, _) = makeStore()
        #expect(store.settings.includeAllDayEvents == false)

        store.settings.includeAllDayEvents = true

        #expect(store.settings.includeAllDayEvents)
    }

    @Test("Activar un calendario queda registrado")
    func calendarioActivado() {
        let (store, _) = makeStore()
        #expect(store.settings.isEnabled(calendarIdentifier: "cal-1", whenUnset: false) == false)

        store.setCalendarEnabled(true, calendarIdentifier: "cal-1")

        #expect(store.settings.isEnabled(calendarIdentifier: "cal-1", whenUnset: false))
    }

    @Test("Los cambios sobreviven a reiniciar la app")
    func persistencia() {
        let (store, defaults) = makeStore()
        store.settings.defaultLeadMinutes = 45
        store.setLeadOverride(15, calendarIdentifier: "cal-1", currentlyEnabled: true)

        let recargado = SettingsStore(defaults: defaults)

        #expect(recargado.settings.defaultLeadMinutes == 45)
        #expect(recargado.settings.leadMinutes(calendarIdentifier: "cal-1") == 15)
        #expect(recargado.settings.leadMinutes(calendarIdentifier: "otro") == 45)
    }

    @Test("Quitar la antelación propia devuelve el calendario a la general")
    func quitarOverride() {
        let (store, _) = makeStore()
        store.settings.defaultLeadMinutes = 20
        store.setLeadOverride(5, calendarIdentifier: "cal-1", currentlyEnabled: true)
        #expect(store.settings.leadMinutes(calendarIdentifier: "cal-1") == 5)

        store.setLeadOverride(nil, calendarIdentifier: "cal-1", currentlyEnabled: true)

        #expect(store.settings.leadMinutes(calendarIdentifier: "cal-1") == 20)
    }
}

@Suite("Compatibilidad de ajustes guardados")
struct SettingsCodableTests {

    /// Ajustes tal y como los guardaba una versión anterior, sin la clave `perEvent`.
    private let jsonAntiguo = """
    {"snoozeMinutes":5,"horizonDays":7,"defaultLeadMinutes":10,\
    "includeAllDayEvents":true,"mode":"confirmedOnly",\
    "perCalendar":{"cal-1":{"isEnabled":true}}}
    """

    @Test("Unos ajustes guardados por una versión anterior siguen leyéndose")
    func compatibilidadHaciaAtras() throws {
        // Si esto falla, cada campo nuevo que se añada a AlarmSettings borra en
        // silencio TODAS las preferencias del usuario al actualizar la app.
        let decoded = try JSONDecoder().decode(AlarmSettings.self, from: Data(jsonAntiguo.utf8))

        #expect(decoded.includeAllDayEvents)
        #expect(decoded.defaultLeadMinutes == 10)
        #expect(decoded.perCalendar["cal-1"]?.isEnabled == true)
        #expect(decoded.perEvent.isEmpty)
    }
}

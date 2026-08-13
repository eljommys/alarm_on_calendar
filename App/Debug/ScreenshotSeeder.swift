#if DEBUG
import EventKit
import Foundation

/// Crea calendarios y eventos de ejemplo para poder hacer las capturas de la App Store.
///
/// Vive dentro de `#if DEBUG` y solo actúa si se pasa el argumento de lanzamiento
/// `-seed-screenshot-data`, así que **no existe en la compilación de release**: la app
/// publicada no crea ni modifica nada en el calendario del usuario, tal y como dice la
/// política de privacidad.
///
///     xcrun simctl launch booted com.rackslabs.alarmoncalendar -seed-screenshot-data
enum ScreenshotSeeder {

    static var isRequested: Bool {
        ProcessInfo.processInfo.arguments.contains("-seed-screenshot-data")
    }

    /// Marca en las notas para poder reconocer y limpiar lo sembrado en pasadas anteriores.
    private static let marca = "· alarma-agenda-captura ·"

    /// Títulos de los calendarios de ejemplo, para reconocerlos y borrarlos después.
    private static let titulosSembrados = ["Trabajo", "Personal", "Work"]

    private struct Plantilla {
        let titulo: String
        let lugar: String?
        let calendario: String
        /// Días desde hoy y hora en punto, para que las capturas salgan con horas limpias.
        let dias: Int
        let hora: Int
        let minuto: Int
        let duracion: Int
    }

    static func seed(locale: String) {
        let store = EKEventStore()
        Task { @MainActor in
            do {
                _ = try await store.requestFullAccessToEvents()
                try limpiar(store)
                let ingles = locale.hasPrefix("en")
                let calendarios = try crearCalendarios(store, ingles: ingles)
                try crearEventos(store, calendarios: calendarios, ingles: ingles)
            } catch {
                print("ScreenshotSeeder: \(error)")
            }
        }
    }

    // MARK: -

    private static func limpiar(_ store: EKEventStore) throws {
        let desde = Date().addingTimeInterval(-86_400 * 30)
        let hasta = Date().addingTimeInterval(86_400 * 30)
        let predicado = store.predicateForEvents(withStart: desde, end: hasta, calendars: nil)
        for evento in store.events(matching: predicado)
        where evento.notes?.contains(marca) == true {
            try? store.remove(evento, span: .thisEvent)
        }
        // Por prefijo, no por igualdad, para barrer también los nombres que usaron
        // pasadas anteriores mientras se afinaban las capturas.
        for calendario in store.calendars(for: .event)
        where calendario.source?.sourceType == .local
            && titulosSembrados.contains(where: { calendario.title.hasPrefix($0) }) {
            try? store.removeCalendar(calendario, commit: true)
        }
    }

    private static func crearCalendarios(
        _ store: EKEventStore,
        ingles: Bool
    ) throws -> [String: EKCalendar] {
        guard let fuente = store.sources.first(where: { $0.sourceType == .local })
                ?? store.defaultCalendarForNewEvents?.source else { return [:] }

        var resultado: [String: EKCalendar] = [:]
        for (clave, nombre, color) in [
            ("trabajo", ingles ? "Work" : "Trabajo", CGColor(red: 0.20, green: 0.47, blue: 0.96, alpha: 1)),
            ("personal", "Personal", CGColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 1)),
        ] {
            let calendario = EKCalendar(for: .event, eventStore: store)
            calendario.title = nombre
            calendario.source = fuente
            calendario.cgColor = color
            try store.saveCalendar(calendario, commit: true)
            resultado[clave] = calendario
        }
        return resultado
    }

    private static func crearEventos(
        _ store: EKEventStore,
        calendarios: [String: EKCalendar],
        ingles: Bool
    ) throws {
        let plantillas: [Plantilla] = ingles ? [
            .init(titulo: "Design review", lugar: "Meet", calendario: "trabajo", dias: 1, hora: 9, minuto: 30, duracion: 45),
            .init(titulo: "1:1 with Marta", lugar: nil, calendario: "trabajo", dias: 1, hora: 11, minuto: 0, duracion: 30),
            .init(titulo: "Dentist", lugar: "Clínica Sur", calendario: "personal", dias: 1, hora: 13, minuto: 30, duracion: 60),
            .init(titulo: "Sprint planning", lugar: "Room 3", calendario: "trabajo", dias: 1, hora: 16, minuto: 0, duracion: 60),
            .init(titulo: "Pick up the kids", lugar: nil, calendario: "personal", dias: 2, hora: 17, minuto: 0, duracion: 30),
        ] : [
            .init(titulo: "Revisión de diseño", lugar: "Meet", calendario: "trabajo", dias: 1, hora: 9, minuto: 30, duracion: 45),
            .init(titulo: "1:1 con Marta", lugar: nil, calendario: "trabajo", dias: 1, hora: 11, minuto: 0, duracion: 30),
            .init(titulo: "Dentista", lugar: "Clínica Sur", calendario: "personal", dias: 1, hora: 13, minuto: 30, duracion: 60),
            .init(titulo: "Planificación del sprint", lugar: "Sala 3", calendario: "trabajo", dias: 1, hora: 16, minuto: 0, duracion: 60),
            .init(titulo: "Recoger a los niños", lugar: nil, calendario: "personal", dias: 2, hora: 17, minuto: 0, duracion: 30),
        ]

        let calendario = Calendar.current
        for plantilla in plantillas {
            guard let cal = calendarios[plantilla.calendario],
                  let dia = calendario.date(byAdding: .day, value: plantilla.dias, to: Date()),
                  let inicio = calendario.date(
                    bySettingHour: plantilla.hora, minute: plantilla.minuto, second: 0, of: dia
                  ) else { continue }
            let evento = EKEvent(eventStore: store)
            evento.title = plantilla.titulo
            evento.location = plantilla.lugar
            evento.calendar = cal
            evento.notes = marca
            evento.startDate = inicio
            evento.endDate = inicio.addingTimeInterval(Double(plantilla.duracion) * 60)
            try store.save(evento, span: .thisEvent)
        }
    }
}
#endif

import Foundation
import Observation

/// Persiste `AlarmSettings` en `UserDefaults`. Es todo lo que la app guarda, y se
/// queda en el dispositivo: no hay iCloud, ni servidor, ni exportación.
@MainActor
@Observable
final class SettingsStore {

    private static let key = "AlarmOnCalendar.settings.v1"

    /// Respaldo observable de verdad.
    ///
    /// `settings` es una propiedad computada sobre esta, en vez de una almacenada con
    /// `didSet`, porque el macro `@Observable` no instrumenta correctamente las
    /// propiedades almacenadas que llevan observadores: las escrituras desde la interfaz
    /// se perdían sin previo aviso y los interruptores volvían solos a su sitio.
    private var storage: AlarmSettings

    var settings: AlarmSettings {
        get { storage }
        set {
            guard newValue != storage else { return }
            storage = newValue
            persist()
        }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode(AlarmSettings.self, from: data) {
            self.storage = decoded
        } else {
            self.storage = AlarmSettings()
        }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(storage) else { return }
        defaults.set(data, forKey: Self.key)
    }

    // MARK: - Ayudas para la interfaz

    func setCalendarEnabled(_ isEnabled: Bool, calendarIdentifier: String) {
        var entry = settings.perCalendar[calendarIdentifier] ?? AlarmSettings.CalendarSetting()
        entry.isEnabled = isEnabled
        settings.perCalendar[calendarIdentifier] = entry
    }

    func setLeadOverride(_ minutes: Int?, calendarIdentifier: String, currentlyEnabled: Bool) {
        var entry = settings.perCalendar[calendarIdentifier]
            ?? AlarmSettings.CalendarSetting(isEnabled: currentlyEnabled)
        entry.leadMinutesOverride = minutes
        settings.perCalendar[calendarIdentifier] = entry
    }
}

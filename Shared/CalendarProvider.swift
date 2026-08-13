import Foundation

/// De qué servicio viene un calendario. Se deduce de `EKSource`, y sirve tanto para
/// agrupar la lista de calendarios como para saber qué proveedores ya están vinculados
/// y no repetirlos en la guía de configuración.
enum CalendarProvider: String, Sendable, Hashable, CaseIterable, Identifiable {
    case apple
    case google
    case microsoft
    case otherCalDAV
    case local
    case subscribed
    case birthdays

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .apple: String(localized: "iCloud")
        case .google: String(localized: "Google")
        case .microsoft: String(localized: "Microsoft / Exchange")
        case .otherCalDAV: String(localized: "Otra cuenta CalDAV")
        case .local: String(localized: "En el iPhone")
        case .subscribed: String(localized: "Calendarios suscritos")
        case .birthdays: String(localized: "Cumpleaños")
        }
    }

    var systemImage: String {
        switch self {
        case .apple: "icloud"
        case .google: "envelope"
        case .microsoft: "briefcase"
        case .otherCalDAV: "network"
        case .local: "iphone"
        case .subscribed: "link"
        case .birthdays: "gift"
        }
    }

    /// Los proveedores que la guía enseña a vincular desde Ajustes.
    static let linkable: [CalendarProvider] = [.apple, .google, .microsoft]

    /// Calendarios de festivos, suscripciones y cumpleaños generan mucho ruido:
    /// se muestran, pero llegan apagados para que el usuario los encienda si quiere.
    var isEnabledByDefault: Bool {
        switch self {
        case .subscribed, .birthdays: false
        default: true
        }
    }
}

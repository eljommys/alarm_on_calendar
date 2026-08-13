import ActivityKit
import AlarmKit
import Foundation
import SwiftUI

/// Adaptador entre `AlarmScheduling` y AlarmKit.
///
/// Es la única pieza de la app que conoce AlarmKit; todo lo de arriba trabaja con
/// `AlarmRequest` y `AlarmSchedulingError`.
///
/// No se aísla a `@MainActor` a propósito: `AlarmManager` no es `Sendable`, así que
/// hacer `await` sobre él desde el actor principal lo cruzaría entre dominios de
/// aislamiento y Swift 6 lo rechaza. Manteniendo la clase sin aislar, cada llamada
/// obtiene y usa `AlarmManager.shared` dentro del mismo contexto y no cruza nada.
final class AlarmKitScheduler: AlarmScheduling {

    static let shared = AlarmKitScheduler()

    private init() {}

    // MARK: - Autorización

    var authorizationState: AlarmManager.AuthorizationState {
        AlarmManager.shared.authorizationState
    }

    @discardableResult
    func requestAuthorization() async -> AlarmManager.AuthorizationState {
        let manager = AlarmManager.shared
        if manager.authorizationState == .authorized { return .authorized }
        do {
            return try await manager.requestAuthorization()
        } catch {
            return manager.authorizationState
        }
    }

    // MARK: - AlarmScheduling

    func scheduledAlarmIDs() async throws -> Set<UUID> {
        Set(try AlarmManager.shared.alarms.map(\.id))
    }

    func schedule(_ request: AlarmRequest) async throws {
        let manager = AlarmManager.shared
        guard manager.authorizationState == .authorized else {
            throw AlarmSchedulingError.notAuthorized
        }

        let configuration = AlarmManager.AlarmConfiguration(
            countdownDuration: Alarm.CountdownDuration(
                preAlert: nil,
                // `postAlert` es lo que convierte el botón secundario en un posponer real:
                // al pulsarlo la alarma entra en cuenta atrás y vuelve a sonar.
                postAlert: TimeInterval(request.snoozeMinutes * 60)
            ),
            schedule: .fixed(request.fireDate),
            attributes: Self.attributes(for: request),
            sound: .default
        )

        do {
            _ = try await manager.schedule(id: request.id, configuration: configuration)
        } catch AlarmManager.AlarmError.maximumLimitReached {
            throw AlarmSchedulingError.limitReached
        } catch {
            throw AlarmSchedulingError.underlying(String(describing: error))
        }
    }

    func cancel(id: UUID) async throws {
        try AlarmManager.shared.cancel(id: id)
    }

    // MARK: - Presentación

    private static func attributes(for request: AlarmRequest) -> AlarmAttributes<EventAlarmMetadata> {
        let snoozeButton = AlarmButton(
            text: "Posponer \(request.snoozeMinutes) min",
            textColor: .white,
            systemImageName: "zzz"
        )

        let alert = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: request.event.title),
            secondaryButton: snoozeButton,
            secondaryButtonBehavior: .countdown
        )

        // Estado tras pulsar «Posponer»: la barra de cuenta atrás en pantalla de bloqueo.
        let countdown = AlarmPresentation.Countdown(
            title: LocalizedStringResource(stringLiteral: request.event.title),
            pauseButton: nil
        )

        return AlarmAttributes(
            presentation: AlarmPresentation(alert: alert, countdown: countdown),
            metadata: EventAlarmMetadata(event: request.event),
            tintColor: Color.accentColor
        )
    }
}

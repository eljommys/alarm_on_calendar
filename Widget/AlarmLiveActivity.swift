import ActivityKit
import AlarmKit
import SwiftUI
import WidgetKit

/// Presentación de la alarma en pantalla de bloqueo y Dynamic Island.
///
/// AlarmKit empareja esta configuración con las alarmas de la app por el tipo genérico
/// `AlarmAttributes<EventAlarmMetadata>`: debe ser exactamente el mismo tipo que usa
/// `AlarmKitScheduler`, y por eso `EventAlarmMetadata` se compila en los dos targets.
struct AlarmLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<EventAlarmMetadata>.self) { context in
            LockScreenView(
                metadata: context.attributes.metadata,
                mode: context.state.mode,
                tint: context.attributes.tintColor
            )
            .padding()
            .activityBackgroundTint(.black.opacity(0.55))

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "alarm.fill")
                        .font(.title2)
                        .foregroundStyle(context.attributes.tintColor)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ModeIndicator(mode: context.state.mode, tint: context.attributes.tintColor)
                        .font(.title3.monospacedDigit())
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.metadata?.eventTitle ?? "Evento")
                            .font(.headline)
                            .lineLimit(1)
                        if let start = context.attributes.metadata?.eventStart {
                            Text("Empieza a las \(start.formatted(date: .omitted, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } compactLeading: {
                Image(systemName: "alarm.fill")
                    .foregroundStyle(context.attributes.tintColor)
            } compactTrailing: {
                ModeIndicator(mode: context.state.mode, tint: context.attributes.tintColor)
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "alarm.fill")
                    .foregroundStyle(context.attributes.tintColor)
            }
        }
    }
}

// MARK: - Pantalla de bloqueo

private struct LockScreenView: View {
    let metadata: EventAlarmMetadata?
    let mode: AlarmPresentationState.Mode
    let tint: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "alarm.fill")
                .font(.title)
                .foregroundStyle(tint)

            VStack(alignment: .leading, spacing: 3) {
                Text(metadata?.eventTitle ?? "Evento")
                    .font(.headline)
                    .lineLimit(2)

                if let metadata {
                    Text(subtitle(for: metadata))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            ModeIndicator(mode: mode, tint: tint)
                .font(.title2.monospacedDigit())
        }
    }

    private func subtitle(for metadata: EventAlarmMetadata) -> String {
        let hora = metadata.eventStart.formatted(date: .omitted, time: .shortened)
        if let location = metadata.location, !location.isEmpty {
            return "\(hora) · \(location)"
        }
        return "\(hora) · \(metadata.calendarTitle)"
    }
}

// MARK: - Indicador de estado

/// Muestra la hora de la alarma, la cuenta atrás del posponer o el estado en pausa.
private struct ModeIndicator: View {
    let mode: AlarmPresentationState.Mode
    let tint: Color

    var body: some View {
        switch mode {
        case .alert:
            Text("Ahora")
                .foregroundStyle(tint)

        case .countdown(let countdown):
            // La barra estilo temporizador: SwiftUI la actualiza sola, sin refrescos nuestros.
            Text(timerInterval: Date.now...countdown.fireDate, countsDown: true)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(tint)

        case .paused(let paused):
            let restante = paused.totalCountdownDuration - paused.previouslyElapsedDuration
            Text(Duration.seconds(max(0, restante)).formatted(.time(pattern: .minuteSecond)))
                .foregroundStyle(.secondary)

        @unknown default:
            Text("Alarma")
                .foregroundStyle(tint)
        }
    }
}

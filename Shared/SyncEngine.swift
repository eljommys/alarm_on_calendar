import Foundation

/// Reconcilia el conjunto de alarmas que *deberían* existir con las que existen.
///
/// No guarda estado propio: la lista de alarmas programadas es la única fuente de
/// verdad, y los identificadores deterministas de `AlarmIDFactory` permiten comparar
/// ambos conjuntos directamente. Eso hace que la operación sea idempotente y que
/// sobreviva a que el usuario mate la app o reinicie el teléfono.
struct SyncEngine: Sendable {

    let scheduler: any AlarmScheduling

    struct Outcome: Equatable, Sendable {
        var scheduled: Int = 0
        var canceled: Int = 0
        var unchanged: Int = 0
        /// Si se alcanzó el tope del sistema, hasta qué instante llegamos a cubrir.
        var coveredUntil: Date?
        var limitReached: Bool = false
        /// Motivo por el que cada evento descartado no lleva alarma, para poder explicarlo.
        var skipped: [String: EventFilter.Reason] = [:]
        var failures: [String] = []
    }

    /// - Parameters:
    ///   - enabledCalendarIDs: calendarios activos ya resueltos (incluyendo los valores
    ///     por defecto de los que el usuario nunca ha tocado).
    func reconcile(
        events: [EventSnapshot],
        settings: AlarmSettings,
        enabledCalendarIDs: Set<String>,
        now: Date = Date()
    ) async throws -> Outcome {

        var outcome = Outcome()

        // 1. Conjunto deseado, de la alarma más cercana a la más lejana.
        var desired: [AlarmRequest] = []
        for event in events {
            let decision = EventFilter.decide(
                event,
                settings: settings,
                calendarEnabled: enabledCalendarIDs.contains(event.calendarIdentifier),
                now: now
            )
            switch decision {
            case .schedule:
                desired.append(AlarmRequest(
                    event: event,
                    leadMinutes: settings.leadMinutes(for: event),
                    snoozeMinutes: settings.snoozeMinutes
                ))
            case .skip(let reason):
                outcome.skipped[event.id] = reason
            }
        }
        desired.sort { $0.fireDate < $1.fireDate }

        // 2. Estado real del sistema.
        let current = try await scheduler.scheduledAlarmIDs()
        let desiredIDs = Set(desired.map(\.id))

        // 3. Retira lo que ya no toca (evento borrado, movido, rechazado, calendario apagado).
        for staleID in current.subtracting(desiredIDs) {
            do {
                try await scheduler.cancel(id: staleID)
                outcome.canceled += 1
            } catch {
                outcome.failures.append("No se pudo cancelar \(staleID): \(error)")
            }
        }

        // 4. Programa lo que falta, empezando por lo más inminente. Si el sistema corta
        //    por el tope, nos quedamos con las alarmas más próximas, que son las que
        //    de verdad importan hoy; las lejanas entrarán en el siguiente refresco.
        for request in desired {
            guard !current.contains(request.id) else {
                outcome.unchanged += 1
                outcome.coveredUntil = request.fireDate
                continue
            }
            do {
                try await scheduler.schedule(request)
                outcome.scheduled += 1
                outcome.coveredUntil = request.fireDate
            } catch AlarmSchedulingError.limitReached {
                outcome.limitReached = true
                break
            } catch {
                outcome.failures.append("No se pudo programar «\(request.event.title)»: \(error)")
            }
        }

        return outcome
    }
}

import BackgroundTasks
import Foundation

/// Refresco periódico en segundo plano.
///
/// Es una red de seguridad, no el mecanismo principal: lo habitual es que la
/// resincronización la disparen `EKEventStoreChanged` o la vuelta a primer plano.
/// Esto cubre el caso de tener la app cerrada varios días con eventos entrando por
/// la sincronización de la cuenta.
@MainActor
enum BackgroundRefresh {

    static let identifier = "com.rackslabs.alarmoncalendar.refresh"

    static func register(perform: @escaping @MainActor () async -> Void) {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: identifier,
            using: .main
        ) { task in
            MainActor.assumeIsolated {
                let work = Task {
                    await perform()
                    // Encadena el siguiente antes de terminar: iOS solo acepta una
                    // petición pendiente por identificador.
                    schedule()
                    task.setTaskCompleted(success: true)
                }
                task.expirationHandler = { work.cancel() }
            }
        }
    }

    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date().addingTimeInterval(4 * 3600)
        try? BGTaskScheduler.shared.submit(request)
    }
}

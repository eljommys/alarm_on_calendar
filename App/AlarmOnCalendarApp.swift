import SwiftUI
import UIKit

@main
struct AlarmOnCalendarApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(delegate.model)
                .task {
                    #if DEBUG
                    // Solo con el argumento -seed-screenshot-data, para las capturas.
                    if ScreenshotSeeder.isRequested {
                        ScreenshotSeeder.seed(locale: Locale.current.identifier)
                    }
                    #endif
                    await delegate.model.bootstrap()
                    BackgroundRefresh.schedule()
                }
        }
    }
}

/// Solo existe para poder registrar la tarea en segundo plano antes de que termine
/// el lanzamiento, que es lo que exige `BGTaskScheduler`.
@MainActor
final class AppDelegate: NSObject, UIApplicationDelegate {

    let model = AppModel()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        BackgroundRefresh.register { [model] in
            await model.sync()
        }
        return true
    }
}

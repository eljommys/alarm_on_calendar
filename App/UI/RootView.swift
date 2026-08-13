import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if model.isReady {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Próximos", systemImage: "alarm") {
                UpcomingEventsView()
            }
            Tab("Calendarios", systemImage: "calendar") {
                CalendarsView()
            }
            Tab("Ajustes", systemImage: "gearshape") {
                SettingsView()
            }
        }
    }
}

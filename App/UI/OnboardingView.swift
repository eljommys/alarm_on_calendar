import SwiftUI

/// Puerta de entrada: pide los dos permisos y lleva a la guía de cuentas.
struct OnboardingView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL
    @State private var showingGuide = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header

                    VStack(spacing: 14) {
                        PermissionCard(
                            icon: "calendar",
                            title: "Acceso a tu calendario",
                            detail: "Para saber qué eventos tienes y a qué hora empiezan.",
                            state: calendarState,
                            actionTitle: calendarActionTitle,
                            action: handleCalendarTap
                        )

                        PermissionCard(
                            icon: "alarm.waves.left.and.right",
                            title: "Permiso de alarmas",
                            detail: "Para que suenen aunque tengas el iPhone en silencio o en Concentración.",
                            state: alarmState,
                            actionTitle: "Permitir alarmas",
                            action: { Task { await model.requestAlarmAuthorization() } }
                        )
                    }

                    Button {
                        showingGuide = true
                    } label: {
                        Label("¿Cómo añado Google o Microsoft?", systemImage: "questionmark.circle")
                            .font(.subheadline.weight(.medium))
                    }

                    privacyNote
                }
                .padding(24)
            }
            .navigationTitle("Bienvenido")
            .navigationDestination(isPresented: $showingGuide) {
                AccountSetupGuideView()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "alarm.fill")
                .font(.system(size: 44))
                .foregroundStyle(.tint)

            Text("Una alarma de verdad antes de cada evento")
                .font(.largeTitle.bold())

            Text("No es un recordatorio: es una alarma que suena aunque tengas el móvil en silencio, con la barra de cuenta atrás en la pantalla de bloqueo.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var privacyNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lock.shield")
                .foregroundStyle(.green)
            Text("Tus eventos se leen y se procesan dentro del iPhone. La app no tiene servidor ni conexión a internet: nada de tu agenda sale del dispositivo.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.green.opacity(0.1), in: .rect(cornerRadius: 12))
    }

    // MARK: - Estado de cada permiso

    private var calendarState: PermissionCard.State {
        switch model.calendars.access {
        case .full: .granted
        case .denied, .writeOnly: .blocked
        case .notDetermined: .pending
        }
    }

    private var alarmState: PermissionCard.State {
        switch model.alarmAuthorization {
        case .authorized: .granted
        case .denied: .blocked
        case .notDetermined: .pending
        @unknown default: .pending
        }
    }

    private var calendarActionTitle: String {
        model.calendars.access == .writeOnly ? "Conceder acceso completo" : "Permitir acceso"
    }

    private func handleCalendarTap() {
        // Con acceso solo de escritura o denegado, el sistema ya no vuelve a preguntar:
        // el único camino es Ajustes.
        switch model.calendars.access {
        case .notDetermined:
            Task { await model.requestCalendarAccess() }
        case .denied, .writeOnly:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                openURL(url)
            }
        case .full:
            break
        }
    }
}

// MARK: - Tarjeta de permiso

struct PermissionCard: View {
    enum State { case pending, granted, blocked }

    let icon: String
    let title: String
    let detail: String
    let state: State
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 32)
                    .foregroundStyle(.tint)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)

                if state == .granted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                }
            }

            switch state {
            case .granted:
                EmptyView()
            case .pending:
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
            case .blocked:
                VStack(alignment: .leading, spacing: 8) {
                    Text("Lo denegaste antes, así que el sistema ya no vuelve a preguntar. Hay que activarlo a mano en Ajustes.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Abrir Ajustes", action: action)
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(.quaternary.opacity(0.4), in: .rect(cornerRadius: 16))
    }
}

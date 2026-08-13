import SwiftUI

/// Guía para vincular Google y Microsoft desde Ajustes de iOS.
///
/// No existe forma pública de abrir directamente Ajustes → Apps → Calendario → Cuentas:
/// los esquemas tipo `App-prefs:` son API privada y provocan rechazo en la revisión de
/// la App Store. Por eso el botón lleva a la ficha de la app en Ajustes y los pasos se
/// explican paso a paso.
struct AccountSetupGuideView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Tus calendarios entran por iOS, no por la app")
                        .font(.headline)
                    Text("Cuando añades una cuenta de Google o Microsoft en Ajustes, iOS se encarga de sincronizar sus calendarios. Esta app se limita a leer lo que iOS ya tiene guardado en el iPhone.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Es lo que permite que ni tu correo ni tu agenda salgan del dispositivo: la app nunca se conecta a Google ni a Microsoft.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }

            Section("Estado de tus cuentas") {
                ForEach(CalendarProvider.linkable) { provider in
                    HStack {
                        Label(provider.displayName, systemImage: provider.systemImage)
                        Spacer()
                        if model.calendars.linkedProviders.contains(provider) {
                            Label("Vinculada", systemImage: "checkmark.circle.fill")
                                .labelStyle(.iconOnly)
                                .foregroundStyle(.green)
                                .font(.title3)
                                .accessibilityLabel("\(provider.displayName): vinculada")
                        } else {
                            Text("Sin vincular")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if !model.calendars.access.canRead {
                    Text("Concede primero el acceso al calendario para poder comprobar qué cuentas tienes.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            GuideSection(
                provider: .google,
                intro: "Sirve tanto para una cuenta personal de Gmail como para Google Workspace.",
                steps: [
                    "Abre **Ajustes** en el iPhone.",
                    "Baja hasta **Apps** y entra en **Calendario**.",
                    "Toca **Cuentas** y luego **Añadir cuenta**.",
                    "Elige **Google** e inicia sesión con tu cuenta.",
                    "Al terminar, asegúrate de que el interruptor de **Calendarios** queda activado.",
                    "Vuelve aquí y tus calendarios de Google aparecerán en la pestaña Calendarios."
                ]
            )

            GuideSection(
                provider: .microsoft,
                intro: "Vale para Outlook.com, Hotmail, Microsoft 365 y Exchange de empresa.",
                steps: [
                    "Abre **Ajustes** en el iPhone.",
                    "Baja hasta **Apps** y entra en **Calendario**.",
                    "Toca **Cuentas** y luego **Añadir cuenta**.",
                    "Elige **Outlook.com** para una cuenta personal, o **Microsoft Exchange** si te la da tu empresa.",
                    "Inicia sesión y acepta lo que pida el administrador si es una cuenta de trabajo.",
                    "Comprueba que el interruptor de **Calendarios** queda activado."
                ]
            )

            Section {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                } label: {
                    Label("Abrir Ajustes", systemImage: "arrow.up.forward.app")
                }
            } footer: {
                Text("iOS solo permite abrir la ficha de esta app en Ajustes. Desde ahí, vuelve atrás una pantalla y busca **Apps → Calendario → Cuentas**.")
            }

            Section {
                Button {
                    Task { await model.sync() }
                } label: {
                    Label("Volver a buscar calendarios", systemImage: "arrow.clockwise")
                }
            } footer: {
                Text("Después de añadir una cuenta, iOS puede tardar un momento en bajar los eventos.")
            }
        }
        .navigationTitle("Vincular cuentas")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct GuideSection: View {
    let provider: CalendarProvider
    let intro: String
    let steps: [String]

    var body: some View {
        Section {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(.tint, in: .circle)

                    Text(.init(step))
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 2)
            }
        } header: {
            Label(provider.displayName, systemImage: provider.systemImage)
        } footer: {
            Text(intro)
        }
    }
}

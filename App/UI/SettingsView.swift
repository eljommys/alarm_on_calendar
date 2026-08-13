import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var settingsStore = model.settingsStore

        NavigationStack {
            Form {
                Section {
                    Picker("Qué eventos", selection: $settingsStore.settings.mode) {
                        ForEach(AlarmSettings.Mode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("Modo")
                } footer: {
                    Text(model.settings.mode.explanation)
                }

                Section {
                    Picker("Antelación general", selection: $settingsStore.settings.defaultLeadMinutes) {
                        ForEach(AlarmSettings.leadMinuteChoices, id: \.self) { minutes in
                            Text(AlarmSettings.leadLabel(minutes)).tag(minutes)
                        }
                    }
                    Picker("Posponer", selection: $settingsStore.settings.snoozeMinutes) {
                        ForEach(AlarmSettings.snoozeMinuteChoices, id: \.self) { minutes in
                            Text("\(minutes) min").tag(minutes)
                        }
                    }
                } header: {
                    Text("Alarma")
                } footer: {
                    Text("Puedes darle una antelación distinta a cada calendario desde la pestaña Calendarios.")
                }

                Section {
                    Toggle("Eventos de todo el día", isOn: $settingsStore.settings.includeAllDayEvents)
                    Picker("Programar con", selection: $settingsStore.settings.horizonDays) {
                        ForEach(AlarmSettings.horizonDayChoices, id: \.self) { days in
                            Text(days == 1 ? "1 día de margen" : "\(days) días de margen").tag(days)
                        }
                    }
                } header: {
                    Text("Alcance")
                } footer: {
                    Text("Un evento de todo el día no tiene hora de inicio real, así que su alarma sonaría a medianoche. Actívalo solo si te sirve.")
                }

                if let outcome = model.lastOutcome {
                    Section("Estado") {
                        LabeledContent("Alarmas activas", value: "\(outcome.scheduled + outcome.unchanged)")
                        LabeledContent("Eventos revisados", value: "\(model.events.count)")
                        if let until = outcome.coveredUntil {
                            LabeledContent(
                                "Cubierto hasta",
                                value: until.formatted(date: .abbreviated, time: .shortened)
                            )
                        }
                    }
                }

                Section {
                    NavigationLink {
                        AccountSetupGuideView()
                    } label: {
                        Label("Vincular Google o Microsoft", systemImage: "person.badge.plus")
                    }
                    Button {
                        Task { await model.sync() }
                    } label: {
                        Label("Resincronizar ahora", systemImage: "arrow.clockwise")
                    }
                }

                Section {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lock.shield")
                            .foregroundStyle(.green)
                        Text("Esta app no tiene servidor ni se conecta a internet. Tus eventos y tus ajustes se quedan en el iPhone.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Ajustes")
            .onChange(of: model.settings) { _, _ in
                Task { await model.sync() }
            }
        }
    }

}

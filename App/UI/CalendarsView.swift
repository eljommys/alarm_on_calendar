import SwiftUI

/// Calendarios agrupados por cuenta, con interruptor y antelación propia por calendario.
struct CalendarsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var settingsStore = model.settingsStore

        NavigationStack {
            List {
                if model.calendars.groups.isEmpty {
                    Section {
                        ContentUnavailableView {
                            Label("No hay calendarios", systemImage: "calendar")
                        } description: {
                            Text("Añade tu cuenta de Google o Microsoft en Ajustes de iOS para que aparezcan aquí.")
                        }
                    }
                }

                ForEach(model.calendars.groups) { group in
                    Section {
                        ForEach(group.calendars) { calendar in
                            CalendarRow(calendar: calendar)
                        }
                    } header: {
                        Label(group.accountTitle, systemImage: group.provider.systemImage)
                    } footer: {
                        switch group.provider {
                        case .subscribed:
                            Text("Los calendarios suscritos (festivos, deportes…) llegan apagados para no llenarte el día de alarmas.")
                        case .birthdays:
                            Text("Los cumpleaños llegan apagados: su alarma sonaría a medianoche.")
                        default:
                            EmptyView()
                        }
                    }
                }

                Section {
                    NavigationLink {
                        AccountSetupGuideView()
                    } label: {
                        Label("Vincular Google o Microsoft", systemImage: "person.badge.plus")
                    }
                }
            }
            .navigationTitle("Calendarios")
            .refreshable { await model.sync() }
        }
    }
}

private struct CalendarRow: View {
    @Environment(AppModel.self) private var model
    let calendar: CalendarStore.CalendarInfo

    private var isEnabled: Bool {
        model.settings.isEnabled(
            calendarIdentifier: calendar.id,
            whenUnset: calendar.isEnabledByDefault
        )
    }

    private var leadOverride: Int? {
        model.settings.perCalendar[calendar.id]?.leadMinutesOverride
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: Binding(
                get: { isEnabled },
                set: { newValue in
                    model.settingsStore.setCalendarEnabled(newValue, calendarIdentifier: calendar.id)
                    Task { await model.sync() }
                }
            )) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(calendar.color)
                        .frame(width: 11, height: 11)
                    Text(calendar.title)
                }
            }

            if isEnabled {
                Picker(selection: Binding(
                    get: { leadOverride ?? -1 },
                    set: { newValue in
                        model.settingsStore.setLeadOverride(
                            newValue < 0 ? nil : newValue,
                            calendarIdentifier: calendar.id,
                            currentlyEnabled: isEnabled
                        )
                        Task { await model.sync() }
                    }
                )) {
                    Text("Usar la general (\(model.settings.defaultLeadMinutes) min)").tag(-1)
                    ForEach(AlarmSettings.leadMinuteChoices, id: \.self) { minutes in
                        Text(AlarmSettings.leadLabel(minutes)).tag(minutes)
                    }
                } label: {
                    Text("Antelación")
                }
                .pickerStyle(.menu)
                .font(.subheadline)
            }
        }
        .padding(.vertical, 2)
    }

}

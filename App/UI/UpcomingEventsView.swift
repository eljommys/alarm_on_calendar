import SwiftUI

/// Lista de los próximos eventos, indicando cuáles llevan alarma y por qué los demás no.
struct UpcomingEventsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationStack {
            Group {
                if model.events.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Próximos")
            .refreshable { await model.sync() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if model.isSyncing {
                        ProgressView()
                    }
                }
            }
        }
    }

    private var list: some View {
        List {
            if let outcome = model.lastOutcome, outcome.limitReached, let until = outcome.coveredUntil {
                Section {
                    Label {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Alarmas puestas hasta el \(until.formatted(date: .abbreviated, time: .shortened))")
                                .font(.subheadline.weight(.medium))
                            Text("iOS limita cuántas alarmas puede tener una app a la vez. Las siguientes se irán programando solas conforme pasen estas.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }
            }

            if let error = model.lastSyncError {
                Section {
                    Label(error, systemImage: "xmark.octagon.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            ForEach(groupedByDay, id: \.day) { group in
                Section(dayTitle(group.day)) {
                    ForEach(group.events) { event in
                        EventRow(event: event)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Sin eventos próximos", systemImage: "calendar.badge.exclamationmark")
        } description: {
            Text("No hay nada en los próximos \(model.settings.horizonDays) días en los calendarios que tienes activados.")
        } actions: {
            Button("Volver a comprobar") {
                Task { await model.sync() }
            }
        }
    }

    private var groupedByDay: [(day: Date, events: [EventSnapshot])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: model.events) {
            calendar.startOfDay(for: $0.occurrenceStart)
        }
        return grouped
            .map { (day: $0.key, events: $0.value.sorted { $0.occurrenceStart < $1.occurrenceStart }) }
            .sorted { $0.day < $1.day }
    }

    private func dayTitle(_ day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return "Hoy" }
        if calendar.isDateInTomorrow(day) { return "Mañana" }
        return day.formatted(.dateTime.weekday(.wide).day().month(.wide)).localizedCapitalized
    }
}

// MARK: - Fila

private struct EventRow: View {
    @Environment(AppModel.self) private var model
    let event: EventSnapshot

    private var hasAlarm: Bool { model.hasAlarm(event) }
    private var isManual: Bool { model.isManual(event) }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(event.isAllDay
                 ? "Todo el día"
                 : event.occurrenceStart.formatted(date: .omitted, time: .shortened))
                .font(.subheadline.weight(.medium).monospacedDigit())
                .frame(width: 74, alignment: .trailing)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.body)
                    .lineLimit(2)

                Text(event.calendarTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                status
            }

            Spacer(minLength: 4)

            Toggle("Alarma para \(event.title)", isOn: Binding(
                get: { hasAlarm },
                set: { model.setAlarm($0, for: event) }
            ))
            .labelsHidden()
            .disabled(isPast)
        }
        .padding(.vertical, 3)
        .contextMenu {
            if isManual {
                Button {
                    model.clearOverride(for: event)
                } label: {
                    Label("Volver al automático", systemImage: "arrow.uturn.backward")
                }
            }
        }
    }

    /// Cuando la hora de la alarma ya pasó no hay nada que activar, así que el
    /// interruptor se bloquea en vez de mentir prometiendo un aviso imposible.
    private var isPast: Bool {
        model.skipReason(for: event) == .alreadyPast
    }

    @ViewBuilder
    private var status: some View {
        if hasAlarm {
            Label {
                Text("Alarma a las \(model.alarmDate(for: event).formatted(date: .omitted, time: .shortened))")
                    + Text(isManual ? " · a mano" : "")
            } icon: {
                Image(systemName: "alarm.fill")
            }
            .font(.caption2.weight(.medium))
            .foregroundStyle(.tint)
        } else if let reason = model.skipReason(for: event) {
            Label(reason.explanation, systemImage: "bell.slash")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

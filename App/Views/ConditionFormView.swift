import SwiftUI
import SwiftData
import PainTrackerKit

/// Adds a new condition, or edits an existing one.
struct ConditionFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let condition: TrackedCondition?

    @State private var name: String
    @State private var instrumentID: String
    @State private var notes: String
    @State private var reminderEnabled: Bool
    @State private var reminderWeekday: Int
    @State private var reminderTime: Date

    init(condition: TrackedCondition? = nil) {
        self.condition = condition
        _name = State(initialValue: condition?.name ?? "")
        _instrumentID = State(initialValue: condition?.instrumentID ?? InstrumentCatalog.neckDisabilityIndex.id)
        _notes = State(initialValue: condition?.notes ?? "")
        _reminderEnabled = State(initialValue: condition?.reminderEnabled ?? false)
        _reminderWeekday = State(initialValue: condition?.reminderWeekday ?? 2)
        let components = DateComponents(hour: condition?.reminderHour ?? 9, minute: condition?.reminderMinute ?? 0)
        _reminderTime = State(initialValue: Calendar.current.date(from: components) ?? .now)
    }

    private var instrument: Instrument? { InstrumentCatalog.instrument(withID: instrumentID) }

    /// Changing questionnaire would mix incomparable scores in one history.
    private var canChangeInstrument: Bool { condition?.assessments.isEmpty ?? true }

    private var resolvedName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? (instrument?.region.defaultConditionName ?? "Chronic pain") : trimmed
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Questionnaire", selection: $instrumentID) {
                        ForEach(InstrumentCatalog.all) { instrument in
                            Label(instrument.name, systemImage: instrument.region.systemImage)
                                .tag(instrument.id)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    .disabled(!canChangeInstrument)

                    if let instrument {
                        Text(instrument.summary)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("What to track")
                } footer: {
                    if !canChangeInstrument {
                        Text("The questionnaire can’t be changed once you have results. Add a new condition to use a different one.")
                    } else if instrument?.region == .general {
                        Text("Use the PEG scale for any condition without its own questionnaire, e.g. fibromyalgia, migraine, arthritis or nerve pain.")
                    }
                }

                Section("Details") {
                    TextField(instrument?.region.defaultConditionName ?? "Name", text: $name)
                    TextField("Notes (diagnosis, side, treatment…)", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }

                Section {
                    Toggle("Weekly reminder", isOn: $reminderEnabled)
                    if reminderEnabled {
                        Picker("Day", selection: $reminderWeekday) {
                            ForEach(1...7, id: \.self) { weekday in
                                Text(Calendar.current.weekdaySymbols[weekday - 1]).tag(weekday)
                            }
                        }
                        DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                } header: {
                    Text("Reminder")
                } footer: {
                    Text("Filling in the questionnaire at the same time each week makes changes easier to spot.")
                }
            }
            .navigationTitle(condition == nil ? "New Condition" : "Edit Condition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                }
            }
        }
    }

    private func save() {
        let target: TrackedCondition
        if let condition {
            target = condition
        } else {
            target = TrackedCondition(name: resolvedName, instrumentID: instrumentID)
            modelContext.insert(target)
        }

        target.name = resolvedName
        if canChangeInstrument {
            target.instrumentID = instrumentID
        }
        target.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        target.reminderEnabled = reminderEnabled
        target.reminderWeekday = reminderWeekday
        let time = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        target.reminderHour = time.hour ?? 9
        target.reminderMinute = time.minute ?? 0

        ReminderScheduler.update(for: target)
        dismiss()
    }
}

import SwiftUI
import SwiftData
import PainTrackerKit

/// Quick 0–10 pain rating between questionnaires.
struct PainLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let condition: TrackedCondition

    @State private var level: Double = 3
    @State private var date = Date.now
    @State private var isFlare = false
    @State private var note = ""

    private var painLevel: Int { Int(level.rounded()) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 8) {
                        Text("\(painLevel)")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(Color.pain(painLevel))
                            .contentTransition(.numericText())
                        Text(PainScale.label(for: painLevel))
                            .foregroundStyle(.secondary)
                        Slider(value: $level, in: 0...10, step: 1) {
                            Text("Pain level")
                        } minimumValueLabel: {
                            Text("0")
                        } maximumValueLabel: {
                            Text("10")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                } header: {
                    Text("\(condition.name) right now")
                }

                Section {
                    Toggle("This is a flare-up", isOn: $isFlare)
                    DatePicker("When", selection: $date, in: ...Date.now)
                }

                Section("Note") {
                    TextField("Triggers, activity, medication, weather…", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Log Pain")
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
        let entry = PainLogEntry(
            date: date,
            painLevel: painLevel,
            isFlare: isFlare,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        modelContext.insert(entry)
        entry.condition = condition
        dismiss()
    }
}

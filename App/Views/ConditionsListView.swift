import SwiftUI
import SwiftData
import PainTrackerKit

struct ConditionsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TrackedCondition.createdAt) private var conditions: [TrackedCondition]
    @State private var showingAdd = false

    var body: some View {
        List {
            ForEach(conditions) { condition in
                NavigationLink(value: condition) {
                    ConditionRow(condition: condition)
                }
            }
            .onDelete(perform: delete)
        }
        .overlay {
            if conditions.isEmpty {
                ContentUnavailableView {
                    Label("Nothing tracked yet", systemImage: "figure.walk")
                } description: {
                    Text("Add a condition, such as neck or hip pain, and fill in a short questionnaire every week or two to see how it changes.")
                } actions: {
                    Button("Add Condition") { showingAdd = true }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle("Pain Tracker")
        .navigationDestination(for: TrackedCondition.self) { condition in
            ConditionDetailView(condition: condition)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add Condition", systemImage: "plus") { showingAdd = true }
            }
        }
        .sheet(isPresented: $showingAdd) {
            ConditionFormView()
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let condition = conditions[index]
            ReminderScheduler.cancel(conditionID: condition.id)
            modelContext.delete(condition)
        }
    }
}

private struct ConditionRow: View {
    let condition: TrackedCondition

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: condition.instrument?.region.systemImage ?? "heart.text.square")
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(condition.name)
                    .font(.headline)
                if let latest = condition.latestAssessment {
                    Text("\(condition.instrument?.shortName ?? "Score") \(latest.displayValue) · \(latest.date.formatted(.relative(presentation: .named)))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text(condition.instrument?.name ?? "No questionnaire")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let latest = condition.latestAssessment {
                Circle()
                    .fill(Color.severity(latest.bandLevel))
                    .frame(width: 12, height: 12)
                    .accessibilityLabel(latest.bandLabel)
            }
        }
        .padding(.vertical, 4)
    }
}

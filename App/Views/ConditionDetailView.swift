import SwiftUI
import SwiftData
import Charts
import PainTrackerKit

struct ConditionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let condition: TrackedCondition

    @State private var showingAssessment = false
    @State private var showingPainLog = false
    @State private var showingEdit = false

    private var assessmentsNewestFirst: [AssessmentRecord] { condition.sortedAssessments.reversed() }
    private var painLogsNewestFirst: [PainLogEntry] { condition.sortedPainLogs.reversed() }

    var body: some View {
        List {
            summarySection

            Section {
                Button {
                    showingAssessment = true
                } label: {
                    Label("Fill in \(condition.instrument?.shortName ?? "questionnaire")", systemImage: "list.clipboard")
                }
                .disabled(condition.instrument == nil)

                Button {
                    showingPainLog = true
                } label: {
                    Label("Log today’s pain", systemImage: "plus.circle")
                }
            }

            if !condition.assessments.isEmpty {
                Section {
                    ScoreHistoryChart(records: condition.sortedAssessments)
                        .padding(.vertical, 8)
                } header: {
                    Text("\(condition.instrument?.shortName ?? "Score") over time")
                } footer: {
                    Text("0 = no limitation, 100 = completely limited. Lower is better.")
                }
            }

            if !condition.painLogs.isEmpty {
                Section {
                    PainHistoryChart(entries: condition.sortedPainLogs)
                        .padding(.vertical, 8)
                } header: {
                    Text("Daily pain")
                } footer: {
                    Text("Red points are flare-ups.")
                }
            }

            if !assessmentsNewestFirst.isEmpty {
                Section("Questionnaire results") {
                    ForEach(assessmentsNewestFirst) { record in
                        NavigationLink {
                            AssessmentDetailView(record: record)
                        } label: {
                            AssessmentRow(record: record)
                        }
                    }
                    .onDelete { offsets in
                        let records = assessmentsNewestFirst
                        offsets.forEach { modelContext.delete(records[$0]) }
                    }
                }
            }

            if !painLogsNewestFirst.isEmpty {
                Section("Pain log") {
                    ForEach(painLogsNewestFirst) { entry in
                        PainLogRow(entry: entry)
                    }
                    .onDelete { offsets in
                        let entries = painLogsNewestFirst
                        offsets.forEach { modelContext.delete(entries[$0]) }
                    }
                }
            }

            if !condition.notes.isEmpty {
                Section("Notes") {
                    Text(condition.notes)
                }
            }
        }
        .navigationTitle(condition.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingAssessment) {
            if let instrument = condition.instrument {
                AssessmentFlowView(instrument: instrument, condition: condition)
            }
        }
        .sheet(isPresented: $showingPainLog) {
            PainLogView(condition: condition)
        }
        .sheet(isPresented: $showingEdit) {
            ConditionFormView(condition: condition)
        }
    }

    @ViewBuilder
    private var summarySection: some View {
        Section {
            if let latest = condition.latestAssessment, let instrument = condition.instrument {
                HStack(alignment: .top) {
                    ScoreBadge(value: latest.displayValue, label: latest.bandLabel, level: latest.bandLevel)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Latest \(instrument.shortName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(latest.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                    }
                }
                .padding(.vertical, 4)

                if let trend = condition.trend {
                    if let previous = trend.previous, let change = trend.changeSincePrevious {
                        ChangeRow(title: "since last time", change: change, since: previous.date, instrument: instrument)
                    }
                    if trend.count > 2 {
                        ChangeRow(title: "since first result", change: trend.changeSinceBaseline, since: trend.baseline.date, instrument: instrument)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("No results yet")
                        .font(.headline)
                    Text("Fill in the \(condition.instrument?.name ?? "questionnaire") to set your baseline. Repeating it every 1–2 weeks shows whether things are improving.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
    }
}

private struct AssessmentRow: View {
    let record: AssessmentRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(record.date.formatted(date: .abbreviated, time: .shortened))
                Text(record.bandLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(record.displayValue)
                .font(.headline)
                .monospacedDigit()
            Circle()
                .fill(Color.severity(record.bandLevel))
                .frame(width: 10, height: 10)
        }
    }
}

private struct PainLogRow: View {
    let entry: PainLogEntry

    var body: some View {
        HStack(alignment: .top) {
            Text("\(entry.painLevel)")
                .font(.title3.bold())
                .monospacedDigit()
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.pain(entry.painLevel).opacity(0.25)))
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    if entry.isFlare {
                        Text("Flare-up")
                            .font(.caption.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.red.opacity(0.2)))
                    }
                }
                if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct ScoreHistoryChart: View {
    let records: [AssessmentRecord]

    var body: some View {
        Chart {
            ForEach(records) { record in
                LineMark(
                    x: .value("Date", record.date),
                    y: .value("Score", record.normalizedScore)
                )
                .interpolationMethod(.monotone)

                PointMark(
                    x: .value("Date", record.date),
                    y: .value("Score", record.normalizedScore)
                )
                .foregroundStyle(Color.severity(record.bandLevel))
            }
        }
        .chartYScale(domain: 0...100)
        .chartYAxis {
            AxisMarks(values: [0, 25, 50, 75, 100])
        }
        .frame(height: 200)
        .accessibilityLabel("Questionnaire score history")
    }
}

struct PainHistoryChart: View {
    let entries: [PainLogEntry]

    var body: some View {
        Chart {
            ForEach(entries) { entry in
                LineMark(
                    x: .value("Date", entry.date),
                    y: .value("Pain", entry.painLevel)
                )
                .foregroundStyle(.secondary)

                PointMark(
                    x: .value("Date", entry.date),
                    y: .value("Pain", entry.painLevel)
                )
                .foregroundStyle(entry.isFlare ? Color.red : Color.accentColor)
            }
        }
        .chartYScale(domain: 0...10)
        .chartYAxis {
            AxisMarks(values: [0, 2, 4, 6, 8, 10])
        }
        .frame(height: 160)
        .accessibilityLabel("Daily pain history")
    }
}

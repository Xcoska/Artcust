import SwiftUI
import PainTrackerKit

/// Shown straight after a questionnaire is saved.
struct AssessmentResultView: View {
    let record: AssessmentRecord
    let instrument: Instrument
    let previous: AssessmentRecord?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Label("Result saved", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.green)

                ScoreBadge(value: record.displayValue, label: record.bandLabel, level: record.bandLevel, large: true)

                if case .percent = instrument.display {
                    Text("Raw score \(record.rawTotal) of \(record.rawMaximum)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let previous {
                    ChangeRow(
                        title: "since last time",
                        change: record.normalizedScore - previous.normalizedScore,
                        since: previous.date,
                        instrument: instrument
                    )
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                } else {
                    Text("This is your baseline. Fill in the questionnaire again in a week or two to see how things change.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }

                Text(Disclaimer.text)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}

/// Full breakdown of a saved result.
struct AssessmentDetailView: View {
    let record: AssessmentRecord

    var body: some View {
        List {
            Section {
                ScoreBadge(value: record.displayValue, label: record.bandLabel, level: record.bandLevel)
                    .padding(.vertical, 4)
                LabeledContent("Date", value: record.date.formatted(date: .long, time: .shortened))
                LabeledContent("Raw score", value: "\(record.rawTotal) of \(record.rawMaximum)")
                if !record.note.isEmpty {
                    Text(record.note)
                }
            }

            if let instrument = record.instrument {
                Section("Answers") {
                    let answers = record.optionalAnswers
                    ForEach(Array(instrument.items.enumerated()), id: \.element.id) { index, item in
                        let answer = index < answers.count ? answers[index] : nil
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(item.title)
                                    .font(.subheadline.bold())
                                Spacer()
                                Text(answer.map { "\($0)/\(item.maximumPoints)" } ?? "N/A")
                                    .font(.subheadline)
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                            Text(answer.flatMap { item.option(forPoints: $0)?.text } ?? "Not applicable")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(record.instrument?.shortName ?? "Result")
    }
}

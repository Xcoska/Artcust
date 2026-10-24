import SwiftUI
import SwiftData
import PainTrackerKit

enum ItemAnswer: Equatable {
    case points(Int)
    case notApplicable
}

/// Walks through a questionnaire one item per screen, then saves the result.
struct AssessmentFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let instrument: Instrument
    let condition: TrackedCondition

    /// -1 = introduction, 0..<items.count = questions, items.count = review.
    @State private var step = -1
    @State private var answers: [Int: ItemAnswer] = [:]
    @State private var returnToReview = false
    @State private var note = ""
    @State private var saved: AssessmentRecord?
    @State private var previous: AssessmentRecord?

    private var itemCount: Int { instrument.items.count }

    private var scoringAnswers: [Int?] {
        instrument.items.indices.map { index -> Int? in
            if case .points(let value) = answers[index] { return value }
            return nil
        }
    }

    private var scoreResult: Result<Score, Error> {
        Result { try instrument.score(scoringAnswers) }
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(instrument.shortName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        if saved == nil {
                            Button("Cancel") { dismiss() }
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        if saved != nil {
                            Button("Done") { dismiss() }
                        }
                    }
                }
        }
        .interactiveDismissDisabled(step >= 0 && saved == nil)
    }

    @ViewBuilder
    private var content: some View {
        if let saved {
            AssessmentResultView(record: saved, instrument: instrument, previous: previous)
        } else if step < 0 {
            introduction
        } else if step < itemCount {
            QuestionView(
                item: instrument.items[step],
                number: step + 1,
                total: itemCount,
                answer: answers[step],
                onSelect: select,
                onBack: goBack,
                onNext: advance
            )
            .id(step)
            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)).combined(with: .opacity))
        } else {
            review
        }
    }

    private var introduction: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Label(instrument.name, systemImage: instrument.region.systemImage)
                    .font(.title2.bold())
                Text(instrument.instructions)
                Text("\(itemCount) questions · about \(max(1, itemCount / 4)) min")
                    .foregroundStyle(.secondary)
                if !instrument.provenance.isValidated {
                    Label("This index uses the NDI format for \(instrument.region.displayName.lowercased()) pain. It isn’t a validated clinical measure, but it’s useful for following your own trend.", systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Button {
                    withAnimation { step = 0 }
                } label: {
                    Text("Start")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, 8)
            }
            .padding()
        }
    }

    private var review: some View {
        Form {
            Section {
                ForEach(Array(instrument.items.enumerated()), id: \.element.id) { index, item in
                    Button {
                        returnToReview = true
                        withAnimation { step = index }
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.subheadline.bold())
                            Text(answerText(for: index))
                                .font(.footnote)
                                .foregroundStyle(answers[index] == nil ? Color.red : Color.secondary)
                        }
                    }
                    .tint(.primary)
                }
            } header: {
                Text("Your answers")
            } footer: {
                Text("Tap an answer to change it.")
            }

            Section("Note (optional)") {
                TextField("Anything that affected today?", text: $note, axis: .vertical)
                    .lineLimit(2...5)
            }

            Section {
                switch scoreResult {
                case .success(let score):
                    LabeledContent("Score", value: score.displayValue)
                    Button("Save Result", action: save)
                        .bold()
                case .failure(let error):
                    Text(error.localizedDescription)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private func answerText(for index: Int) -> String {
        switch answers[index] {
        case .some(.points(let points)):
            return instrument.items[index].option(forPoints: points)?.text ?? "\(points)"
        case .some(.notApplicable):
            return "Not applicable"
        case .none:
            return "Not answered"
        }
    }

    private func select(_ answer: ItemAnswer) {
        answers[step] = answer
        advance()
    }

    private func advance() {
        withAnimation {
            if returnToReview {
                returnToReview = false
                step = itemCount
            } else {
                step = min(step + 1, itemCount)
            }
        }
    }

    private func goBack() {
        returnToReview = false
        withAnimation { step = max(step - 1, -1) }
    }

    private func save() {
        guard case .success(let score) = scoreResult else { return }
        previous = condition.latestAssessment
        let record = AssessmentRecord(
            instrumentID: instrument.id,
            answers: scoringAnswers,
            score: score,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        modelContext.insert(record)
        record.condition = condition
        saved = record
    }
}

private struct QuestionView: View {
    let item: InstrumentItem
    let number: Int
    let total: Int
    let answer: ItemAnswer?
    let onSelect: (ItemAnswer) -> Void
    let onBack: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ProgressView(value: Double(number), total: Double(total))
                .padding(.horizontal)
                .padding(.top, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Question \(number) of \(total)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(item.title)
                        .font(.title2.bold())
                    Text(item.prompt)
                        .foregroundStyle(.secondary)

                    switch item.presentation {
                    case .choices:
                        choices
                    case .scale(let lowLabel, let highLabel):
                        scale(lowLabel: lowLabel, highLabel: highLabel)
                    }

                    if item.allowsNotApplicable {
                        Button {
                            onSelect(.notApplicable)
                        } label: {
                            Label("Not applicable to me", systemImage: answer == .notApplicable ? "checkmark.circle.fill" : "minus.circle")
                        }
                        .padding(.top, 4)
                    }
                }
                .padding()
            }

            HStack {
                Button("Back", systemImage: "chevron.left", action: onBack)
                Spacer()
                Button(action: onNext) {
                    HStack(spacing: 4) {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                }
                .disabled(answer == nil)
            }
            .padding()
            .background(.bar)
        }
    }

    private var choices: some View {
        VStack(spacing: 10) {
            ForEach(item.options) { option in
                let selected = answer == .points(option.points)
                Button {
                    onSelect(.points(option.points))
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selected ? Color.accentColor : Color.secondary)
                        Text(option.text)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selected ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground))
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }

    private func scale(lowLabel: String, highLabel: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                ForEach(item.options) { option in
                    let selected = answer == .points(option.points)
                    Button {
                        onSelect(.points(option.points))
                    } label: {
                        Text(option.text)
                            .font(.title3.bold())
                            .monospacedDigit()
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .foregroundStyle(selected ? Color.white : Color.primary)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selected ? Color.accentColor : Color(.secondarySystemBackground))
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("0 = \(lowLabel)")
                Text("10 = \(highLabel)")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

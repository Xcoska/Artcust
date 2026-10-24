import Foundation

/// Part of the body a questionnaire is about.
public enum BodyRegion: String, CaseIterable, Codable, Sendable, Identifiable {
    case neck
    case lowBack
    case hip
    case knee
    case shoulder
    case general

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .neck: "Neck"
        case .lowBack: "Low back"
        case .hip: "Hip"
        case .knee: "Knee"
        case .shoulder: "Shoulder"
        case .general: "General / other"
        }
    }

    /// Suggested name for a new tracked condition in this region.
    public var defaultConditionName: String {
        switch self {
        case .neck: "Neck pain"
        case .lowBack: "Low back pain"
        case .hip: "Hip pain"
        case .knee: "Knee pain"
        case .shoulder: "Shoulder pain"
        case .general: "Chronic pain"
        }
    }

    /// SF Symbol used to represent the region.
    public var systemImage: String {
        switch self {
        case .neck: "person.bust"
        case .lowBack: "figure.cooldown"
        case .hip: "figure.walk"
        case .knee: "figure.stairs"
        case .shoulder: "figure.arms.open"
        case .general: "heart.text.square"
        }
    }
}

/// One answer a person can choose for an item.
public struct ResponseOption: Identifiable, Hashable, Sendable {
    public let points: Int
    public let text: String

    public var id: Int { points }

    public init(points: Int, text: String) {
        self.points = points
        self.text = text
    }
}

/// A single question (or "section", in NDI terminology).
public struct InstrumentItem: Identifiable, Hashable, Sendable {
    public enum Presentation: Hashable, Sendable {
        /// A list of descriptive statements; pick the one that fits best.
        case choices
        /// A numeric rating scale with anchor labels for the two ends.
        case scale(lowLabel: String, highLabel: String)
    }

    public let id: String
    public let title: String
    public let prompt: String
    public let options: [ResponseOption]
    /// Whether the person may mark the item as not applicable (e.g. driving
    /// for someone who doesn't drive). Such items are left out of the score.
    public let allowsNotApplicable: Bool
    public let presentation: Presentation

    public init(
        id: String,
        title: String,
        prompt: String,
        options: [ResponseOption],
        allowsNotApplicable: Bool = false,
        presentation: Presentation = .choices
    ) {
        self.id = id
        self.title = title
        self.prompt = prompt
        self.options = options
        self.allowsNotApplicable = allowsNotApplicable
        self.presentation = presentation
    }

    public var maximumPoints: Int { options.map(\.points).max() ?? 0 }

    public func option(forPoints points: Int) -> ResponseOption? {
        options.first { $0.points == points }
    }
}

/// How a score is shown to the person.
public enum ScoreDisplay: Hashable, Sendable {
    /// Percentage of the maximum possible (NDI / Oswestry style).
    case percent
    /// Mean item score on a 0–`maximum` scale (PEG style).
    case mean(maximum: Int)
}

/// Interpretation band for a normalised (0–100) score.
public struct SeverityBand: Identifiable, Hashable, Sendable {
    public let label: String
    /// Inclusive lower bound on the 0–100 normalised scale.
    public let lowerBound: Double
    /// 0 (best) … 4 (worst); used for colouring.
    public let level: Int

    public var id: String { label }

    public init(label: String, lowerBound: Double, level: Int) {
        self.label = label
        self.lowerBound = lowerBound
        self.level = level
    }
}

/// Where a questionnaire comes from.
public enum Provenance: Hashable, Sendable {
    /// A published, validated instrument.
    case validated(citation: String)
    /// Designed for this app in the same format as a validated instrument,
    /// but not itself validated.
    case custom(modelledOn: String)

    public var isValidated: Bool {
        if case .validated = self { return true }
        return false
    }
}

public enum ScoringError: Error, Equatable, LocalizedError {
    case answerCountMismatch(expected: Int, actual: Int)
    case invalidAnswer(itemID: String, points: Int)
    case notApplicableNotAllowed(itemID: String)
    case tooFewAnswers(required: Int, answered: Int)

    public var errorDescription: String? {
        switch self {
        case let .answerCountMismatch(expected, actual):
            "Expected \(expected) answers but got \(actual)."
        case let .invalidAnswer(itemID, points):
            "\(points) is not a valid answer for “\(itemID)”."
        case let .notApplicableNotAllowed(itemID):
            "“\(itemID)” needs an answer."
        case let .tooFewAnswers(required, answered):
            "Answer at least \(required) questions to get a score (\(answered) answered so far)."
        }
    }
}

/// The result of scoring a completed questionnaire.
public struct Score: Hashable, Sendable {
    /// Score on a 0–100 scale where higher is worse.
    public let normalized: Double
    public let rawTotal: Int
    /// Maximum possible raw total for the items that were answered.
    public let rawMaximum: Int
    public let answeredCount: Int
    public let itemCount: Int
    public let band: SeverityBand?
    public let displayValue: String
}

/// A patient-reported outcome questionnaire.
public struct Instrument: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let shortName: String
    public let region: BodyRegion
    public let summary: String
    public let instructions: String
    public let items: [InstrumentItem]
    public let display: ScoreDisplay
    public let bands: [SeverityBand]
    /// Fewest answered (not "not applicable") items that still give a valid score.
    public let minimumAnswered: Int
    /// Change on the 0–100 scale treated as more than day-to-day variation.
    public let meaningfulChange: Double
    public let provenance: Provenance
    public let notes: String?

    public init(
        id: String,
        name: String,
        shortName: String,
        region: BodyRegion,
        summary: String,
        instructions: String,
        items: [InstrumentItem],
        display: ScoreDisplay,
        bands: [SeverityBand],
        minimumAnswered: Int,
        meaningfulChange: Double,
        provenance: Provenance,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.shortName = shortName
        self.region = region
        self.summary = summary
        self.instructions = instructions
        self.items = items
        self.display = display
        self.bands = bands.sorted { $0.lowerBound < $1.lowerBound }
        self.minimumAnswered = minimumAnswered
        self.meaningfulChange = meaningfulChange
        self.provenance = provenance
        self.notes = notes
    }

    /// Scores a set of answers.
    ///
    /// - Parameter answers: One entry per item, in order. Each is the chosen
    ///   option's points, or `nil` when the item was marked not applicable or
    ///   skipped. Unanswered items are removed from both the total and the
    ///   maximum, as the NDI scoring instructions describe.
    public func score(_ answers: [Int?]) throws -> Score {
        guard answers.count == items.count else {
            throw ScoringError.answerCountMismatch(expected: items.count, actual: answers.count)
        }

        var rawTotal = 0
        var rawMaximum = 0
        var answeredCount = 0
        for (item, answer) in zip(items, answers) {
            guard let answer else { continue }
            guard item.option(forPoints: answer) != nil else {
                throw ScoringError.invalidAnswer(itemID: item.id, points: answer)
            }
            rawTotal += answer
            rawMaximum += item.maximumPoints
            answeredCount += 1
        }

        guard answeredCount >= minimumAnswered, rawMaximum > 0 else {
            throw ScoringError.tooFewAnswers(required: minimumAnswered, answered: answeredCount)
        }

        let normalized = Double(rawTotal) / Double(rawMaximum) * 100
        let displayValue: String
        switch display {
        case .percent:
            displayValue = "\(Int(normalized.rounded()))%"
        case .mean(let maximum):
            let mean = Double(rawTotal) / Double(answeredCount)
            displayValue = String(format: "%.1f / %d", mean, maximum)
        }

        return Score(
            normalized: normalized,
            rawTotal: rawTotal,
            rawMaximum: rawMaximum,
            answeredCount: answeredCount,
            itemCount: items.count,
            band: band(forNormalizedScore: normalized),
            displayValue: displayValue
        )
    }

    public func band(forNormalizedScore score: Double) -> SeverityBand? {
        bands.last { $0.lowerBound <= score } ?? bands.first
    }

    /// Formats the size of a change on the 0–100 scale in the units the
    /// person sees, e.g. "12 points" for NDI or "1.3 points" for PEG.
    public func formattedChangeMagnitude(_ normalizedChange: Double) -> String {
        let magnitude = abs(normalizedChange)
        switch display {
        case .percent:
            let points = Int(magnitude.rounded())
            return points == 1 ? "1 point" : "\(points) points"
        case .mean(let maximum):
            return String(format: "%.1f points", magnitude * Double(maximum) / 100)
        }
    }
}

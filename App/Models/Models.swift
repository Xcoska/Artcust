import Foundation
import SwiftData
import PainTrackerKit

/// A condition the person is tracking, e.g. "Neck pain", with the
/// questionnaire used to measure it.
@Model
final class TrackedCondition {
    var id: UUID = UUID()
    var name: String = ""
    var instrumentID: String = ""
    var notes: String = ""
    var createdAt: Date = Date.now

    var reminderEnabled: Bool = false
    /// 1 = Sunday … 7 = Saturday, matching `Calendar.weekday`.
    var reminderWeekday: Int = 2
    var reminderHour: Int = 9
    var reminderMinute: Int = 0

    @Relationship(deleteRule: .cascade, inverse: \AssessmentRecord.condition)
    var assessments: [AssessmentRecord] = []

    @Relationship(deleteRule: .cascade, inverse: \PainLogEntry.condition)
    var painLogs: [PainLogEntry] = []

    init(name: String, instrumentID: String, notes: String = "") {
        self.name = name
        self.instrumentID = instrumentID
        self.notes = notes
    }

    var instrument: Instrument? { InstrumentCatalog.instrument(withID: instrumentID) }

    /// Oldest first.
    var sortedAssessments: [AssessmentRecord] { assessments.sorted { $0.date < $1.date } }

    /// Oldest first.
    var sortedPainLogs: [PainLogEntry] { painLogs.sorted { $0.date < $1.date } }

    var latestAssessment: AssessmentRecord? { assessments.max { $0.date < $1.date } }

    var trend: TrendSummary? {
        TrendSummary(points: assessments.map { ScorePoint(date: $0.date, value: $0.normalizedScore) })
    }
}

/// One completed questionnaire. The score is stored alongside the answers so
/// history stays readable even if the questionnaire wording changes later.
@Model
final class AssessmentRecord {
    var id: UUID = UUID()
    var date: Date = Date.now
    var instrumentID: String = ""
    /// Points per item, in item order; -1 means not applicable.
    var answers: [Int] = []
    var normalizedScore: Double = 0
    var rawTotal: Int = 0
    var rawMaximum: Int = 0
    var displayValue: String = ""
    var bandLabel: String = ""
    var bandLevel: Int = 0
    var note: String = ""
    var condition: TrackedCondition?

    init(date: Date = .now, instrumentID: String, answers: [Int?], score: Score, note: String = "") {
        self.date = date
        self.instrumentID = instrumentID
        self.answers = answers.map { $0 ?? -1 }
        self.normalizedScore = score.normalized
        self.rawTotal = score.rawTotal
        self.rawMaximum = score.rawMaximum
        self.displayValue = score.displayValue
        self.bandLabel = score.band?.label ?? ""
        self.bandLevel = score.band?.level ?? 0
        self.note = note
    }

    var instrument: Instrument? { InstrumentCatalog.instrument(withID: instrumentID) }

    var optionalAnswers: [Int?] { answers.map { $0 < 0 ? nil : $0 } }
}

/// A quick 0–10 pain rating, for day-to-day tracking between questionnaires.
@Model
final class PainLogEntry {
    var id: UUID = UUID()
    var date: Date = Date.now
    var painLevel: Int = 0
    var isFlare: Bool = false
    var note: String = ""
    var condition: TrackedCondition?

    init(date: Date = .now, painLevel: Int, isFlare: Bool = false, note: String = "") {
        self.date = date
        self.painLevel = painLevel
        self.isFlare = isFlare
        self.note = note
    }
}

import Foundation
import PainTrackerKit

/// Writes the person's data to CSV files they can share with a clinician.
enum Exporter {
    struct Files {
        let assessments: URL
        let painLog: URL
    }

    static func writeFiles(for conditions: [TrackedCondition]) throws -> Files {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("Export", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let assessments = directory.appendingPathComponent("pain-tracker-assessments.csv")
        try assessmentsCSV(for: conditions).write(to: assessments, atomically: true, encoding: .utf8)

        let painLog = directory.appendingPathComponent("pain-tracker-pain-log.csv")
        try painLogCSV(for: conditions).write(to: painLog, atomically: true, encoding: .utf8)

        return Files(assessments: assessments, painLog: painLog)
    }

    static func assessmentsCSV(for conditions: [TrackedCondition]) -> String {
        let header = ["Date", "Condition", "Questionnaire", "Score (0-100)", "Score", "Severity", "Raw total", "Raw maximum", "Responses", "Note"]
        let rows = conditions.flatMap { condition in
            condition.sortedAssessments.map { record -> [String] in
                [
                    timestamp(record.date),
                    condition.name,
                    record.instrument?.name ?? record.instrumentID,
                    String(format: "%.1f", record.normalizedScore),
                    record.displayValue,
                    record.bandLabel,
                    String(record.rawTotal),
                    String(record.rawMaximum),
                    responses(for: record),
                    record.note,
                ]
            }
        }
        return CSV.document(header: header, rows: rows)
    }

    static func painLogCSV(for conditions: [TrackedCondition]) -> String {
        let header = ["Date", "Condition", "Pain (0-10)", "Flare-up", "Note"]
        let rows = conditions.flatMap { condition in
            condition.sortedPainLogs.map { entry -> [String] in
                [
                    timestamp(entry.date),
                    condition.name,
                    String(entry.painLevel),
                    entry.isFlare ? "Yes" : "No",
                    entry.note,
                ]
            }
        }
        return CSV.document(header: header, rows: rows)
    }

    /// "Pain intensity=2; Driving=N/A; …"
    private static func responses(for record: AssessmentRecord) -> String {
        guard let instrument = record.instrument else {
            return record.answers.map { String($0) }.joined(separator: "; ")
        }
        return zip(instrument.items, record.optionalAnswers)
            .map { item, answer in "\(item.title)=\(answer.map { String($0) } ?? "N/A")" }
            .joined(separator: "; ")
    }

    private static func timestamp(_ date: Date) -> String {
        date.formatted(.iso8601)
    }
}

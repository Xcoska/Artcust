import Foundation

/// A dated score on the 0–100 normalised scale (higher is worse).
public struct ScorePoint: Hashable, Sendable {
    public let date: Date
    public let value: Double

    public init(date: Date, value: Double) {
        self.date = date
        self.value = value
    }
}

public enum TrendDirection: Sendable {
    case improved
    case worsened
    case stable
}

/// Compares the latest score with the previous one and with the first one.
public struct TrendSummary: Sendable {
    public let baseline: ScorePoint
    public let previous: ScorePoint?
    public let latest: ScorePoint
    public let count: Int

    public init?(points: [ScorePoint]) {
        let sorted = points.sorted { $0.date < $1.date }
        guard let first = sorted.first, let last = sorted.last else { return nil }
        baseline = first
        latest = last
        previous = sorted.count > 1 ? sorted[sorted.count - 2] : nil
        count = sorted.count
    }

    public var changeSinceBaseline: Double { latest.value - baseline.value }

    public var changeSincePrevious: Double? { previous.map { latest.value - $0.value } }

    /// Lower scores are better, so a fall of at least `meaningfulChange`
    /// counts as an improvement.
    public static func direction(of change: Double, meaningfulChange: Double) -> TrendDirection {
        if change <= -meaningfulChange { return .improved }
        if change >= meaningfulChange { return .worsened }
        return .stable
    }
}

/// Descriptions for a single 0–10 numeric pain rating.
public enum PainScale {
    public static let range = 0...10

    public static func label(for level: Int) -> String {
        switch level {
        case ...0: "No pain"
        case 1...3: "Mild"
        case 4...6: "Moderate"
        case 7...9: "Severe"
        default: "Worst imaginable"
        }
    }
}

/// Minimal RFC 4180 CSV writer.
public enum CSV {
    private static let specialCharacters = Set(",\"\r\n".unicodeScalars)

    public static func escape(_ field: String) -> String {
        guard field.unicodeScalars.contains(where: { specialCharacters.contains($0) }) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    public static func row(_ fields: [String]) -> String {
        fields.map(escape).joined(separator: ",")
    }

    public static func document(header: [String], rows: [[String]]) -> String {
        ([header] + rows).map(row).joined(separator: "\r\n") + "\r\n"
    }
}

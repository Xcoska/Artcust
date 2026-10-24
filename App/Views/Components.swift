import SwiftUI
import PainTrackerKit

extension Color {
    /// Colour for a severity band level (0 = best).
    static func severity(_ level: Int) -> Color {
        switch level {
        case ...0: .green
        case 1: .yellow
        case 2: .orange
        case 3: .red
        default: .purple
        }
    }

    /// Colour for a single 0–10 pain rating.
    static func pain(_ level: Int) -> Color {
        switch level {
        case ...0: .green
        case 1...3: .yellow
        case 4...6: .orange
        default: .red
        }
    }
}

/// Large or compact score with its severity label.
struct ScoreBadge: View {
    let value: String
    let label: String
    let level: Int
    var large = false

    var body: some View {
        VStack(alignment: large ? .center : .leading, spacing: 6) {
            Text(value)
                .font(large ? .system(size: 48, weight: .bold, design: .rounded) : .title2.bold())
                .monospacedDigit()
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.severity(level))
                    .frame(width: 10, height: 10)
                Text(label)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.severity(level).opacity(0.18)))
        }
        .accessibilityElement(children: .combine)
    }
}

/// "Down 12 points since 3 Mar · Meaningful improvement"
struct ChangeRow: View {
    let title: String
    let change: Double
    let since: Date
    let instrument: Instrument

    private var direction: TrendDirection {
        TrendSummary.direction(of: change, meaningfulChange: instrument.meaningfulChange)
    }

    private var changeText: String {
        let magnitude = instrument.formattedChangeMagnitude(change)
        if magnitude.hasPrefix("0 ") || magnitude.hasPrefix("0.0 ") { return "No change" }
        return change < 0 ? "Down \(magnitude)" : "Up \(magnitude)"
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Image(systemName: symbol)
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(changeText) \(title)")
                Text("\(since.formatted(date: .abbreviated, time: .omitted)) · \(verdict)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var symbol: String {
        switch direction {
        case .improved: "arrow.down.circle.fill"
        case .worsened: "arrow.up.circle.fill"
        case .stable: "equal.circle.fill"
        }
    }

    private var color: Color {
        switch direction {
        case .improved: .green
        case .worsened: .red
        case .stable: .secondary
        }
    }

    private var verdict: String {
        switch direction {
        case .improved: "Meaningful improvement"
        case .worsened: "Meaningful worsening"
        case .stable: "Within normal variation"
        }
    }
}

enum Disclaimer {
    static let text = "Scores are for personal tracking and are not a diagnosis. Share your trends with your doctor or physiotherapist, and seek urgent care for new numbness, weakness, loss of bladder or bowel control, fever, or severe pain after an injury."
}

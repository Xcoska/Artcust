import XCTest
@testable import PainTrackerKit

final class ScoringTests: XCTestCase {
    private let ndi = InstrumentCatalog.neckDisabilityIndex

    func testNoLimitationScoresZero() throws {
        let score = try ndi.score(Array(repeating: 0, count: 10))
        XCTAssertEqual(score.normalized, 0)
        XCTAssertEqual(score.rawTotal, 0)
        XCTAssertEqual(score.rawMaximum, 50)
        XCTAssertEqual(score.displayValue, "0%")
        XCTAssertEqual(score.band?.label, "No disability")
    }

    func testMaximumScoresOneHundred() throws {
        let score = try ndi.score(Array(repeating: 5, count: 10))
        XCTAssertEqual(score.normalized, 100)
        XCTAssertEqual(score.band?.label, "Complete disability")
    }

    func testNDIBandBoundaries() throws {
        // 4/50 = 8% → none, 5/50 = 10% → mild, 15/50 → moderate, 25/50 → severe, 35/50 → complete.
        let expectations: [(Int, String)] = [
            (4, "No disability"),
            (5, "Mild disability"),
            (14, "Mild disability"),
            (15, "Moderate disability"),
            (25, "Severe disability"),
            (35, "Complete disability"),
        ]
        for (raw, label) in expectations {
            let score = try ndi.score(answers(totalling: raw))
            XCTAssertEqual(score.rawTotal, raw)
            XCTAssertEqual(score.band?.label, label, "raw \(raw)")
        }
    }

    func testNotApplicableItemIsRemovedFromMaximum() throws {
        var values: [Int?] = Array(repeating: 2, count: 10)
        values[7] = nil // driving
        let score = try ndi.score(values)
        XCTAssertEqual(score.rawTotal, 18)
        XCTAssertEqual(score.rawMaximum, 45)
        XCTAssertEqual(score.normalized, 40, accuracy: 0.0001)
        XCTAssertEqual(score.answeredCount, 9)
    }

    func testTooFewAnswersThrows() {
        var values: [Int?] = Array(repeating: 1, count: 10)
        values[0] = nil
        values[1] = nil
        values[2] = nil
        XCTAssertThrowsError(try ndi.score(values)) { error in
            XCTAssertEqual(error as? ScoringError, .tooFewAnswers(required: 8, answered: 7))
        }
    }

    func testInvalidAnswerThrows() {
        var values: [Int?] = Array(repeating: 1, count: 10)
        values[3] = 6
        XCTAssertThrowsError(try ndi.score(values)) { error in
            XCTAssertEqual(error as? ScoringError, .invalidAnswer(itemID: "reading", points: 6))
        }
    }

    func testWrongAnswerCountThrows() {
        XCTAssertThrowsError(try ndi.score([1, 2, 3])) { error in
            XCTAssertEqual(error as? ScoringError, .answerCountMismatch(expected: 10, actual: 3))
        }
    }

    func testPEGShowsMeanOutOfTen() throws {
        let score = try InstrumentCatalog.peg.score([6, 4, 5])
        XCTAssertEqual(score.displayValue, "5.0 / 10")
        XCTAssertEqual(score.normalized, 50, accuracy: 0.0001)
        XCTAssertEqual(score.band?.label, "Moderate")
    }

    func testPEGAllZeroIsNoPain() throws {
        let score = try InstrumentCatalog.peg.score([0, 0, 0])
        XCTAssertEqual(score.band?.label, "No pain or interference")
        XCTAssertEqual(try InstrumentCatalog.peg.score([1, 0, 0]).band?.label, "Mild")
    }

    func testChangeMagnitudeUsesDisplayUnits() {
        XCTAssertEqual(ndi.formattedChangeMagnitude(-12.4), "12 points")
        XCTAssertEqual(ndi.formattedChangeMagnitude(1), "1 point")
        XCTAssertEqual(InstrumentCatalog.peg.formattedChangeMagnitude(-13), "1.3 points")
    }

    /// Spreads `total` across the ten 0–5 items.
    private func answers(totalling total: Int) -> [Int?] {
        var remaining = total
        return (0..<10).map { _ -> Int? in
            let value = min(5, remaining)
            remaining -= value
            return value
        }
    }
}

final class CatalogTests: XCTestCase {
    func testInstrumentIDsAreUnique() {
        let ids = InstrumentCatalog.all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func testItemIDsAreUniqueWithinEachInstrument() {
        for instrument in InstrumentCatalog.all {
            let ids = instrument.items.map(\.id)
            XCTAssertEqual(Set(ids).count, ids.count, instrument.id)
        }
    }

    func testOptionsAreContiguousFromZero() {
        for instrument in InstrumentCatalog.all {
            for item in instrument.items {
                XCTAssertEqual(item.options.map(\.points), Array(0...item.maximumPoints), "\(instrument.id)/\(item.id)")
            }
        }
    }

    func testMinimumAnsweredIsAchievable() {
        for instrument in InstrumentCatalog.all {
            XCTAssertLessThanOrEqual(instrument.minimumAnswered, instrument.items.count, instrument.id)
            XCTAssertGreaterThan(instrument.minimumAnswered, 0, instrument.id)
        }
    }

    func testEveryRegionHasAnInstrument() {
        for region in BodyRegion.allCases {
            XCTAssertTrue(InstrumentCatalog.all.contains { $0.region == region }, region.rawValue)
        }
    }

    func testLookupByID() {
        XCTAssertEqual(InstrumentCatalog.instrument(withID: "hip-di")?.name, "Hip Disability Index")
        XCTAssertNil(InstrumentCatalog.instrument(withID: "nope"))
    }
}

final class TrendTests: XCTestCase {
    func testTrendComparesLatestWithPreviousAndBaseline() throws {
        let day: TimeInterval = 86_400
        let start = Date(timeIntervalSince1970: 0)
        let points = [
            ScorePoint(date: start.addingTimeInterval(2 * day), value: 40),
            ScorePoint(date: start, value: 60),
            ScorePoint(date: start.addingTimeInterval(9 * day), value: 36),
        ]
        let trend = try XCTUnwrap(TrendSummary(points: points))
        XCTAssertEqual(trend.baseline.value, 60)
        XCTAssertEqual(trend.previous?.value, 40)
        XCTAssertEqual(trend.latest.value, 36)
        XCTAssertEqual(trend.changeSinceBaseline, -24)
        XCTAssertEqual(trend.changeSincePrevious, -4)
        XCTAssertEqual(trend.count, 3)
    }

    func testEmptyTrendIsNil() {
        XCTAssertNil(TrendSummary(points: []))
    }

    func testSinglePointHasNoPrevious() throws {
        let trend = try XCTUnwrap(TrendSummary(points: [ScorePoint(date: .now, value: 20)]))
        XCTAssertNil(trend.previous)
        XCTAssertNil(trend.changeSincePrevious)
    }

    func testDirection() {
        XCTAssertEqual(TrendSummary.direction(of: -10, meaningfulChange: 10), .improved)
        XCTAssertEqual(TrendSummary.direction(of: -9.9, meaningfulChange: 10), .stable)
        XCTAssertEqual(TrendSummary.direction(of: 12, meaningfulChange: 10), .worsened)
    }

    func testPainScaleLabels() {
        XCTAssertEqual(PainScale.label(for: 0), "No pain")
        XCTAssertEqual(PainScale.label(for: 3), "Mild")
        XCTAssertEqual(PainScale.label(for: 6), "Moderate")
        XCTAssertEqual(PainScale.label(for: 9), "Severe")
        XCTAssertEqual(PainScale.label(for: 10), "Worst imaginable")
    }
}

final class CSVTests: XCTestCase {
    func testEscaping() {
        XCTAssertEqual(CSV.escape("plain"), "plain")
        XCTAssertEqual(CSV.escape("a,b"), "\"a,b\"")
        XCTAssertEqual(CSV.escape("say \"hi\""), "\"say \"\"hi\"\"\"")
        XCTAssertEqual(CSV.escape("line\nbreak"), "\"line\nbreak\"")
        XCTAssertEqual(CSV.escape("crlf\r\nbreak"), "\"crlf\r\nbreak\"")
    }

    func testDocument() {
        let document = CSV.document(header: ["a", "b"], rows: [["1", "x,y"]])
        XCTAssertEqual(document, "a,b\r\n1,\"x,y\"\r\n")
    }
}

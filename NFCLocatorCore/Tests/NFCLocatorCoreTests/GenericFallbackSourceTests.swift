import XCTest
@testable import NFCLocatorCore

final class GenericFallbackSourceTests: XCTestCase {
    func testAlwaysSucceeds() async {
        let source = GenericFallbackSource()
        let result = await source.resolve(signals: TestFixtures.signals)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.confidence, .generic)
        XCTAssertEqual(result?.source, .heuristic)
    }

    func testBarZone() {
        let rect = GenericFallbackSource.zone(for: .bar, foldState: .notApplicable)
        XCTAssertEqual(rect.centerX, 0.5, accuracy: 0.001)
        XCTAssertEqual(rect.centerY, 0.22, accuracy: 0.001)
    }

    func testTabletZone() {
        let rect = GenericFallbackSource.zone(for: .tablet, foldState: .notApplicable)
        XCTAssertEqual(rect.centerX, 0.5, accuracy: 0.001)
        XCTAssertEqual(rect.centerY, 0.45, accuracy: 0.001)
    }

    func testFoldBookFoldedVsUnfoldedDiffer() {
        let folded = GenericFallbackSource.zone(for: .foldBook, foldState: .folded)
        let unfolded = GenericFallbackSource.zone(for: .foldBook, foldState: .unfolded)
        XCTAssertEqual(folded.centerX, 0.5, accuracy: 0.001)
        XCTAssertEqual(unfolded.centerX, 0.25, accuracy: 0.001)
    }

    func testFoldFlipFoldedVsUnfoldedDiffer() {
        let folded = GenericFallbackSource.zone(for: .foldFlip, foldState: .folded)
        let unfolded = GenericFallbackSource.zone(for: .foldFlip, foldState: .unfolded)
        XCTAssertEqual(folded.centerY, 0.45, accuracy: 0.001)
        XCTAssertEqual(unfolded.centerY, 0.28, accuracy: 0.001)
    }

    func testNotApplicableMatchesUnfoldedForFoldables() {
        let notApplicable = GenericFallbackSource.zone(for: .foldBook, foldState: .notApplicable)
        let unfolded = GenericFallbackSource.zone(for: .foldBook, foldState: .unfolded)
        XCTAssertEqual(notApplicable.centerX, unfolded.centerX, accuracy: 0.0001)
        XCTAssertEqual(notApplicable.centerY, unfolded.centerY, accuracy: 0.0001)
    }
}

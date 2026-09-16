import XCTest
@testable import NFCLocatorCore

final class NormalizedRectTests: XCTestCase {
    func testValidRectConstructs() throws {
        let rect = try NormalizedRect(x: 0.2, y: 0.3, width: 0.4, height: 0.1)
        XCTAssertEqual(rect.centerX, 0.4, accuracy: 0.0001)
        XCTAssertEqual(rect.centerY, 0.35, accuracy: 0.0001)
    }

    func testNegativeXThrows() {
        XCTAssertThrowsError(try NormalizedRect(x: -0.1, y: 0, width: 0.1, height: 0.1))
    }

    func testXPlusWidthOverOneThrows() {
        XCTAssertThrowsError(try NormalizedRect(x: 0.9, y: 0, width: 0.3, height: 0.1))
    }

    func testXPlusWidthWithinEpsilonSucceeds() throws {
        // 0.7 + 0.3 = 1.0 exactly, must not throw.
        _ = try NormalizedRect(x: 0.7, y: 0, width: 0.3, height: 0.1)
    }

    func testCenteredSquareNeverThrowsAndClampsToBounds() {
        let rect = NormalizedRect.centeredSquare(centerX: 0.02, centerY: 0.98, side: 0.3)
        XCTAssertGreaterThanOrEqual(rect.x, 0)
        XCTAssertLessThanOrEqual(rect.x + rect.width, 1.0001)
        XCTAssertGreaterThanOrEqual(rect.y, 0)
        XCTAssertLessThanOrEqual(rect.y + rect.height, 1.0001)
    }

    func testCenteredSquareAtCenter() {
        let rect = NormalizedRect.centeredSquare(centerX: 0.5, centerY: 0.5, side: 0.2)
        XCTAssertEqual(rect.x, 0.4, accuracy: 0.0001)
        XCTAssertEqual(rect.y, 0.4, accuracy: 0.0001)
        XCTAssertEqual(rect.width, 0.2, accuracy: 0.0001)
        XCTAssertEqual(rect.height, 0.2, accuracy: 0.0001)
    }
}

import XCTest
@testable import BokashiCore

final class ScreenRectConverterTests: XCTestCase {
    func testPrimaryRetinaDisplayRect() {
        let rect = ScreenRectConverter.pixelRectInDisplay(
            screenRect: CGRect(x: 100, y: 100, width: 200, height: 150),
            displayFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            backingScaleFactor: 2
        )
        XCTAssertEqual(rect, CGRect(x: 200, y: 1300, width: 400, height: 300))
    }

    func testNonPrimaryToTheRight() {
        // Secondary display sits to the right of the primary.
        let rect = ScreenRectConverter.pixelRectInDisplay(
            screenRect: CGRect(x: 1500, y: 200, width: 300, height: 200),
            displayFrame: CGRect(x: 1440, y: 0, width: 1920, height: 1080),
            backingScaleFactor: 1
        )
        XCTAssertEqual(rect, CGRect(x: 60, y: 680, width: 300, height: 200))
    }

    func testNonPrimaryAbovePrimary() {
        // Secondary display sits above the primary (y > 0 in global coords).
        let rect = ScreenRectConverter.pixelRectInDisplay(
            screenRect: CGRect(x: 100, y: 1000, width: 200, height: 150),
            displayFrame: CGRect(x: 0, y: 900, width: 1920, height: 1080),
            backingScaleFactor: 2
        )
        XCTAssertEqual(rect, CGRect(x: 200, y: 1660, width: 400, height: 300))
    }

    func testIntegralRoundsFractionalCoords() {
        let rect = ScreenRectConverter.pixelRectInDisplay(
            screenRect: CGRect(x: 10.4, y: 20.6, width: 100.3, height: 50.7),
            displayFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            backingScaleFactor: 1
        )
        // .integral expands to enclose the original rect.
        XCTAssertEqual(rect.minX.truncatingRemainder(dividingBy: 1), 0)
        XCTAssertEqual(rect.minY.truncatingRemainder(dividingBy: 1), 0)
        XCTAssertEqual(rect.width.truncatingRemainder(dividingBy: 1), 0)
        XCTAssertEqual(rect.height.truncatingRemainder(dividingBy: 1), 0)
    }
}

import XCTest
@testable import BokashiCore

final class WindowFrameConverterTests: XCTestCase {
    func testConvertsTopLeftWindow() {
        let ns = WindowFrameConverter.nsRect(
            fromCG: CGRect(x: 0, y: 0, width: 800, height: 600),
            primaryScreenHeight: 900
        )
        XCTAssertEqual(ns, CGRect(x: 0, y: 300, width: 800, height: 600))
    }

    func testConvertsOffsetWindow() {
        let ns = WindowFrameConverter.nsRect(
            fromCG: CGRect(x: 100, y: 50, width: 400, height: 300),
            primaryScreenHeight: 900
        )
        XCTAssertEqual(ns, CGRect(x: 100, y: 550, width: 400, height: 300))
    }

    func testRoundTripConsistencyWithItself() {
        // Converting twice with the same primary height returns the original.
        let original = CGRect(x: 50, y: 200, width: 1024, height: 768)
        let primaryHeight: CGFloat = 1080
        let ns = WindowFrameConverter.nsRect(fromCG: original, primaryScreenHeight: primaryHeight)
        let back = WindowFrameConverter.nsRect(fromCG: ns, primaryScreenHeight: primaryHeight)
        XCTAssertEqual(back, original)
    }
}

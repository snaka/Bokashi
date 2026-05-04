import XCTest
@testable import BokashiCore

final class CaptureFilenameTests: XCTestCase {
    private let utc = TimeZone(identifier: "UTC")!

    func testFormatAtEpoch() {
        let date = Date(timeIntervalSince1970: 0)
        XCTAssertEqual(
            CaptureFilename.make(for: date, timeZone: utc),
            "Bokashi-1970-01-01-000000.png"
        )
    }

    func testCustomPrefix() {
        let date = Date(timeIntervalSince1970: 0)
        XCTAssertEqual(
            CaptureFilename.make(for: date, timeZone: utc, prefix: "Test"),
            "Test-1970-01-01-000000.png"
        )
    }

    func testFixedDate() {
        var components = DateComponents()
        components.year = 2026
        components.month = 5
        components.day = 3
        components.hour = 14
        components.minute = 25
        components.second = 7
        components.timeZone = utc
        let date = Calendar(identifier: .gregorian).date(from: components)!
        XCTAssertEqual(
            CaptureFilename.make(for: date, timeZone: utc),
            "Bokashi-2026-05-03-142507.png"
        )
    }
}

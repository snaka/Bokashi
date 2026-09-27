import BokashiCore
import XCTest

final class JoinedLinesTests: XCTestCase {
    func testMapsRangeBackToItsLine() {
        let joined = JoinedLines(["担当: 田中健一", "連絡先 090-1234-5678"])
        let range = (joined.text as NSString).range(of: "090-1234-5678")
        let located = joined.locate(range)
        XCTAssertEqual(located?.lineIndex, 1)
        XCTAssertEqual(located?.range, NSRange(location: 4, length: 13))
    }

    func testCountsUTF16UnitsForSurrogatePairs() {
        let joined = JoinedLines(["😀😀", "alice@example.com"])
        let range = (joined.text as NSString).range(of: "alice")
        XCTAssertEqual(joined.locate(range), JoinedLines.Located(lineIndex: 1, range: NSRange(location: 0, length: 5)))
    }

    func testClipsRangeCrossingNewlineToFirstLine() {
        let joined = JoinedLines(["abc", "def"])
        XCTAssertEqual(joined.locate(NSRange(location: 1, length: 4)), JoinedLines.Located(lineIndex: 0, range: NSRange(location: 1, length: 2)))
    }

    func testRejectsEmptyAndNewlineOnlyRanges() {
        let joined = JoinedLines(["abc", "def"])
        XCTAssertNil(joined.locate(NSRange(location: 0, length: 0)))
        XCTAssertNil(joined.locate(NSRange(location: 3, length: 1)))
        XCTAssertNil(JoinedLines([]).locate(NSRange(location: 0, length: 1)))
    }
}

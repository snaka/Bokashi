import XCTest
@testable import BokashiCore

final class FindingLocatorTests: XCTestCase {
    let lines = [
        "Dashboard",
        "Signed in as @taro_yam",
        "電話: 090-1234-5678",
        "Contact: alice@example.com now",
    ]

    func testFindsVerbatimTextOnHintedLine() {
        let located = FindingLocator.locate(text: "@taro_yam", hintIndex: 1, in: lines)
        XCTAssertEqual(located?.lineIndex, 1)
        XCTAssertEqual(located?.nsRange, NSRange(location: 13, length: 9))
    }

    func testRecoversFromOffByOneHint() {
        let located = FindingLocator.locate(text: "@taro_yam", hintIndex: 2, in: lines)
        XCTAssertEqual(located?.lineIndex, 1)
    }

    func testFallsBackToSearchingAllLines() {
        let located = FindingLocator.locate(text: "alice@example.com", hintIndex: 0, in: lines)
        XCTAssertEqual(located?.lineIndex, 3)
    }

    func testNilHintSearchesAllLines() {
        let located = FindingLocator.locate(text: "090-1234-5678", hintIndex: nil, in: lines)
        XCTAssertEqual(located?.lineIndex, 2)
    }

    func testJapaneseSubstringRangeIsUTF16() {
        let located = FindingLocator.locate(text: "090-1234-5678", hintIndex: 2, in: lines)
        // "電話: " is 4 UTF-16 units (電, 話, :, space).
        XCTAssertEqual(located?.nsRange, NSRange(location: 4, length: 13))
    }

    func testMatchesCaseInsensitively() {
        let located = FindingLocator.locate(text: "ALICE@EXAMPLE.COM", hintIndex: 3, in: lines)
        XCTAssertEqual(located?.lineIndex, 3)
        XCTAssertEqual(located?.nsRange, NSRange(location: 9, length: 17))
    }

    func testTrimsWhitespaceFromFinding() {
        let located = FindingLocator.locate(text: "  @taro_yam \n", hintIndex: 1, in: lines)
        XCTAssertEqual(located?.nsRange, NSRange(location: 13, length: 9))
    }

    func testReturnsNilWhenTextNowhere() {
        XCTAssertNil(FindingLocator.locate(text: "not-in-any-line", hintIndex: 1, in: lines))
        XCTAssertNil(FindingLocator.locate(text: "   ", hintIndex: 1, in: lines))
        XCTAssertNil(FindingLocator.locate(text: "Dashboard", hintIndex: 0, in: []))
    }

    func testOutOfBoundsHintStillSearches() {
        let located = FindingLocator.locate(text: "@taro_yam", hintIndex: 99, in: lines)
        XCTAssertEqual(located?.lineIndex, 1)
    }
}

import XCTest
@testable import BokashiCore

final class LineBatcherTests: XCTestCase {
    func testSingleBatchWhenUnderBudget() {
        let batches = LineBatcher.batches(from: ["one", "two", "three"], characterBudget: 200)
        XCTAssertEqual(batches.count, 1)
        XCTAssertEqual(batches[0].map(\.text), ["one", "two", "three"])
        XCTAssertEqual(batches[0].map(\.index), [0, 1, 2])
    }

    func testSplitsWhenBudgetExceeded() {
        // Each line costs 10 (text) + 8 (per-line overhead) = 18; budget 40 fits two.
        let lines = ["aaaaaaaaaa", "bbbbbbbbbb", "cccccccccc", "dddddddddd"]
        let batches = LineBatcher.batches(from: lines, characterBudget: 40)
        XCTAssertEqual(batches.count, 2)
        XCTAssertEqual(batches[0].map(\.index), [0, 1])
        XCTAssertEqual(batches[1].map(\.index), [2, 3])
    }

    func testNeverSplitsASingleLongLine() {
        let long = String(repeating: "x", count: 500)
        let batches = LineBatcher.batches(from: ["short", long, "tail"], characterBudget: 100)
        XCTAssertEqual(batches.count, 3)
        XCTAssertEqual(batches[1].map(\.text), [long])
        XCTAssertEqual(batches[1].map(\.index), [1])
    }

    func testSkipsBlankLinesButKeepsGlobalIndices() {
        let batches = LineBatcher.batches(from: ["a", "", "   ", "b"], characterBudget: 200)
        XCTAssertEqual(batches.count, 1)
        XCTAssertEqual(batches[0].map(\.index), [0, 3])
        XCTAssertEqual(batches[0].map(\.text), ["a", "b"])
    }

    func testEmptyInputYieldsNoBatches() {
        XCTAssertTrue(LineBatcher.batches(from: [], characterBudget: 100).isEmpty)
        XCTAssertTrue(LineBatcher.batches(from: ["", "  "], characterBudget: 100).isEmpty)
    }
}

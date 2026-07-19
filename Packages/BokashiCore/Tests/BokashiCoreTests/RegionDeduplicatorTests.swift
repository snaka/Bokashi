import XCTest
@testable import BokashiCore

final class RegionDeduplicatorTests: XCTestCase {
    private func region(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat,
                        label: String = "test") -> DetectedRegion {
        DetectedRegion(rect: CGRect(x: x, y: y, width: w, height: h), label: label)
    }

    func testKeepsDisjointRegions() {
        let regions = [region(0, 0, 10, 10), region(100, 100, 10, 10)]
        XCTAssertEqual(RegionDeduplicator.keptIndices(of: regions), [0, 1])
    }

    func testDropsNearIdenticalDuplicate() {
        // Second rect shifted by 1px on a 100x20 rect: IoU ≈ 0.9.
        let regions = [region(10, 10, 100, 20), region(11, 10, 100, 20)]
        XCTAssertEqual(RegionDeduplicator.keptIndices(of: regions), [0])
    }

    func testDropsContainedRegion() {
        // Small rect inside a big one has low IoU but should still be dropped.
        let regions = [region(0, 0, 200, 100), region(50, 40, 20, 10)]
        XCTAssertEqual(RegionDeduplicator.keptIndices(of: regions), [0])
    }

    func testKeepsPartialOverlapBelowThreshold() {
        // Half-width overlap on equal rects: IoU = 1/3 < 0.6.
        let regions = [region(0, 0, 100, 20), region(50, 0, 100, 20)]
        XCTAssertEqual(RegionDeduplicator.keptIndices(of: regions), [0, 1])
    }

    func testEarlierRegionWins() {
        // Order encodes priority; the caller lists deterministic detectors first.
        let regions = [region(0, 0, 100, 20, label: "email"),
                       region(0, 0, 100, 20, label: "aiEmail")]
        let kept = RegionDeduplicator.keptIndices(of: regions)
        XCTAssertEqual(kept, [0])
        XCTAssertEqual(regions[kept[0]].label, "email")
    }

    func testDropsEmptyRects() {
        let regions = [region(0, 0, 0, 0), region(5, 5, 10, 10)]
        XCTAssertEqual(RegionDeduplicator.keptIndices(of: regions), [1])
    }

    func testEmptyInput() {
        XCTAssertTrue(RegionDeduplicator.keptIndices(of: []).isEmpty)
    }
}

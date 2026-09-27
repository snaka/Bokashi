import BokashiCore
import CoreGraphics
import XCTest

final class AnnotationHitTestTests: XCTestCase {
    private let outline = AnnotationStyle(color: .bokashiRed, lineWidth: 4, filled: false)
    private let filled = AnnotationStyle(color: .bokashiRed, lineWidth: 4, filled: true)
    private let rect = CGRect(x: 100, y: 100, width: 200, height: 100)

    func testMosaicIsHitAnywhereInside() {
        let mosaic = Annotation(kind: .mosaic(rect: rect), style: outline)
        XCTAssertTrue(mosaic.isHit(by: CGPoint(x: 200, y: 150), tolerance: 4))
        XCTAssertFalse(mosaic.isHit(by: CGPoint(x: 50, y: 50), tolerance: 4))
    }

    func testOutlinedBoxIsHitOnlyNearItsEdge() {
        let box = Annotation(kind: .box(rect: rect), style: outline)
        XCTAssertTrue(box.isHit(by: CGPoint(x: 102, y: 150), tolerance: 4))
        XCTAssertFalse(box.isHit(by: CGPoint(x: 200, y: 150), tolerance: 4))
        XCTAssertFalse(box.isHit(by: CGPoint(x: 90, y: 150), tolerance: 4))
    }

    func testFilledBoxIsHitInside() {
        let box = Annotation(kind: .box(rect: rect), style: filled)
        XCTAssertTrue(box.isHit(by: CGPoint(x: 200, y: 150), tolerance: 4))
    }

    func testOutlinedEllipseIsHitNearItsCurveNotAtCornerOrCenter() {
        let ellipse = Annotation(kind: .ellipse(rect: rect), style: outline)
        XCTAssertTrue(ellipse.isHit(by: CGPoint(x: 200, y: 101), tolerance: 4))
        XCTAssertFalse(ellipse.isHit(by: CGPoint(x: 200, y: 150), tolerance: 4))
        XCTAssertFalse(ellipse.isHit(by: CGPoint(x: 102, y: 102), tolerance: 4))
    }

    func testFilledEllipseIsHitAtCenter() {
        let ellipse = Annotation(kind: .ellipse(rect: rect), style: filled)
        XCTAssertTrue(ellipse.isHit(by: CGPoint(x: 200, y: 150), tolerance: 4))
    }

    func testLineIsHitNearTheSegmentOnly() {
        let line = Annotation(kind: .arrow(start: CGPoint(x: 0, y: 0), end: CGPoint(x: 100, y: 0)), style: outline)
        XCTAssertTrue(line.isHit(by: CGPoint(x: 50, y: 5), tolerance: 4))
        XCTAssertFalse(line.isHit(by: CGPoint(x: 50, y: 10), tolerance: 4))
        XCTAssertFalse(line.isHit(by: CGPoint(x: 110, y: 0), tolerance: 4))
    }
}

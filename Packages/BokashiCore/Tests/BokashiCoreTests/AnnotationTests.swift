import XCTest
@testable import BokashiCore

final class AnnotationTests: XCTestCase {
    func testRectBetweenAcceptsAnyOrientation() {
        let topLeft = CGPoint(x: 10, y: 20)
        let bottomRight = CGPoint(x: 50, y: 80)
        let bottomLeft = CGPoint(x: 10, y: 80)
        let topRight = CGPoint(x: 50, y: 20)

        let cases: [(CGPoint, CGPoint)] = [
            (topLeft, bottomRight),
            (bottomRight, topLeft),
            (bottomLeft, topRight),
            (topRight, bottomLeft),
        ]
        for (a, b) in cases {
            let rect = CGRect.between(a, b)
            XCTAssertEqual(rect.origin, CGPoint(x: 10, y: 20))
            XCTAssertEqual(rect.size, CGSize(width: 40, height: 60))
        }
    }

    func testAnnotationsWithSameValuesButDifferentIDsAreNotEqual() {
        let a = Annotation(
            kind: .line(start: .zero, end: CGPoint(x: 10, y: 10)),
            style: .defaultOutline
        )
        let b = Annotation(
            kind: .line(start: .zero, end: CGPoint(x: 10, y: 10)),
            style: .defaultOutline
        )
        XCTAssertNotEqual(a, b)
        XCTAssertNotEqual(a.id, b.id)
    }

    func testStyleFilledFlag() {
        XCTAssertFalse(AnnotationStyle.defaultOutline.filled)
        XCTAssertTrue(AnnotationStyle.defaultFilled.filled)
    }

    func testWidthPresetsAreOrderedThinToThick() {
        let widths = AnnotationStyle.WidthPreset.allCases.map { $0.lineWidth }
        XCTAssertEqual(widths.count, 5)
        XCTAssertEqual(widths, widths.sorted())
        // The medium preset is the historical default (defaultOutline uses 6).
        XCTAssertEqual(AnnotationStyle.WidthPreset.medium.lineWidth, 6)
    }
}

import XCTest
import CoreGraphics
@testable import BokashiCore

final class ImageDecoderTests: XCTestCase {
    func testDecodesPngDataAtItsPixelDimensions() throws {
        let data = try PNGWriter.data(from: makeSolidImage(width: 7, height: 3))

        let decoded = try XCTUnwrap(ImageDecoder.decode(data))

        XCTAssertEqual(decoded.width, 7)
        XCTAssertEqual(decoded.height, 3)
    }

    func testReturnsNilForDataThatIsNotAnImage() {
        let data = Data("not an image".utf8)

        XCTAssertNil(ImageDecoder.decode(data))
    }
}

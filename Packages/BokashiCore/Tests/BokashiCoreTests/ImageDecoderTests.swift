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

    private func makeSolidImage(width: Int, height: Int) -> CGImage {
        let bytesPerPixel = 4
        var pixels = [UInt8](repeating: 0xFF, count: width * height * bytesPerPixel)
        let context = pixels.withUnsafeMutableBufferPointer { buffer -> CGContext? in
            CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * bytesPerPixel,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        }
        return context!.makeImage()!
    }
}

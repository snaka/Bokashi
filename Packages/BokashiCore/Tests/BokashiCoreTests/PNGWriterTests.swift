import XCTest
import CoreGraphics
@testable import BokashiCore

final class PNGWriterTests: XCTestCase {
    func testWritesValidPngFile() throws {
        let image = makeSolidImage(width: 4, height: 4)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("bokashi-test-\(UUID().uuidString).png")
        defer { try? FileManager.default.removeItem(at: url) }

        try PNGWriter.write(image, to: url)

        let data = try Data(contentsOf: url)
        let pngMagic: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        XCTAssertEqual(Array(data.prefix(8)), pngMagic)
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

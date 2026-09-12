import CoreGraphics

func makeSolidImage(width: Int, height: Int) -> CGImage {
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

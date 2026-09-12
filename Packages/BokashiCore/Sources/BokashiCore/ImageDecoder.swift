import CoreGraphics
import Foundation
import ImageIO

public enum ImageDecoder {
    public static func decode(_ data: Data) -> CGImage? {
        CGImageSourceCreateWithData(data as CFData, nil)
            .flatMap { CGImageSourceCreateImageAtIndex($0, 0, nil) }
    }
}

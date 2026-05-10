import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

public enum PNGWriter {
    public enum WriteError: Error {
        case destinationCreationFailed
        case finalizationFailed
    }

    public static func write(_ image: CGImage, to url: URL) throws {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw WriteError.destinationCreationFailed
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw WriteError.finalizationFailed
        }
    }

    public static func data(from image: CGImage) throws -> Data {
        let buffer = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            buffer,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw WriteError.destinationCreationFailed
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw WriteError.finalizationFailed
        }
        return buffer as Data
    }
}

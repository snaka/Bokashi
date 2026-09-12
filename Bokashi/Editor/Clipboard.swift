import AppKit
import BokashiCore
import CoreGraphics
import UniformTypeIdentifiers

@MainActor
enum Clipboard {
    /// Order matters: `availableType(from:)` honours it, and AppKit's own
    /// `writeObjects` (so Preview, and `copy` below) offers TIFF only.
    /// Preferring PNG keeps a Retina screenshot to a few MB instead of the
    /// ~24 MB an uncompressed TIFF costs to copy and decode.
    private static let imageTypes: [NSPasteboard.PasteboardType] = [
        .png,
        NSPasteboard.PasteboardType(UTType.jpeg.identifier),
        .tiff,
    ]

    static func copy(_ image: CGImage) {
        let pasteboard = NSPasteboard.general
        let nsImage = NSImage(cgImage: image, size: .zero)
        pasteboard.clearContents()
        pasteboard.writeObjects([nsImage])
    }

    /// Decodes the pasteboard bytes directly rather than going through
    /// `NSImage`, whose `cgImage(forProposedRect:)` rasterizes at a size
    /// derived from the image's DPI. Masking has to line up with the
    /// pixels the user sees, so the image must come back at its true
    /// pixel dimensions.
    static func readImage() -> CGImage? {
        let pasteboard = NSPasteboard.general
        guard
            let type = pasteboard.availableType(from: imageTypes),
            let data = pasteboard.data(forType: type)
        else { return nil }
        return ImageDecoder.decode(data)
    }
}

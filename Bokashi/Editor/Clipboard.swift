import AppKit
import BokashiCore
import CoreGraphics
import UniformTypeIdentifiers

@MainActor
enum Clipboard {
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

    static var hasImage: Bool {
        NSPasteboard.general.canReadItem(
            withDataConformingToTypes: imageTypes.map(\.rawValue)
        )
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

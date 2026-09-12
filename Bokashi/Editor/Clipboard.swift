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

    /// Offers PNG alongside TIFF on a single pasteboard item. Writing an
    /// `NSImage` offers TIFF only (`NSImage.writableTypes` is
    /// `[public.tiff]`), which for a Retina screenshot is ~24 MB of
    /// uncompressed pixels every receiver has to copy — including
    /// `readImage` below, on a Bokashi-to-Bokashi round trip. TIFF stays
    /// for anything that cannot read PNG.
    static func copy(_ image: CGImage) {
        let item = NSPasteboardItem()
        if let png = try? PNGWriter.data(from: image) {
            item.setData(png, forType: .png)
        }
        if let tiff = NSBitmapImageRep(cgImage: image)
            .representation(using: .tiff, properties: [:]) {
            item.setData(tiff, forType: .tiff)
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([item])
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

import AppKit
import CoreGraphics

@MainActor
enum Clipboard {
    static func copy(_ image: CGImage) {
        let pasteboard = NSPasteboard.general
        let nsImage = NSImage(cgImage: image, size: .zero)
        pasteboard.clearContents()
        pasteboard.writeObjects([nsImage])
    }
}

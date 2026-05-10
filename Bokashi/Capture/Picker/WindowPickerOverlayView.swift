import AppKit

@MainActor
final class WindowPickerOverlayView: NSView {
    var onMouseMoved: (() -> Void)?
    var onClick: (() -> Void)?
    var onCancel: (() -> Void)?

    /// Hovered window's frame in global NSScreen coordinates. Each overlay
    /// view draws the intersection with its own screen.
    var hoveredFrame: CGRect? {
        didSet { needsDisplay = true }
    }

    /// Pre-captured snapshot of the hovered window. Drawn inside the
    /// cutout so occluded windows still show their actual content.
    var hoveredImage: CGImage? {
        didSet { needsDisplay = true }
    }

    override var isFlipped: Bool { false }
    override var acceptsFirstResponder: Bool { true }

    override func resetCursorRects() {
        discardCursorRects()
        addCursorRect(bounds, cursor: .pointingHand)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas {
            removeTrackingArea(area)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseMoved, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
    }

    override func mouseMoved(with event: NSEvent) {
        onMouseMoved?()
    }

    override func mouseEntered(with event: NSEvent) {
        onMouseMoved?()
    }

    override func mouseDown(with event: NSEvent) {
        onClick?()
    }

    override func keyDown(with event: NSEvent) {
        // Escape
        if event.keyCode == 53 {
            onCancel?()
            return
        }
        super.keyDown(with: event)
    }

    override func draw(_ dirtyRect: NSRect) {
        let dim = NSBezierPath(rect: bounds)

        guard let hovered = hoveredFrame, let win = window else {
            NSColor(white: 0, alpha: 0.18).setFill()
            dim.fill()
            return
        }

        let local = NSRect(
            x: hovered.origin.x - win.frame.origin.x,
            y: hovered.origin.y - win.frame.origin.y,
            width: hovered.width,
            height: hovered.height
        )

        let cutout = NSBezierPath(rect: local)
        dim.append(cutout)
        dim.windingRule = .evenOdd
        NSColor(white: 0, alpha: 0.18).setFill()
        dim.fill()

        if let image = hoveredImage {
            let nsImage = NSImage(cgImage: image, size: local.size)
            nsImage.draw(in: local)
        }

        NSColor.systemBlue.setStroke()
        let stroke = NSBezierPath(rect: local)
        stroke.lineWidth = 3
        stroke.stroke()
    }
}

import AppKit

@MainActor
final class RegionOverlayView: NSView {
    var onCompleted: ((CGRect?) -> Void)?

    private var dragStart: NSPoint?
    private var dragCurrent: NSPoint?

    override var isFlipped: Bool { false }

    override var acceptsFirstResponder: Bool { true }

    override func resetCursorRects() {
        discardCursorRects()
        addCursorRect(bounds, cursor: .crosshair)
    }

    override func draw(_ dirtyRect: NSRect) {
        let dimPath = NSBezierPath(rect: bounds)
        var selection: NSRect?
        if let start = dragStart, let current = dragCurrent {
            let rect = NSRect(
                x: min(start.x, current.x),
                y: min(start.y, current.y),
                width: abs(current.x - start.x),
                height: abs(current.y - start.y)
            )
            selection = rect
            let cutout = NSBezierPath(rect: rect)
            dimPath.append(cutout)
            dimPath.windingRule = .evenOdd
        }
        NSColor(white: 0, alpha: 0.18).setFill()
        dimPath.fill()

        if let rect = selection {
            NSColor.systemBlue.setStroke()
            let stroke = NSBezierPath(rect: rect)
            stroke.lineWidth = 1
            stroke.stroke()
        }
    }

    override func mouseDown(with event: NSEvent) {
        dragStart = convert(event.locationInWindow, from: nil)
        dragCurrent = dragStart
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        dragCurrent = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        defer {
            dragStart = nil
            dragCurrent = nil
        }
        guard let start = dragStart, let current = dragCurrent else {
            onCompleted?(nil)
            return
        }
        let viewRect = NSRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        )
        let windowRect = convert(viewRect, to: nil)
        guard let screenRect = window?.convertToScreen(windowRect),
              screenRect.width >= 4, screenRect.height >= 4 else {
            onCompleted?(nil)
            return
        }
        onCompleted?(screenRect)
    }
}

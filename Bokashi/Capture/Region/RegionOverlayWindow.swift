import AppKit

@MainActor
final class RegionOverlayWindow: NSWindow {
    private static let escKeyCode: UInt16 = 53

    init(screenFrame: CGRect, onComplete: @escaping (CGRect?) -> Void) {
        super.init(
            contentRect: screenFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        level = .screenSaver
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = false
        acceptsMouseMovedEvents = true
        isReleasedWhenClosed = false
        animationBehavior = .none

        let view = RegionOverlayView()
        view.frame = NSRect(origin: .zero, size: screenFrame.size)
        view.onCompleted = onComplete
        contentView = view
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == Self.escKeyCode {
            (contentView as? RegionOverlayView)?.onCompleted?(nil)
            return
        }
        super.keyDown(with: event)
    }
}

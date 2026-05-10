import AppKit

@MainActor
final class WindowPickerOverlayWindow: NSWindow {
    init(screenFrame: CGRect) {
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

        let view = WindowPickerOverlayView()
        view.frame = NSRect(origin: .zero, size: screenFrame.size)
        contentView = view
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

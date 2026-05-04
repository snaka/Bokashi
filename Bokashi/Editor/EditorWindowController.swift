import AppKit
import BokashiCore
import SwiftUI

@MainActor
final class EditorWindowController: NSWindowController, NSWindowDelegate {
    enum Outcome {
        case copyOnClose
        case discarded
        case saved
    }

    private let image: CGImage
    private var outcome: Outcome = .copyOnClose
    var onClosed: (() -> Void)?

    init(image: CGImage) {
        self.image = image

        let window = Self.makeWindow(forImage: image)
        super.init(window: window)
        window.delegate = self
        window.contentViewController = NSHostingController(
            rootView: EditorView(
                image: image,
                onDone: { [weak self] in self?.done() },
                onSave: { [weak self] in self?.save() },
                onDiscard: { [weak self] in self?.discard() }
            )
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    private static func makeWindow(forImage image: CGImage) -> NSWindow {
        let scale = NSScreen.main?.backingScaleFactor ?? 2
        let imageWidthPoints = CGFloat(image.width) / scale
        let imageHeightPoints = CGFloat(image.height) / scale

        let bounds = NSScreen.main?.visibleFrame.size ?? CGSize(width: 1200, height: 800)
        let toolbarHeight: CGFloat = 56
        let maxImageWidth = bounds.width * 2 / 3
        let maxImageHeight = bounds.height * 2 / 3

        let widthRatio = min(1, maxImageWidth / imageWidthPoints)
        let heightRatio = min(1, maxImageHeight / imageHeightPoints)
        let scaleFactor = min(widthRatio, heightRatio)
        let contentWidth = max(420, imageWidthPoints * scaleFactor)
        let contentHeight = imageHeightPoints * scaleFactor + toolbarHeight

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: contentWidth, height: contentHeight),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = makeTitle()
        window.minSize = CGSize(width: 420, height: 320)
        window.center()
        window.isReleasedWhenClosed = false
        return window
    }

    private static func makeTitle() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return "Bokashi · \(formatter.string(from: Date()))"
    }

    private func done() {
        outcome = .copyOnClose
        close()
    }

    private func discard() {
        outcome = .discarded
        close()
    }

    private func save() {
        guard let window = self.window else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = CaptureFilename.make()
        if let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {
            panel.directoryURL = desktop
        }
        panel.beginSheetModal(for: window) { [weak self] response in
            guard let self else { return }
            guard response == .OK, let url = panel.url else { return }
            do {
                try PNGWriter.write(self.image, to: url)
                self.outcome = .saved
                Task { @MainActor in
                    await NotificationManager.shared.notifyScreenshotSaved(at: url)
                    self.close()
                }
            } catch {
                let alert = NSAlert(error: error)
                alert.runModal()
            }
        }
    }

    func windowWillClose(_ notification: Notification) {
        if outcome == .copyOnClose {
            Clipboard.copy(image)
        }
        onClosed?()
    }
}

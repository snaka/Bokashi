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
    private let mosaicImage: CGImage?
    private let state = EditorState()
    private let autoMaskOnCapture: Bool
    private var outcome: Outcome = .copyOnClose
    var onClosed: (() -> Void)?

    init(image: CGImage, autoMaskOnCapture: Bool = false) {
        self.image = image
        self.mosaicImage = MosaicRenderer.apply(to: image)
        self.autoMaskOnCapture = autoMaskOnCapture

        let (window, contentSize) = Self.makeWindow(forImage: image)
        super.init(window: window)
        window.delegate = self
        weak let weakWindow = window
        let host = NSHostingController(
            rootView: EditorView(
                image: image,
                mosaicImage: mosaicImage,
                state: state,
                onDone: { [weak self] in self?.done() },
                onSave: { [weak self] in self?.save() },
                onDiscard: { [weak self] in self?.discard() },
                onToolbarMinWidthChange: { width in
                    guard let window = weakWindow, width > 0 else { return }
                    let newMin = NSSize(
                        width: ceil(width),
                        height: window.contentMinSize.height
                    )
                    window.contentMinSize = newMin
                    let contentRect = window.contentRect(forFrameRect: window.frame)
                    if contentRect.width < newMin.width {
                        window.setContentSize(NSSize(
                            width: newMin.width,
                            height: contentRect.height
                        ))
                    }
                }
            )
        )
        host.sizingOptions = []
        window.contentViewController = host
        window.setContentSize(contentSize)
        window.center()

        Task { @MainActor [state, image, autoMaskOnCapture] in
            await state.runOCR(on: image)
            if autoMaskOnCapture {
                // Silent on empty: when auto-mask runs as part of capture
                // there's no user gesture to confirm; a "nothing detected"
                // toast would just be noise.
                await state.detectSensitiveInfo(in: image, silentIfEmpty: true)
            }
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    private static func makeWindow(forImage image: CGImage) -> (NSWindow, NSSize) {
        let scale = NSScreen.main?.backingScaleFactor ?? 2
        let imageWidthPoints = CGFloat(image.width) / scale
        let imageHeightPoints = CGFloat(image.height) / scale

        let bounds = NSScreen.main?.visibleFrame.size ?? CGSize(width: 1200, height: 800)
        let toolbarHeight: CGFloat = 56
        let maxImageWidth = bounds.width * 0.8
        let maxImageHeight = bounds.height * 0.8

        let widthRatio = min(1, maxImageWidth / imageWidthPoints)
        let heightRatio = min(1, maxImageHeight / imageHeightPoints)
        let scaleFactor = min(widthRatio, heightRatio)
        let contentWidth = max(420, imageWidthPoints * scaleFactor)
        let contentHeight = imageHeightPoints * scaleFactor + toolbarHeight
        let contentSize = NSSize(width: contentWidth, height: contentHeight)

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: contentSize),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = makeTitle()
        // Width floor is overridden once the SwiftUI toolbar reports its
        // natural width via `onToolbarMinWidthChange`; this initial value
        // is a fallback used until the first layout pass lands.
        window.contentMinSize = CGSize(width: 420, height: 320)
        window.isReleasedWhenClosed = false
        return (window, contentSize)
    }

    private static func makeTitle() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return "Bokashi · \(formatter.string(from: Date()))"
    }

    private var renderedImage: CGImage {
        AnnotationFlattener.flatten(
            image: image,
            mosaicImage: mosaicImage,
            annotations: state.annotations
        )
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
                try PNGWriter.write(self.renderedImage, to: url)
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
            Clipboard.copy(renderedImage)
        }
        onClosed?()
    }
}

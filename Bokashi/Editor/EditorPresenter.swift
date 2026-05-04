import AppKit
import CoreGraphics

@MainActor
final class EditorPresenter {
    private var controllers: [EditorWindowController] = []

    func present(image: CGImage) {
        let controller = EditorWindowController(
            image: image,
            autoMaskOnCapture: Preferences.shared.autoMaskOnCapture
        )
        controller.onClosed = { [weak self, weak controller] in
            guard let controller else { return }
            self?.controllers.removeAll { $0 === controller }
        }
        controllers.append(controller)
        NSApp.activate(ignoringOtherApps: true)
        controller.showWindow(nil)
    }
}

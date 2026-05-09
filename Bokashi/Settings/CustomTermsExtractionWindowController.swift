import AppKit
import SwiftUI

@MainActor
final class CustomTermsExtractionWindowController: NSWindowController, NSWindowDelegate {
    var onClosed: (() -> Void)?

    init(candidates: [String]) {
        let model = CustomTermsExtractionModel(candidates: candidates)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 380),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Add Custom Terms"
        window.minSize = NSSize(width: 420, height: 320)
        window.isReleasedWhenClosed = false

        super.init(window: window)
        window.delegate = self

        let host = NSHostingController(
            rootView: CustomTermsExtractionView(
                model: model,
                onAdd: { [weak self] terms in
                    for term in terms {
                        CustomTermsManager.shared.add(term)
                    }
                    self?.close()
                },
                onCancel: { [weak self] in self?.close() }
            )
        )
        host.sizingOptions = []
        window.contentViewController = host
        window.center()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func windowWillClose(_ notification: Notification) {
        onClosed?()
    }
}

@MainActor
final class CustomTermsExtractionPresenter {
    private var controllers: [CustomTermsExtractionWindowController] = []

    func present(candidates: [String]) {
        guard !candidates.isEmpty else { return }
        let controller = CustomTermsExtractionWindowController(candidates: candidates)
        controller.onClosed = { [weak self, weak controller] in
            guard let controller else { return }
            self?.controllers.removeAll { $0 === controller }
        }
        controllers.append(controller)
        NSApp.activate(ignoringOtherApps: true)
        controller.showWindow(nil)
    }
}

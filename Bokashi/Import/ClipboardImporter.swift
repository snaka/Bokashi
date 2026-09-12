import AppKit

@MainActor
final class ClipboardImporter {
    /// What to do when the clipboard holds no image. A menu click is
    /// deliberate and deserves an answer; a hotkey press may well be a
    /// mistake, and a modal thrown in front of whatever the user was
    /// doing would be worse than nothing.
    enum EmptyBehavior {
        case silent
        case alert
    }

    private let editorPresenter: EditorPresenter

    init(editorPresenter: EditorPresenter) {
        self.editorPresenter = editorPresenter
    }

    /// Unlike every capture path this deliberately skips
    /// `ensurePermission()`: reading the pasteboard needs no Screen
    /// Recording grant, so importing works before the user gives one.
    func importImage(whenEmpty behavior: EmptyBehavior) {
        guard let image = Clipboard.readImage() else {
            if case .alert = behavior { presentNoImage() }
            return
        }
        editorPresenter.present(image: image)
    }

    private func presentNoImage() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "No image in the clipboard"
        alert.informativeText = """
            Copy an image first, then choose New from Clipboard.
            """
        alert.runModal()
    }
}

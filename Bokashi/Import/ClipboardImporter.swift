import AppKit

@MainActor
final class ClipboardImporter {
    private let editorPresenter: EditorPresenter

    init(editorPresenter: EditorPresenter) {
        self.editorPresenter = editorPresenter
    }

    /// Unlike every capture path this deliberately skips
    /// `ensurePermission()`: reading the pasteboard needs no Screen
    /// Recording grant, so importing works before the user gives one.
    ///
    /// A menu click is deliberate and deserves an answer when the
    /// clipboard turns out to be empty; a hotkey press may well be a
    /// mistake, and a modal thrown in front of whatever the user was
    /// doing would be worse than nothing.
    func importImage(alertWhenEmpty: Bool) {
        guard let image = Clipboard.readImage() else {
            if alertWhenEmpty { presentNoImage() }
            return
        }
        editorPresenter.present(image: image)
    }

    private func presentNoImage() {
        Alerts.show(
            title: "No image in the clipboard",
            message: "Copy an image first, then choose New from Clipboard."
        )
    }
}

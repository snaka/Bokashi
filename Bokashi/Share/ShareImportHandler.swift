import BokashiCore
import Foundation

@MainActor
final class ShareImportHandler {
    private let editorPresenter: EditorPresenter

    init(editorPresenter: EditorPresenter) {
        self.editorPresenter = editorPresenter
    }

    /// A payload that will not decode is dropped without a word: the user
    /// asked to share an image, not to be told about a format Bokashi
    /// could not read, and the share sheet is already gone by now.
    func importPending() {
        guard let inbox = AppGroup.inbox else { return }
        for data in inbox.drain() {
            guard let image = ImageDecoder.decode(data) else { continue }
            editorPresenter.present(image: image)
        }
    }
}

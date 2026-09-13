import AppKit
import BokashiCore
import UniformTypeIdentifiers

/// The `@objc` name is load-bearing: `NSExtensionPrincipalClass` is
/// resolved through the Objective-C runtime, and Swift's mangled name does
/// not match. Without it the extension never launches, with no crash
/// report and no error — the Share menu item simply does nothing.
@objc(ShareViewController)
final class ShareViewController: NSViewController {
    private enum ShareError: Error {
        case noInboxAvailable
        case noImageData
    }

    override func loadView() {
        view = NSView(frame: .zero)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        handOff()
    }

    /// The context is held strongly for the whole hand-off: routing the
    /// completion through `self` meant a deallocated controller never
    /// called `completeRequest`, hanging the share sheet until the OS
    /// reaped the process.
    private func handOff() {
        guard let context = extensionContext else { return }

        let providers = (context.inputItems as? [NSExtensionItem] ?? [])
            .flatMap { $0.attachments ?? [] }
        guard
            let provider = providers.first(where: {
                $0.hasItemConformingToTypeIdentifier(UTType.image.identifier)
            })
        else {
            context.completeRequest(returningItems: [], completionHandler: nil)
            return
        }

        provider.loadDataRepresentation(
            forTypeIdentifier: UTType.image.identifier
        ) { data, error in
            let result: Result<Void, Error>
            if let data {
                if let inbox = AppGroup.inbox {
                    result = Result { _ = try inbox.write(data) }
                } else {
                    result = .failure(ShareError.noInboxAvailable)
                }
            } else {
                result = .failure(error ?? ShareError.noImageData)
            }

            DispatchQueue.main.async {
                switch result {
                case .success:
                    // The bytes are already in the inbox, so the app picks
                    // them up whether or not it was running: this launches
                    // it if needed and is otherwise just a nudge.
                    NSWorkspace.shared.open(URL(string: "bokashi://import")!)
                    context.completeRequest(returningItems: [], completionHandler: nil)
                case .failure(let error):
                    context.cancelRequest(withError: error)
                }
            }
        }
    }
}

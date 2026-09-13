import AppKit
import BokashiCore
import UniformTypeIdentifiers

/// The `@objc` name is load-bearing: `NSExtensionPrincipalClass` is
/// resolved through the Objective-C runtime, and Swift's mangled name does
/// not match. Without it the extension never launches, with no crash
/// report and no error — the Share menu item simply does nothing.
@objc(ShareViewController)
final class ShareViewController: NSViewController {
    override func loadView() {
        view = NSView(frame: .zero)
        handOff()
    }

    private func handOff() {
        let providers = (extensionContext?.inputItems as? [NSExtensionItem] ?? [])
            .flatMap { $0.attachments ?? [] }
        guard
            let provider = providers.first(where: {
                $0.hasItemConformingToTypeIdentifier(UTType.image.identifier)
            })
        else {
            complete()
            return
        }

        provider.loadDataRepresentation(
            forTypeIdentifier: UTType.image.identifier
        ) { [weak self] data, _ in
            if let data { try? AppGroup.inbox?.write(data) }
            DispatchQueue.main.async {
                // The bytes are already in the inbox, so the app picks
                // them up whether or not it was running: this launches it
                // if needed and is otherwise just a nudge.
                NSWorkspace.shared.open(URL(string: "bokashi://import")!)
                self?.complete()
            }
        }
    }

    private func complete() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}

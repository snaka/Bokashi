import AppKit

@MainActor
enum Alerts {
    /// Bokashi is `LSUIElement`, so it is never the active app when a
    /// capture or an import finishes. Without the activation the modal
    /// opens behind whatever the user is looking at, which is why every
    /// alert in the app has to go through here.
    static func make(title: String, message: String) -> NSAlert {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        return alert
    }

    static func show(title: String, message: String) {
        make(title: title, message: message).runModal()
    }
}

import AppKit
import KeyboardShortcuts

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let captureCoordinator = CaptureCoordinator()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationManager.shared.setUp()
        registerHotkeys()
    }

    private func registerHotkeys() {
        KeyboardShortcuts.onKeyDown(for: .captureFullScreen) { [weak self] in
            Task { @MainActor in
                await self?.captureCoordinator.captureFullScreen()
            }
        }
    }
}

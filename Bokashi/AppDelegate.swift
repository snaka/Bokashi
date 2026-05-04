import AppKit
import KeyboardShortcuts

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let captureCoordinator = CaptureCoordinator()
    let windowsModel = WindowsModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationManager.shared.setUp()
        registerHotkeys()
        Task { @MainActor in
            await windowsModel.refresh()
        }
    }

    private func registerHotkeys() {
        KeyboardShortcuts.onKeyDown(for: .captureFullScreen) { [weak self] in
            Task { @MainActor in
                await self?.captureCoordinator.captureFullScreen()
            }
        }
        KeyboardShortcuts.onKeyDown(for: .captureRegion) { [weak self] in
            Task { @MainActor in
                await self?.captureCoordinator.captureRegion()
            }
        }
    }
}

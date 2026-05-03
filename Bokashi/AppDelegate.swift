import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let captureCoordinator = CaptureCoordinator()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationManager.shared.setUp()
    }
}

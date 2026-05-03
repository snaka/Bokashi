import AppKit
import BokashiCore

@MainActor
final class CaptureCoordinator {
    private static let permissionPromptedKey = "BokashiScreenRecordingPromptedOnce"

    private let captureService = CaptureService()

    func captureFullScreen() async {
        guard ensurePermission() else { return }

        do {
            let image = try await captureService.captureMainDisplay()
            let url = SaveDestination.desktopURL(for: CaptureFilename.make())
            try PNGWriter.write(image, to: url)
            let posted = await NotificationManager.shared.notifyScreenshotSaved(at: url)
            if !posted {
                NSSound.beep()
            }
        } catch {
            presentError(error)
        }
    }

    private func ensurePermission() -> Bool {
        if ScreenRecordingPermission.isGranted { return true }

        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: Self.permissionPromptedKey) {
            defaults.set(true, forKey: Self.permissionPromptedKey)
            _ = ScreenRecordingPermission.request()
            return false
        }

        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Screen Recording permission required"
        alert.informativeText = """
            Bokashi needs Screen Recording access to capture your screen.

            If you have already enabled it in System Settings, quit and reopen \
            Bokashi for the change to take effect.
            """
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            ScreenRecordingPermission.openSystemSettings()
        }
        return false
    }

    private func presentError(_ error: Error) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Capture failed"
        alert.informativeText = (error as? LocalizedError)?.errorDescription
            ?? error.localizedDescription
        alert.runModal()
    }
}

import AppKit
import BokashiCore
import ScreenCaptureKit

@MainActor
final class CaptureCoordinator {
    private let captureService = CaptureService()

    func captureFullScreen() async {
        guard ensurePermission() else { return }
        await save { try await captureService.captureMainDisplay() }
    }

    func captureWindow(byID windowID: CGWindowID) async {
        guard ensurePermission() else { return }
        await save {
            let content = try await SCShareableContent.current
            guard let window = content.windows.first(where: { $0.windowID == windowID }) else {
                throw CaptureCoordinatorError.windowNoLongerAvailable
            }
            return try await self.captureService.captureWindow(window)
        }
    }

    private func save(_ produce: () async throws -> CGImage) async {
        do {
            let image = try await produce()
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
        if ScreenRecordingPermission.request() { return true }

        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Screen Recording permission required"
        alert.informativeText = """
            Bokashi needs Screen Recording access in System Settings to capture your screen.
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

enum CaptureCoordinatorError: Error, LocalizedError {
    case windowNoLongerAvailable

    var errorDescription: String? {
        switch self {
        case .windowNoLongerAvailable:
            return "The selected window is no longer available."
        }
    }
}

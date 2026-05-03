import AppKit
import BokashiCore

@MainActor
final class CaptureCoordinator {
    private let captureService = CaptureService()

    func captureFullScreen() async {
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

    private func presentError(_ error: Error) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Capture failed"
        alert.informativeText = (error as? LocalizedError)?.errorDescription
            ?? error.localizedDescription
        alert.runModal()
    }
}

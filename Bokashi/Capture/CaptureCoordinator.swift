import AppKit
import BokashiCore
import ScreenCaptureKit

@MainActor
final class CaptureCoordinator {
    private let captureService = CaptureService()
    private let regionSelector = RegionSelector()
    private let editorPresenter: EditorPresenter

    init(editorPresenter: EditorPresenter) {
        self.editorPresenter = editorPresenter
    }

    func captureFullScreen() async {
        guard ensurePermission() else { return }
        await present { try await self.captureService.captureMainDisplay() }
    }

    func captureWindow(byID windowID: CGWindowID) async {
        guard ensurePermission() else { return }
        await present {
            let content = try await SCShareableContent.current
            guard let window = content.windows.first(where: { $0.windowID == windowID }) else {
                throw CaptureCoordinatorError.windowNoLongerAvailable
            }
            return try await self.captureService.captureWindow(window)
        }
    }

    func captureRegion() async {
        guard ensurePermission() else { return }
        guard let screenRect = await regionSelector.selectRegion() else { return }
        try? await Task.sleep(for: .milliseconds(100))
        await present { try await self.captureService.captureRegion(in: screenRect) }
    }

    private func present(_ produce: () async throws -> CGImage) async {
        do {
            let image = try await produce()
            editorPresenter.present(image: image)
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

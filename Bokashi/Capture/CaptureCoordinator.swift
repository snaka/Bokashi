import AppKit
import BokashiCore
import ScreenCaptureKit

@MainActor
final class CaptureCoordinator {
    private let captureService = CaptureService()
    private let regionSelector = RegionSelector()
    private let windowPicker = WindowPicker()
    private let editorPresenter: EditorPresenter
    private let customTermsExtractionPresenter: CustomTermsExtractionPresenter

    init(
        editorPresenter: EditorPresenter,
        customTermsExtractionPresenter: CustomTermsExtractionPresenter
    ) {
        self.editorPresenter = editorPresenter
        self.customTermsExtractionPresenter = customTermsExtractionPresenter
    }

    func captureFullScreen() async {
        guard ensurePermission() else { return }
        await present { try await self.captureService.captureCursorDisplay() }
    }

    func pickAndCaptureWindow() async {
        guard ensurePermission() else { return }
        guard let window = await windowPicker.pickWindow() else { return }
        try? await Task.sleep(for: .milliseconds(100))
        await present { try await self.captureService.captureWindow(window) }
    }

    func captureRegion() async {
        guard ensurePermission() else { return }
        guard let screenRect = await regionSelector.selectRegion() else { return }
        try? await Task.sleep(for: .milliseconds(100))
        await present { try await self.captureService.captureRegion(in: screenRect) }
    }

    func captureRegionForCustomTerms() async {
        guard ensurePermission() else { return }
        guard let screenRect = await regionSelector.selectRegion() else { return }
        try? await Task.sleep(for: .milliseconds(100))
        do {
            let image = try await captureService.captureRegion(in: screenRect)
            let observations = try await OCRRunner.recognize(image)
            let candidates = observations
                .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            guard !candidates.isEmpty else {
                presentNoTextDetected()
                return
            }
            customTermsExtractionPresenter.present(candidates: candidates)
        } catch {
            presentError(error)
        }
    }

    private func presentNoTextDetected() {
        Alerts.show(
            title: "No text detected",
            message: "Bokashi could not find any text in the selected region."
        )
    }

    private func present(_ produce: () async throws -> CGImage) async {
        do {
            let image = try await produce()
            // Make the raw capture immediately pasteable; the editor's
            // copy-on-close path overwrites this with the annotated image
            // if the user edits and confirms.
            Clipboard.copy(image)
            editorPresenter.present(image: image)
        } catch {
            presentError(error)
        }
    }

    private func ensurePermission() -> Bool {
        if ScreenRecordingPermission.isGranted { return true }
        if ScreenRecordingPermission.request() { return true }

        let alert = Alerts.make(
            title: "Screen Recording permission required",
            message: "Bokashi needs Screen Recording access in System Settings to capture your screen."
        )
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            ScreenRecordingPermission.openSystemSettings()
        }
        return false
    }

    private func presentError(_ error: Error) {
        Alerts.show(
            title: "Capture failed",
            message: (error as? LocalizedError)?.errorDescription
                ?? error.localizedDescription
        )
    }
}

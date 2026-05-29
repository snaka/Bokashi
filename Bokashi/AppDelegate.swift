import AppKit
import KeyboardShortcuts
import Sparkle

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let editorPresenter = EditorPresenter()
    let customTermsExtractionPresenter = CustomTermsExtractionPresenter()
    lazy var captureCoordinator = CaptureCoordinator(
        editorPresenter: editorPresenter,
        customTermsExtractionPresenter: customTermsExtractionPresenter
    )
    let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )
    lazy var updaterSettings = UpdaterSettings(updater: updaterController.updater)

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
        KeyboardShortcuts.onKeyDown(for: .captureRegion) { [weak self] in
            Task { @MainActor in
                await self?.captureCoordinator.captureRegion()
            }
        }
        KeyboardShortcuts.onKeyDown(for: .captureWindow) { [weak self] in
            Task { @MainActor in
                await self?.captureCoordinator.pickAndCaptureWindow()
            }
        }
    }
}

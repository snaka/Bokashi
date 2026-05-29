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
        migrateCaptureHotkeysIfNeeded()
        registerHotkeys()
    }

    /// `KeyboardShortcuts.Name.init` materializes its `default:` into
    /// `UserDefaults` on first launch, so simply changing the default
    /// in code does not propagate to users who already ran an earlier
    /// build. Detect entries that still match a previous shipped default
    /// and reset them to today's default; record a schema version so the
    /// migration runs at most once per user and never clobbers shortcuts
    /// the user has intentionally customized.
    private func migrateCaptureHotkeysIfNeeded() {
        let schemaKey = "BokashiCaptureHotkeySchemaVersion"
        let currentSchema = 1
        let defaults = UserDefaults.standard
        guard defaults.integer(forKey: schemaKey) < currentSchema else { return }

        let legacyFullScreen = KeyboardShortcuts.Shortcut(
            .four, modifiers: [.control, .option, .shift]
        )
        let legacyRegion = KeyboardShortcuts.Shortcut(
            .six, modifiers: [.control, .option, .shift]
        )
        if KeyboardShortcuts.getShortcut(for: .captureFullScreen) == legacyFullScreen {
            KeyboardShortcuts.reset(.captureFullScreen)
        }
        if KeyboardShortcuts.getShortcut(for: .captureRegion) == legacyRegion {
            KeyboardShortcuts.reset(.captureRegion)
        }
        defaults.set(currentSchema, forKey: schemaKey)
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

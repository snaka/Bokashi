import KeyboardShortcuts
import SwiftUI

@main
struct BokashiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    /// `CFBundleShortVersionString` from the app bundle (driven by
    /// `MARKETING_VERSION` in `project.yml`). Falls back to "?" only if
    /// the Info.plist key is somehow missing.
    private static let marketingVersion: String =
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"

    var body: some Scene {
        MenuBarExtra("Bokashi", image: "MenuBarIcon") {
            menuContent
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(
                onAddFromSelection: {
                    Task { @MainActor in
                        await appDelegate.captureCoordinator.captureRegionForCustomTerms()
                    }
                },
                updaterSettings: appDelegate.updaterSettings
            )
        }
    }

    @ViewBuilder
    private var menuContent: some View {
        @Bindable var prefs = Preferences.shared

        Text("Bokashi v\(Self.marketingVersion)")
        Divider()
        captureButton("Capture Full Screen", shortcut: .captureFullScreen) {
            await appDelegate.captureCoordinator.captureFullScreen()
        }
        captureButton("Capture Region…", shortcut: .captureRegion) {
            await appDelegate.captureCoordinator.captureRegion()
        }
        captureButton("Capture Window…", shortcut: .captureWindow) {
            await appDelegate.captureCoordinator.pickAndCaptureWindow()
        }
        Divider()
        Toggle("Auto-mask sensitive info on capture", isOn: $prefs.autoMaskOnCapture)
        SettingsLink {
            Text("Settings…")
        }
        .keyboardShortcut(",")
        Button("Check for Updates…") {
            appDelegate.updaterController.checkForUpdates(nil)
        }
        Divider()
        Button("Quit Bokashi") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    @ViewBuilder
    private func captureButton(
        _ title: String,
        shortcut name: KeyboardShortcuts.Name,
        action: @escaping () async -> Void
    ) -> some View {
        let shortcut = KeyboardShortcuts.getShortcut(for: name)
        if let key = shortcut?.swiftUIKeyEquivalent {
            Button(title) {
                Task { @MainActor in await action() }
            }
            .keyboardShortcut(key, modifiers: shortcut?.swiftUIModifiers ?? [])
        } else {
            Button(title) {
                Task { @MainActor in await action() }
            }
        }
    }
}

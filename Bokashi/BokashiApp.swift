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
        Button("Capture Full Screen") {
            Task { @MainActor in
                await appDelegate.captureCoordinator.captureFullScreen()
            }
        }
        Button("Capture Region…") {
            Task { @MainActor in
                await appDelegate.captureCoordinator.captureRegion()
            }
        }
        Button("Capture Window…") {
            Task { @MainActor in
                await appDelegate.captureCoordinator.pickAndCaptureWindow()
            }
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
}

import SwiftUI
import BokashiCore

@main
struct BokashiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Bokashi", image: "MenuBarIcon") {
            menuContent
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(onAddFromSelection: {
                Task { @MainActor in
                    await appDelegate.captureCoordinator.captureRegionForCustomTerms()
                }
            })
        }
    }

    @ViewBuilder
    private var menuContent: some View {
        @Bindable var prefs = Preferences.shared

        Text("Bokashi v\(BokashiCore.version)")
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
        Divider()
        Button("Quit Bokashi") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}

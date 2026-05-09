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
            SettingsView()
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
        Menu("Capture Window") {
            Button("Refresh") {
                Task { @MainActor in
                    await appDelegate.windowsModel.refresh()
                }
            }
            Divider()
            if appDelegate.windowsModel.windows.isEmpty {
                Text("No windows").disabled(true)
            } else {
                ForEach(appDelegate.windowsModel.windows) { item in
                    Button(item.displayName) {
                        let id = item.id
                        Task { @MainActor in
                            await appDelegate.captureCoordinator.captureWindow(byID: id)
                        }
                    }
                }
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

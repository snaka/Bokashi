import SwiftUI
import BokashiCore

@main
struct BokashiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Bokashi", systemImage: "camera.viewfinder") {
            menuContent
        }
        .menuBarExtraStyle(.menu)
    }

    @ViewBuilder
    private var menuContent: some View {
        Text("Bokashi v\(BokashiCore.version)")
        Divider()
        Button("Capture Full Screen") {
            Task { @MainActor in
                await appDelegate.captureCoordinator.captureFullScreen()
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
        Button("Quit Bokashi") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}

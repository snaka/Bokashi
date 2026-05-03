import SwiftUI
import BokashiCore

@main
struct BokashiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Bokashi", systemImage: "camera.viewfinder") {
            Text("Bokashi v\(BokashiCore.version)")
            Divider()
            Button("Capture Full Screen") {
                Task { @MainActor in
                    await appDelegate.captureCoordinator.captureFullScreen()
                }
            }
            Divider()
            Button("Quit Bokashi") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .menuBarExtraStyle(.menu)
    }
}

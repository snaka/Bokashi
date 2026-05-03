import SwiftUI
import BokashiCore

@main
struct BokashiApp: App {
    var body: some Scene {
        MenuBarExtra("Bokashi", systemImage: "camera.viewfinder") {
            Text("Bokashi v\(BokashiCore.version)")
            Divider()
            Button("Capture (not yet implemented)") {
                // Implemented in M1
            }
            .disabled(true)
            Divider()
            Button("Quit Bokashi") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .menuBarExtraStyle(.menu)
    }
}

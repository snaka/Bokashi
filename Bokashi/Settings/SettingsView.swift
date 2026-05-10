import SwiftUI

struct SettingsView: View {
    var onAddFromSelection: () -> Void

    var body: some View {
        TabView {
            CustomTermsSettingsView(onAddFromSelection: onAddFromSelection)
                .tabItem {
                    Label("Custom Terms", systemImage: "eye.slash")
                }
            DetectorsSettingsView()
                .tabItem {
                    Label("Detectors", systemImage: "sparkles.rectangle.stack")
                }
        }
        .frame(width: 520, height: 420)
    }
}

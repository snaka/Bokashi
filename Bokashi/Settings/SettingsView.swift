import SwiftUI

struct SettingsView: View {
    var onAddFromSelection: () -> Void
    var updaterSettings: UpdaterSettings

    var body: some View {
        TabView {
            GeneralSettingsView(updaterSettings: updaterSettings)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
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

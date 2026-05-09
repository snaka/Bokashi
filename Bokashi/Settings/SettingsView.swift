import SwiftUI

struct SettingsView: View {
    var onAddFromSelection: () -> Void

    var body: some View {
        TabView {
            CustomTermsSettingsView(onAddFromSelection: onAddFromSelection)
                .tabItem {
                    Label("Custom Terms", systemImage: "eye.slash")
                }
        }
        .frame(width: 520, height: 400)
    }
}

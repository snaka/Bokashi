import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            CustomTermsSettingsView()
                .tabItem {
                    Label("Custom Terms", systemImage: "eye.slash")
                }
        }
        .frame(width: 480, height: 360)
    }
}

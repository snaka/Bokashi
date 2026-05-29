import SwiftUI

struct GeneralSettingsView: View {
    @Bindable var updaterSettings: UpdaterSettings

    var body: some View {
        Form {
            Section("Updates") {
                Toggle(
                    "Check for updates automatically",
                    isOn: $updaterSettings.automaticallyChecksForUpdates
                )
                Text("When enabled, Bokashi periodically checks for new releases in the background. You can also check manually from the menu bar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }
}

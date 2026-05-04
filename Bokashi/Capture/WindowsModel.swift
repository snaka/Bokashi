import Foundation
import ScreenCaptureKit

@MainActor
@Observable
final class WindowsModel {
    private(set) var windows: [WindowItem] = []

    struct WindowItem: Identifiable, Hashable {
        let id: CGWindowID
        let title: String
        let appName: String

        var displayName: String { "\(appName) — \(title)" }
    }

    func refresh() async {
        do {
            let content = try await SCShareableContent.current
            let myBundleID = Bundle.main.bundleIdentifier
            self.windows = content.windows
                .filter { $0.isOnScreen }
                .filter { $0.windowLayer == 0 }
                .filter { ($0.title?.isEmpty == false) }
                .filter { $0.owningApplication?.bundleIdentifier != myBundleID }
                .map { sc in
                    WindowItem(
                        id: sc.windowID,
                        title: sc.title ?? "",
                        appName: sc.owningApplication?.applicationName ?? "Unknown"
                    )
                }
                .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
        } catch {
            self.windows = []
        }
    }
}

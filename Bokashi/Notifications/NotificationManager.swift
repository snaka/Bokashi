import AppKit
import UserNotifications

@MainActor
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private static let revealActionIdentifier = "BOKASHI_REVEAL_IN_FINDER"
    private static let savedCategoryIdentifier = "BOKASHI_SCREENSHOT_SAVED"
    private static let deniedAlertShownKey = "BokashiNotificationDeniedAlertShown"

    func setUp() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        let revealAction = UNNotificationAction(
            identifier: Self.revealActionIdentifier,
            title: "Reveal in Finder",
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: Self.savedCategoryIdentifier,
            actions: [revealAction],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }

    @discardableResult
    func notifyScreenshotSaved(at fileURL: URL) async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .notDetermined:
            NSApp.activate(ignoringOtherApps: true)
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            guard granted else { return false }
        case .denied:
            presentDeniedAlertIfNeeded()
            return false
        case .authorized, .provisional, .ephemeral:
            break
        @unknown default:
            return false
        }

        let content = UNMutableNotificationContent()
        content.title = "Screenshot saved"
        content.body = fileURL.lastPathComponent
        content.categoryIdentifier = Self.savedCategoryIdentifier
        content.userInfo = ["filePath": fileURL.path]

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        do {
            try await center.add(request)
            return true
        } catch {
            return false
        }
    }

    private func presentDeniedAlertIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: Self.deniedAlertShownKey) else { return }
        defaults.set(true, forKey: Self.deniedAlertShownKey)

        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Notifications are disabled for Bokashi"
        alert.informativeText = """
            Screenshots are still saved to your Desktop, but Bokashi cannot show \
            a banner to confirm them. Enable notifications in System Settings if \
            you want them back.
            """
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Not Now")
        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let path = response.notification.request.content.userInfo["filePath"] as? String else {
            return
        }
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}

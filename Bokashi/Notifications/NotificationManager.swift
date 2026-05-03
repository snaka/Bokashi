import AppKit
import UserNotifications

@MainActor
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private static let revealActionIdentifier = "BOKASHI_REVEAL_IN_FINDER"
    private static let savedCategoryIdentifier = "BOKASHI_SCREENSHOT_SAVED"

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

        Task {
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
        }
    }

    @discardableResult
    func notifyScreenshotSaved(at fileURL: URL) async -> Bool {
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
            try await UNUserNotificationCenter.current().add(request)
            return true
        } catch {
            return false
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

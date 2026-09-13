import Foundation

public enum AppGroup {
    /// Published by `project.yml` as `$(TeamIdentifierPrefix)com.snaka.Bokashi`
    /// in both bundles, so the entitlement and this lookup cannot drift
    /// apart and neither can the app and the extension.
    public static var identifier: String? {
        Bundle.main.object(forInfoDictionaryKey: "BokashiAppGroupIdentifier") as? String
    }

    public static var inbox: ShareInbox? {
        guard
            let identifier,
            let container = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: identifier)
        else { return nil }
        return ShareInbox(directory: container.appendingPathComponent("Inbox"))
    }
}

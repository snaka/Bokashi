import Foundation

public enum AppGroup {
    /// Published by `project.yml` as `$(DEVELOPMENT_TEAM).com.snaka.Bokashi`
    /// in both bundles. `$(DEVELOPMENT_TEAM)` is one explicit build setting
    /// that both the entitlement and this plist key derive from, so they
    /// cannot drift apart the way `$(TeamIdentifierPrefix)` did: that
    /// variable is resolved from different sources in the entitlement and
    /// Info.plist substitution paths, and let the two disagree silently.
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

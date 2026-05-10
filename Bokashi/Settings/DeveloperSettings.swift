import Foundation

@MainActor
@Observable
final class DeveloperSettings {
    static let shared = DeveloperSettings()

    private static let highlightSourceKey = "BokashiDevHighlightMaskSource"

    /// When on, the editor draws a colored stroke around each
    /// auto-detected mosaic, colored by which detector produced it.
    var highlightMaskSource: Bool {
        didSet { UserDefaults.standard.set(highlightMaskSource, forKey: Self.highlightSourceKey) }
    }

    private init() {
        highlightMaskSource = UserDefaults.standard.bool(forKey: Self.highlightSourceKey)
    }
}

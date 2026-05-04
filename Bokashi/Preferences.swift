import Foundation

@MainActor
@Observable
final class Preferences {
    static let shared = Preferences()

    private static let autoMaskKey = "BokashiAutoMaskOnCapture"

    var autoMaskOnCapture: Bool {
        didSet {
            UserDefaults.standard.set(autoMaskOnCapture, forKey: Self.autoMaskKey)
        }
    }

    private init() {
        autoMaskOnCapture = UserDefaults.standard.bool(forKey: Self.autoMaskKey)
    }
}

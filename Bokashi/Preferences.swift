import Foundation

@MainActor
@Observable
final class Preferences {
    static let shared = Preferences()

    /// Still spelled "OnCapture" so existing users keep their setting;
    /// the preference itself has covered every way an image reaches the
    /// editor since clipboard import landed.
    private static let autoMaskKey = "BokashiAutoMaskOnCapture"

    var autoMask: Bool {
        didSet {
            UserDefaults.standard.set(autoMask, forKey: Self.autoMaskKey)
        }
    }

    private init() {
        autoMask = UserDefaults.standard.bool(forKey: Self.autoMaskKey)
    }
}

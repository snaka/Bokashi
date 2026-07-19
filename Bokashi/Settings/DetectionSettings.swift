import Foundation

@MainActor
@Observable
final class DetectionSettings {
    static let shared = DetectionSettings()

    private static let aiEnabledKey = "BokashiAIDetectorEnabled"
    private static let faceEnabledKey = "BokashiFaceDetectorEnabled"

    var aiDetectionEnabled: Bool {
        didSet { UserDefaults.standard.set(aiDetectionEnabled, forKey: Self.aiEnabledKey) }
    }

    var faceMaskingEnabled: Bool {
        didSet { UserDefaults.standard.set(faceMaskingEnabled, forKey: Self.faceEnabledKey) }
    }

    private init() {
        let defaults = UserDefaults.standard
        aiDetectionEnabled = (defaults.object(forKey: Self.aiEnabledKey) as? Bool) ?? true
        faceMaskingEnabled = (defaults.object(forKey: Self.faceEnabledKey) as? Bool) ?? true
    }

    /// The Ollama detector shipped in v0.5.0 and was removed in favor of
    /// the Apple Intelligence detector; clear its orphaned defaults.
    static func removeObsoleteOllamaDefaults() {
        let defaults = UserDefaults.standard
        for key in [
            "BokashiOllamaDetectorEnabled",
            "BokashiOllamaDetectorEndpoint",
            "BokashiOllamaDetectorModel",
        ] {
            defaults.removeObject(forKey: key)
        }
    }
}

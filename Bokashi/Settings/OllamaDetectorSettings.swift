import Foundation

@MainActor
@Observable
final class OllamaDetectorSettings {
    static let shared = OllamaDetectorSettings()

    private static let enabledKey = "BokashiOllamaDetectorEnabled"
    private static let endpointKey = "BokashiOllamaDetectorEndpoint"
    private static let modelKey = "BokashiOllamaDetectorModel"

    static let defaultEndpoint = "http://localhost:11434"
    static let modelPlaceholder = "llama3.2-vision"

    var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey) }
    }

    var endpoint: String {
        didSet { UserDefaults.standard.set(endpoint, forKey: Self.endpointKey) }
    }

    var model: String {
        didSet { UserDefaults.standard.set(model, forKey: Self.modelKey) }
    }

    private init() {
        let defaults = UserDefaults.standard
        self.isEnabled = defaults.bool(forKey: Self.enabledKey)
        self.endpoint = (defaults.string(forKey: Self.endpointKey)?.nilIfBlank)
            ?? Self.defaultEndpoint
        self.model = defaults.string(forKey: Self.modelKey) ?? ""
    }

    var trimmedEndpoint: String {
        endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedModel: String {
        model.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

import SwiftUI

struct DetectorsSettingsView: View {
    @State private var settings = OllamaDetectorSettings.shared
    @State private var dev = DeveloperSettings.shared
    @State private var testStatus: TestStatus = .idle

    enum TestStatus: Equatable {
        case idle
        case running
        case success(String)
        case failure(String)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Optional vision-LLM detector that runs entirely on your machine via Ollama. Bokashi only ever talks to the endpoint you configure (default: localhost). No screenshot ever leaves the destination you set here.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Toggle("Enable Ollama vision detector", isOn: $settings.isEnabled)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 6) {
                Text("Endpoint").font(.caption).foregroundStyle(.secondary)
                TextField(OllamaDetectorSettings.defaultEndpoint, text: $settings.endpoint)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!settings.isEnabled)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Model").font(.caption).foregroundStyle(.secondary)
                TextField(OllamaDetectorSettings.modelPlaceholder, text: $settings.model)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!settings.isEnabled)
            }

            HStack(spacing: 8) {
                Button {
                    runConnectionTest()
                } label: {
                    if case .running = testStatus {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("Test Connection")
                    }
                }
                .disabled(!settings.isEnabled || isTestRunning)

                statusLabel
            }

            Divider().padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 4) {
                Text("Developer").font(.caption).foregroundStyle(.secondary)
                Toggle("Highlight mask source in editor", isOn: $dev.highlightMaskSource)
                Text("Outlines auto-detected mosaics with a colored dashed border in the editor: blue = OCR / regex / NLTagger, orange = Ollama. Useful for tuning prompts and detectors.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding()
    }

    private var isTestRunning: Bool {
        if case .running = testStatus { return true }
        return false
    }

    @ViewBuilder
    private var statusLabel: some View {
        switch testStatus {
        case .idle:
            EmptyView()
        case .running:
            Text("Checking…").foregroundStyle(.secondary)
        case .success(let message):
            Label(message, systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .labelStyle(.titleAndIcon)
        case .failure(let message):
            Label(message, systemImage: "xmark.circle.fill")
                .foregroundStyle(.red)
                .labelStyle(.titleAndIcon)
        }
    }

    private func runConnectionTest() {
        let endpoint = settings.trimmedEndpoint
        let model = settings.trimmedModel
        testStatus = .running
        Task { @MainActor in
            let result = await OllamaConnectionTester.test(endpoint: endpoint, model: model)
            testStatus = result
        }
    }
}

@MainActor
enum OllamaConnectionTester {
    static func test(endpoint: String, model: String) async -> DetectorsSettingsView.TestStatus {
        guard !endpoint.isEmpty else {
            return .failure("Endpoint is empty")
        }
        guard let base = URL(string: endpoint) else {
            return .failure("Endpoint is not a valid URL")
        }
        let tagsURL = base.appendingPathComponent("api/tags")

        var request = URLRequest(url: tagsURL)
        request.timeoutInterval = 5

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return .failure("Endpoint reachable but returned an error")
            }

            if model.isEmpty {
                return .success("Ollama reachable. Specify a model to detect with.")
            }

            guard
                let envelope = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let models = envelope["models"] as? [[String: Any]]
            else {
                return .success("Ollama reachable (model list could not be parsed)")
            }
            let names = models.compactMap { $0["name"] as? String }
            let matches = names.contains { $0 == model || $0.hasPrefix("\(model):") }
            if matches {
                return .success("Ollama reachable. Model \(model) is loaded.")
            } else {
                return .failure("Endpoint reachable, but model \(model) is not pulled. Run `ollama pull \(model)`.")
            }
        } catch {
            return .failure("Could not reach \(endpoint)")
        }
    }
}

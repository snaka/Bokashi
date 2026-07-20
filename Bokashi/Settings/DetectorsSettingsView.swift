import FoundationModels
import SwiftUI

struct DetectorsSettingsView: View {
    @State private var settings = DetectionSettings.shared
    @State private var dev = DeveloperSettings.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("All detection runs entirely on this Mac. Nothing ever leaves your machine.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 6) {
                Toggle("Use Apple Intelligence detection", isOn: $settings.aiDetectionEnabled)
                availabilityLabel
                Text("Finds sensitive text the pattern-based detectors miss: usernames and handles, API keys and other secrets, credit card numbers, and names in context.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider().padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 6) {
                Toggle("Mask faces and avatars", isOn: $settings.faceMaskingEnabled)
                Text("Masks any detected face, including profile pictures. Individual masks can be removed with the eraser.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider().padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 4) {
                Text("Developer").font(.caption).foregroundStyle(.secondary)
                Toggle("Highlight mask source in editor", isOn: $dev.highlightMaskSource)
                Text("Outlines auto-detected mosaics with a colored dashed border in the editor: blue = OCR / regex / NLTagger, orange = Apple Intelligence, green = faces.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding()
    }

    @ViewBuilder
    private var availabilityLabel: some View {
        switch SystemLanguageModel.default.availability {
        case .available:
            Label("Apple Intelligence is ready", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
        case .unavailable(.appleIntelligenceNotEnabled):
            Label(
                "Turn on Apple Intelligence in System Settings to use this",
                systemImage: "exclamationmark.triangle.fill"
            )
            .font(.caption)
            .foregroundStyle(.orange)
        case .unavailable(.modelNotReady):
            Label(
                "The on-device model is still getting ready — try again later",
                systemImage: "arrow.down.circle"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        case .unavailable(.deviceNotEligible):
            Label(
                "Apple Intelligence is not supported on this Mac",
                systemImage: "xmark.circle"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        case .unavailable:
            Label("Apple Intelligence is unavailable", systemImage: "xmark.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

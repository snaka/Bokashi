// Bokashi/Detection/AppleIntelligenceSensitiveRegionDetector.swift
import BokashiCore
import CoreGraphics
import Foundation
import FoundationModels

@Generable
private struct AIFinding {
    @Guide(description: "Index of the line containing the sensitive text")
    var lineIndex: Int
    @Guide(description: "The exact sensitive substring copied verbatim from the line, nothing more")
    var text: String
    @Guide(
        description: "Category of the sensitive item",
        .anyOf([
            "personalName", "username", "email", "phoneNumber",
            "address", "apiKey", "creditCard",
        ])
    )
    var category: String
}

@Generable
private struct AIFindings {
    var findings: [AIFinding]
}

@MainActor
struct AppleIntelligenceSensitiveRegionDetector: SensitiveRegionDetector {
    nonisolated let identifier = "appleIntelligence"

    let observations: [OCRRunner.TextObservation]

    /// Stays well under the 4,096-token shared context window even for
    /// all-Japanese text (~1 token per character).
    private static let characterBudget = 1500

    private static let instructions = """
        You review OCR text lines extracted from a screenshot and identify \
        sensitive personal information that should be masked before the \
        screenshot is shared: personal names, usernames and account handles, \
        email addresses, phone numbers, physical addresses, API keys, access \
        tokens and other secrets, and credit card numbers. Report each \
        sensitive item with the index of the line it appears on and the exact \
        substring copied verbatim from that line, only the sensitive part, \
        not the surrounding text. Ignore generic UI text, dates, prices, and \
        button labels. If nothing is sensitive, return an empty findings array.
        """

    static var isModelAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability {
            return true
        }
        return false
    }

    /// Pages the on-device model in ahead of the first Detect click.
    static func prewarmIfNeeded() {
        guard DetectionSettings.shared.aiDetectionEnabled, isModelAvailable else { return }
        LanguageModelSession(instructions: instructions).prewarm()
    }

    func detect(in image: CGImage) async throws -> [DetectedRegion] {
        guard Self.isModelAvailable, !observations.isEmpty else { return [] }

        let lines = observations.map(\.text)
        var regions: [DetectedRegion] = []

        for batch in LineBatcher.batches(from: lines, characterBudget: Self.characterBudget) {
            let numbered = batch
                .map { "\($0.index): \($0.text)" }
                .joined(separator: "\n")

            // A fresh session per batch keeps the transcript from
            // accumulating toward the context window; failures (safety
            // guardrails, overflow) cost only this batch.
            let session = LanguageModelSession(instructions: Self.instructions)
            let findings: [AIFinding]
            do {
                let response = try await session.respond(
                    to: "Lines:\n\(numbered)",
                    generating: AIFindings.self
                )
                findings = response.content.findings
            } catch {
                continue
            }

            for finding in findings {
                guard
                    let located = FindingLocator.locate(
                        text: finding.text,
                        hintIndex: finding.lineIndex,
                        in: lines
                    ),
                    let rect = observations[located.lineIndex]
                        .imageRect(forSubrange: located.nsRange)
                else { continue }
                regions.append(
                    DetectedRegion(
                        rect: rect.insetBy(dx: -2, dy: -2),
                        label: finding.category
                    )
                )
            }
        }
        return regions
    }
}

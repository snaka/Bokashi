import CoreGraphics
import Foundation
import Vision

enum OCRRunner {
    struct TextObservation {
        let text: String
        let recognizedText: VNRecognizedText
        let imageSize: CGSize

        func imageRect(forSubrange nsRange: NSRange) -> CGRect? {
            guard let stringRange = Range(nsRange, in: text) else { return nil }
            guard let observation = try? recognizedText.boundingBox(for: stringRange) else {
                return nil
            }
            return Self.imagePixelRect(fromNormalized: observation.boundingBox, imageSize: imageSize)
        }

        private static func imagePixelRect(fromNormalized normalized: CGRect, imageSize: CGSize) -> CGRect {
            // Vision returns normalized (0–1) coordinates with a bottom-left origin.
            // Annotations are stored in image-pixel coordinates with a top-left origin.
            let x = normalized.origin.x * imageSize.width
            let yBottomLeft = normalized.origin.y * imageSize.height
            let width = normalized.width * imageSize.width
            let height = normalized.height * imageSize.height
            let yTopLeft = imageSize.height - yBottomLeft - height
            return CGRect(x: x, y: yTopLeft, width: width, height: height)
        }
    }

    static func recognize(_ image: CGImage) async throws -> [TextObservation] {
        let imageSize = CGSize(width: image.width, height: image.height)
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let results = (request.results as? [VNRecognizedTextObservation]) ?? []
                let observations = results.compactMap { observation -> TextObservation? in
                    guard let candidate = observation.topCandidates(1).first else { return nil }
                    return TextObservation(
                        text: candidate.string,
                        recognizedText: candidate,
                        imageSize: imageSize
                    )
                }
                continuation.resume(returning: observations)
            }
            request.recognitionLanguages = ["ja-JP", "en-US"]
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

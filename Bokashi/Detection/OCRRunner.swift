import CoreGraphics
import Foundation
import Vision

enum OCRRunner {
    struct TextObservation {
        let text: String
        let recognizedText: VNRecognizedText
        let imageSize: CGSize
        let fullImageRect: CGRect

        init(text: String, recognizedText: VNRecognizedText, imageSize: CGSize) {
            self.text = text
            self.recognizedText = recognizedText
            self.imageSize = imageSize
            let nsRange = NSRange(location: 0, length: (text as NSString).length)
            self.fullImageRect = Self.imageRect(
                in: recognizedText,
                forNSRange: nsRange,
                rangeBaseString: text,
                imageSize: imageSize
            ) ?? .zero
        }

        func imageRect(forSubrange nsRange: NSRange) -> CGRect? {
            Self.imageRect(
                in: recognizedText,
                forNSRange: nsRange,
                rangeBaseString: text,
                imageSize: imageSize
            )
        }

        private static func imageRect(
            in recognizedText: VNRecognizedText,
            forNSRange nsRange: NSRange,
            rangeBaseString text: String,
            imageSize: CGSize
        ) -> CGRect? {
            guard let stringRange = Range(nsRange, in: text) else { return nil }
            do {
                guard let observation = try recognizedText.boundingBox(for: stringRange) else {
                    return nil
                }
                return imagePixelRect(
                    fromNormalized: observation.boundingBox,
                    imageSize: imageSize
                )
            } catch {
                return nil
            }
        }

        private static func imagePixelRect(
            fromNormalized normalized: CGRect,
            imageSize: CGSize
        ) -> CGRect {
            // Vision uses normalized 0–1 coords with bottom-left origin.
            // Annotations live in image-pixel coords with top-left origin.
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

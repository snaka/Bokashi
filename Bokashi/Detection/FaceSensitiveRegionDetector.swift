import BokashiCore
import CoreGraphics
import Vision

@MainActor
struct FaceSensitiveRegionDetector: SensitiveRegionDetector {
    nonisolated let identifier = "face"

    /// Face rects hug the face itself while avatars are usually a larger
    /// circle, so each side is padded by this fraction of the rect's size.
    private static let padding: CGFloat = 0.1

    func detect(in image: CGImage) async throws -> [DetectedRegion] {
        let imageSize = CGSize(width: image.width, height: image.height)
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectFaceRectanglesRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let results = (request.results as? [VNFaceObservation]) ?? []
                let bounds = CGRect(origin: .zero, size: imageSize)
                let regions = results.compactMap { observation -> DetectedRegion? in
                    let normalized = observation.boundingBox
                    let width = normalized.width * imageSize.width
                    let height = normalized.height * imageSize.height
                    let x = normalized.origin.x * imageSize.width
                    let yTopLeft = imageSize.height
                        - normalized.origin.y * imageSize.height
                        - height
                    let padded = CGRect(x: x, y: yTopLeft, width: width, height: height)
                        .insetBy(dx: -width * Self.padding, dy: -height * Self.padding)
                        .intersection(bounds)
                    guard !padded.isNull, padded.width >= 4, padded.height >= 4 else {
                        return nil
                    }
                    return DetectedRegion(rect: padded.integral, label: "face")
                }
                continuation.resume(returning: regions)
            }
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

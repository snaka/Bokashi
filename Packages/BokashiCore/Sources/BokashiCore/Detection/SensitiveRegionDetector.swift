import CoreGraphics

public struct DetectedRegion: Hashable, Sendable {
    public let rect: CGRect
    public let label: String
    public let confidence: Double?

    public init(rect: CGRect, label: String, confidence: Double? = nil) {
        self.rect = rect
        self.label = label
        self.confidence = confidence
    }
}

/// A pluggable detector that returns rectangles in image-pixel coordinates
/// that should be masked. Implementations may use OCR + heuristics, Vision
/// requests, the on-device Foundation Models LLM, bundled CoreML models, or
/// anything else; the orchestrator merges their output and feeds it into
/// the annotation pipeline.
public protocol SensitiveRegionDetector {
    /// Stable identifier for diagnostics and per-detector toggles.
    var identifier: String { get }

    /// Returns regions to mask for the given image. Implementations should
    /// fail silently with an empty array rather than throw for non-fatal
    /// issues; throw only when the failure should abort the whole pipeline.
    func detect(in image: CGImage) async throws -> [DetectedRegion]
}

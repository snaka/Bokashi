import CoreGraphics

/// Drops regions that duplicate an earlier region — either near-identical
/// (IoU at or above the threshold) or fully contained. Order encodes
/// priority: callers list deterministic detectors before AI ones so the
/// precise, reproducible rect survives a conflict.
public enum RegionDeduplicator {
    public static func keptIndices(
        of regions: [DetectedRegion],
        iouThreshold: Double = 0.6
    ) -> [Int] {
        var kept: [Int] = []
        outer: for (index, region) in regions.enumerated() {
            let rect = region.rect
            guard !rect.isNull, rect.width > 0, rect.height > 0 else { continue }
            for keptIndex in kept {
                let keptRect = regions[keptIndex].rect
                if keptRect.contains(rect) { continue outer }
                if iou(keptRect, rect) >= iouThreshold { continue outer }
            }
            kept.append(index)
        }
        return kept
    }

    private static func iou(_ a: CGRect, _ b: CGRect) -> Double {
        let intersection = a.intersection(b)
        guard !intersection.isNull, intersection.width > 0, intersection.height > 0 else {
            return 0
        }
        let intersectionArea = Double(intersection.width * intersection.height)
        let unionArea = Double(a.width * a.height) + Double(b.width * b.height) - intersectionArea
        guard unionArea > 0 else { return 0 }
        return intersectionArea / unionArea
    }
}

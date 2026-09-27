import CoreGraphics

extension Annotation {
    /// Whether a click at `point` lands on this annotation. Filled shapes and
    /// mosaics are hit anywhere inside; outlines, lines and arrows only near
    /// their stroke, so an annotation drawn inside an outline stays
    /// reachable. `tolerance` is added to half the stroke width.
    public func isHit(by point: CGPoint, tolerance: CGFloat) -> Bool {
        let reach = style.lineWidth / 2 + tolerance
        switch kind {
        case .mosaic(let rect):
            return rect.insetBy(dx: -reach, dy: -reach).contains(point)
        case .box(let rect):
            let outer = rect.insetBy(dx: -reach, dy: -reach)
            guard outer.contains(point) else { return false }
            if style.filled { return true }
            let inner = rect.insetBy(dx: reach, dy: reach)
            return inner.isEmpty || !inner.contains(point)
        case .ellipse(let rect):
            guard Self.ellipse(rect.insetBy(dx: -reach, dy: -reach), contains: point) else {
                return false
            }
            if style.filled { return true }
            return !Self.ellipse(rect.insetBy(dx: reach, dy: reach), contains: point)
        case .line(let start, let end), .arrow(let start, let end):
            return Self.distance(from: point, toSegment: start, end) <= reach
        }
    }

    private static func ellipse(_ rect: CGRect, contains point: CGPoint) -> Bool {
        guard !rect.isEmpty, rect.width > 0, rect.height > 0 else { return false }
        let dx = (point.x - rect.midX) / (rect.width / 2)
        let dy = (point.y - rect.midY) / (rect.height / 2)
        return dx * dx + dy * dy <= 1
    }

    private static func distance(from p: CGPoint, toSegment a: CGPoint, _ b: CGPoint) -> CGFloat {
        let abx = b.x - a.x
        let aby = b.y - a.y
        let lengthSquared = abx * abx + aby * aby
        var t: CGFloat = 0
        if lengthSquared > 0 {
            t = max(0, min(1, ((p.x - a.x) * abx + (p.y - a.y) * aby) / lengthSquared))
        }
        let dx = p.x - (a.x + t * abx)
        let dy = p.y - (a.y + t * aby)
        return (dx * dx + dy * dy).squareRoot()
    }
}

import CoreGraphics

public enum WindowFrameConverter {
    /// Convert a window frame in CG window coordinates (origin = primary
    /// display's top-left, y-down — what `SCWindow.frame` reports) into
    /// global NSScreen coordinates (origin = primary display's bottom-left,
    /// y-up).
    public static func nsRect(
        fromCG cgRect: CGRect,
        primaryScreenHeight: CGFloat
    ) -> CGRect {
        CGRect(
            x: cgRect.origin.x,
            y: primaryScreenHeight - cgRect.origin.y - cgRect.height,
            width: cgRect.width,
            height: cgRect.height
        )
    }
}

import CoreGraphics

public enum ScreenRectConverter {
    /// Convert a rect in global screen coordinates (NSScreen frame coords —
    /// origin at the *primary* display's bottom-left, y-up) into pixel
    /// coordinates local to a specific display (origin at that display's
    /// top-left, y-down) suitable for `CGImage.cropping(to:)`.
    public static func pixelRectInDisplay(
        screenRect: CGRect,
        displayFrame: CGRect,
        backingScaleFactor: CGFloat
    ) -> CGRect {
        let localX = screenRect.origin.x - displayFrame.origin.x
        let localBottomY = screenRect.origin.y - displayFrame.origin.y
        let localTopY = displayFrame.height - localBottomY - screenRect.height
        return CGRect(
            x: localX * backingScaleFactor,
            y: localTopY * backingScaleFactor,
            width: screenRect.width * backingScaleFactor,
            height: screenRect.height * backingScaleFactor
        ).integral
    }
}

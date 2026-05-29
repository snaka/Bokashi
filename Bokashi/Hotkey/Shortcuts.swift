import KeyboardShortcuts

// Digit assignment mirrors the macOS screenshot conventions
// (⇧⌘3/4/5 = full / region / toolbar) so the combos are easy to recall.
// We use ⌃⌥⇧ as the modifier prefix to avoid clashing with the system's
// own ⇧⌘ shortcuts.
extension KeyboardShortcuts.Name {
    static let captureFullScreen = Self(
        "captureFullScreen",
        default: .init(.three, modifiers: [.control, .option, .shift])
    )

    static let captureRegion = Self(
        "captureRegion",
        default: .init(.four, modifiers: [.control, .option, .shift])
    )

    static let captureWindow = Self(
        "captureWindow",
        default: .init(.five, modifiers: [.control, .option, .shift])
    )
}

import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let captureFullScreen = Self(
        "captureFullScreen",
        default: .init(.four, modifiers: [.control, .option, .shift])
    )

    static let captureRegion = Self(
        "captureRegion",
        default: .init(.six, modifiers: [.control, .option, .shift])
    )

    static let captureWindow = Self(
        "captureWindow",
        default: .init(.five, modifiers: [.control, .option, .shift])
    )
}

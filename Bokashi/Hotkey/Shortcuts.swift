import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let captureFullScreen = Self(
        "captureFullScreen",
        default: .init(.four, modifiers: [.control, .option, .shift])
    )
}

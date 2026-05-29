import AppKit
import KeyboardShortcuts
import SwiftUI

// Bridges the KeyboardShortcuts library's `Shortcut` value into SwiftUI's
// `KeyEquivalent` + `EventModifiers` so menu items can display the same
// combo the global hotkey fires on. We only use these for the menu bar
// hint — the actual capture is triggered by the Carbon global hotkey
// registered in `AppDelegate.registerHotkeys`, which consumes the event
// before SwiftUI sees it, so this never double-fires.
extension KeyboardShortcuts.Shortcut {
    @MainActor
    var swiftUIKeyEquivalent: KeyEquivalent? {
        guard
            let string = nsMenuItemKeyEquivalent,
            let character = string.first
        else { return nil }
        return KeyEquivalent(character)
    }

    var swiftUIModifiers: EventModifiers {
        var result: EventModifiers = []
        if modifiers.contains(.command) { result.insert(.command) }
        if modifiers.contains(.option) { result.insert(.option) }
        if modifiers.contains(.control) { result.insert(.control) }
        if modifiers.contains(.shift) { result.insert(.shift) }
        return result
    }
}

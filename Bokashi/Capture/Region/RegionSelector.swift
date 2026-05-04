import AppKit

@MainActor
final class RegionSelector {
    private var window: RegionOverlayWindow?
    private var continuation: CheckedContinuation<CGRect?, Never>?

    func selectRegion() async -> CGRect? {
        if continuation != nil {
            return nil
        }

        guard let screen = NSScreen.main else { return nil }

        return await withCheckedContinuation { continuation in
            self.continuation = continuation

            let win = RegionOverlayWindow(screenFrame: screen.frame) { [weak self] rect in
                self?.finish(with: rect)
            }
            self.window = win
            NSApp.activate(ignoringOtherApps: true)
            win.makeKeyAndOrderFront(nil)
        }
    }

    private func finish(with rect: CGRect?) {
        window?.orderOut(nil)
        window = nil
        let cont = continuation
        continuation = nil
        cont?.resume(returning: rect)
    }
}

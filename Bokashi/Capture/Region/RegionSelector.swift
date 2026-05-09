import AppKit

@MainActor
final class RegionSelector {
    private var windows: [RegionOverlayWindow] = []
    private var continuation: CheckedContinuation<CGRect?, Never>?

    func selectRegion() async -> CGRect? {
        if continuation != nil {
            return nil
        }

        let screens = NSScreen.screens
        guard !screens.isEmpty else { return nil }

        return await withCheckedContinuation { continuation in
            self.continuation = continuation

            for screen in screens {
                let win = RegionOverlayWindow(screenFrame: screen.frame) { [weak self] rect in
                    self?.finish(with: rect)
                }
                windows.append(win)
            }
            NSApp.activate(ignoringOtherApps: true)
            for win in windows {
                win.makeKeyAndOrderFront(nil)
            }
        }
    }

    private func finish(with rect: CGRect?) {
        for win in windows {
            win.orderOut(nil)
        }
        windows.removeAll()
        let cont = continuation
        continuation = nil
        cont?.resume(returning: rect)
    }
}

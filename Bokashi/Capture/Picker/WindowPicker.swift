import AppKit
import BokashiCore
import ScreenCaptureKit

@MainActor
final class WindowPicker {
    private struct Candidate {
        let scWindow: SCWindow
        let nsRect: CGRect
        let thumbnail: CGImage?
    }

    private var overlayWindows: [WindowPickerOverlayWindow] = []
    private var overlayViews: [WindowPickerOverlayView] = []
    private var candidates: [Candidate] = []
    private var continuation: CheckedContinuation<SCWindow?, Never>?

    func pickWindow() async -> SCWindow? {
        if continuation != nil { return nil }

        let screens = NSScreen.screens
        guard !screens.isEmpty else { return nil }

        let scWindows: [SCWindow]
        do {
            scWindows = try await loadCandidates()
        } catch {
            return nil
        }

        let primaryHeight = screens.first?.frame.height ?? 0
        candidates = await captureThumbnails(for: scWindows, primaryScreenHeight: primaryHeight)

        return await withCheckedContinuation { continuation in
            self.continuation = continuation

            for screen in screens {
                let win = WindowPickerOverlayWindow(screenFrame: screen.frame)
                guard let view = win.contentView as? WindowPickerOverlayView else { continue }
                view.onMouseMoved = { [weak self] in self?.handleMouseMoved() }
                view.onClick = { [weak self] in self?.handleClick() }
                view.onCancel = { [weak self] in self?.finish(with: nil) }
                overlayWindows.append(win)
                overlayViews.append(view)
            }

            NSApp.activate(ignoringOtherApps: true)
            for win in overlayWindows {
                win.makeKeyAndOrderFront(nil)
            }
        }
    }

    private func handleMouseMoved() {
        let cursor = NSEvent.mouseLocation
        let hovered = candidates.first(where: { $0.nsRect.contains(cursor) })
        for view in overlayViews {
            view.hoveredFrame = hovered?.nsRect
            view.hoveredImage = hovered?.thumbnail
        }
    }

    private func handleClick() {
        let cursor = NSEvent.mouseLocation
        let picked = candidates.first(where: { $0.nsRect.contains(cursor) })
        finish(with: picked?.scWindow)
    }

    private func finish(with window: SCWindow?) {
        for win in overlayWindows {
            win.orderOut(nil)
        }
        overlayWindows.removeAll()
        overlayViews.removeAll()
        candidates.removeAll()
        let cont = continuation
        continuation = nil
        cont?.resume(returning: window)
    }

    private func loadCandidates() async throws -> [SCWindow] {
        let content = try await SCShareableContent.current
        let myBundleID = Bundle.main.bundleIdentifier
        let windows = content.windows.filter { sc in
            sc.isOnScreen
                && sc.windowLayer == 0
                && (sc.title?.isEmpty == false)
                && sc.owningApplication?.bundleIdentifier != myBundleID
        }
        return orderedFrontToBack(windows)
    }

    /// Orders windows front-to-back by their on-screen z-order.
    ///
    /// `SCShareableContent.current.windows` does not guarantee z-order, so the
    /// cursor hit-test in `handleMouseMoved`/`handleClick` could resolve to a
    /// window occluded at the cursor point instead of the one actually visible
    /// there. Sorting by the on-screen window list (front-to-back) makes
    /// `first(where:)` pick the front-most window under the cursor.
    private func orderedFrontToBack(_ windows: [SCWindow]) -> [SCWindow] {
        let info = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] ?? []
        var zIndex: [CGWindowID: Int] = [:]
        for (index, entry) in info.enumerated() {
            if let number = (entry[kCGWindowNumber as String] as? NSNumber)?.uint32Value {
                zIndex[number] = index
            }
        }
        return windows.sorted { lhs, rhs in
            (zIndex[lhs.windowID] ?? .max) < (zIndex[rhs.windowID] ?? .max)
        }
    }

    private func captureThumbnails(
        for scWindows: [SCWindow],
        primaryScreenHeight: CGFloat
    ) async -> [Candidate] {
        await withTaskGroup(of: (Int, CGImage?).self) { group in
            for (index, sc) in scWindows.enumerated() {
                group.addTask {
                    let image = try? await Self.captureThumbnail(for: sc)
                    return (index, image)
                }
            }
            var images = Array<CGImage?>(repeating: nil, count: scWindows.count)
            for await (index, image) in group {
                images[index] = image
            }
            return scWindows.enumerated().map { index, sc in
                Candidate(
                    scWindow: sc,
                    nsRect: WindowFrameConverter.nsRect(
                        fromCG: sc.frame,
                        primaryScreenHeight: primaryScreenHeight
                    ),
                    thumbnail: images[index]
                )
            }
        }
    }

    private static func captureThumbnail(for window: SCWindow) async throws -> CGImage {
        let filter = SCContentFilter(desktopIndependentWindow: window)
        let configuration = SCStreamConfiguration()
        let pixelScale = Double(filter.pointPixelScale)
        configuration.width = max(1, Int(filter.contentRect.width * pixelScale))
        configuration.height = max(1, Int(filter.contentRect.height * pixelScale))
        configuration.showsCursor = false
        configuration.ignoreShadowsSingleWindow = true
        return try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: configuration
        )
    }
}

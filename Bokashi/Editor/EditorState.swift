import AppKit
import BokashiCore
import CoreGraphics
import Foundation

@MainActor
@Observable
final class EditorState {
    var tool: Tool = .arrow
    var color: RGBA = .bokashiRed
    var lineWidth: CGFloat = AnnotationStyle.WidthPreset.medium.lineWidth
    var annotations: [Annotation] = []
    var draft: Annotation?
    var isDetecting: Bool = false
    var isOCRReady: Bool = false

    @ObservationIgnored
    var undoManager: UndoManager?

    @ObservationIgnored
    private var ocrObservations: [OCRRunner.TextObservation] = []

    @ObservationIgnored
    private var ocrTask: Task<Void, Never>?

    func runOCR(on image: CGImage) async {
        if isOCRReady { return }
        if let existing = ocrTask {
            await existing.value
            return
        }
        let task = Task { @MainActor in
            do {
                self.ocrObservations = try await OCRRunner.recognize(image)
            } catch {
                self.ocrObservations = []
            }
            self.isOCRReady = true
        }
        ocrTask = task
        await task.value
    }

    func detectSensitiveInfo(in image: CGImage) async {
        guard !isDetecting else { return }
        isDetecting = true
        defer { isDetecting = false }

        await runOCR(on: image)

        let detected = AutoMasker.detect(in: ocrObservations)
        guard !detected.isEmpty else { return }

        undoManager?.beginUndoGrouping()
        for annotation in detected {
            addAnnotation(annotation)
        }
        undoManager?.setActionName("Auto-Mask Sensitive Info")
        undoManager?.endUndoGrouping()
    }

    var currentStyle: AnnotationStyle {
        AnnotationStyle(color: color, lineWidth: lineWidth, filled: tool.isFilled)
    }

    func updateDraft(start: CGPoint, current: CGPoint) {
        draft = tool.makeAnnotation(from: start, to: current, style: currentStyle)
    }

    func commitDraft() {
        defer { draft = nil }
        guard let candidate = draft else { return }

        // Mosaic tool: a click (zero-distance drag) on detected text masks
        // that whole text region. Otherwise fall back to the meaningful-drag
        // rule used by every tool.
        if tool == .mosaic, !isMeaningful(candidate),
           case .mosaic(let rect) = candidate.kind,
           let textRect = textRect(at: CGPoint(x: rect.midX, y: rect.midY))
        {
            let textAnnotation = Annotation(
                kind: .mosaic(rect: textRect.insetBy(dx: -2, dy: -2)),
                style: candidate.style
            )
            addAnnotation(textAnnotation)
            return
        }

        guard isMeaningful(candidate) else { return }
        addAnnotation(candidate)
    }

    private func textRect(at imagePoint: CGPoint) -> CGRect? {
        for obs in ocrObservations where obs.fullImageRect.contains(imagePoint) {
            return obs.fullImageRect
        }
        return nil
    }

    private func addAnnotation(_ annotation: Annotation) {
        annotations.append(annotation)
        let id = annotation.id
        undoManager?.registerUndo(withTarget: self) { state in
            state.removeAnnotation(id: id)
        }
        undoManager?.setActionName("Add Annotation")
    }

    private func removeAnnotation(id: UUID) {
        guard let index = annotations.firstIndex(where: { $0.id == id }) else { return }
        let removed = annotations.remove(at: index)
        undoManager?.registerUndo(withTarget: self) { state in
            state.insertAnnotation(removed, at: index)
        }
        undoManager?.setActionName("Remove Annotation")
    }

    private func insertAnnotation(_ annotation: Annotation, at index: Int) {
        let safeIndex = min(index, annotations.count)
        annotations.insert(annotation, at: safeIndex)
        let id = annotation.id
        undoManager?.registerUndo(withTarget: self) { state in
            state.removeAnnotation(id: id)
        }
        undoManager?.setActionName("Add Annotation")
    }

    private func isMeaningful(_ annotation: Annotation) -> Bool {
        switch annotation.kind {
        case .line(let s, let e), .arrow(let s, let e):
            let dx = e.x - s.x
            let dy = e.y - s.y
            return (dx * dx + dy * dy).squareRoot() >= 4
        case .box(let r), .ellipse(let r), .mosaic(let r):
            return r.width >= 4 && r.height >= 4
        }
    }
}

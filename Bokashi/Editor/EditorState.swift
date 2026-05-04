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

    @ObservationIgnored
    var undoManager: UndoManager?

    var currentStyle: AnnotationStyle {
        AnnotationStyle(color: color, lineWidth: lineWidth, filled: tool.isFilled)
    }

    func updateDraft(start: CGPoint, current: CGPoint) {
        draft = tool.makeAnnotation(from: start, to: current, style: currentStyle)
    }

    func commitDraft() {
        defer { draft = nil }
        guard let candidate = draft, isMeaningful(candidate) else { return }
        addAnnotation(candidate)
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
        case .box(let r), .ellipse(let r):
            return r.width >= 4 && r.height >= 4
        }
    }
}

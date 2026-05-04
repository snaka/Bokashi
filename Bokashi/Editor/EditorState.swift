import BokashiCore
import CoreGraphics
import Foundation

@MainActor
@Observable
final class EditorState {
    var tool: Tool = .arrow
    var annotations: [Annotation] = []
    var draft: Annotation?

    func updateDraft(start: CGPoint, current: CGPoint) {
        draft = tool.makeAnnotation(from: start, to: current)
    }

    func commitDraft() {
        defer { draft = nil }
        guard let candidate = draft, isMeaningful(candidate) else { return }
        annotations.append(candidate)
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

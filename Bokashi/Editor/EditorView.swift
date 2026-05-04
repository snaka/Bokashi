import SwiftUI

struct EditorView: View {
    let image: CGImage
    let state: EditorState
    let onDone: () -> Void
    let onSave: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            AnnotationCanvas(image: image, state: state)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            Button(role: .destructive, action: onDiscard) {
                Label("Discard", systemImage: "trash")
            }
            .keyboardShortcut(.cancelAction)

            Divider().frame(height: 22)

            HStack(spacing: 4) {
                ForEach(Tool.allCases, id: \.self) { tool in
                    toolButton(tool)
                }
            }

            Spacer()

            Button(action: onSave) {
                Label("Save…", systemImage: "square.and.arrow.down")
            }
            .keyboardShortcut("s", modifiers: .command)

            Button(action: onDone) {
                Label("Copy & Close", systemImage: "doc.on.clipboard")
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private func toolButton(_ tool: Tool) -> some View {
        let isSelected = state.tool == tool
        return Button {
            state.tool = tool
        } label: {
            Image(systemName: tool.systemImage)
                .frame(width: 28, height: 24)
                .background(
                    isSelected ? Color.accentColor.opacity(0.25) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 5)
                )
        }
        .buttonStyle(.borderless)
        .help(tool.label)
    }
}

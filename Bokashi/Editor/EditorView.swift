import BokashiCore
import SwiftUI

struct EditorView: View {
    let image: CGImage
    let mosaicImage: CGImage?
    let state: EditorState
    let onDone: () -> Void
    let onSave: () -> Void
    let onDiscard: () -> Void

    @Environment(\.undoManager) private var undoManager

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            AnnotationCanvas(image: image, mosaicImage: mosaicImage, state: state)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .background(undoShortcuts)
        .onAppear { state.undoManager = undoManager }
        .onChange(of: undoManager) { _, newValue in
            state.undoManager = newValue
        }
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            Button(role: .destructive, action: onDiscard) {
                Label("Discard", systemImage: "trash")
            }
            .keyboardShortcut(.cancelAction)

            Divider().frame(height: 22)

            HStack(spacing: 4) {
                ForEach(Tool.allCases, id: \.self) { toolButton($0) }
            }

            Divider().frame(height: 22)

            HStack(spacing: 4) {
                ForEach(RGBA.presets, id: \.self) { colorChip($0) }
            }

            Divider().frame(height: 22)

            HStack(spacing: 4) {
                ForEach(AnnotationStyle.WidthPreset.allCases, id: \.self) { widthButton($0) }
            }

            Spacer()

            detectButton

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

    private func colorChip(_ rgba: RGBA) -> some View {
        let isSelected = state.color == rgba
        return Button {
            state.color = rgba
        } label: {
            Circle()
                .fill(Color(rgba))
                .frame(width: 18, height: 18)
                .overlay(
                    Circle()
                        .stroke(Color.secondary.opacity(0.4), lineWidth: 0.5)
                )
                .padding(3)
                .background(
                    isSelected ? Color.accentColor.opacity(0.25) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 5)
                )
        }
        .buttonStyle(.borderless)
        .help("Color")
    }

    private func widthButton(_ preset: AnnotationStyle.WidthPreset) -> some View {
        let isSelected = abs(state.lineWidth - preset.lineWidth) < 0.01
        return Button {
            state.lineWidth = preset.lineWidth
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(isSelected ? Color.accentColor.opacity(0.25) : Color.clear)
                    .frame(width: 32, height: 24)
                Capsule()
                    .fill(Color.primary)
                    .frame(width: 18, height: max(2, preset.lineWidth))
            }
        }
        .buttonStyle(.borderless)
        .help(preset.label)
    }

    private var detectButton: some View {
        let isWorking = state.isDetecting || !state.isOCRReady
        return Button {
            Task { @MainActor in
                await state.detectSensitiveInfo(in: image)
            }
        } label: {
            Group {
                if isWorking {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Label("Detect", systemImage: "wand.and.rays")
                }
            }
            .frame(minWidth: 64)
        }
        .disabled(state.isDetecting)
        .help(state.isOCRReady
              ? "Detect and mask sensitive information"
              : "Scanning text in capture…")
    }

    private var undoShortcuts: some View {
        HStack {
            Button("Undo") { undoManager?.undo() }
                .keyboardShortcut("z", modifiers: .command)
                .disabled(!(undoManager?.canUndo ?? false))
            Button("Redo") { undoManager?.redo() }
                .keyboardShortcut("z", modifiers: [.command, .shift])
                .disabled(!(undoManager?.canRedo ?? false))
        }
        .opacity(0)
        .accessibilityHidden(true)
        .frame(width: 0, height: 0)
    }
}

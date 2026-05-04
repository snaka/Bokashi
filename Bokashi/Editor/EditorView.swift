import SwiftUI

struct EditorView: View {
    let image: CGImage
    let onDone: () -> Void
    let onSave: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            imageArea
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            Button(role: .destructive, action: onDiscard) {
                Label("Discard", systemImage: "trash")
            }
            .keyboardShortcut(.cancelAction)

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

    private var imageArea: some View {
        Image(image, scale: 1, label: Text("Captured screenshot"))
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.7))
    }
}

import SwiftUI

struct CustomTermsSettingsView: View {
    var onAddFromSelection: () -> Void

    @State private var manager = CustomTermsManager.shared
    @State private var selection: Int?
    @State private var draft: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Strings listed here are masked automatically when found in a captured screenshot. Matching is case-insensitive and matches the substring exactly as entered.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            List(selection: $selection) {
                ForEach(Array(manager.terms.enumerated()), id: \.offset) { index, term in
                    Text(term)
                        .tag(index)
                }
            }
            .frame(minHeight: 180)
            .border(Color.secondary.opacity(0.25))

            HStack(spacing: 8) {
                TextField("Add term…", text: $draft)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(commitDraft)
                Button("Add", action: commitDraft)
                    .disabled(trimmedDraft.isEmpty)
                Spacer()
                Button("Remove", action: removeSelected)
                    .disabled(selection == nil)
            }

            Divider()

            HStack {
                Button {
                    onAddFromSelection()
                } label: {
                    Label("Add from Screen Selection…", systemImage: "rectangle.dashed.badge.record")
                }
                Spacer()
            }
        }
        .padding()
    }

    private var trimmedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func commitDraft() {
        let value = trimmedDraft
        guard !value.isEmpty else { return }
        manager.add(value)
        draft = ""
    }

    private func removeSelected() {
        guard let index = selection else { return }
        manager.remove(at: IndexSet(integer: index))
        selection = nil
    }
}

import SwiftUI

@MainActor
@Observable
final class CustomTermsExtractionModel {
    struct Candidate: Identifiable {
        let id = UUID()
        var text: String
        var isEnabled: Bool
    }

    var candidates: [Candidate]

    init(candidates: [String]) {
        self.candidates = candidates.map { Candidate(text: $0, isEnabled: true) }
    }

    var selectedTrimmedTerms: [String] {
        candidates
            .filter { $0.isEnabled }
            .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

struct CustomTermsExtractionView: View {
    @State var model: CustomTermsExtractionModel
    var onAdd: ([String]) -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detected text from your selection. Uncheck any you don't want, edit to refine, then add the rest as custom mask terms.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            List {
                ForEach($model.candidates) { $candidate in
                    HStack(spacing: 8) {
                        Toggle("", isOn: $candidate.isEnabled)
                            .labelsHidden()
                        TextField("", text: $candidate.text)
                            .textFieldStyle(.plain)
                            .disabled(!candidate.isEnabled)
                    }
                }
            }
            .frame(minHeight: 220)
            .border(Color.secondary.opacity(0.25))

            HStack {
                Spacer()
                Button("Cancel", role: .cancel, action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button("Add \(model.selectedTrimmedTerms.count) term\(model.selectedTrimmedTerms.count == 1 ? "" : "s")") {
                    onAdd(model.selectedTrimmedTerms)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(model.selectedTrimmedTerms.isEmpty)
            }
        }
        .padding()
        .frame(minWidth: 420, minHeight: 320)
    }
}

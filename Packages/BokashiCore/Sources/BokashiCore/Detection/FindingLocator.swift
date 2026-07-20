import Foundation

/// Resolves a substring reported by the on-device language model back to a
/// verbatim UTF-16 range in the source OCR lines. The model's line index is
/// only a hint — small models are occasionally off by one — so the hinted
/// line and its neighbors are tried first, then every line in order. Matching
/// is case-insensitive because the model sometimes normalizes case.
public enum FindingLocator {
    public struct Located: Hashable, Sendable {
        public let lineIndex: Int
        public let nsRange: NSRange

        public init(lineIndex: Int, nsRange: NSRange) {
            self.lineIndex = lineIndex
            self.nsRange = nsRange
        }
    }

    public static func locate(
        text: String,
        hintIndex: Int?,
        in lines: [String]
    ) -> Located? {
        let needle = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty, !lines.isEmpty else { return nil }

        var order: [Int] = []
        if let hint = hintIndex {
            for candidate in [hint, hint - 1, hint + 1]
            where lines.indices.contains(candidate) && !order.contains(candidate) {
                order.append(candidate)
            }
        }
        for index in lines.indices where !order.contains(index) {
            order.append(index)
        }

        for index in order {
            let nsLine = lines[index] as NSString
            let range = nsLine.range(of: needle, options: .caseInsensitive)
            if range.location != NSNotFound {
                return Located(lineIndex: index, nsRange: range)
            }
        }
        return nil
    }
}

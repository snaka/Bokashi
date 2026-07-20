import Foundation

public struct IndexedLine: Hashable, Sendable {
    public let index: Int
    public let text: String

    public init(index: Int, text: String) {
        self.index = index
        self.text = text
    }
}

/// Splits OCR lines into batches that each fit a per-request character
/// budget. The on-device Foundation Models context window is 4,096 tokens
/// shared between input and output, and Japanese costs roughly one token
/// per character, so callers pass a budget well below that. Lines are
/// never split; a line longer than the budget gets a batch of its own.
public enum LineBatcher {
    /// Accounts for the "<index>: " prefix and newline each line costs
    /// in the numbered prompt.
    private static let perLineOverhead = 8

    public static func batches(
        from lines: [String],
        characterBudget: Int
    ) -> [[IndexedLine]] {
        var result: [[IndexedLine]] = []
        var current: [IndexedLine] = []
        var currentCost = 0
        for (index, text) in lines.enumerated() {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let cost = text.count + Self.perLineOverhead
            if !current.isEmpty, currentCost + cost > characterBudget {
                result.append(current)
                current = []
                currentCost = 0
            }
            current.append(IndexedLine(index: index, text: text))
            currentCost += cost
        }
        if !current.isEmpty {
            result.append(current)
        }
        return result
    }
}

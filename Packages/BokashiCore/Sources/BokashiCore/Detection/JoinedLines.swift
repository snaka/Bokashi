import Foundation

/// OCR lines joined with "\n" into one text, so a text-level detector sees
/// them as a document, with the ability to map a UTF-16 range in that text
/// back to the line it came from.
public struct JoinedLines: Sendable {
    public struct Located: Hashable, Sendable {
        public let lineIndex: Int
        public let range: NSRange

        public init(lineIndex: Int, range: NSRange) {
            self.lineIndex = lineIndex
            self.range = range
        }
    }

    public let text: String
    private let lineStarts: [Int]
    private let lineLengths: [Int]

    public init(_ lines: [String]) {
        text = lines.joined(separator: "\n")
        var starts: [Int] = []
        var lengths: [Int] = []
        var cursor = 0
        for line in lines {
            let length = (line as NSString).length
            starts.append(cursor)
            lengths.append(length)
            cursor += length + 1
        }
        lineStarts = starts
        lineLengths = lengths
    }

    /// A range that runs past the end of its line is cut back to that line.
    public func locate(_ range: NSRange) -> Located? {
        guard range.location != NSNotFound, range.length > 0 else { return nil }
        guard let index = lineStarts.lastIndex(where: { $0 <= range.location }) else { return nil }
        let local = range.location - lineStarts[index]
        let length = min(range.length, lineLengths[index] - local)
        guard length > 0 else { return nil }
        return Located(lineIndex: index, range: NSRange(location: local, length: length))
    }
}

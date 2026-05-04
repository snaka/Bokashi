import Foundation

public enum SensitiveKind: Hashable, Sendable {
    case email
    case phone
}

public enum SensitiveDetectors {
    public struct Match: Hashable, Sendable {
        public let kind: SensitiveKind
        public let nsRange: NSRange
        public let matchedText: String

        public init(kind: SensitiveKind, nsRange: NSRange, matchedText: String) {
            self.kind = kind
            self.nsRange = nsRange
            self.matchedText = matchedText
        }
    }

    private static let email: NSRegularExpression = {
        let pattern = #"[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}"#
        return try! NSRegularExpression(pattern: pattern)
    }()

    // Japanese-style phone numbers, e.g. 03-1234-5678 / 090-1234-5678 / 0312345678
    private static let phoneJP: NSRegularExpression = {
        let pattern = #"(?<!\d)0\d{1,4}[\-\s]?\d{1,4}[\-\s]?\d{4}(?!\d)"#
        return try! NSRegularExpression(pattern: pattern)
    }()

    public static func detectAll(in text: String) -> [Match] {
        var matches: [Match] = []
        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)

        for result in email.matches(in: text, range: fullRange) {
            let substring = nsText.substring(with: result.range)
            matches.append(Match(kind: .email, nsRange: result.range, matchedText: substring))
        }
        for result in phoneJP.matches(in: text, range: fullRange) {
            let substring = nsText.substring(with: result.range)
            matches.append(Match(kind: .phone, nsRange: result.range, matchedText: substring))
        }
        return matches
    }
}

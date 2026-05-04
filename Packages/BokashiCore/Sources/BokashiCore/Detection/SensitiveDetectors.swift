import Foundation
import NaturalLanguage

public enum SensitiveKind: Hashable, Sendable {
    case email
    case phoneNumber
    case address
    case personalName
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

    public static func detectAll(in text: String) -> [Match] {
        guard !text.isEmpty else { return [] }
        var matches: [Match] = []
        matches.append(contentsOf: detectEmails(in: text))
        matches.append(contentsOf: detectViaDataDetector(in: text))
        matches.append(contentsOf: detectPersonalNames(in: text))
        return matches
    }

    // MARK: - Emails (regex; NSDataDetector does not catch bare emails)

    private static let emailRegex: NSRegularExpression = {
        let pattern = #"[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}"#
        return try! NSRegularExpression(pattern: pattern)
    }()

    private static func detectEmails(in text: String) -> [Match] {
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        return emailRegex.matches(in: text, range: range).map { result in
            Match(
                kind: .email,
                nsRange: result.range,
                matchedText: nsText.substring(with: result.range)
            )
        }
    }

    // MARK: - Phone numbers + addresses (NSDataDetector — uses Apple's models, not regex)

    private static let dataDetector: NSDataDetector? = {
        let types: NSTextCheckingResult.CheckingType = [.phoneNumber, .address]
        return try? NSDataDetector(types: types.rawValue)
    }()

    private static func detectViaDataDetector(in text: String) -> [Match] {
        guard let detector = dataDetector else { return [] }
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        var matches: [Match] = []
        detector.enumerateMatches(in: text, options: [], range: range) { result, _, _ in
            guard let result else { return }
            let kind: SensitiveKind?
            switch result.resultType {
            case .phoneNumber: kind = .phoneNumber
            case .address: kind = .address
            default: kind = nil
            }
            guard let kind else { return }
            matches.append(
                Match(
                    kind: kind,
                    nsRange: result.range,
                    matchedText: nsText.substring(with: result.range)
                )
            )
        }
        return matches
    }

    // MARK: - Personal names (NLTagger — Apple's named-entity tagger)

    private static func detectPersonalNames(in text: String) -> [Match] {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text

        let nsText = text as NSString
        var matches: [Match] = []
        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation, .joinNames]

        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .nameType,
            options: options
        ) { tag, range in
            guard tag == .personalName else { return true }
            let nsRange = NSRange(range, in: text)
            matches.append(
                Match(
                    kind: .personalName,
                    nsRange: nsRange,
                    matchedText: nsText.substring(with: nsRange)
                )
            )
            return true
        }
        return matches
    }
}

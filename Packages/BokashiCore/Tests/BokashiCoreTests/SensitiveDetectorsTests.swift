import XCTest
@testable import BokashiCore

final class SensitiveDetectorsTests: XCTestCase {
    // MARK: - Email (regex)

    func testDetectsSimpleEmail() {
        let matches = SensitiveDetectors.detectAll(in: "Contact me at alice@example.com please")
        let emails = matches.filter { $0.kind == .email }
        XCTAssertEqual(emails.count, 1)
        XCTAssertEqual(emails.first?.matchedText, "alice@example.com")
    }

    func testDetectsMultipleEmails() {
        let text = "to: a@x.io, cc: bob.smith+spam@example.co.jp"
        let emails = SensitiveDetectors.detectAll(in: text).filter { $0.kind == .email }
        XCTAssertEqual(Set(emails.map { $0.matchedText }), [
            "a@x.io",
            "bob.smith+spam@example.co.jp",
        ])
    }

    // MARK: - Phone numbers (NSDataDetector)

    func testDetectsHyphenatedJapanesePhone() {
        let matches = SensitiveDetectors.detectAll(in: "電話番号: 03-1234-5678 まで")
        let phones = matches.filter { $0.kind == .phoneNumber }
        XCTAssertGreaterThanOrEqual(phones.count, 1)
        XCTAssertTrue(phones.contains { $0.matchedText.contains("03") })
    }

    func testDetectsMobileJapanesePhone() {
        let matches = SensitiveDetectors.detectAll(in: "Call 090-1234-5678")
        let phones = matches.filter { $0.kind == .phoneNumber }
        XCTAssertGreaterThanOrEqual(phones.count, 1)
    }

    // MARK: - No-match

    func testDetectsNoMatch() {
        let matches = SensitiveDetectors.detectAll(in: "This text has nothing sensitive.")
        XCTAssertTrue(matches.filter { $0.kind == .email || $0.kind == .phoneNumber }.isEmpty)
    }

    func testHandlesEmptyText() {
        XCTAssertTrue(SensitiveDetectors.detectAll(in: "").isEmpty)
    }

    // MARK: - Personal name (NLTagger smoke test)

    // NLTagger output is OS-version dependent; assert "we got at least one
    // personalName covering the obvious name" rather than exact ranges.
    func testDetectsEnglishPersonalNameSmoke() {
        let matches = SensitiveDetectors.detectAll(in: "Project owner: John Smith. Contact above.")
        let names = matches.filter { $0.kind == .personalName }
        XCTAssertTrue(
            names.contains { $0.matchedText.contains("John") || $0.matchedText.contains("Smith") },
            "Expected NLTagger to flag 'John' or 'Smith' as a personal name; got \(names.map { $0.matchedText })"
        )
    }
}

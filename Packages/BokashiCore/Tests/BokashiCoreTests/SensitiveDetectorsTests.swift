import XCTest
@testable import BokashiCore

final class SensitiveDetectorsTests: XCTestCase {
    func testDetectsSimpleEmail() {
        let text = "Contact me at alice@example.com please"
        let matches = SensitiveDetectors.detectAll(in: text)
        let emails = matches.filter { $0.kind == .email }
        XCTAssertEqual(emails.count, 1)
        XCTAssertEqual(emails.first?.matchedText, "alice@example.com")
    }

    func testDetectsMultipleEmails() {
        let text = "to: a@x.io, cc: bob.smith+spam@example.co.jp"
        let emails = SensitiveDetectors.detectAll(in: text).filter { $0.kind == .email }
        XCTAssertEqual(emails.count, 2)
        XCTAssertEqual(Set(emails.map { $0.matchedText }), [
            "a@x.io",
            "bob.smith+spam@example.co.jp",
        ])
    }

    func testDetectsHyphenatedJapanesePhone() {
        let text = "電話番号: 03-1234-5678 まで"
        let phones = SensitiveDetectors.detectAll(in: text).filter { $0.kind == .phone }
        XCTAssertEqual(phones.count, 1)
        XCTAssertEqual(phones.first?.matchedText, "03-1234-5678")
    }

    func testDetectsMobileJapanesePhone() {
        let text = "Call 090-1234-5678"
        let phones = SensitiveDetectors.detectAll(in: text).filter { $0.kind == .phone }
        XCTAssertEqual(phones.count, 1)
    }

    func testDetectsNoMatch() {
        let text = "This text has nothing sensitive."
        XCTAssertTrue(SensitiveDetectors.detectAll(in: text).isEmpty)
    }

    func testIgnoresLongerNumberSequences() {
        let text = "tracking-number: 0123456789012345"
        let phones = SensitiveDetectors.detectAll(in: text).filter { $0.kind == .phone }
        XCTAssertTrue(phones.isEmpty)
    }
}

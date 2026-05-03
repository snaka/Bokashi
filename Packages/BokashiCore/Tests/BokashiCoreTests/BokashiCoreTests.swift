import XCTest
@testable import BokashiCore

final class BokashiCoreTests: XCTestCase {
    func testVersionIsNotEmpty() {
        XCTAssertFalse(BokashiCore.version.isEmpty)
    }
}

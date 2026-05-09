import XCTest
@testable import BokashiCore

final class CustomTermsStoreTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("BokashiCustomTermsTests-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDownWithError() throws {
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try FileManager.default.removeItem(at: tempDirectory)
        }
        try super.tearDownWithError()
    }

    func testLoadFromMissingFileReturnsEmpty() throws {
        let store = CustomTermsStore(fileURL: tempDirectory.appendingPathComponent("nope.json"))
        XCTAssertEqual(try store.load(), [])
    }

    func testRoundTripPreservesOrderAndContent() throws {
        let store = CustomTermsStore(fileURL: tempDirectory.appendingPathComponent("terms.json"))
        let input = ["Acme", "鈴木", "MyProduct"]
        try store.save(input)
        XCTAssertEqual(try store.load(), input)
    }

    func testSaveCreatesParentDirectories() throws {
        let nested = tempDirectory
            .appendingPathComponent("a", isDirectory: true)
            .appendingPathComponent("b", isDirectory: true)
            .appendingPathComponent("terms.json")
        let store = CustomTermsStore(fileURL: nested)
        try store.save(["x"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: nested.path))
    }

    func testSaveOverwritesExisting() throws {
        let url = tempDirectory.appendingPathComponent("terms.json")
        let store = CustomTermsStore(fileURL: url)
        try store.save(["one"])
        try store.save(["two", "three"])
        XCTAssertEqual(try store.load(), ["two", "three"])
    }
}

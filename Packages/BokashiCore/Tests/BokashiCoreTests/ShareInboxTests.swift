import XCTest
@testable import BokashiCore

final class ShareInboxTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("bokashi-inbox-\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testWriteCreatesTheDirectoryIfItIsMissing() throws {
        let inbox = ShareInbox(directory: directory)

        _ = try inbox.write(Data("payload".utf8))

        var isDirectory: ObjCBool = false
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory)
        )
        XCTAssertTrue(isDirectory.boolValue)
    }

    func testDrainReturnsWhatWasWritten() throws {
        let inbox = ShareInbox(directory: directory)
        try inbox.write(Data("first".utf8))
        try inbox.write(Data("second".utf8))

        let drained = inbox.drain().map { String(decoding: $0, as: UTF8.self) }

        XCTAssertEqual(Set(drained), ["first", "second"])
    }

    func testDrainEmptiesTheInbox() throws {
        let inbox = ShareInbox(directory: directory)
        try inbox.write(Data("payload".utf8))

        _ = inbox.drain()

        XCTAssertEqual(inbox.drain(), [])
        let remaining = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        XCTAssertEqual(remaining, [])
    }

    func testDrainOnAMissingDirectoryReturnsNothing() {
        let inbox = ShareInbox(directory: directory)

        XCTAssertEqual(inbox.drain(), [])
    }
}

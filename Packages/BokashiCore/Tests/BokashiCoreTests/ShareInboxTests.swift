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

    func testDrainLeavesAPartialWriteAlone() throws {
        let inbox = ShareInbox(directory: directory)
        try inbox.write(Data("finished".utf8))
        let partial = directory.appendingPathComponent("\(UUID().uuidString).part")
        try Data("half".utf8).write(to: partial)

        let drained = inbox.drain().map { String(decoding: $0, as: UTF8.self) }

        XCTAssertEqual(drained, ["finished"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: partial.path))
    }

    func testDrainLeavesASubdirectoryAlone() throws {
        let inbox = ShareInbox(directory: directory)
        try inbox.write(Data("payload".utf8))
        let nested = directory.appendingPathComponent("nested")
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        let keeper = nested.appendingPathComponent("keeper")
        try Data("keeper".utf8).write(to: keeper)

        let drained = inbox.drain().map { String(decoding: $0, as: UTF8.self) }

        XCTAssertEqual(drained, ["payload"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: keeper.path))
    }

    func testDrainRemovesAPayloadItCannotRead() throws {
        let inbox = ShareInbox(directory: directory)
        let unreadable = try inbox.write(Data("payload".utf8))
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o000],
            ofItemAtPath: unreadable.path
        )

        XCTAssertEqual(inbox.drain(), [])
        XCTAssertFalse(FileManager.default.fileExists(atPath: unreadable.path))
    }
}

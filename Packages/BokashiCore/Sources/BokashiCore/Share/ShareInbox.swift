import Foundation

public struct ShareInbox {
    private static let stagingExtension = "part"

    private let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    /// The payload is staged under a `.part` name and then renamed into
    /// place, so a concurrent `drain()` can never observe a half-written
    /// file: a same-directory rename is atomic. `Data.WritingOptions.atomic`
    /// would not do, because it stages a dotfile in the same directory that
    /// `drain()` would list and delete out from under the rename.
    @discardableResult
    public func write(_ data: Data) throws -> URL {
        let manager = FileManager.default
        try manager.createDirectory(at: directory, withIntermediateDirectories: true)
        let name = UUID().uuidString
        let staging = directory.appendingPathComponent(name)
            .appendingPathExtension(Self.stagingExtension)
        try data.write(to: staging)
        let destination = directory.appendingPathComponent(name)
        do {
            try manager.moveItem(at: staging, to: destination)
        } catch {
            try? manager.removeItem(at: staging)
            throw error
        }
        return destination
    }

    /// Only finished payloads are considered: staging files and anything
    /// that is not a regular file are left untouched. Every payload that
    /// does qualify is removed even when it cannot be read, so one bad file
    /// cannot leave the queue stuck behind it forever.
    public func drain() -> [Data] {
        let manager = FileManager.default
        let urls = (try? manager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: []
        )) ?? []
        return urls.compactMap { url in
            guard url.pathExtension != Self.stagingExtension else { return nil }
            guard
                let values = try? url.resourceValues(forKeys: [.isRegularFileKey]),
                values.isRegularFile == true
            else { return nil }
            let data = try? Data(contentsOf: url)
            try? manager.removeItem(at: url)
            return data
        }
    }
}

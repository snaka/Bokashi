import Foundation

public struct ShareInbox {
    private let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    @discardableResult
    public func write(_ data: Data) throws -> URL {
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        let destination = directory.appendingPathComponent(UUID().uuidString)
        try data.write(to: destination)
        return destination
    }

    /// Every payload is removed even when it cannot be read, so one bad
    /// file cannot leave the queue stuck behind it forever.
    public func drain() -> [Data] {
        let manager = FileManager.default
        let names = (try? manager.contentsOfDirectory(atPath: directory.path)) ?? []
        return names.compactMap { name in
            let url = directory.appendingPathComponent(name)
            let data = try? Data(contentsOf: url)
            try? manager.removeItem(at: url)
            return data
        }
    }
}

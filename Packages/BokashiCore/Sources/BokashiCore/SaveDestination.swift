import Foundation

public enum SaveDestination {
    public static func desktopURL(for filename: String) -> URL {
        let fileManager = FileManager.default
        let desktop = fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first
            ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        return desktop.appendingPathComponent(filename)
    }
}

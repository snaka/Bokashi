import Foundation

public enum CaptureFilename {
    public static func make(
        for date: Date = Date(),
        timeZone: TimeZone = .current,
        prefix: String = "Bokashi"
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return "\(prefix)-\(formatter.string(from: date)).png"
    }
}

import Foundation

public struct RGBA: Hashable, Codable, Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public static let bokashiRed = RGBA(red: 1.0, green: 0.231, blue: 0.188)
}

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

    public static let presets: [RGBA] = [
        bokashiRed,
        RGBA(red: 1.0,   green: 0.584, blue: 0.0),    // orange
        RGBA(red: 0.95,  green: 0.776, blue: 0.0),    // yellow
        RGBA(red: 0.235, green: 0.745, blue: 0.255),  // green
        RGBA(red: 0.0,   green: 0.478, blue: 1.0),    // blue
        RGBA(red: 0.706, green: 0.318, blue: 0.847),  // purple
        RGBA(red: 0.1,   green: 0.1,   blue: 0.1),    // near-black
        RGBA(red: 0.95,  green: 0.95,  blue: 0.95),   // near-white
    ]
}

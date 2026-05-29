import Observation
import Sparkle

/// Thin Observable bridge over `SPUUpdater` so SwiftUI Settings can bind
/// to the auto-check preference. Sparkle persists the underlying value
/// itself (UserDefaults `SUEnableAutomaticChecks`), so we just mirror it.
@MainActor
@Observable
final class UpdaterSettings {
    var automaticallyChecksForUpdates: Bool {
        didSet {
            updater.automaticallyChecksForUpdates = automaticallyChecksForUpdates
        }
    }

    @ObservationIgnored
    private let updater: SPUUpdater

    init(updater: SPUUpdater) {
        self.updater = updater
        self.automaticallyChecksForUpdates = updater.automaticallyChecksForUpdates
    }
}

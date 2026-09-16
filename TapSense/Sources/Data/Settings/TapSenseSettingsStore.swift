import Foundation
import Observation
import NFCLocatorCore

/// Persists `TapSenseSettings` as JSON in `Application Support`, with the file's
/// `isExcludedFromBackup` resource value set. A completed-onboarding flag silently restored
/// from an iCloud/Finder backup on reinstall would make onboarding unreachable even after a
/// genuine uninstall, so the settings file lives somewhere backups skip entirely rather than
/// relying on export-rule exclusions layered on top of a backed-up location.
@MainActor
@Observable
final class TapSenseSettingsStore {
    private(set) var settings: TapSenseSettings

    private let fileURL: URL
    private let logger: NFCLocatorLogger

    init(logger: NFCLocatorLogger) {
        self.logger = logger
        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: supportDir, withIntermediateDirectories: true)
        self.fileURL = supportDir.appendingPathComponent("tapsense_settings.json")
        self.settings = TapSenseSettingsStore.load(from: fileURL) ?? TapSenseSettings()
        excludeFromBackup()
    }

    private static func load(from url: URL) -> TapSenseSettings? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(TapSenseSettings.self, from: data)
    }

    private func excludeFromBackup() {
        var url = fileURL
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? url.setResourceValues(values)
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(settings)
            try data.write(to: fileURL, options: .atomic)
            excludeFromBackup()
        } catch {
            logger.e(tag: "TapSenseSettingsStore", message: "Failed to persist settings", error: error)
        }
    }

    func setOnboardingCompleted(_ completed: Bool) {
        guard settings.onboardingCompleted != completed else { return }
        settings.onboardingCompleted = completed
        persist()
    }

    func setSelectedPhone(manufacturer: String, model: String, formFactor: FormFactor) {
        settings.manufacturer = manufacturer
        settings.model = model
        settings.formFactor = formFactor
        persist()
    }

    func clearSelectedPhone() {
        settings.manufacturer = nil
        settings.model = nil
        settings.formFactor = nil
        persist()
    }

    func setHapticsEnabled(_ enabled: Bool) {
        settings.hapticsEnabled = enabled
        persist()
    }

    func setReduceMotion(_ enabled: Bool) {
        settings.reduceMotion = enabled
        persist()
    }

    func setAppearanceMode(_ mode: AppearanceMode) {
        settings.appearanceMode = mode
        persist()
    }
}

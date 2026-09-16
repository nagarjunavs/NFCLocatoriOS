import Foundation
import NFCLocatorCore

struct TapSenseSettings: Codable, Equatable {
    var onboardingCompleted: Bool = false
    var manufacturer: String?
    var model: String?
    var formFactor: FormFactor?
    var hapticsEnabled: Bool = true
    var reduceMotion: Bool = false
    var appearanceMode: AppearanceMode = .system

    var hasManualPhoneOverride: Bool { manufacturer != nil && model != nil }
}

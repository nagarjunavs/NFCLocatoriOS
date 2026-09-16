import SwiftUI

/// Raw TapSense design-system palette — named tokens grouped by light/dark scheme, with the
/// rationale for each grouping captured alongside the values below.
enum TapSensePalette {
    // MARK: Light
    static let lightBg = Color(hex: 0xF6F5F1)
    static let lightSurface = Color(hex: 0xFFFFFF)
    static let lightSurfaceAlt = Color(hex: 0xF1F0EC)
    static let ink = Color(hex: 0x211F1C)
    static let ink2 = Color(hex: 0x6B675F)
    static let ink3 = Color(hex: 0x8B8779)
    static let lightOutline = Color(hex: 0xE4E1DA)
    static let lightDivider = Color(hex: 0xEFEDE7)

    // MARK: Dark
    static let darkBg = Color(hex: 0x171613)
    static let darkSurface = Color(hex: 0x1F1D19)
    static let darkSurfaceAlt = Color(hex: 0x262420)
    static let darkSurfaceDeep = Color(hex: 0x100F0D)
    static let darkOutline = Color(hex: 0x34322C)
    static let darkDivider = Color(hex: 0x2A2823)
    static let textLight = Color(hex: 0xF3F1EB)
    static let textLightSecondary = Color(hex: 0xA6A199)

    // MARK: Brand / accents (shared both themes unless noted)
    static let graphite = Color(hex: 0x33312C)
    static let aqua = Color(hex: 0x35C6D9)
    static let aquaDark = Color(hex: 0x4FE0F0)
    static let aquaLink = Color(hex: 0x0E4B54)
    static let amber = Color(hex: 0xE0A63C)
    static let amberOn = Color(hex: 0x7A5A1E)
    static let amberOnStrong = Color(hex: 0x8C6317)
    static let amberContainer = Color(hex: 0xFBF2E2)
    static let amberContainerDark = Color(hex: 0x262420)
    static let success = Color(hex: 0x3FA66B)
    static let successOn = Color(hex: 0x245C3E)
    static let successContainer = Color(hex: 0xEAF6EF)
    static let error = Color(hex: 0xD1483C)
    static let approxOn = Color(hex: 0x1B818E)
    static let approxContainer = Color(hex: 0xE9FAFB)

    // MARK: Generic reader/terminal device illustration (Onboarding, Tap Guide)
    static let readerOuter = Color(hex: 0x413E37)
    static let readerInner = Color(hex: 0x514E46)
    static let readerOuterLight = Color(hex: 0xDAD6CC)
    static let readerInnerLight = Color(hex: 0xC9C6BD)

    // MARK: My Phone's Back/Front segmented toggle
    static let toggleTrackLight = Color(hex: 0xEAE7E0)
    static let toggleTrackDark = Color(hex: 0x2E2C27)
    static let toggleTabSelectedDark = Color(hex: 0x454239)

    // MARK: Settings switches, unchecked (off) state only
    static let switchOffTrackLight = Color(hex: 0xC9C6BD)
    static let switchOffTrackDark = Color(hex: 0x4C4A44)
    static let switchOffThumbDark = Color(hex: 0xD8D5CC)

    // MARK: My Phone's Front screen-inset hardware-cutout accent
    static let screenInsetLight = Color(hex: 0x0D0C0B)
    static let hardwareCutoutDark = Color(hex: 0x000000)

    // MARK: Back-of-phone silhouette body/border
    static let phoneBody = Color(hex: 0x57544C)
    static let phoneBodyBorder = Color(hex: 0x6B675F)
    static let phoneBodyDark = Color(hex: 0x68655C)
    static let phoneBodyBorderDark = Color(hex: 0x7A766C)
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

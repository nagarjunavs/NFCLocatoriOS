import SwiftUI

/// Context-dependent tone pairs for the phone-mockup silhouette. Each function branches on the
/// *app's own* light/dark theme (`colors.isDark`), not any override — read it before drawing a
/// fixed-dark "mockup card" (Home, Tap Guide, Tap Test), whose card background itself never
/// follows `AppearanceMode`.
///
/// No theme-override wrapper is needed here: `NFCLocatorCore`'s `AntennaSilhouette` takes its
/// colors as explicit parameters rather than reading an ambient theme, so a caller on a
/// hardcoded-dark card just passes the dark-appropriate constants directly (see
/// `AntennaMarker`'s `markerColor` default).
enum DarkMockupColors {
    /// The solid device-shape fill for My Phone's Front tab — the only remaining caller; every
    /// *back*-panel silhouette uses `TapSensePalette.phoneBody` instead.
    static func darkCardSilhouetteColor(_ colors: TapSenseColors) -> Color {
        colors.isDark ? TapSensePalette.darkSurfaceDeep : TapSensePalette.graphite
    }

    /// Home's outer card background — deliberately a *different* dark tone than
    /// `darkCardSilhouetteColor` so the phone shape stays visible against its card.
    static func darkCardBackgroundColor(_ colors: TapSenseColors) -> Color {
        colors.isDark ? TapSensePalette.darkSurfaceAlt : TapSensePalette.ink
    }

    /// The top-left camera-bump accent every *back*-panel silhouette draws.
    static func cameraBumpAccentColor(_ colors: TapSenseColors) -> Color {
        colors.isDark ? TapSensePalette.darkSurfaceDeep : TapSensePalette.ink
    }

    /// My Phone Back tab's silhouette body fill — a step lighter in dark mode since that
    /// screen has no intermediate mockup card between the phone and the near-black background.
    static func myPhoneBackBodyColor(_ colors: TapSenseColors) -> Color {
        colors.isDark ? TapSensePalette.phoneBodyDark : TapSensePalette.phoneBody
    }

    static func myPhoneBackBorderColor(_ colors: TapSenseColors) -> Color {
        colors.isDark ? TapSensePalette.phoneBodyBorderDark : TapSensePalette.phoneBodyBorder
    }

    /// Tap Guide's silhouette body fill — swaps to a *light* body in dark mode (Tap Guide's
    /// dark card is less black than Home's/Tap Test's).
    static func tapGuideBodyColor(_ colors: TapSenseColors) -> Color {
        colors.isDark ? TapSensePalette.readerOuterLight : TapSensePalette.phoneBody
    }

    static func tapGuideBorderColor(_ colors: TapSenseColors) -> Color {
        colors.isDark ? TapSensePalette.readerInnerLight : TapSensePalette.phoneBodyBorder
    }

    /// My Phone Front tab's inset "screen" fill.
    static func screenInsetColor(_ colors: TapSenseColors) -> Color {
        colors.isDark ? TapSensePalette.hardwareCutoutDark : TapSensePalette.screenInsetLight
    }

    /// My Phone Front tab's top-center notch — a step lighter than `screenInsetColor`.
    static func screenNotchColor(_ colors: TapSenseColors) -> Color {
        colors.isDark ? TapSensePalette.darkSurfaceDeep : TapSensePalette.ink
    }
}

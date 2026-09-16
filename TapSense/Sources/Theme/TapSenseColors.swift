import SwiftUI

/// Semantic color slots for the app's light and dark schemes. `primary`/`tertiary` are both
/// the single aqua accent reserved for the tap-zone marker (fill-vs-outline carries the
/// confidence distinction, not a second hue); the `*Container` slots are wired directly to the
/// four confidence-badge colors, not tonal derivatives of `primary`, matching
/// `NFCLocatorCore.ConfidenceBadge`'s own reads of those slots. `inverseSurface`/
/// `inverseOnSurface` hold the actual primary-button colors (graphite-on-white light /
/// cream-on-black dark), kept off `primary` itself for the reason above — see the
/// `tapSenseFilled` button style, which reads from these slots.
struct TapSenseColors {
    let background: Color
    let onBackground: Color
    let surface: Color
    let onSurface: Color
    let surfaceVariant: Color
    let onSurfaceVariant: Color
    let outline: Color
    let outlineVariant: Color
    let primary: Color
    let onPrimary: Color
    let primaryContainer: Color
    let onPrimaryContainer: Color
    let secondary: Color
    let onSecondary: Color
    let secondaryContainer: Color
    let onSecondaryContainer: Color
    let tertiary: Color
    let onTertiary: Color
    let tertiaryContainer: Color
    let onTertiaryContainer: Color
    let error: Color
    let onError: Color
    let errorContainer: Color
    let onErrorContainer: Color
    let inverseSurface: Color
    let inverseOnSurface: Color

    let isDark: Bool

    // MARK: - Convenience (mirrors ButtonDefaults.tapSenseFilled()/tapSenseOutlined())

    var filledButtonBackground: Color { inverseSurface }
    var filledButtonForeground: Color { inverseOnSurface }
    var outlinedButtonForeground: Color { onSurface }
    var outlinedButtonBorder: Color { outline }
    // `aquaLink` is the *on-primary* contrast color — dark text/icons meant to sit on top of an
    // aqua-filled background (see `onPrimary`/`onTertiary` below). A link's text sits directly
    // on the screen background instead, so it needs the same accent `primary`/`tertiary` use,
    // not the color designed to contrast *against* that accent — using `aquaLink` here made
    // every `.tapSenseText` link ("Tap not working?", "Skip", "Use my phone automatically")
    // render as a barely-visible near-black teal instead of the intended vivid aqua, matching
    // `ActionRow`'s already-correct direct read of `colors.primary`.
    var linkForeground: Color { isDark ? TapSensePalette.aquaDark : TapSensePalette.aqua }

    var switchOffThumb: Color { isDark ? TapSensePalette.switchOffThumbDark : surface }
    var switchOffTrack: Color { isDark ? TapSensePalette.switchOffTrackDark : TapSensePalette.switchOffTrackLight }

    static let light = TapSenseColors(
        background: TapSensePalette.lightBg,
        onBackground: TapSensePalette.ink,
        surface: TapSensePalette.lightSurface,
        onSurface: TapSensePalette.ink,
        surfaceVariant: TapSensePalette.lightSurfaceAlt,
        onSurfaceVariant: TapSensePalette.ink2,
        outline: TapSensePalette.lightOutline,
        outlineVariant: TapSensePalette.lightDivider,
        primary: TapSensePalette.aqua,
        onPrimary: TapSensePalette.aquaLink,
        primaryContainer: TapSensePalette.successContainer,
        onPrimaryContainer: TapSensePalette.successOn,
        secondary: TapSensePalette.graphite,
        onSecondary: TapSensePalette.lightSurface,
        secondaryContainer: TapSensePalette.approxContainer,
        onSecondaryContainer: TapSensePalette.approxOn,
        tertiary: TapSensePalette.aqua,
        onTertiary: TapSensePalette.aquaLink,
        tertiaryContainer: TapSensePalette.amberContainer,
        onTertiaryContainer: TapSensePalette.amberOnStrong,
        error: TapSensePalette.error,
        onError: TapSensePalette.lightSurface,
        errorContainer: TapSensePalette.amberContainer,
        onErrorContainer: TapSensePalette.error,
        inverseSurface: TapSensePalette.graphite,
        inverseOnSurface: TapSensePalette.lightSurface,
        isDark: false
    )

    static let dark = TapSenseColors(
        background: TapSensePalette.darkBg,
        onBackground: TapSensePalette.textLight,
        surface: TapSensePalette.darkSurface,
        onSurface: TapSensePalette.textLight,
        surfaceVariant: TapSensePalette.darkSurfaceAlt,
        onSurfaceVariant: TapSensePalette.textLightSecondary,
        outline: TapSensePalette.darkOutline,
        outlineVariant: TapSensePalette.darkDivider,
        primary: TapSensePalette.aquaDark,
        onPrimary: TapSensePalette.darkSurfaceDeep,
        primaryContainer: TapSensePalette.darkSurfaceAlt,
        onPrimaryContainer: TapSensePalette.aquaDark,
        secondary: TapSensePalette.textLight,
        onSecondary: TapSensePalette.darkBg,
        secondaryContainer: TapSensePalette.darkSurfaceAlt,
        onSecondaryContainer: TapSensePalette.aquaDark,
        tertiary: TapSensePalette.aquaDark,
        onTertiary: TapSensePalette.darkSurfaceDeep,
        tertiaryContainer: TapSensePalette.amberContainerDark,
        onTertiaryContainer: TapSensePalette.amber,
        error: TapSensePalette.error,
        onError: TapSensePalette.textLight,
        errorContainer: TapSensePalette.darkSurfaceAlt,
        onErrorContainer: TapSensePalette.error,
        inverseSurface: TapSensePalette.textLight,
        inverseOnSurface: TapSensePalette.darkSurfaceDeep,
        isDark: true
    )
}

private struct TapSenseColorsKey: EnvironmentKey {
    static let defaultValue = TapSenseColors.light
}

extension EnvironmentValues {
    var tsColors: TapSenseColors {
        get { self[TapSenseColorsKey.self] }
        set { self[TapSenseColorsKey.self] = newValue }
    }
}

/// Applies the resolved `TapSenseColors` (from `appearanceMode` + the system color scheme) to
/// the environment, and forces `colorScheme` so system controls — not just this view's own
/// tint — follow the in-app appearance override rather than the OS setting.
struct TapSenseTheme: ViewModifier {
    let appearanceMode: AppearanceMode
    @Environment(\.colorScheme) private var systemColorScheme

    private var useDark: Bool {
        switch appearanceMode {
        case .system: return systemColorScheme == .dark
        case .light: return false
        case .dark: return true
        }
    }

    func body(content: Content) -> some View {
        content
            .environment(\.tsColors, useDark ? .dark : .light)
            .preferredColorScheme(appearanceMode == .system ? nil : (useDark ? .dark : .light))
            .tint(useDark ? TapSensePalette.aquaDark : TapSensePalette.aqua)
    }
}

extension View {
    func tapSenseTheme(appearanceMode: AppearanceMode) -> some View {
        modifier(TapSenseTheme(appearanceMode: appearanceMode))
    }
}

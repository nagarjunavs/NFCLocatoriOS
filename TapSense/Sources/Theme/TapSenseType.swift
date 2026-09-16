import SwiftUI

/// TapSense's type scale. Manrope (500-800) carries headlines/titles, Inter (400-700) carries
/// body/labels — both bundled as variable-weight TTFs (`Resources/Fonts/`), registered via
/// `UIAppFonts` in Info.plist. `Font.custom(_:size:).weight(_:)` resolves the requested weight
/// against the font's `wght` variation axis.
struct TapSenseTextStyle {
    let fontName: String
    let weight: Font.Weight
    let size: CGFloat
    /// The design spec's line-height in points; converted to SwiftUI's `.lineSpacing` (extra
    /// space added between lines, not a per-line box height) as `lineHeight - size`.
    let lineHeight: CGFloat
    let tracking: CGFloat

    var font: Font { .custom(fontName, size: size).weight(weight) }
    var lineSpacing: CGFloat { max(lineHeight - size, 0) }
}

enum TapSenseType {
    private static let manrope = "Manrope"
    private static let inter = "Inter"

    static let displayMedium = TapSenseTextStyle(fontName: manrope, weight: .heavy, size: 32, lineHeight: 38, tracking: -0.32)
    static let headlineLarge = TapSenseTextStyle(fontName: manrope, weight: .heavy, size: 26, lineHeight: 32, tracking: -0.26)
    static let headlineSmall = TapSenseTextStyle(fontName: manrope, weight: .heavy, size: 22, lineHeight: 28, tracking: -0.22)
    static let titleLarge = TapSenseTextStyle(fontName: manrope, weight: .bold, size: 20, lineHeight: 26, tracking: 0)
    static let titleMedium = TapSenseTextStyle(fontName: manrope, weight: .bold, size: 17, lineHeight: 22, tracking: 0)
    static let titleSmall = TapSenseTextStyle(fontName: inter, weight: .semibold, size: 14, lineHeight: 20, tracking: 0)
    static let bodyLarge = TapSenseTextStyle(fontName: inter, weight: .regular, size: 16, lineHeight: 24, tracking: 0)
    static let bodyMedium = TapSenseTextStyle(fontName: inter, weight: .regular, size: 14, lineHeight: 21, tracking: 0)
    static let bodySmall = TapSenseTextStyle(fontName: inter, weight: .regular, size: 13, lineHeight: 19, tracking: 0)
    static let labelLarge = TapSenseTextStyle(fontName: inter, weight: .semibold, size: 15, lineHeight: 20, tracking: 0)
    static let labelMedium = TapSenseTextStyle(fontName: inter, weight: .bold, size: 12, lineHeight: 16, tracking: 0)
    static let labelSmall = TapSenseTextStyle(fontName: inter, weight: .bold, size: 11, lineHeight: 14, tracking: 0.08)
}

extension View {
    func tapSenseStyle(_ style: TapSenseTextStyle, color: Color? = nil) -> some View {
        modifier(TapSenseTextStyleModifier(style: style, color: color))
    }
}

private struct TapSenseTextStyleModifier: ViewModifier {
    let style: TapSenseTextStyle
    let color: Color?

    func body(content: Content) -> some View {
        content
            .font(style.font)
            .tracking(style.tracking)
            .lineSpacing(style.lineSpacing)
            .foregroundStyle(color ?? .primary)
    }
}

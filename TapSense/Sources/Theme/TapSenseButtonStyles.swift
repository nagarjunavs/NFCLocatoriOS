import SwiftUI

/// Filled pill button (`Start tap guide`, `Continue`, etc.) — matches the style guide's
/// graphite-fill / white-text pill, `999pt` corner radius, `16pt` vertical padding.
struct TapSenseFilledButtonStyle: ButtonStyle {
    @Environment(\.tsColors) private var colors
    @Environment(\.isEnabled) private var isEnabled
    var fullWidth = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .tapSenseStyle(TapSenseType.labelLarge, color: isEnabled ? colors.filledButtonForeground : TapSensePalette.textLightSecondary)
            .padding(.vertical, 16)
            .padding(.horizontal, 26)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(isEnabled ? colors.filledButtonBackground : TapSensePalette.lightDivider)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

/// Outlined pill button (`Change`, `Cancel`) — transparent fill, `1.5pt` border.
struct TapSenseOutlinedButtonStyle: ButtonStyle {
    @Environment(\.tsColors) private var colors
    var fullWidth = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .tapSenseStyle(TapSenseType.labelLarge, color: colors.outlinedButtonForeground)
            .padding(.vertical, 14.5)
            .padding(.horizontal, 26)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(
                Capsule().strokeBorder(colors.outlinedButtonBorder, lineWidth: 1.5)
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

/// Plain text link button (`Learn more`, `Tap not working?`) in the teal/aqua link color.
struct TapSenseTextButtonStyle: ButtonStyle {
    @Environment(\.tsColors) private var colors
    var color: Color?

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .tapSenseStyle(TapSenseType.labelLarge, color: color ?? colors.linkForeground)
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

/// Destructive filled pill (`Remove phone`) — error-red fill.
struct TapSenseDestructiveButtonStyle: ButtonStyle {
    @Environment(\.tsColors) private var colors

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .tapSenseStyle(TapSenseType.labelLarge, color: .white)
            .padding(.vertical, 16)
            .padding(.horizontal, 26)
            .frame(maxWidth: .infinity)
            .background(colors.error)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

extension ButtonStyle where Self == TapSenseFilledButtonStyle {
    static var tapSenseFilled: TapSenseFilledButtonStyle { TapSenseFilledButtonStyle() }
}

extension ButtonStyle where Self == TapSenseOutlinedButtonStyle {
    static var tapSenseOutlined: TapSenseOutlinedButtonStyle { TapSenseOutlinedButtonStyle() }
}

extension ButtonStyle where Self == TapSenseTextButtonStyle {
    static var tapSenseText: TapSenseTextButtonStyle { TapSenseTextButtonStyle() }
}

extension ButtonStyle where Self == TapSenseDestructiveButtonStyle {
    static var tapSenseDestructive: TapSenseDestructiveButtonStyle { TapSenseDestructiveButtonStyle() }
}

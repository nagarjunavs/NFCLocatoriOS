import SwiftUI
import NFCLocatorCore

/// The terse "EXACT / APPROXIMATE / ESTIMATED / UNKNOWN" pill from the TapSense style guide —
/// distinct from `NFCLocatorCore.ConfidenceBadge`, which uses longer, more descriptive copy
/// suited to a generic host. This one is for contexts that follow the style guide literally:
/// the phone picker list and the My Phone antenna detail card.
///
/// Colors are read straight from `TapSensePalette`, not the app's light/dark `TapSenseColors`
/// scheme — the chip looks the same regardless of app theme, by design.
///
/// `onDarkCard` switches to the design's subtler translucent-white-on-dark treatment (colored
/// text + dot, no colored pill background) used for the badge shown *inside* a
/// hardcoded-dark device card (Home, Tap Guide) — as opposed to the bold colored pill used
/// everywhere else, which stays the default (`false`).
struct ConfidenceChip: View {
    let confidence: Confidence
    var onDarkCard = false

    private struct ChipStyle {
        let dot: Color
        let container: Color
        let text: Color
        let label: LocalizedStringKey
    }

    private var style: ChipStyle {
        switch confidence {
        case .exact:
            return ChipStyle(dot: TapSensePalette.success, container: TapSensePalette.successContainer, text: TapSensePalette.successOn, label: "confidence_chip.exact")
        case .approximate:
            return ChipStyle(dot: TapSensePalette.approxOn, container: TapSensePalette.approxContainer, text: TapSensePalette.approxOn, label: "confidence_chip.approximate")
        case .generic:
            return ChipStyle(dot: TapSensePalette.amber, container: TapSensePalette.amberContainer, text: TapSensePalette.amberOnStrong, label: "confidence_chip.estimated")
        case .unknown:
            return ChipStyle(dot: TapSensePalette.ink2, container: TapSensePalette.lightSurfaceAlt, text: TapSensePalette.ink2, label: "confidence_chip.unknown")
        }
    }

    var body: some View {
        let s = style
        let containerColor = onDarkCard ? Color.white.opacity(0.1) : s.container
        let textColor = onDarkCard ? s.dot : s.text

        HStack(spacing: 6) {
            Circle()
                .fill(s.dot)
                .frame(width: 8, height: 8)
            Text(s.label, bundle: .main)
                .tapSenseStyle(TapSenseType.labelMedium, color: textColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(containerColor)
        .clipShape(Capsule())
    }
}

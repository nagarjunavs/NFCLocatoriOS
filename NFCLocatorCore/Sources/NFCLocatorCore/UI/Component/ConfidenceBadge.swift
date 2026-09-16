import SwiftUI

/// A pill badge naming the current ``Confidence`` tier. The library never hardcodes brand
/// colors — callers can override `backgroundColor`/`foregroundColor`, or leave the defaults,
/// which pick a distinct, colorblind-safe hue per tier.
public struct ConfidenceBadge: View {
    private let confidence: Confidence
    private let backgroundColor: Color?
    private let foregroundColor: Color?

    public init(confidence: Confidence, backgroundColor: Color? = nil, foregroundColor: Color? = nil) {
        self.confidence = confidence
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }

    public var body: some View {
        Text(label, bundle: .nfcLocatorCoreResources)
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(backgroundColor ?? defaultBackground)
            .foregroundStyle(foregroundColor ?? defaultForeground)
            .clipShape(Capsule())
            .accessibilityLabel(Text(label, bundle: .nfcLocatorCoreResources))
    }

    private var label: LocalizedStringKey {
        switch confidence {
        case .exact: return "nfc_locator.confidence.exact"
        case .approximate: return "nfc_locator.confidence.approximate"
        case .generic: return "nfc_locator.confidence.generic"
        case .unknown: return "nfc_locator.confidence.unknown"
        }
    }

    private var defaultBackground: Color {
        switch confidence {
        case .exact: return .green.opacity(0.18)
        case .approximate: return .teal.opacity(0.18)
        case .generic: return .orange.opacity(0.18)
        case .unknown: return .gray.opacity(0.18)
        }
    }

    private var defaultForeground: Color {
        switch confidence {
        case .exact: return .green
        case .approximate: return .teal
        case .generic: return .orange
        case .unknown: return .gray
        }
    }
}

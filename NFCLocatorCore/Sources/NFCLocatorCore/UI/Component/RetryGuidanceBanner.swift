import SwiftUI

/// A standalone banner, not wired into ``AntennaLocatorScreen`` — the host shows this after a
/// failed tap/read attempt, typically paired with `NFCLocatorAnalytics.retryGuidanceShown`.
public struct RetryGuidanceBanner: View {
    private let backgroundColor: Color

    public init(backgroundColor: Color = .red.opacity(0.12)) {
        self.backgroundColor = backgroundColor
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("nfc_locator.retry_guidance.title", bundle: .nfcLocatorCoreResources)
                .font(.headline)
            Text("nfc_locator.retry_guidance.body", bundle: .nfcLocatorCoreResources)
                .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.updatesFrequently)
    }
}

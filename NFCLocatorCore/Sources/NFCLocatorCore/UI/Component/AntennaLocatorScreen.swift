import SwiftUI

/// A complete, opinionated screen for ``AntennaLocatorUIState`` — title, badge, marker or
/// guided sweep, hint text, retry. Stateless: the host owns the resolve lifecycle and passes
/// state in, calling `onRetry` in response to a tap.
///
/// If you want to lay out the marker yourself alongside your own copy/branding, drop down to
/// its two building blocks directly — ``AntennaSilhouette`` for `.resolvedMarker`,
/// ``GuidedSweepAnimation`` for `.fallbackGuidance`.
public struct AntennaLocatorScreen: View {
    private static let maxSilhouetteHeight: CGFloat = 340

    private let state: AntennaLocatorUIState
    private let onRetry: () -> Void
    private let reducedMotion: Bool

    public init(state: AntennaLocatorUIState, reducedMotion: Bool = false, onRetry: @escaping () -> Void) {
        self.state = state
        self.reducedMotion = reducedMotion
        self.onRetry = onRetry
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("nfc_locator.screen.title", bundle: .nfcLocatorCoreResources)
                .font(.title3.weight(.semibold))

            switch state {
            case .loading:
                ProgressView()
                    .accessibilityLabel(Text("nfc_locator.loading.content_description", bundle: .nfcLocatorCoreResources))
            case .error:
                errorContent
            case .resolvedMarker(let marker):
                resolvedMarkerContent(marker)
            case .fallbackGuidance(let guidance):
                fallbackGuidanceContent(guidance)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.updatesFrequently)
    }

    private var errorContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("nfc_locator.error.title", bundle: .nfcLocatorCoreResources).font(.headline)
            Text("nfc_locator.error.body", bundle: .nfcLocatorCoreResources).font(.body)
            Button {
                onRetry()
            } label: {
                Text("nfc_locator.retry_button", bundle: .nfcLocatorCoreResources)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    @ViewBuilder
    private func resolvedMarkerContent(_ marker: AntennaLocatorUIState.ResolvedMarker) -> some View {
        ConfidenceBadge(confidence: marker.confidence)
        AntennaSilhouette(
            templateID: marker.silhouetteTemplateID,
            zone: marker.antennaZone,
            isConfident: !marker.isStale,
            reducedMotion: reducedMotion,
            aspectRatioOverride: marker.aspectRatio
        )
        .frame(maxWidth: .infinity)
        .frame(height: Self.maxSilhouetteHeight)

        Text(hintKey(for: marker), bundle: .nfcLocatorCoreResources)
            .font(.body)

        if marker.isStale {
            GuidedSweepAnimation(
                templateID: marker.silhouetteTemplateID,
                zone: marker.antennaZone,
                reducedMotion: reducedMotion,
                aspectRatioOverride: marker.aspectRatio
            )
            .frame(maxWidth: .infinity)
            .frame(height: Self.maxSilhouetteHeight)
        }
    }

    /// `isStale` -> stale hint; else `.approximate` -> approximate hint; else
    /// `source == .remoteCatalog`/`.seedCatalog` with `verified` (i.e. `.exact` here) ->
    /// verified hint. (There is no OS-measured `.exact` path on iOS — see ``DataSource``.)
    private func hintKey(for marker: AntennaLocatorUIState.ResolvedMarker) -> LocalizedStringKey {
        if marker.isStale { return "nfc_locator.marker.stale_hint" }
        if marker.confidence == .approximate { return "nfc_locator.marker.approximate_hint" }
        return "nfc_locator.marker.verified_hint"
    }

    @ViewBuilder
    private func fallbackGuidanceContent(_ guidance: AntennaLocatorUIState.FallbackGuidance) -> some View {
        ConfidenceBadge(confidence: guidance.confidence)
        GuidedSweepAnimation(
            templateID: guidance.silhouetteTemplateID,
            zone: guidance.approximateZone,
            reducedMotion: reducedMotion,
            aspectRatioOverride: guidance.aspectRatio
        )
        .frame(maxWidth: .infinity)
        .frame(height: Self.maxSilhouetteHeight)

        Text(LocalizedStringKey(guidance.tipTextKey), bundle: .nfcLocatorCoreResources)
            .font(.body)
    }
}

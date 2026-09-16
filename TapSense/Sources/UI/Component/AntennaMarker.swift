import SwiftUI
import NFCLocatorCore

/// Renders the antenna-location marker for a resolved `AntennaLocatorUIState`, following
/// `AntennaLocatorScreen`'s own resolved-marker/fallback-guidance branching so every screen in
/// this app treats confidence the same way: a solid marker only for a non-stale
/// `.resolvedMarker`, `GuidedSweepAnimation`'s moving highlight for every other case (a stale
/// approximate match, or `.fallbackGuidance`) — never a static marker for a guess.
///
/// `markerColor` is passed as *both* the confident and uncertain marker color — the app's theme
/// deliberately maps `primary` and `tertiary` to the same aqua accent in every color scheme
/// (including the always-dark "mockup card" override used on Home/Tap Guide/Tap Test), so
/// confidence is conveyed by the silhouette's solid-vs-dashed styling alone, never by a second
/// hue. Callers on an always-dark card pass the fixed light-aqua constant (`TapSensePalette.aqua`,
/// never `.aquaDark`) regardless of the app's own theme, matching `DarkMockupColors`'s override;
/// callers on an ambient-themed background pass `colors.primary`.
struct AntennaMarker: View {
    let state: AntennaLocatorUIState?
    let reducedMotion: Bool
    var markerColor: Color = TapSensePalette.aqua
    var silhouetteColor: Color = TapSensePalette.phoneBody
    var showCameraBump = false
    var cameraBumpColor: Color?
    var silhouetteBorderColor: Color?

    var body: some View {
        switch state {
        case .resolvedMarker(let marker) where marker.isStale:
            GuidedSweepAnimation(
                templateID: marker.silhouetteTemplateID,
                zone: marker.antennaZone,
                reducedMotion: reducedMotion,
                silhouetteColor: silhouetteColor,
                highlightColor: markerColor,
                aspectRatioOverride: marker.aspectRatio,
                showCameraBump: showCameraBump,
                cameraBumpColor: cameraBumpColor,
                silhouetteBorderColor: silhouetteBorderColor
            )
        case .resolvedMarker(let marker):
            AntennaSilhouette(
                templateID: marker.silhouetteTemplateID,
                zone: marker.antennaZone,
                isConfident: true,
                reducedMotion: reducedMotion,
                silhouetteColor: silhouetteColor,
                confidentMarkerColor: markerColor,
                uncertainMarkerColor: markerColor,
                aspectRatioOverride: marker.aspectRatio,
                showCameraBump: showCameraBump,
                cameraBumpColor: cameraBumpColor ?? silhouetteColor,
                silhouetteBorderColor: silhouetteBorderColor
            )
        case .fallbackGuidance(let guidance):
            GuidedSweepAnimation(
                templateID: guidance.silhouetteTemplateID,
                zone: guidance.approximateZone,
                reducedMotion: reducedMotion,
                silhouetteColor: silhouetteColor,
                highlightColor: markerColor,
                aspectRatioOverride: guidance.aspectRatio,
                showCameraBump: showCameraBump,
                cameraBumpColor: cameraBumpColor,
                silhouetteBorderColor: silhouetteBorderColor
            )
        default:
            EmptyView()
        }
    }
}

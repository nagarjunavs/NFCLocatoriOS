import SwiftUI

/// Wraps ``AntennaSilhouette`` (always dashed — `isConfident` is hardcoded `false`) with a
/// horizontal sweep highlight layered on top, for a heuristic/guess result.
public struct GuidedSweepAnimation: View {
    private let templateID: String
    private let zone: NormalizedRect
    private let reducedMotion: Bool
    private let silhouetteColor: Color
    private let highlightColor: Color
    private let aspectRatioOverride: Float?
    private let showCameraBump: Bool
    private let cameraBumpColor: Color?
    private let silhouetteBorderColor: Color?

    public init(
        templateID: String,
        zone: NormalizedRect,
        reducedMotion: Bool = false,
        silhouetteColor: Color = Color.gray.opacity(0.35),
        highlightColor: Color = .orange,
        aspectRatioOverride: Float? = nil,
        showCameraBump: Bool = false,
        cameraBumpColor: Color? = nil,
        silhouetteBorderColor: Color? = nil
    ) {
        self.templateID = templateID
        self.zone = zone
        self.reducedMotion = reducedMotion
        self.silhouetteColor = silhouetteColor
        self.highlightColor = highlightColor
        self.aspectRatioOverride = aspectRatioOverride
        self.showCameraBump = showCameraBump
        self.cameraBumpColor = cameraBumpColor
        self.silhouetteBorderColor = silhouetteBorderColor
    }

    public var body: some View {
        ZStack {
            AntennaSilhouette(
                templateID: templateID,
                zone: zone,
                isConfident: false,
                reducedMotion: reducedMotion,
                silhouetteColor: silhouetteColor,
                uncertainMarkerColor: highlightColor,
                aspectRatioOverride: aspectRatioOverride,
                showCameraBump: showCameraBump,
                cameraBumpColor: cameraBumpColor,
                silhouetteBorderColor: silhouetteBorderColor
            )
            TimelineView(.animation(paused: reducedMotion)) { context in
                Canvas { canvasContext, size in
                    drawSweep(in: &canvasContext, size: size, now: context.date)
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel(Text("nfc_locator.sweep.content_description", bundle: .nfcLocatorCoreResources))
    }

    private func drawSweep(in context: inout GraphicsContext, size: CGSize, now: Date) {
        let ratio = SilhouetteGeometry.aspectRatio(templateID: templateID, override: aspectRatioOverride)
        let contentSize = SilhouetteGeometry.fitWithinBounds(size, ratio: ratio)
        guard contentSize.width > 0, contentSize.height > 0 else { return }
        let offset = SilhouetteGeometry.centeringOffset(bounds: size, content: contentSize)
        let contentRect = CGRect(origin: offset, size: contentSize)

        let left = contentRect.minX + CGFloat(zone.x) * contentRect.width
        let right = contentRect.minX + CGFloat(zone.x + zone.width) * contentRect.width
        let centerY = contentRect.minY + CGFloat(zone.centerY) * contentRect.height

        let progress: CGFloat
        if reducedMotion {
            progress = 0.5
        } else {
            // 0->1 over 1800ms, reversing (back-and-forth), unlike the ripple's one-way restart.
            let period = 1.8
            let phase = (now.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period * 2)) / period
            progress = phase <= 1 ? CGFloat(phase) : CGFloat(2 - phase)
        }

        let x = left + (right - left) * progress
        let radius = SilhouetteGeometry.markerRadius(contentSize: contentRect.size)
        let center = CGPoint(x: x, y: centerY)

        context.fill(
            Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
            with: .radialGradient(
                Gradient(colors: [highlightColor.opacity(0.55), highlightColor.opacity(0)]),
                center: center,
                startRadius: 0,
                endRadius: radius
            )
        )
    }
}

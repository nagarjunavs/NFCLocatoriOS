import SwiftUI

/// Draws a device silhouette (a vector outline, never photographic art — see `DECISIONS.md`)
/// with the antenna marker at `zone`.
///
/// The one rule this component must never violate: a confident result (`isConfident == true`)
/// draws a **solid** ring and center dot; anything else draws a **dashed** ring with no dot.
/// This solid-vs-dashed distinction is the load-bearing accessibility/trust signal — never
/// change it to a color-only distinction.
///
/// The ripple/ring/dot are drawn as plain SwiftUI shapes layered over a `Canvas` (which holds
/// only the silhouette body, never overshoots its own bounds), not drawn inside the `Canvas`
/// itself. `Canvas` rasterizes into a fixed-size surface matching its own frame and hard-clips
/// anything drawn past that edge — unlike ordinary composited views, which can render outside
/// their layout frame. The ripple's radius grows up to `maxRadius * 1.9`, comfortably exceeding
/// the marker's own frame for every size used across the app well before its alpha fades to
/// zero; drawn inside the `Canvas` that overflow got clipped into a visible square/rectangle at
/// the end of each pulse instead of staying a circle. Plain shapes in a `ZStack` aren't clipped
/// by their siblings' or the stack's own bounds, so the same geometry now renders correctly.
public struct AntennaSilhouette: View {
    private let templateID: String
    private let zone: NormalizedRect
    private let isConfident: Bool
    private let reducedMotion: Bool
    private let silhouetteColor: Color
    private let confidentMarkerColor: Color
    private let uncertainMarkerColor: Color
    private let aspectRatioOverride: Float?
    private let showCameraBump: Bool
    private let cameraBumpColor: Color
    private let silhouetteBorderColor: Color?

    public init(
        templateID: String,
        zone: NormalizedRect,
        isConfident: Bool,
        reducedMotion: Bool = false,
        silhouetteColor: Color = Color.gray.opacity(0.35),
        confidentMarkerColor: Color = .accentColor,
        uncertainMarkerColor: Color = .orange,
        aspectRatioOverride: Float? = nil,
        showCameraBump: Bool = false,
        cameraBumpColor: Color? = nil,
        silhouetteBorderColor: Color? = nil
    ) {
        self.templateID = templateID
        self.zone = zone
        self.isConfident = isConfident
        self.reducedMotion = reducedMotion
        self.silhouetteColor = silhouetteColor
        self.confidentMarkerColor = confidentMarkerColor
        self.uncertainMarkerColor = uncertainMarkerColor
        self.aspectRatioOverride = aspectRatioOverride
        self.showCameraBump = showCameraBump
        self.cameraBumpColor = cameraBumpColor ?? silhouetteColor
        self.silhouetteBorderColor = silhouetteBorderColor
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                if let metrics = metrics(for: proxy.size) {
                    Canvas { context, _ in
                        drawSilhouette(in: &context, metrics: metrics)
                    }
                    rippleLayer(metrics: metrics)
                    ringAndDotLayer(metrics: metrics)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .accessibilityElement()
        .accessibilityLabel(Text("nfc_locator.marker.content_description", bundle: .nfcLocatorCoreResources))
    }

    // MARK: - Shared geometry

    private struct Metrics {
        let shape: SilhouetteShape
        let contentRect: CGRect
        let zoneCenter: CGPoint
        let maxRadius: CGFloat
        let markerColor: Color
    }

    private func metrics(for size: CGSize) -> Metrics? {
        let shape = SilhouetteShape.forTemplate(templateID)
        let ratio = SilhouetteGeometry.aspectRatio(templateID: templateID, override: aspectRatioOverride)
        let contentSize = SilhouetteGeometry.fitWithinBounds(size, ratio: ratio)
        guard contentSize.width > 0, contentSize.height > 0 else { return nil }
        let offset = SilhouetteGeometry.centeringOffset(bounds: size, content: contentSize)
        let contentRect = CGRect(origin: offset, size: contentSize)
        let zoneCenter = CGPoint(
            x: contentRect.minX + CGFloat(zone.centerX) * contentRect.width,
            y: contentRect.minY + CGFloat(zone.centerY) * contentRect.height
        )
        let maxRadius = SilhouetteGeometry.markerRadius(contentSize: contentRect.size)
        let markerColor = isConfident ? confidentMarkerColor : uncertainMarkerColor
        return Metrics(shape: shape, contentRect: contentRect, zoneCenter: zoneCenter, maxRadius: maxRadius, markerColor: markerColor)
    }

    // MARK: - Layer 1: silhouette body (Canvas — never overshoots its own bounds)

    private func drawSilhouette(in context: inout GraphicsContext, metrics: Metrics) {
        let outline = Path(metrics.shape.path(in: metrics.contentRect))
        context.fill(outline, with: .color(silhouetteColor))
        if let silhouetteBorderColor {
            context.stroke(outline, with: .color(silhouetteBorderColor), lineWidth: 1)
        }
        if metrics.shape.hasHingeSeam {
            var seam = Path()
            seam.move(to: CGPoint(x: metrics.contentRect.midX, y: metrics.contentRect.minY))
            seam.addLine(to: CGPoint(x: metrics.contentRect.midX, y: metrics.contentRect.maxY))
            context.stroke(seam, with: .color(.black.opacity(0.18)), lineWidth: 1)
        }

        // Optional camera bump — fixed fractional position within the content rect.
        if showCameraBump {
            let contentRect = metrics.contentRect
            let bumpRect = CGRect(
                x: contentRect.minX + 0.1154 * contentRect.width,
                y: contentRect.minY + 0.0621 * contentRect.height,
                width: 0.1987 * contentRect.width,
                height: 0.0917 * contentRect.height
            )
            let bumpPath = Path(
                roundedRect: bumpRect,
                cornerRadius: 0.3548 * bumpRect.width
            )
            context.fill(bumpPath, with: .color(cameraBumpColor))
        }
    }

    // MARK: - Layer 2: ripple/glow (plain shape — allowed to overflow its nominal frame)

    /// Animates 0.6->1.9 over 2200ms, restarting (not reversing), unless reduced motion, in
    /// which case a static glow at alpha 0.28 / full radius.
    @ViewBuilder
    private func rippleLayer(metrics: Metrics) -> some View {
        if reducedMotion {
            Circle()
                .fill(metrics.markerColor.opacity(0.28))
                .frame(width: metrics.maxRadius * 2, height: metrics.maxRadius * 2)
                .position(metrics.zoneCenter)
        } else {
            TimelineView(.animation) { context in
                let period = 2.2
                let phase = (context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period)) / period
                let ripple = 0.6 + phase * (1.9 - 0.6)
                let rippleAlpha = min(max((ripple - 0.6) / (1.9 - 0.6) * 0.5, 0), 0.5)
                let radius = metrics.maxRadius * ripple
                Circle()
                    .fill(metrics.markerColor.opacity(rippleAlpha))
                    .frame(width: radius * 2, height: radius * 2)
                    .position(metrics.zoneCenter)
            }
        }
    }

    // MARK: - Layer 3: ring + optional center dot (plain shapes)

    /// Solid ring + filled dot for confident; dashed ring with no dot otherwise.
    @ViewBuilder
    private func ringAndDotLayer(metrics: Metrics) -> some View {
        let ringRadius = metrics.maxRadius * 0.57
        let ringStroke = metrics.maxRadius * 0.06
        if isConfident {
            Circle()
                .stroke(metrics.markerColor, lineWidth: ringStroke)
                .frame(width: ringRadius * 2, height: ringRadius * 2)
                .position(metrics.zoneCenter)
            Circle()
                .fill(metrics.markerColor)
                .frame(width: metrics.maxRadius * 0.4, height: metrics.maxRadius * 0.4)
                .position(metrics.zoneCenter)
        } else {
            Circle()
                .stroke(metrics.markerColor, style: StrokeStyle(lineWidth: ringStroke, dash: [6, 5]))
                .frame(width: ringRadius * 2, height: ringRadius * 2)
                .position(metrics.zoneCenter)
        }
    }
}

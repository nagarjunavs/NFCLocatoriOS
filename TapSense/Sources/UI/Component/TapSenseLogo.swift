import SwiftUI

/// The TapSense mark: concentric rings around a solid dot — the same shape language as
/// `NFCLocatorCore`'s `AntennaSilhouette` marker. Used on the splash screen, onboarding, and
/// the bottom bar's Tap Guide FAB (`singleRing: true`).
///
/// The pulsing ripple is drawn as a plain `Circle` shape layered over a `Canvas` (which holds
/// only the two rings + dot, none of which exceed `maxRadius`), not drawn inside the `Canvas`
/// itself. `Canvas` rasterizes into a fixed-size surface matching its own frame and hard-clips
/// anything drawn past that edge; the ripple's radius grows up to `maxRadius * 1.9` — nearly
/// double the mark's own bounds — so drawn inside the `Canvas` that overflow got clipped into a
/// visible square at the end of each pulse instead of staying a circle. A plain shape isn't
/// clipped by its `ZStack` siblings or the stack's own bounds, so the same geometry now renders
/// correctly.
struct TapSenseLogo: View {
    let color: Color
    var size: CGFloat = 96
    var pulsing = false
    var reducedMotion = false
    var singleRing = false

    private static let rippleMinScale: CGFloat = 0.6
    private static let rippleMaxScale: CGFloat = 1.9
    private static let ripplePeakAlpha: CGFloat = 0.5

    var body: some View {
        GeometryReader { proxy in
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let maxRadius = min(proxy.size.width, proxy.size.height) / 2

            ZStack(alignment: .topLeading) {
                if pulsing, !reducedMotion {
                    TimelineView(.animation) { context in
                        let period = 2.2
                        let phase = (context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period)) / period
                        let scale = Self.rippleMinScale + CGFloat(phase) * (Self.rippleMaxScale - Self.rippleMinScale)
                        let alpha = min(max((Self.rippleMaxScale - scale) / (Self.rippleMaxScale - Self.rippleMinScale) * Self.ripplePeakAlpha, 0), Self.ripplePeakAlpha)
                        let radius = maxRadius * scale
                        Circle()
                            .fill(color.opacity(alpha))
                            .frame(width: radius * 2, height: radius * 2)
                            .position(center)
                    }
                }

                Canvas { gc, _ in
                    if !singleRing {
                        stroke(&gc, center: center, radius: maxRadius * 0.92, lineWidth: maxRadius * 0.06)
                    }
                    stroke(&gc, center: center, radius: maxRadius * 0.56, lineWidth: maxRadius * 0.06)

                    let dotRadius = maxRadius * 0.21
                    gc.fill(Path(ellipseIn: CGRect(x: center.x - dotRadius, y: center.y - dotRadius, width: dotRadius * 2, height: dotRadius * 2)), with: .color(color))
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .frame(width: size, height: size)
    }

    private func stroke(_ gc: inout GraphicsContext, center: CGPoint, radius: CGFloat, lineWidth: CGFloat) {
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        gc.stroke(Path(ellipseIn: rect), with: .color(color), lineWidth: lineWidth)
    }
}

import SwiftUI

/// A plain solid-filled phone silhouette for decorative (non-data-driven) contexts — My Phone's
/// Front tab and (before any device is resolved) the Onboarding walkthrough, so it has no real
/// antenna zone to draw `NFCLocatorCore.AntennaSilhouette` against.
///
/// `cameraBump` draws a top-left corner camera-module square, matching a device's *back* panel.
/// `screenInset` draws an inset "screen" rectangle with a top-center notch instead, matching a
/// device's *front* — the two are mutually exclusive decorations for the same body shape.
struct PhoneSilhouette: View {
    let color: Color
    var cameraBump = false
    var bumpColor: Color?
    var screenInset = false
    var insetColor: Color?
    var notchColor: Color?
    var borderColor: Color?

    var body: some View {
        Canvas { context, size in
            let cornerRadius = size.width * 0.22
            let bodyPath = Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: cornerRadius)
            context.fill(bodyPath, with: .color(color))
            if let borderColor {
                context.stroke(bodyPath, with: .color(borderColor), lineWidth: 1)
            }
            if cameraBump {
                let bumpWidth = size.width * 0.1987
                let bumpHeight = size.height * 0.0917
                let bumpRect = CGRect(x: size.width * 0.1154, y: size.height * 0.0621, width: bumpWidth, height: bumpHeight)
                context.fill(Path(roundedRect: bumpRect, cornerRadius: bumpWidth * 0.3548), with: .color(bumpColor ?? color))
            }
            if screenInset {
                let insetLeft = size.width * 0.0641
                let insetTop = size.height * 0.0296
                let insetRect = CGRect(x: insetLeft, y: insetTop, width: size.width - insetLeft * 2, height: size.height - insetTop * 2)
                context.fill(Path(roundedRect: insetRect, cornerRadius: size.width * 0.2179), with: .color(insetColor ?? color))

                let notchWidth = size.width * 0.2821
                let notchHeight = size.height * 0.0355
                let notchRect = CGRect(x: (size.width - notchWidth) / 2, y: size.height * 0.0473, width: notchWidth, height: notchHeight)
                context.fill(Path(roundedRect: notchRect, cornerRadius: notchHeight / 2), with: .color(notchColor ?? color))
            }
        }
        .accessibilityHidden(true)
    }
}

/// A generic circular reader/terminal device — represents the tag/lock/terminal the phone taps
/// against (never the tap-zone marker's own aqua accent, since this is hardware, not guidance).
struct ReaderDeviceIllustration: View {
    let outerColor: Color
    let innerColor: Color

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let outerRadius = min(size.width, size.height) / 2
            context.fill(Path(ellipseIn: CGRect(x: center.x - outerRadius, y: center.y - outerRadius, width: outerRadius * 2, height: outerRadius * 2)), with: .color(outerColor))
            let innerRadius = min(size.width, size.height) * 0.31
            context.fill(Path(ellipseIn: CGRect(x: center.x - innerRadius, y: center.y - innerRadius, width: innerRadius * 2, height: innerRadius * 2)), with: .color(innerColor))
        }
        .accessibilityHidden(true)
    }
}

/// Overlays a pulsing `TapSenseLogo` ripple marker at a fractional position within `content` —
/// used to place the "here's where you'd tap" indicator on the Onboarding illustrations, whose
/// phone has no real antenna-zone data to position a marker from.
struct MarkerOverlay<Content: View>: View {
    let markerColor: Color
    let horizontalBias: CGFloat
    let verticalBias: CGFloat
    let markerSize: CGFloat
    let reducedMotion: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                content()
                TapSenseLogo(color: markerColor, size: markerSize, pulsing: true, reducedMotion: reducedMotion, singleRing: true)
                    .position(
                        x: proxy.size.width * (0.5 + horizontalBias / 2),
                        y: proxy.size.height * (0.5 + verticalBias / 2)
                    )
            }
        }
    }
}

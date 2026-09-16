import CoreGraphics
import Foundation

/// Geometry helpers shared by ``AntennaSilhouette`` and ``GuidedSweepAnimation`` so the marker
/// and the sweep highlight always line up pixel-for-pixel.
enum SilhouetteGeometry {
    /// Classic "fit inside, preserve aspect ratio" (letterbox/pillarbox) sizing.
    static func fitWithinBounds(_ bounds: CGSize, ratio: CGFloat) -> CGSize {
        guard bounds.width > 0, bounds.height > 0, ratio > 0 else { return .zero }
        let heightForFullWidth = bounds.width / ratio
        if heightForFullWidth <= bounds.height {
            return CGSize(width: bounds.width, height: heightForFullWidth)
        }
        let width = bounds.height * ratio
        return CGSize(width: width, height: bounds.height)
    }

    /// The offset to center a `fitWithinBounds` content size within the full bounds.
    static func centeringOffset(bounds: CGSize, content: CGSize) -> CGPoint {
        CGPoint(x: (bounds.width - content.width) / 2, y: (bounds.height - content.height) / 2)
    }

    static func markerRadius(contentSize: CGSize) -> CGFloat {
        contentSize.width * 0.38
    }

    static func aspectRatio(templateID: String, override: Float?) -> CGFloat {
        if let override, override > 0 { return CGFloat(override) }
        return SilhouetteShape.forTemplate(templateID).aspectRatio
    }
}

/// Which vector outline to draw for a given template id, and its aspect ratio.
enum SilhouetteShape {
    case bar
    case foldBookOpen
    case square
    case tablet

    var aspectRatio: CGFloat {
        switch self {
        case .bar: return 0.5
        case .foldBookOpen: return 1.1
        case .square: return 0.85
        case .tablet: return 0.72
        }
    }

    static func forTemplate(_ templateID: String) -> SilhouetteShape {
        switch templateID {
        case DeviceAntennaProfile.templateFoldBookOpen:
            return .foldBookOpen
        case DeviceAntennaProfile.templateFoldBookClosed:
            return .bar
        case DeviceAntennaProfile.templateFoldFlipOpen:
            return .bar
        case DeviceAntennaProfile.templateFoldFlipClosed:
            return .square
        case DeviceAntennaProfile.templateTablet:
            return .tablet
        case DeviceAntennaProfile.templateBar:
            return .bar
        default:
            return .bar
        }
    }

    /// Builds the outline path within `rect` (already the fitted content rect).
    func path(in rect: CGRect) -> CGPath {
        switch self {
        case .bar:
            return CGPath(roundedRect: rect, cornerWidth: rect.width * 0.18, cornerHeight: rect.width * 0.18, transform: nil)
        case .foldBookOpen:
            return CGPath(roundedRect: rect, cornerWidth: rect.width * 0.06, cornerHeight: rect.width * 0.06, transform: nil)
        case .square:
            return CGPath(roundedRect: rect, cornerWidth: rect.width * 0.22, cornerHeight: rect.width * 0.22, transform: nil)
        case .tablet:
            return CGPath(roundedRect: rect, cornerWidth: rect.width * 0.1, cornerHeight: rect.width * 0.1, transform: nil)
        }
    }

    /// `foldBookOpen` additionally draws a hinge seam line down the middle.
    var hasHingeSeam: Bool { self == .foldBookOpen }
}

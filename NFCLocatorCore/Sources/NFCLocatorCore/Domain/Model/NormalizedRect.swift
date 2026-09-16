import Foundation

/// A rectangle in `[0, 1]` normalized coordinates, relative to the phone's **back panel**,
/// viewed with the back facing the viewer, portrait, top edge up.
///
/// Any source that reports coordinates in a different frame (e.g. a screen-facing/front frame)
/// must transform into this convention before constructing a value. This convention is shared
/// with the catalog wire format, so entries stay compatible across client platforms regardless
/// of which coordinate frame a given data source natively reports in.
public struct NormalizedRect: Codable, Sendable, Equatable {
    public let x: Float
    public let y: Float
    public let width: Float
    public let height: Float

    private static let epsilon: Float = 0.001

    /// Thrown by the validating initializer when a rect falls outside `[0, 1]` or its edges
    /// would extend past the unit square. Callers that need "always valid" construction should
    /// use ``centeredSquare(centerX:centerY:side:)`` instead, which coerces rather than throws.
    public enum ValidationError: Error, Equatable {
        case outOfBounds(String)
    }

    /// Validating initializer. Callers that treat an invalid entry as "skip this one" (catalog
    /// mapping, cache row decoding) should call this via `try?`; callers that want a hard,
    /// unmissable programmer-error signal should use `try!`.
    public init(x: Float, y: Float, width: Float, height: Float) throws {
        guard (0...1).contains(x) else {
            throw ValidationError.outOfBounds("x must be in [0,1], was \(x)")
        }
        guard (0...1).contains(y) else {
            throw ValidationError.outOfBounds("y must be in [0,1], was \(y)")
        }
        guard (0...1).contains(width) else {
            throw ValidationError.outOfBounds("width must be in [0,1], was \(width)")
        }
        guard (0...1).contains(height) else {
            throw ValidationError.outOfBounds("height must be in [0,1], was \(height)")
        }
        guard x + width <= 1 + Self.epsilon else {
            throw ValidationError.outOfBounds("x + width must be <= 1, was \(x + width)")
        }
        guard y + height <= 1 + Self.epsilon else {
            throw ValidationError.outOfBounds("y + height must be <= 1, was \(y + height)")
        }
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    /// Unchecked initializer for call sites that have already established validity (e.g.
    /// ``centeredSquare(centerX:centerY:side:)``, which coerces its inputs into range).
    private init(uncheckedX x: Float, y: Float, width: Float, height: Float) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public var centerX: Float { x + width / 2 }
    public var centerY: Float { y + height / 2 }

    /// Builds a square rect of the given `side`, centered at `(centerX, centerY)`, coercing
    /// the top-left corner into `[0, 1 - side]` so the result is always a valid rect — never
    /// throws. This is the standard way ``GenericFallbackSource`` and the OS-antenna mapper
    /// build a marker zone from a single center point.
    public static func centeredSquare(centerX: Float, centerY: Float, side: Float) -> NormalizedRect {
        let clampedSide = side.clamped(to: 0...1)
        let rawX = centerX - clampedSide / 2
        let rawY = centerY - clampedSide / 2
        let x = rawX.clamped(to: 0...(1 - clampedSide))
        let y = rawY.clamped(to: 0...(1 - clampedSide))
        return NormalizedRect(uncheckedX: x, y: y, width: clampedSide, height: clampedSide)
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

import Foundation

extension DeviceAntennaProfile {
    private static let staleAfterDays = 180

    /// Maps the resolved profile to its UI-shaped state.
    public func toUIState(now: Date = Date()) -> AntennaLocatorUIState {
        switch confidence {
        case .exact, .approximate:
            return .resolvedMarker(
                AntennaLocatorUIState.ResolvedMarker(
                    formFactor: formFactor,
                    silhouetteTemplateID: silhouetteTemplateID,
                    antennaZone: antennaZone,
                    confidence: confidence,
                    source: source,
                    isStale: isStale(now: now),
                    aspectRatio: aspectRatio
                )
            )
        case .generic, .unknown:
            return .fallbackGuidance(
                AntennaLocatorUIState.FallbackGuidance(
                    formFactor: formFactor,
                    silhouetteTemplateID: silhouetteTemplateID,
                    approximateZone: antennaZone,
                    confidence: confidence,
                    tipTextKey: Self.tipTextKey(confidence: confidence, formFactor: formFactor),
                    aspectRatio: aspectRatio
                )
            )
        }
    }

    /// `.exact` is never stale. An `.approximate` entry with no `lastVerifiedAt` is always
    /// stale. Otherwise: stale if strictly more than 180 days old (180 exactly is *not* stale).
    func isStale(now: Date) -> Bool {
        guard confidence == .approximate else { return false }
        guard let lastVerifiedAt else { return true }
        let days = Calendar(identifier: .gregorian)
            .dateComponents([.day], from: lastVerifiedAt, to: now)
            .day ?? Int.max
        return days > Self.staleAfterDays
    }

    private static func tipTextKey(confidence: Confidence, formFactor: FormFactor) -> String {
        switch confidence {
        case .unknown:
            return "nfc_locator.sweep.unknown_tip"
        case .generic:
            switch formFactor {
            case .bar: return "nfc_locator.sweep.bar_tip"
            case .foldBook: return "nfc_locator.sweep.fold_book_tip"
            case .foldFlip: return "nfc_locator.sweep.fold_flip_tip"
            case .tablet: return "nfc_locator.sweep.tablet_tip"
            }
        case .exact, .approximate:
            // Unreachable in practice (these confidences build .resolvedMarker, not
            // .fallbackGuidance) — kept so the switch stays exhaustive rather than silently
            // dropping a future case.
            return "nfc_locator.sweep.generic_tip"
        }
    }
}

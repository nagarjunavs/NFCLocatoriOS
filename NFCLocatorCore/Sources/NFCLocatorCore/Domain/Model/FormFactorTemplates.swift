import Foundation

extension FormFactor {
    /// Maps `(FormFactor, FoldState)` to one of the six silhouette template ids drawn by
    /// ``AntennaSilhouette``. Mirrors `DeviceAntennaProfile`'s template-id constants.
    public func silhouetteTemplateID(foldState: FoldState) -> String {
        switch self {
        case .bar:
            return DeviceAntennaProfile.templateBar
        case .tablet:
            return DeviceAntennaProfile.templateTablet
        case .foldBook:
            return foldState == .folded
                ? DeviceAntennaProfile.templateFoldBookClosed
                : DeviceAntennaProfile.templateFoldBookOpen
        case .foldFlip:
            return foldState == .folded
                ? DeviceAntennaProfile.templateFoldFlipClosed
                : DeviceAntennaProfile.templateFoldFlipOpen
        }
    }
}

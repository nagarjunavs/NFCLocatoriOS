import Foundation

/// Flat route table — a bottom bar is shown/hidden per-route rather than via a nested
/// navigation graph.
enum Route: Hashable {
    case onboarding
    case home
    case myPhone
    case settings
    case phoneSelection
    case phoneConfirmed
    case tapGuide
    case tapTest
    case troubleshoot
    case education
    case privacy

    /// Routes that show the persistent bottom navigation bar.
    static let bottomBarRoutes: Set<Route> = [.home, .myPhone, .settings]
}

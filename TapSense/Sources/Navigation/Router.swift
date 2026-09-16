import Observation

/// A single flat, shared back stack for every screen except Splash (which is a phase gate, not
/// a stack entry; see `TapSenseRootView`). `root` is the dynamic "start of the visible stack"
/// (Onboarding or Home, depending on whether onboarding has been completed), `path` holds
/// everything pushed on top of it.
@MainActor
@Observable
final class Router {
    var root: Route = .onboarding
    var path: [Route] = []

    var current: Route { path.last ?? root }

    /// Splash -> Onboarding or Home, discarding Splash entirely (`popUpTo(SPLASH){inclusive}`).
    func finishSplash(onboardingCompleted: Bool) {
        root = onboardingCompleted ? .home : .onboarding
        path = []
    }

    func push(_ route: Route) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    /// `navigate(route) { popUpTo(currentTopRoute) { inclusive = true } }` — replaces the
    /// current top of stack instead of pushing on top of it.
    func replaceTop(with route: Route) {
        if path.isEmpty {
            root = route
        } else {
            path[path.count - 1] = route
        }
    }

    /// `navigateTopLevel` — a bottom-tab switch: clears every pushed screen and shows the tab's
    /// root fresh, matching `popUpTo(graph.startDestinationId){saveState=true}`.
    func navigateTopLevel(_ route: Route) {
        root = route
        path = []
    }
}

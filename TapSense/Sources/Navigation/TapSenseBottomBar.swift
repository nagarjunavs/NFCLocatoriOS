import SwiftUI

/// Bottom navigation: Home / My Phone / a center Tap Guide action / Settings. Tap Guide is a
/// full-screen flow pushed onto the stack, not a persistent tab — it has no state to preserve
/// the way Home/My Phone/Settings do.
///
/// Icons use SF Symbols (`house`, `iphone`, `gearshape`) — the platform-idiomatic choice for
/// standard navigation glyphs, unlike the brand-specific `TapSenseLogo` mark used for the
/// center FAB, which is drawn by hand.
struct TapSenseBottomBar: View {
    @Environment(\.tsColors) private var colors
    let currentRoute: Route
    let onHomeClick: () -> Void
    let onMyPhoneClick: () -> Void
    let onTapGuideClick: () -> Void
    let onSettingsClick: () -> Void

    /// This bar is added to each tab-root screen via `.safeAreaInset(edge: .bottom)` on the
    /// enclosing `NavigationStack` (see `TapSenseRootView`), not a hard frame — that reserves
    /// visual space but, confirmed by driving Home/My Phone/Settings in the Simulator, does not
    /// reliably add enough scrollable headroom for a `ScrollView`'s own last item to clear the
    /// bar once content is tall enough to need scrolling at all (My Phone's back-content state
    /// is the first screen tall enough to expose it). Rather than have each screen guess a
    /// padding value that can silently drift out of sync with this view's actual intrinsic
    /// height (raised FAB item + top/bottom padding — no explicit `.frame(height:)` exists to
    /// read instead), every scrollable tab-root screen adds this single, deliberately-generous
    /// constant as trailing content padding.
    static let reservedBottomClearance: CGFloat = 110

    /// Home/My Phone/Settings' natural height (18pt icon + 4pt spacing + `labelSmall`'s 14pt
    /// line height + the item's own 4pt top/bottom padding). `fabItem` is intrinsically much
    /// taller (52pt circle + spacing + label, ~71pt) before its `-14`/`-10` offsets shift it
    /// upward to produce the "raised" look — offsets reposition rendering only, they don't
    /// shrink layout size, so left unconstrained the row's height is driven by the *unshifted*
    /// FAB, not by what's actually visible. With `alignment: .top`, that stretched the whole bar
    /// far past its visible content, leaving a large band of dead surface-colored space below
    /// Home/My Phone/Settings that read as excess spacing above the home indicator (confirmed by
    /// sampling pixel rows directly: those three items' content ended around 60pt above where
    /// the row actually stopped). Constraining the row to this height keeps the bar sized to
    /// what's actually there — the FAB's circle still renders above this frame exactly as
    /// before, since SwiftUI doesn't clip a child's rendering to an ancestor's frame.
    private static let itemRowHeight: CGFloat = 44

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            item(systemImage: "house.fill", label: String(localized: "nav.home"), selected: currentRoute == .home, action: onHomeClick)
            Spacer()
            item(systemImage: "iphone", label: String(localized: "nav.my_phone"), selected: currentRoute == .myPhone, action: onMyPhoneClick)
            Spacer()
            fabItem
            Spacer()
            item(systemImage: "gearshape.fill", label: String(localized: "nav.settings"), selected: currentRoute == .settings, action: onSettingsClick)
        }
        .frame(height: Self.itemRowHeight, alignment: .top)
        .padding(.horizontal, 12)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background(colors.surface)
    }

    private func item(systemImage: String, label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        let color = selected ? colors.onSurface : colors.onSurfaceVariant
        return Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
                Text(label)
                    .tapSenseStyle(TapSenseType.labelSmall, color: color)
            }
            .padding(4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var fabItem: some View {
        let label = String(localized: "nav.tap_guide")
        return Button(action: onTapGuideClick) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(colors.primary)
                        .frame(width: 52, height: 52)
                    TapSenseLogo(color: colors.onPrimary, size: 24, singleRing: true)
                }
                .offset(y: -14)
                .shadow(color: colors.primary.opacity(0.4), radius: 8, x: 0, y: 4)
                Text(label)
                    .tapSenseStyle(TapSenseType.labelSmall, color: colors.primary)
                    .offset(y: -10)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

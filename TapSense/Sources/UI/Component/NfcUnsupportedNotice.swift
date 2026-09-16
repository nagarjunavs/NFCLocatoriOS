import SwiftUI

/// The "this device can't do that" notice for a screen that would otherwise show an antenna
/// tap-zone marker — a device with no NFC hardware at all has no antenna location to show, so
/// showing one anyway (as the resolver chain's generic-fallback heuristic otherwise would) is
/// actively misleading. Mirrors Tap Test's `NfcUnsupported` state treatment (same
/// icon/heading/message language) so the message reads the same everywhere a user can encounter
/// it, just recolored per host screen's background context.
struct NfcUnsupportedNotice: View {
    @Environment(\.tsColors) private var colors
    let heading: String
    let message: String
    var iconBackground: Color?
    var iconTint: Color?
    var headingColor: Color?
    var messageColor: Color?

    var body: some View {
        VStack {
            Circle()
                .fill(iconBackground ?? colors.surfaceVariant)
                .frame(width: 96, height: 96)
                .overlay(
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(iconTint ?? colors.onSurfaceVariant)
                )
            Text(heading)
                .tapSenseStyle(TapSenseType.titleSmall, color: headingColor ?? colors.onSurface)
                .multilineTextAlignment(.center)
                .padding(.top, 20)
            Text(message)
                .tapSenseStyle(TapSenseType.bodySmall, color: messageColor ?? colors.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
    }
}

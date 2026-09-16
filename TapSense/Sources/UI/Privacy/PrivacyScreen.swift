import SwiftUI

/// States only what the app's code actually does with data — each section below corresponds
/// directly to a real code path (Core NFC APIs, the catalog network call, local logging), not
/// boilerplate policy language.
struct PrivacyScreen: View {
    @Environment(\.tsColors) private var colors

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("privacy.title", bundle: .main)
                    .tapSenseStyle(TapSenseType.headlineSmall, color: colors.onSurface)
                    .padding(.top, 12)

                Text("privacy.disclaimer", bundle: .main)
                    .tapSenseStyle(TapSenseType.bodySmall, color: colors.onSurfaceVariant)

                PrivacySection(titleKey: "privacy.on_device_title", bodyKey: "privacy.on_device_body")
                PrivacySection(titleKey: "privacy.catalog_title", bodyKey: "privacy.catalog_body")
                PrivacySection(titleKey: "privacy.analytics_title", bodyKey: "privacy.analytics_body")
                PrivacySection(titleKey: "privacy.permissions_title", bodyKey: "privacy.permissions_body")
                PrivacySection(titleKey: "privacy.third_party_title", bodyKey: "privacy.third_party_body")
                PrivacySection(titleKey: "privacy.retention_title", bodyKey: "privacy.retention_body")

                Spacer().frame(height: 24)
            }
            .padding(.horizontal, 24)
        }
        .background(colors.background)
    }
}

private struct PrivacySection: View {
    @Environment(\.tsColors) private var colors
    let titleKey: String.LocalizationValue
    let bodyKey: String.LocalizationValue

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: titleKey))
                .tapSenseStyle(TapSenseType.titleSmall, color: colors.onSurface)
            Text(String(localized: bodyKey))
                .tapSenseStyle(TapSenseType.bodySmall, color: colors.onSurfaceVariant)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colors.surfaceVariant)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

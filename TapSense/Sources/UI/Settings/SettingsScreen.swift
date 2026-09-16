import SwiftUI
import NFCLocatorCore

struct SettingsScreen: View {
    @Environment(\.appEnvironment) private var env
    @Environment(\.tsColors) private var colors
    @Environment(Router.self) private var router

    private var settings: TapSenseSettings { env?.settingsStore.settings ?? TapSenseSettings() }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("settings.title", bundle: .main)
                    .tapSenseStyle(TapSenseType.headlineSmall, color: colors.onSurface)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                SettingsRow(label: String(localized: "settings.phone_model")) {
                    router.push(.phoneSelection)
                } trailing: {
                    Text(verbatim: "\(phoneLabel)  ›")
                        .tapSenseStyle(TapSenseType.bodyMedium, color: colors.onSurfaceVariant)
                        .accessibilityHidden(true)
                }
                .accessibilityValue(phoneLabel)
                Divider().background(colors.outlineVariant)

                SettingsRow(label: String(localized: "settings.haptics"), onClick: nil) {
                    Toggle(String(localized: "settings.haptics"), isOn: Binding(
                        get: { settings.hapticsEnabled },
                        set: { env?.settingsStore.setHapticsEnabled($0) }
                    ))
                    .labelsHidden()
                    .tint(colors.primary)
                }
                Divider().background(colors.outlineVariant)

                SettingsRow(label: String(localized: "settings.reduce_motion"), onClick: nil) {
                    Toggle(String(localized: "settings.reduce_motion"), isOn: Binding(
                        get: { settings.reduceMotion },
                        set: { env?.settingsStore.setReduceMotion($0) }
                    ))
                    .labelsHidden()
                    .tint(colors.primary)
                }
                Divider().background(colors.outlineVariant)

                VStack(alignment: .leading, spacing: 8) {
                    Text("settings.appearance", bundle: .main)
                        .tapSenseStyle(TapSenseType.bodyMedium, color: colors.onSurface)
                    HStack(spacing: 8) {
                        appearanceChip(.system, label: String(localized: "settings.appearance_system"))
                        appearanceChip(.light, label: String(localized: "settings.appearance_light"))
                        appearanceChip(.dark, label: String(localized: "settings.appearance_dark"))
                    }
                }
                .padding(.vertical, 12)
                Divider().background(colors.outlineVariant)

                SettingsRow(label: String(localized: "settings.help_center")) {
                    router.push(.troubleshoot)
                } trailing: {
                    Text(verbatim: "›")
                        .tapSenseStyle(TapSenseType.bodyMedium, color: colors.onSurfaceVariant)
                        .accessibilityHidden(true)
                }
                Divider().background(colors.outlineVariant)

                SettingsRow(label: String(localized: "settings.privacy")) {
                    router.push(.privacy)
                } trailing: {
                    Text(verbatim: "›")
                        .tapSenseStyle(TapSenseType.bodyMedium, color: colors.onSurfaceVariant)
                        .accessibilityHidden(true)
                }

                Text(L10n("settings.version", appVersionString))
                    .tapSenseStyle(TapSenseType.bodySmall, color: colors.onSurfaceVariant)
                    .padding(.vertical, 16)
            }
            .padding(.horizontal, 24)
            // See `TapSenseBottomBar.reservedBottomClearance` — same defensive reservation as
            // Home/My Phone, which share this exact ScrollView-over-a-floating-tab-bar pattern.
            .padding(.bottom, TapSenseBottomBar.reservedBottomClearance)
        }
        .background(colors.background)
    }

    private var phoneLabel: String {
        settings.hasManualPhoneOverride ? (settings.model ?? "").friendlyModelName() : String(localized: "settings.phone_auto")
    }

    private var appVersionString: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private func appearanceChip(_ mode: AppearanceMode, label: String) -> some View {
        let selected = settings.appearanceMode == mode
        return Button {
            env?.settingsStore.setAppearanceMode(mode)
        } label: {
            Text(label)
                .tapSenseStyle(TapSenseType.labelLarge, color: selected ? colors.onSecondaryContainer : colors.onSurfaceVariant)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(selected ? colors.secondaryContainer : colors.surfaceVariant)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private struct SettingsRow<Trailing: View>: View {
    @Environment(\.tsColors) private var colors
    let label: String
    var onClick: (() -> Void)?
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        Group {
            if let onClick {
                Button(action: onClick) { content }
                    .buttonStyle(.plain)
            } else {
                content
            }
        }
    }

    private var content: some View {
        HStack {
            Text(label).tapSenseStyle(TapSenseType.bodyMedium, color: colors.onSurface)
            Spacer()
            trailing()
        }
        .padding(.vertical, 13)
        .contentShape(Rectangle())
    }
}

import SwiftUI
import NFCLocatorCore

private enum PhoneSide { case back, front }

struct MyPhoneScreen: View {
    @Environment(\.appEnvironment) private var env
    @Environment(\.tsColors) private var colors
    @Environment(Router.self) private var router
    @State private var viewModel = MyPhoneViewModel()
    @State private var side: PhoneSide = .back

    private var settings: TapSenseSettings { env?.settingsStore.settings ?? TapSenseSettings() }
    private var isNfcSupported: Bool { env?.nfcStateObserver.isNfcSupported ?? false }
    private var showNfcUnsupported: Bool { !viewModel.uiState.isLoading && !isNfcSupported && !settings.hasManualPhoneOverride }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.uiState.displayManufacturer)
                        .tapSenseStyle(TapSenseType.bodySmall, color: colors.onSurfaceVariant)
                    Text(viewModel.uiState.displayModel.isEmpty ? " " : viewModel.uiState.displayModel)
                        .tapSenseStyle(TapSenseType.headlineSmall, color: colors.onSurface)
                }
                .padding(.top, 12)
                .padding(.bottom, 8)

                if !showNfcUnsupported {
                    SideToggle(selected: side) { side = $0 }
                        .padding(.vertical, 8)
                }

                Group {
                    if viewModel.uiState.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 280)
                    } else if showNfcUnsupported {
                        VStack {
                            NfcUnsupportedNotice(
                                heading: String(localized: "home.nfc_unsupported"),
                                message: String(localized: "my_phone.nfc_unsupported_body")
                            )
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 280)
                    } else if side == .front {
                        frontContent
                    } else {
                        backContent
                    }
                }
            }
            .padding(.horizontal, 24)
            // See `TapSenseBottomBar.reservedBottomClearance` — without this, the back-content
            // state's "Test this location" button is left behind the floating tab bar with no
            // way to scroll far enough to reach it (confirmed by driving this screen directly).
            .padding(.bottom, TapSenseBottomBar.reservedBottomClearance)
        }
        .background(colors.background)
        .task(id: PhoneOverrideKey(settings: settings)) {
            guard let env else { return }
            await viewModel.resolveCurrent(env: env)
        }
    }

    @ViewBuilder
    private var backContent: some View {
        HStack {
            Spacer()
            AntennaMarker(
                state: viewModel.uiState.antennaState,
                reducedMotion: settings.reduceMotion,
                markerColor: TapSensePalette.aqua,
                silhouetteColor: DarkMockupColors.myPhoneBackBodyColor(colors),
                showCameraBump: true,
                cameraBumpColor: DarkMockupColors.cameraBumpAccentColor(colors),
                silhouetteBorderColor: DarkMockupColors.myPhoneBackBorderColor(colors)
            )
            .frame(width: 150, height: 300)
            Spacer()
        }

        if let confidence = viewModel.uiState.antennaState.confidenceOrNil {
            HStack {
                Spacer()
                ConfidenceChip(confidence: confidence)
                Spacer()
            }
            .padding(.top, 14)
        }

        Text("my_phone.zone_description", bundle: .main)
            .tapSenseStyle(TapSenseType.bodyMedium, color: colors.onSurfaceVariant)
            .padding(.top, 8)

        Text("my_phone.case_warning", bundle: .main)
            .tapSenseStyle(TapSenseType.bodySmall, color: colors.onTertiaryContainer)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(colors.tertiaryContainer)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.top, 12)

        VStack(alignment: .leading, spacing: 0) {
            Text("my_phone.orientation_header", bundle: .main)
                .tapSenseStyle(TapSenseType.labelSmall, color: colors.onSurfaceVariant)
            OrientationRow(text: String(localized: "my_phone.orientation_back_contact"))
        }
        .padding(.top, 16)

        Button {
            router.push(.tapTest)
        } label: {
            Text("my_phone.test_location", bundle: .main)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.tapSenseFilled)
        .padding(.top, 16)
        .padding(.bottom, 24)
    }

    @ViewBuilder
    private var frontContent: some View {
        HStack {
            Spacer()
            PhoneSilhouette(
                color: DarkMockupColors.darkCardSilhouetteColor(colors),
                screenInset: true,
                insetColor: DarkMockupColors.screenInsetColor(colors),
                notchColor: DarkMockupColors.screenNotchColor(colors)
            )
            .frame(width: 150, height: 300)
            Spacer()
        }

        HStack {
            Spacer()
            NotApplicableBadge()
            Spacer()
        }
        .padding(.top, 14)

        Text("my_phone.front_body", bundle: .main)
            .tapSenseStyle(TapSenseType.bodyMedium, color: colors.onSurfaceVariant)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 8)

        Text("my_phone.front_banner", bundle: .main)
            .tapSenseStyle(TapSenseType.bodySmall, color: colors.onSurfaceVariant)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(colors.surfaceVariant)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.top, 12)

        Button {
            side = .back
        } label: {
            Text("my_phone.view_back_placement", bundle: .main)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.tapSenseFilled)
        .padding(.top, 20)
        .padding(.bottom, 24)
    }
}

/// My Phone Front tab's "this isn't the antenna side" indicator — a UI-only state, distinct
/// from `ConfidenceChip`'s resolver-confidence tiers.
private struct NotApplicableBadge: View {
    @Environment(\.tsColors) private var colors

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .stroke(colors.isDark ? TapSensePalette.textLightSecondary : TapSensePalette.ink3, lineWidth: 1.4)
                .frame(width: 10, height: 10)
            Text("my_phone.not_applicable", bundle: .main)
                .tapSenseStyle(TapSenseType.labelSmall, color: colors.onSurfaceVariant)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(colors.surfaceVariant)
        .clipShape(Capsule())
    }
}

private struct SideToggle: View {
    @Environment(\.tsColors) private var colors
    let selected: PhoneSide
    let onSelect: (PhoneSide) -> Void

    var body: some View {
        let trackColor = colors.isDark ? TapSensePalette.toggleTrackDark : TapSensePalette.toggleTrackLight
        let selectedTabColor = colors.isDark ? TapSensePalette.toggleTabSelectedDark : colors.surface

        HStack(spacing: 0) {
            tab(String(localized: "my_phone.tab_back"), isSelected: selected == .back, selectedTabColor: selectedTabColor) { onSelect(.back) }
            tab(String(localized: "my_phone.tab_front"), isSelected: selected == .front, selectedTabColor: selectedTabColor) { onSelect(.front) }
        }
        .padding(4)
        .background(trackColor)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func tab(_ label: String, isSelected: Bool, selectedTabColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .tapSenseStyle(TapSenseType.titleSmall, color: isSelected ? colors.onSurface : colors.onSurfaceVariant)
                .padding(.horizontal, 20)
                .frame(minHeight: 44)
                .background(isSelected ? selectedTabColor : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 11))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(2)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct OrientationRow: View {
    @Environment(\.tsColors) private var colors
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Circle().fill(colors.primary).frame(width: 6, height: 6)
            Text(text).tapSenseStyle(TapSenseType.bodyMedium, color: colors.onSurface)
        }
        .padding(.vertical, 6)
    }
}

private struct PhoneOverrideKey: Equatable {
    let manufacturer: String?
    let model: String?
    let formFactor: String?

    init(settings: TapSenseSettings) {
        manufacturer = settings.manufacturer
        model = settings.model
        formFactor = settings.formFactor?.rawValue
    }
}

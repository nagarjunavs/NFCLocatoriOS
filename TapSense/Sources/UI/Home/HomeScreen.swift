import SwiftUI
import NFCLocatorCore

struct HomeScreen: View {
    @Environment(\.appEnvironment) private var env
    @Environment(\.tsColors) private var colors
    @Environment(Router.self) private var router
    @State private var viewModel = HomeViewModel()

    private var settings: TapSenseSettings { env?.settingsStore.settings ?? TapSenseSettings() }
    private var isNfcSupported: Bool { env?.nfcStateObserver.isNfcSupported ?? false }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(settings.hasManualPhoneOverride ? String(localized: "home.previewing_label") : timeOfDayGreeting())
                        .tapSenseStyle(TapSenseType.bodySmall, color: colors.onSurfaceVariant)
                    Text(viewModel.uiState.displayModel.isEmpty ? " " : viewModel.uiState.displayModel)
                        .tapSenseStyle(TapSenseType.headlineSmall, color: colors.onSurface)
                }
                .padding(.top, 12)

                deviceCard
                    .padding(.vertical, 16)

                HStack(spacing: 10) {
                    Button {
                        router.push(.tapGuide)
                    } label: {
                        Text("home.start_tap_guide", bundle: .main)
                    }
                    .buttonStyle(TapSenseFilledButtonStyle(fullWidth: false))
                    .frame(maxWidth: .infinity)

                    Button {
                        router.push(.phoneSelection)
                    } label: {
                        Text("home.change_phone", bundle: .main)
                    }
                    .buttonStyle(TapSenseOutlinedButtonStyle(fullWidth: false))
                }

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(colors.onTertiaryContainer)
                        .accessibilityHidden(true)
                    Text("home.tip_case", bundle: .main)
                        .tapSenseStyle(TapSenseType.bodySmall, color: colors.onTertiaryContainer)
                }
                .padding(16)
                .background(colors.tertiaryContainer)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.top, 16)

                Button {
                    router.push(.troubleshoot)
                } label: {
                    Text("home.tap_not_working", bundle: .main)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.tapSenseText)
                .padding(.top, 30)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            // See `TapSenseBottomBar.reservedBottomClearance` — this screen's content doesn't
            // reach the bar today, but shares MyPhoneScreen's exact layout pattern (same fix
            // applied there after driving it directly exposed the bug), so the same headroom is
            // reserved defensively rather than waiting for a future addition to hit it too.
            .padding(.bottom, TapSenseBottomBar.reservedBottomClearance)
        }
        .background(colors.background)
        .task(id: PhoneOverrideKey(settings: settings)) {
            guard let env else { return }
            await viewModel.resolveCurrent(env: env)
        }
    }

    @ViewBuilder
    private var deviceCard: some View {
        VStack {
            if viewModel.uiState.isLoading {
                ProgressView()
                    .tint(TapSensePalette.aqua)
            } else if !isNfcSupported && !settings.hasManualPhoneOverride {
                // A device with no NFC hardware at all has no real antenna to point at -
                // showing a tap zone (as the resolver's generic fallback otherwise would) would
                // be actively misleading, not just imprecise. Manual-override previews are
                // exempt: the antenna belongs to the previewed model, not this physical device.
                NfcUnsupportedNotice(
                    heading: String(localized: "home.nfc_unsupported"),
                    message: String(localized: "home.nfc_unsupported_body"),
                    iconBackground: Color.white.opacity(0.08),
                    iconTint: TapSensePalette.textLightSecondary,
                    headingColor: TapSensePalette.textLight,
                    messageColor: TapSensePalette.textLightSecondary
                )
            } else {
                if let confidence = viewModel.uiState.antennaState.confidenceOrNil {
                    HStack {
                        ConfidenceChip(confidence: confidence, onDarkCard: true)
                        Spacer()
                    }
                    .padding(.bottom, 14)
                }
                AntennaMarker(
                    state: viewModel.uiState.antennaState,
                    reducedMotion: settings.reduceMotion,
                    markerColor: TapSensePalette.aqua,
                    silhouetteColor: TapSensePalette.phoneBody,
                    showCameraBump: true,
                    cameraBumpColor: DarkMockupColors.cameraBumpAccentColor(colors),
                    silhouetteBorderColor: TapSensePalette.phoneBodyBorder
                )
                .frame(width: 120, height: 230)

                Text(viewModel.uiState.antennaState.isGuidedSweep ? String(localized: "home.tap_area_estimated") : String(localized: "home.tap_area_recommended"))
                    .tapSenseStyle(TapSenseType.bodyMedium, color: TapSensePalette.textLightSecondary)
                    .padding(.top, 12)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(DarkMockupColors.darkCardBackgroundColor(colors))
        .clipShape(RoundedRectangle(cornerRadius: 28))
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

private func timeOfDayGreeting() -> String {
    let hour = Calendar.current.component(.hour, from: Date())
    switch hour {
    case 5...11: return String(localized: "home.greeting_morning")
    case 12...17: return String(localized: "home.greeting_afternoon")
    default: return String(localized: "home.greeting_evening")
    }
}

extension AntennaLocatorUIState {
    var confidenceOrNil: Confidence? {
        switch self {
        case .resolvedMarker(let marker): return marker.confidence
        case .fallbackGuidance(let guidance): return guidance.confidence
        case .loading, .error: return nil
        }
    }
}

import SwiftUI
import NFCLocatorCore

struct OnboardingScreen: View {
    @Environment(\.appEnvironment) private var env
    @Environment(\.tsColors) private var colors
    @Environment(Router.self) private var router
    @State private var viewModel = OnboardingViewModel()
    @State private var currentPage = 0

    var reducedMotion: Bool { env?.settingsStore.settings.reduceMotion ?? false }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    complete()
                } label: {
                    Text("onboarding.skip", bundle: .main)
                }
                .buttonStyle(.tapSenseText)
            }
            .padding(16)

            TabView(selection: $currentPage) {
                OnboardingPage(
                    title: String(localized: "onboarding.page1_title"),
                    message: String(localized: "onboarding.page1_body"),
                    reducedMotion: reducedMotion,
                    showReaderDevice: false
                )
                .tag(0)

                OnboardingPage(
                    title: String(localized: "onboarding.page2_title"),
                    message: String(localized: "onboarding.page2_body"),
                    reducedMotion: reducedMotion,
                    showReaderDevice: true
                )
                .tag(1)

                OnboardingFinalPage(autoDetectedProfile: viewModel.autoDetectedProfile)
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            PageIndicator(pageCount: 3, currentPage: currentPage)
                .padding(.bottom, 20)

            VStack(spacing: 8) {
                if currentPage < 2 {
                    Button {
                        withAnimation { currentPage += 1 }
                    } label: {
                        Text("onboarding.continue", bundle: .main)
                    }
                    .buttonStyle(.tapSenseFilled)
                } else {
                    Button {
                        complete()
                    } label: {
                        Text("onboarding.get_started", bundle: .main)
                    }
                    .buttonStyle(.tapSenseFilled)

                    Button {
                        router.push(.phoneSelection)
                    } label: {
                        Text("phone_confirmed.choose_different", bundle: .main)
                    }
                    .buttonStyle(.tapSenseText)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)

            Spacer().frame(height: 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.background)
        .task {
            if let env { await viewModel.load(env: env) }
        }
    }

    private func complete() {
        guard let env else { return }
        viewModel.completeOnboarding(env: env) {
            router.navigateTopLevel(.home)
        }
    }
}

private struct OnboardingPage: View {
    @Environment(\.tsColors) private var colors
    let title: String
    let message: String
    let reducedMotion: Bool
    let showReaderDevice: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if showReaderDevice {
                    HStack(spacing: 12) {
                        MarkerOverlay(markerColor: colors.primary, horizontalBias: 0, verticalBias: 0, markerSize: 64, reducedMotion: reducedMotion) {
                            PhoneSilhouette(color: TapSensePalette.phoneBody, cameraBump: true, bumpColor: DarkMockupColors.cameraBumpAccentColor(colors), borderColor: TapSensePalette.phoneBodyBorder)
                        }
                        .frame(width: 130, height: 280)

                        ReaderDeviceIllustration(outerColor: TapSensePalette.readerOuter, innerColor: TapSensePalette.readerInner)
                            .frame(width: 120, height: 120)
                    }
                } else {
                    MarkerOverlay(markerColor: colors.primary, horizontalBias: 0, verticalBias: -0.5, markerSize: 72, reducedMotion: reducedMotion) {
                        PhoneSilhouette(color: TapSensePalette.phoneBody, cameraBump: true, bumpColor: DarkMockupColors.cameraBumpAccentColor(colors), borderColor: TapSensePalette.phoneBodyBorder)
                    }
                    .frame(width: 150, height: 320)
                }

                Spacer().frame(height: 32)

                Text(title)
                    .tapSenseStyle(TapSenseType.headlineLarge, color: colors.onSurface)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                Spacer().frame(height: 12)

                Text(message)
                    .tapSenseStyle(TapSenseType.bodyLarge, color: colors.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 32)
            .frame(minHeight: 500)
        }
    }
}

private struct OnboardingFinalPage: View {
    @Environment(\.tsColors) private var colors
    let autoDetectedProfile: DeviceAntennaProfile?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                MarkerOverlay(markerColor: colors.primary, horizontalBias: 0, verticalBias: -0.5, markerSize: 72, reducedMotion: false) {
                    PhoneSilhouette(color: TapSensePalette.phoneBody, cameraBump: true, bumpColor: DarkMockupColors.cameraBumpAccentColor(colors), borderColor: TapSensePalette.phoneBodyBorder)
                }
                .frame(width: 140, height: 300)

                Spacer().frame(height: 24)

                Text("onboarding.page3_title", bundle: .main)
                    .tapSenseStyle(TapSenseType.headlineLarge, color: colors.onSurface)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 12)

                Text("onboarding.page3_body", bundle: .main)
                    .tapSenseStyle(TapSenseType.bodyLarge, color: colors.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 24)

                HStack(spacing: 12) {
                    if let autoDetectedProfile {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(autoDetectedProfile.model.friendlyModelName())
                                .tapSenseStyle(TapSenseType.titleSmall, color: colors.onSurface)
                            Text(autoDetectedProfile.manufacturer.capitalizingFirstLetter())
                                .tapSenseStyle(TapSenseType.bodySmall, color: colors.onSurfaceVariant)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        ConfidenceChip(confidence: autoDetectedProfile.confidence)
                    } else {
                        Text("phone_selection.loading", bundle: .main)
                            .tapSenseStyle(TapSenseType.bodyMedium, color: colors.onSurface)
                    }
                }
                .padding(16)
                .background(colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .padding(.horizontal, 32)
            .frame(minHeight: 500)
        }
    }
}

private struct PageIndicator: View {
    @Environment(\.tsColors) private var colors
    let pageCount: Int
    let currentPage: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<pageCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(index == currentPage ? colors.secondary : colors.outline)
                    .frame(width: index == currentPage ? 20 : 6, height: 6)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

extension String {
    func capitalizingFirstLetter() -> String {
        guard let first else { return self }
        return first.uppercased() + dropFirst()
    }
}

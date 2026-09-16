import SwiftUI
import NFCLocatorCore

struct TapGuideScreen: View {
    @Environment(\.appEnvironment) private var env
    @Environment(\.tsColors) private var colors
    @Environment(Router.self) private var router
    @State private var viewModel = TapGuideViewModel()
    @State private var currentStep = 0
    @State private var sweepOffset: CGFloat = -6

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    router.pop()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(colors.onSurfaceVariant)
                        .frame(width: 32, height: 32)
                        .background(colors.surfaceVariant)
                        .clipShape(Circle())
                }
                .accessibilityLabel(String(localized: "tap_guide.close_content_description"))
            }
            .padding(.top, 8)
            .padding(.trailing, 16)

            HStack(spacing: 20) {
                if let state = viewModel.uiState.antennaState {
                    AntennaMarker(
                        state: state,
                        reducedMotion: viewModel.uiState.reduceMotion,
                        markerColor: TapSensePalette.aqua,
                        silhouetteColor: DarkMockupColors.tapGuideBodyColor(colors),
                        showCameraBump: true,
                        cameraBumpColor: DarkMockupColors.cameraBumpAccentColor(colors),
                        silhouetteBorderColor: DarkMockupColors.tapGuideBorderColor(colors)
                    )
                    .frame(width: 140, height: 300)
                    .offset(x: sweepOffset)

                    ReaderDeviceIllustration(
                        outerColor: colors.isDark ? TapSensePalette.readerOuter : TapSensePalette.readerOuterLight,
                        innerColor: colors.isDark ? TapSensePalette.readerInner : TapSensePalette.readerInnerLight
                    )
                    .frame(width: 150, height: 150)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(alignment: .leading, spacing: 0) {
                Text(L10n("tap_guide.step_of", currentStep + 1, tapGuideSteps.count))
                    .tapSenseStyle(TapSenseType.labelMedium, color: colors.primary)
                Text(String(localized: tapGuideSteps[currentStep].titleKey))
                    .tapSenseStyle(TapSenseType.titleLarge, color: colors.onBackground)
                    .padding(.top, 8)
                Text(String(localized: tapGuideSteps[currentStep].bodyKey))
                    .tapSenseStyle(TapSenseType.bodyMedium, color: colors.onSurfaceVariant)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
            }
            .padding(.horizontal, 28)

            HStack(spacing: 6) {
                ForEach(0..<tapGuideSteps.count, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index <= currentStep ? colors.primary : colors.outline)
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 28)

            VStack {
                if currentStep < tapGuideSteps.count - 1 {
                    Button {
                        currentStep += 1
                    } label: {
                        Text("tap_guide.next", bundle: .main)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.tapSenseFilled)
                } else {
                    Button {
                        router.push(.tapTest)
                    } label: {
                        Text("tap_guide.step5_action", bundle: .main)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.tapSenseFilled)
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.background)
        .task {
            guard let env else { return }
            await viewModel.load(env: env)
            if !env.nfcStateObserver.isNfcSupported {
                // A device with no NFC hardware can never complete the walkthrough's end goal
                // (a real tap test), so skip the guided steps entirely and land straight on Tap
                // Test's own "no NFC hardware" screen rather than a near-duplicate message here.
                router.replaceTop(with: .tapTest)
                return
            }
            if !viewModel.uiState.reduceMotion {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    sweepOffset = 6
                }
            }
        }
    }
}

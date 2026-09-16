import SwiftUI
import UIKit
import NFCLocatorCore

/// The real "does this tap zone actually work" flow: registers a live Core NFC reader session
/// for as long as this screen is on screen, driven by `TapTestViewModel`. Reader-session
/// start/stop is tied to this view's lifetime via `.task`'s own cancellation, not a separate
/// lifecycle callback.
///
/// `startListening()` is called from inside the same `.task` that creates the view model, not
/// a separate `.onAppear` — `.onAppear` fires synchronously and would race the `.task`'s async
/// view-model creation, silently no-op'ing through the `viewModel?` optional and leaving the
/// reader session never actually started (caught by running this screen in the Simulator: the
/// state stuck on "Detecting…" instead of resolving to "no NFC hardware").
///
/// The Core NFC session start is additionally held back by `Constants.readerStartDelay` past
/// that: `.task` fires as soon as this screen is inserted into the navigation stack, which is
/// the *start* of the push transition, not after it settles. Calling `NFCTagReaderSession.begin()`
/// while the screen is still mid-transition is a known way to get the session rejected
/// immediately — invalidated before it ever becomes active, so the system "Hold Near the Top of
/// iPhone" sheet never even appears — which is indistinguishable from a real device with no NFC
/// entitlement provisioned. Waiting for the transition to finish first avoids that failure mode
/// entirely, independent of whatever else `onSessionEnded`'s `becameActive` flag is for.
struct TapTestScreen: View {
    @Environment(\.appEnvironment) private var env
    @Environment(\.tsColors) private var colors
    @Environment(Router.self) private var router
    @State private var viewModel: TapTestViewModel?

    private enum Constants {
        static let readerStartDelay = Duration.milliseconds(500)
    }

    var body: some View {
        Group {
            if let viewModel {
                content(viewModel)
            } else {
                Color.clear
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.background)
        .task {
            guard let env, viewModel == nil else { return }
            let vm = TapTestViewModel(readerModeController: env.makeReaderModeController(), isNfcSupported: env.nfcStateObserver.isNfcSupported)
            viewModel = vm
            try? await Task.sleep(for: Constants.readerStartDelay)
            guard !Task.isCancelled else { return }
            vm.startListening()
            await vm.loadAntennaState(env: env)
        }
        .onDisappear {
            viewModel?.stopListening()
        }
    }

    @ViewBuilder
    private func content(_ viewModel: TapTestViewModel) -> some View {
        VStack(spacing: 0) {
            Text("tap_test.title", bundle: .main)
                .tapSenseStyle(TapSenseType.headlineSmall, color: colors.onSurface)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)
                .padding(.bottom, 8)

            VStack {
                switch viewModel.uiState {
                case .ready, .detecting:
                    DetectingContent(antennaState: viewModel.antennaState, reducedMotion: env?.settingsStore.settings.reduceMotion ?? false)
                case .detected:
                    DetectedContent()
                case .timedOut:
                    TimedOutContent()
                case .readerUnavailable:
                    ReaderUnavailableContent()
                case .nfcUnsupported:
                    NfcUnsupportedContent()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            actions(viewModel)
                .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
        .onChange(of: viewModel.uiState) { _, newValue in
            guard newValue == .detected, env?.settingsStore.settings.hapticsEnabled == true else { return }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    @ViewBuilder
    private func actions(_ viewModel: TapTestViewModel) -> some View {
        switch viewModel.uiState {
        case .ready, .detecting:
            Button {
                router.pop()
            } label: {
                Text("tap_test.cancel", bundle: .main).frame(maxWidth: .infinity)
            }
            .buttonStyle(.tapSenseOutlined)
        case .detected:
            HStack(spacing: 10) {
                Button {
                    viewModel.retry()
                } label: {
                    Text("tap_test.tap_again", bundle: .main).frame(maxWidth: .infinity)
                }
                .buttonStyle(.tapSenseOutlined)
                Button {
                    router.pop()
                } label: {
                    Text("tap_test.cancel", bundle: .main).frame(maxWidth: .infinity)
                }
                .buttonStyle(.tapSenseFilled)
            }
        case .timedOut, .readerUnavailable:
            Button {
                viewModel.retry()
            } label: {
                Text("tap_test.try_again", bundle: .main).frame(maxWidth: .infinity)
            }
            .buttonStyle(.tapSenseFilled)
        case .nfcUnsupported:
            Button {
                router.pop()
            } label: {
                Text("tap_test.cancel", bundle: .main).frame(maxWidth: .infinity)
            }
            .buttonStyle(.tapSenseOutlined)
        }
    }
}

private struct DetectingContent: View {
    @Environment(\.tsColors) private var colors
    let antennaState: AntennaLocatorUIState?
    let reducedMotion: Bool

    var body: some View {
        Group {
            if let antennaState {
                AntennaMarker(
                    state: antennaState,
                    reducedMotion: reducedMotion,
                    markerColor: TapSensePalette.aqua,
                    silhouetteColor: TapSensePalette.phoneBody,
                    showCameraBump: true,
                    cameraBumpColor: DarkMockupColors.cameraBumpAccentColor(colors),
                    silhouetteBorderColor: TapSensePalette.phoneBodyBorder
                )
                .frame(width: 147, height: 320)
            } else {
                ProgressView()
                    .tint(colors.primary)
                    .frame(width: 64, height: 64)
            }
        }
        Text("tap_test.state_detecting", bundle: .main)
            .tapSenseStyle(TapSenseType.titleSmall, color: colors.onSurface)
            .padding(.top, 20)
        Text("tap_test.hint_detecting", bundle: .main)
            .tapSenseStyle(TapSenseType.bodySmall, color: colors.onSurfaceVariant)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
            .padding(.top, 8)
    }
}

private struct DetectedContent: View {
    @Environment(\.tsColors) private var colors

    var body: some View {
        StatusIcon(systemImage: "checkmark.circle.fill", background: colors.primaryContainer, tint: TapSensePalette.success)
        Text("tap_test.state_detected", bundle: .main)
            .tapSenseStyle(TapSenseType.titleSmall, color: colors.onSurface)
            .padding(.top, 20)
        Text("tap_test.hint_detected", bundle: .main)
            .tapSenseStyle(TapSenseType.bodySmall, color: colors.onSurfaceVariant)
            .padding(.top, 8)
    }
}

private struct TimedOutContent: View {
    @Environment(\.tsColors) private var colors

    var body: some View {
        StatusIcon(systemImage: "exclamationmark.triangle.fill", background: colors.tertiaryContainer, tint: colors.onTertiaryContainer)
        Text("tap_test.state_timed_out", bundle: .main)
            .tapSenseStyle(TapSenseType.titleSmall, color: colors.onSurface)
            .padding(.top, 20)
        Text("tap_test.hint_timed_out", bundle: .main)
            .tapSenseStyle(TapSenseType.bodySmall, color: colors.onSurfaceVariant)
            .multilineTextAlignment(.leading)
            .padding(.top, 8)
    }
}

private struct ReaderUnavailableContent: View {
    @Environment(\.tsColors) private var colors

    var body: some View {
        StatusIcon(systemImage: "exclamationmark.triangle.fill", background: colors.tertiaryContainer, tint: colors.onTertiaryContainer)
        Text("tap_test.state_reader_unavailable", bundle: .main)
            .tapSenseStyle(TapSenseType.titleSmall, color: colors.onSurface)
            .padding(.top, 20)
        Text("tap_test.hint_reader_unavailable", bundle: .main)
            .tapSenseStyle(TapSenseType.bodySmall, color: colors.onSurfaceVariant)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
            .padding(.top, 8)
    }
}

private struct NfcUnsupportedContent: View {
    @Environment(\.tsColors) private var colors

    var body: some View {
        StatusIcon(systemImage: "exclamationmark.triangle.fill", background: colors.surfaceVariant, tint: colors.onSurfaceVariant)
        Text("tap_test.state_nfc_unsupported", bundle: .main)
            .tapSenseStyle(TapSenseType.titleSmall, color: colors.onSurface)
            .padding(.top, 20)
        Text("tap_test.hint_nfc_unsupported", bundle: .main)
            .tapSenseStyle(TapSenseType.bodySmall, color: colors.onSurfaceVariant)
            .padding(.top, 8)
    }
}

private struct StatusIcon: View {
    let systemImage: String
    let background: Color
    let tint: Color

    var body: some View {
        Circle()
            .fill(background)
            .frame(width: 96, height: 96)
            .overlay(
                Image(systemName: systemImage)
                    .font(.system(size: 40))
                    .foregroundStyle(tint)
            )
    }
}

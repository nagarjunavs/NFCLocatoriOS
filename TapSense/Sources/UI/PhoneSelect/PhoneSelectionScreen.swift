import SwiftUI
import NFCLocatorCore

struct PhoneSelectionScreen: View {
    @Environment(\.appEnvironment) private var env
    @Environment(\.tsColors) private var colors
    @Environment(Router.self) private var router
    @State private var viewModel = PhoneSelectionViewModel()

    var body: some View {
        VStack(spacing: 0) {
            Text("phone_selection.title", bundle: .main)
                .tapSenseStyle(TapSenseType.headlineSmall, color: colors.onSurface)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)

            PlatformFilterToggle(selected: viewModel.uiState.platformFilter) {
                viewModel.onPlatformFilterChange($0)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 14)

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(colors.onSurfaceVariant)
                TextField(String(localized: "phone_selection.search_placeholder"), text: Binding(
                    get: { viewModel.uiState.query },
                    set: { viewModel.onQueryChange($0) }
                ))
                .textFieldStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 12).strokeBorder(colors.outline))
            .padding(.horizontal, 24)

            Text("phone_selection.section_header", bundle: .main)
                .tapSenseStyle(TapSenseType.labelSmall, color: colors.onSurfaceVariant)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)

            if viewModel.uiState.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if viewModel.uiState.results.isEmpty {
                Spacer()
                Text(L10n("phone_selection.empty", viewModel.uiState.query))
                    .tapSenseStyle(TapSenseType.bodyMedium, color: colors.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .padding(24)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.uiState.results, id: \.lookupIdentity) { profile in
                            PhoneRow(profile: profile) {
                                guard let env else { return }
                                viewModel.selectPhone(profile, env: env) {
                                    router.replaceTop(with: .phoneConfirmed)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 4)
                }
            }

            Button {
                guard let env else { return }
                viewModel.useMyPhoneAutomatically(env: env) {
                    router.pop()
                }
            } label: {
                Text("phone_selection.use_my_phone", bundle: .main)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.tapSenseText)
            .padding(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.background)
        .task {
            if let env { await viewModel.load(env: env) }
        }
    }
}

/// Android/Apple segmented filter, directly below the title — same visual language as My Phone's
/// Back/Front `SideToggle`, but full-width with two equal-width segments (this control gates the
/// whole catalog list, not a compact secondary toggle), matching the design's "Phone selection &
/// compatibility search" mockup.
private struct PlatformFilterToggle: View {
    @Environment(\.tsColors) private var colors
    let selected: PhoneSelectionPlatform
    let onSelect: (PhoneSelectionPlatform) -> Void

    var body: some View {
        let trackColor = colors.isDark ? TapSensePalette.toggleTrackDark : TapSensePalette.toggleTrackLight
        let selectedTabColor = colors.isDark ? TapSensePalette.toggleTabSelectedDark : colors.surface

        HStack(spacing: 0) {
            tab(.android, label: String(localized: "phone_selection.filter_android"), selectedTabColor: selectedTabColor)
            tab(.apple, label: String(localized: "phone_selection.filter_apple"), selectedTabColor: selectedTabColor)
        }
        .padding(4)
        .background(trackColor)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func tab(_ platform: PhoneSelectionPlatform, label: String, selectedTabColor: Color) -> some View {
        let isSelected = platform == selected
        return Button {
            onSelect(platform)
        } label: {
            Text(label)
                .tapSenseStyle(TapSenseType.titleSmall, color: isSelected ? colors.onSurface : colors.onSurfaceVariant)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(isSelected ? selectedTabColor : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 11))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct PhoneRow: View {
    @Environment(\.tsColors) private var colors
    let profile: DeviceAntennaProfile
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.model.friendlyModelName())
                        .tapSenseStyle(TapSenseType.titleSmall, color: colors.onSurface)
                    Text(profile.manufacturer.capitalizingFirstLetter())
                        .tapSenseStyle(TapSenseType.bodySmall, color: colors.onSurfaceVariant)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                ConfidenceChip(confidence: profile.confidence)
            }
            .padding(14)
            .background(colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

extension DeviceAntennaProfile {
    var lookupIdentity: String { "\(manufacturer):\(model)" }
}

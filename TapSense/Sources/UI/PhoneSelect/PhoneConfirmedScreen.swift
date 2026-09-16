import SwiftUI
import NFCLocatorCore

struct PhoneConfirmedScreen: View {
    @Environment(\.appEnvironment) private var env
    @Environment(\.tsColors) private var colors
    @Environment(Router.self) private var router
    @State private var viewModel = PhoneConfirmedViewModel()

    var body: some View {
        VStack {
            Spacer()

            Circle()
                .fill(colors.primaryContainer)
                .frame(width: 72, height: 72)
                .overlay(
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(colors.onPrimaryContainer)
                )

            Text("phone_confirmed.title", bundle: .main)
                .tapSenseStyle(TapSenseType.headlineSmall, color: colors.onSurface)
                .padding(.top, 20)
                .padding(.bottom, 20)

            HStack(spacing: 12) {
                if let profile = viewModel.confirmedProfile {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile.model.friendlyModelName())
                            .tapSenseStyle(TapSenseType.titleSmall, color: colors.onSurface)
                        Text(profile.manufacturer.capitalizingFirstLetter())
                            .tapSenseStyle(TapSenseType.bodySmall, color: colors.onSurfaceVariant)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    ConfidenceChip(confidence: profile.confidence)
                } else {
                    ProgressView().frame(width: 20, height: 20)
                    Spacer()
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18))

            Button {
                guard let env else { return }
                viewModel.goHome(env: env) {
                    router.navigateTopLevel(.home)
                }
            } label: {
                Text("phone_confirmed.go_home", bundle: .main)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.tapSenseFilled)
            .padding(.top, 24)

            Button {
                router.replaceTop(with: .phoneSelection)
            } label: {
                Text("phone_confirmed.choose_different", bundle: .main)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.tapSenseText)

            Spacer()
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.background)
        .task {
            if let env { await viewModel.load(env: env) }
        }
    }
}

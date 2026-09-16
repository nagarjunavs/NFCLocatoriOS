import SwiftUI

/// Selecting an issue reveals contextual, real actions — not just static tips: tap-zone
/// confusion routes to My Phone, an unlisted model routes to phone selection, etc.
struct TroubleshootScreen: View {
    @Environment(\.tsColors) private var colors
    @Environment(Router.self) private var router
    @State private var selected: TroubleshootIssue?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("troubleshoot.title", bundle: .main)
                .tapSenseStyle(TapSenseType.headlineSmall, color: colors.onSurface)
                .padding(.top, 12)
            Text("troubleshoot.subtitle", bundle: .main)
                .tapSenseStyle(TapSenseType.bodySmall, color: colors.onSurfaceVariant)
                .padding(.top, 4)
                .padding(.bottom, 12)

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(TroubleshootIssue.allCases, id: \.self) { issue in
                        IssueRow(issue: issue, isSelected: issue == selected) {
                            selected = issue
                        }
                    }
                }
                .padding(.vertical, 4)

                if let selected {
                    TroubleshootActions(
                        issue: selected,
                        onRunTapTest: { router.push(.tapTest) },
                        onViewTapZone: { router.navigateTopLevel(.myPhone) },
                        onChoosePhone: { router.push(.phoneSelection) },
                        onLearnMore: { router.push(.education) }
                    )
                    .padding(.top, 14)
                    .padding(.bottom, 24)
                }
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.background)
    }
}

private struct IssueRow: View {
    @Environment(\.tsColors) private var colors
    let issue: TroubleshootIssue
    let isSelected: Bool
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            HStack {
                Text(String(localized: issue.labelKey))
                    .tapSenseStyle(TapSenseType.bodyMedium, color: colors.onSurface)
                Spacer()
                Text(verbatim: "›").foregroundStyle(colors.onSurfaceVariant)
            }
            .padding(16)
            .background(isSelected ? colors.secondaryContainer : colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

private struct TroubleshootActions: View {
    @Environment(\.tsColors) private var colors
    let issue: TroubleshootIssue
    let onRunTapTest: () -> Void
    let onViewTapZone: () -> Void
    let onChoosePhone: () -> Void
    let onLearnMore: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Text("troubleshoot.selected_prefix", bundle: .main)
                    .tapSenseStyle(TapSenseType.labelSmall, color: colors.onSurfaceVariant)
                Text(" " + String(localized: issue.labelKey))
                    .tapSenseStyle(TapSenseType.labelSmall, color: colors.onSurfaceVariant)
            }

            switch issue {
            case .noReaction, .readerSilent, .payFailing:
                ActionRow(label: String(localized: "troubleshoot.action_run_tap_test"), onClick: onRunTapTest)
            case .cannotScan:
                ActionRow(label: String(localized: "troubleshoot.action_run_tap_test"), onClick: onRunTapTest)
                ActionRow(label: String(localized: "troubleshoot.action_view_tap_zone"), onClick: onViewTapZone)
            case .dontKnowWhere:
                ActionRow(label: String(localized: "troubleshoot.action_view_tap_zone"), onClick: onViewTapZone)
                ActionRow(label: String(localized: "troubleshoot.action_learn_more"), onClick: onLearnMore)
            case .modelMissing:
                ActionRow(label: String(localized: "troubleshoot.action_choose_phone"), onClick: onChoosePhone)
            }
        }
        .padding(16)
        .background(colors.surfaceVariant)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

private struct ActionRow: View {
    @Environment(\.tsColors) private var colors
    let label: String
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            Text(label)
                .tapSenseStyle(TapSenseType.bodyMedium, color: colors.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }
}

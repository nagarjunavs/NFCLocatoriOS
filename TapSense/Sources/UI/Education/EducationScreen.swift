import SwiftUI

private struct Faq {
    let questionKey: String.LocalizationValue
    let answerKey: String.LocalizationValue
}

private let faqs: [Faq] = [
    Faq(questionKey: "education.faq_antenna_location", answerKey: "education.faq_antenna_location_answer"),
    Faq(questionKey: "education.faq_tap_tag", answerKey: "education.faq_tap_tag_answer"),
    Faq(questionKey: "education.faq_pay_vs_scan", answerKey: "education.faq_pay_vs_scan_answer"),
    Faq(questionKey: "education.faq_why_fail", answerKey: "education.faq_why_fail_answer"),
]

struct EducationScreen: View {
    @Environment(\.tsColors) private var colors

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("education.title", bundle: .main)
                .tapSenseStyle(TapSenseType.headlineSmall, color: colors.onSurface)
                .padding(.top, 12)
                .padding(.bottom, 12)

            ScrollView {
                LazyVStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("education.what_is_nfc_title", bundle: .main)
                            .tapSenseStyle(TapSenseType.titleSmall, color: colors.onSurface)
                        Text("education.what_is_nfc_body", bundle: .main)
                            .tapSenseStyle(TapSenseType.bodySmall, color: colors.onSurfaceVariant)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(colors.surfaceVariant)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    ForEach(faqs.indices, id: \.self) { index in
                        FaqRow(faq: faqs[index])
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.background)
    }
}

private struct FaqRow: View {
    @Environment(\.tsColors) private var colors
    let faq: Faq
    @State private var expanded = false

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(String(localized: faq.questionKey))
                        .tapSenseStyle(TapSenseType.bodyMedium, color: colors.onSurface)
                    Spacer()
                    Text(verbatim: expanded ? "−" : "+")
                        .foregroundStyle(colors.onSurfaceVariant)
                }
                if expanded {
                    Text(String(localized: faq.answerKey))
                        .tapSenseStyle(TapSenseType.bodySmall, color: colors.onSurfaceVariant)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
            .background(colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

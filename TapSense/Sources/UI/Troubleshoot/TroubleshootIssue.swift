import Foundation

enum TroubleshootIssue: CaseIterable {
    case noReaction
    case readerSilent
    case payFailing
    case cannotScan
    case dontKnowWhere
    case modelMissing

    var labelKey: String.LocalizationValue {
        switch self {
        case .noReaction: return "troubleshoot.issue_no_reaction"
        case .readerSilent: return "troubleshoot.issue_reader_silent"
        case .payFailing: return "troubleshoot.issue_pay_failing"
        case .cannotScan: return "troubleshoot.issue_cannot_scan"
        case .dontKnowWhere: return "troubleshoot.issue_dont_know_where"
        case .modelMissing: return "troubleshoot.issue_model_missing"
        }
    }
}

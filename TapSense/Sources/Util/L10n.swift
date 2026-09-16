import Foundation

/// Formats a localized template string (looked up by key from `Localizable.xcstrings`) with
/// positional arguments — for the handful of strings that carry `%1$d`/`%1$s`-style
/// placeholders (`tap_guide.step_of`, `settings.version`, `phone_selection.empty`).
func L10n(_ key: String.LocalizationValue, _ args: CVarArg...) -> String {
    String(format: String(localized: key), arguments: args)
}

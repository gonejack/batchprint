import Foundation

enum L10n {
    static func text(_ key: String) -> String {
        NSLocalizedString(key, tableName: nil, bundle: .main, value: key, comment: "")
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: text(key), arguments: arguments)
    }

    /// "1 File" / "3 Files", localized in the active interface language.
    static func files(_ count: Int) -> String {
        format(count == 1 ? "%lld File" : "%lld Files", count)
    }

    /// "1 Page" / "3 Pages", localized in the active interface language.
    static func pages(_ count: Int) -> String {
        format(count == 1 ? "%lld Page" : "%lld Pages", count)
    }

    static func printTitle(_ count: Int) -> String {
        guard count > 0 else { return text("Print") }
        return format(count == 1 ? "Print %lld File" : "Print %lld Files", count)
    }
}

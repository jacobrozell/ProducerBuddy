import Foundation

/// Validates streaming links saved on a song's release card.
enum ReleaseURLValidator {
    static func normalized(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func isValid(_ raw: String) -> Bool {
        let value = normalized(raw)
        guard !value.isEmpty else { return true }
        guard let url = URL(string: value), let scheme = url.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }

    static func validationMessage(for raw: String) -> String? {
        isValid(raw) ? nil : "Enter a valid https:// link"
    }
}

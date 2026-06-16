import Foundation

struct ExportPrefixValidation: Equatable, Sendable {
    let isValid: Bool
    let warning: String?
    let error: String?
}

/// Validates per-song export prefixes (see VersionStack spec).
enum ExportPrefixValidator {
    private static let reserved = Set([
        "beat", "beats", "project", "track", "tracks", "mix", "song", "audio"
    ])

    static func validate(
        _ prefix: String,
        excludingSongID: UUID? = nil,
        existingSongs: [Song]
    ) -> ExportPrefixValidation {
        let trimmed = prefix.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ExportPrefixValidation(isValid: true, warning: nil, error: nil)
        }

        if trimmed.count < 3 {
            return ExportPrefixValidation(
                isValid: false, warning: nil,
                error: "Prefix must be at least 3 characters."
            )
        }

        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-")
        if trimmed.unicodeScalars.contains(where: { !allowed.contains($0) }) {
            return ExportPrefixValidation(
                isValid: false, warning: nil,
                error: "Use only letters, numbers, underscores, and hyphens."
            )
        }

        let lowered = trimmed.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "_-"))
        if reserved.contains(lowered) {
            return ExportPrefixValidation(
                isValid: false, warning: nil,
                error: "\"\(trimmed)\" is too generic — pick a beat-specific prefix."
            )
        }

        var warning: String?
        if !trimmed.hasSuffix("_") && !trimmed.hasSuffix("-") {
            warning = "Add _ at the end so \"\(trimmed)\" doesn't match unrelated files."
        }

        if let conflict = existingSongs.first(where: { other in
            guard other.id != excludingSongID else { return false }
            let otherPrefix = other.exportPrefix.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !otherPrefix.isEmpty else { return false }
            return otherPrefix.lowercased() == trimmed.lowercased()
        }) {
            return ExportPrefixValidation(
                isValid: false, warning: warning,
                error: "Already used by \"\(conflict.title)\"."
            )
        }

        return ExportPrefixValidation(isValid: true, warning: warning, error: nil)
    }
}

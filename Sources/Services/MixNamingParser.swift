import Foundation

/// Parsed metadata from an audio filename (basename, no extension).
struct ParsedMixFilename: Sendable, Equatable {
    let baseTitle: String
    let versionLabel: String?
    let suggestedRole: MixRole
    let normalizedTitle: String
}

/// Heuristic filename parser for producer export names.
enum MixNamingParser {
  private static let roleTokenMap: [(token: String, role: MixRole)] = [
    ("mastered", .master), ("master", .master), ("mstr", .master), ("final", .master),
    ("rough", .rough), ("demo", .rough), ("wip", .rough), ("bounce", .rough),
    ("tagged", .tagged), ("tag", .tagged),
    ("instrumental", .instrumental), ("inst", .instrumental),
    ("slowed", .arrangement), ("sped", .arrangement), ("reverb", .arrangement),
    ("acoustic", .arrangement), ("remix", .arrangement),
    ("ref", .reference), ("reference", .reference),
    ("original", .original),
  ]

  static func parse(basename: String) -> ParsedMixFilename {
    var working = basename.trimmingCharacters(in: .whitespacesAndNewlines)
    var versionLabel: String?
    var role: MixRole = .original

    if let fl = parseFLProjectName(working) {
      return ParsedMixFilename(
        baseTitle: fl,
        versionLabel: nil,
        suggestedRole: .original,
        normalizedTitle: normalize(fl)
      )
    }

    if let version = extractVersionToken(from: &working) {
      versionLabel = version
    }

    let lowered = working.lowercased()
    for (token, mappedRole) in roleTokenMap {
      let patterns = ["_\(token)", "-\(token)", " \(token)"]
      for pattern in patterns where lowered.hasSuffix(pattern) {
        role = mappedRole
        working = String(working.prefix(working.count - pattern.count))
        break
      }
    }

    let baseTitle = collapseSeparators(working)
    let title = baseTitle.isEmpty ? basename : baseTitle
    return ParsedMixFilename(
      baseTitle: title,
      versionLabel: versionLabel,
      suggestedRole: role,
      normalizedTitle: normalize(title)
    )
  }

  static func normalize(_ title: String) -> String {
    collapseSeparators(title)
      .lowercased()
      .filter { $0.isLetter || $0.isNumber }
  }

  /// Export prefix for FL `Project_6` files and parsed beat stems.
  static func suggestedExportPrefix(from basename: String) -> String? {
    let trimmed = basename.trimmingCharacters(in: .whitespacesAndNewlines)
    let flPattern = #"(?i)^Project[_\s-]?(\d+)$"#
    if trimmed.range(of: flPattern, options: .regularExpression) != nil {
      let digits = trimmed.filter(\.isNumber)
      guard !digits.isEmpty else { return nil }
      return "Project_\(digits)_"
    }
    let parsed = parse(basename: trimmed)
    let suggested = ExportPrefixSuggester.suggest(fromParsedBaseTitle: parsed.baseTitle)
    return suggested.isEmpty ? nil : suggested
  }

  private static func extractVersionToken(from working: inout String) -> String? {
    guard let match = working.range(of: #"(?i)[ _-]v(\d+)"#, options: .regularExpression) else {
      return nil
    }
    let digits = working[match].filter(\.isNumber)
    working.removeSubrange(match)
    return digits.isEmpty ? nil : "v\(digits)"
  }

  private static func parseFLProjectName(_ name: String) -> String? {
    let pattern = #"(?i)^Project[_\s-]?(\d+)$"#
    guard let match = name.range(of: pattern, options: .regularExpression) else { return nil }
    let digits = name[match].filter(\.isNumber)
    guard !digits.isEmpty else { return nil }
    return "Project \(digits)"
  }

  private static func collapseSeparators(_ value: String) -> String {
    value
      .replacingOccurrences(of: "_", with: " ")
      .replacingOccurrences(of: "-", with: " ")
      .split(whereSeparator: \.isWhitespace)
      .joined(separator: " ")
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }
}

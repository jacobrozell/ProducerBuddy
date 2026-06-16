import Foundation

/// Suggests export prefixes from song titles and parsed filenames.
enum ExportPrefixSuggester {
  static func suggest(from title: String) -> String {
    let collapsed = title
      .replacingOccurrences(of: " ", with: "")
      .replacingOccurrences(of: "_", with: "")
      .replacingOccurrences(of: "-", with: "")
      .filter { $0.isLetter || $0.isNumber }
    guard collapsed.count >= 3 else { return "" }
    return "\(collapsed)_"
  }

  static func suggest(fromParsedBaseTitle baseTitle: String) -> String {
    suggest(from: baseTitle)
  }
}

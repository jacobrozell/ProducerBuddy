import Foundation

/// User preferences for version-stack import behavior.
enum VersionImportSettings {
    private static let autoAddKey = "versionImport.autoAddOnPrefixMatch"
    private static let autoSuggestKey = "versionImport.autoSuggestExportPrefix"
    private static let autoMatchKey = "versionImport.autoMatchVersions"
    private static let durationAskKey = "versionImport.askWhenDurationDiffers"

    static var autoAddOnPrefixMatch: Bool {
        get { UserDefaults.standard.object(forKey: autoAddKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: autoAddKey) }
    }

    static var autoSuggestExportPrefix: Bool {
        get { UserDefaults.standard.object(forKey: autoSuggestKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: autoSuggestKey) }
    }

    static var autoMatchVersions: Bool {
        get { UserDefaults.standard.object(forKey: autoMatchKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: autoMatchKey) }
    }

    static var askWhenDurationDiffers: Bool {
        get { UserDefaults.standard.object(forKey: durationAskKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: durationAskKey) }
    }
}

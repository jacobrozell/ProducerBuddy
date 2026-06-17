import Foundation

/// Centralized localized strings (see `Resources/Localizable.xcstrings`).
enum L10n {
    static let tabLibrary = String(localized: "tab.library", defaultValue: "Library")
    static let tabProjects = String(localized: "tab.projects", defaultValue: "Projects")
    static let settingsTitle = String(localized: "settings.title", defaultValue: "Settings")
    static let done = String(localized: "common.done", defaultValue: "Done")
    static let cancel = String(localized: "common.cancel", defaultValue: "Cancel")
    static let loopOff = String(localized: "player.loop.off", defaultValue: "Off")
    static let loopTrack = String(localized: "player.loop.track", defaultValue: "Track")
    static let loopSection = String(localized: "player.loop.section", defaultValue: "Section")
    static let loopPlayback = String(localized: "player.loop.label", defaultValue: "Loop playback")
    static let exportCatalog = String(localized: "settings.exportCatalog", defaultValue: "Export Catalog…")
    static let importCatalog = String(localized: "settings.importCatalog", defaultValue: "Import Catalog…")
    static let catalogExported = String(
        localized: "settings.catalogExported",
        defaultValue: "Catalog exported. Share or save the file from the sheet."
    )
    static let catalogImported = String(
        localized: "settings.catalogImported",
        defaultValue: "Catalog imported successfully."
    )
    static let importMerge = String(localized: "settings.importMerge", defaultValue: "Merge")
    static let importReplace = String(localized: "settings.importReplace", defaultValue: "Replace All")
    static let importReplaceConfirm = String(
        localized: "settings.importReplaceConfirm",
        defaultValue: """
        Replace your entire library with this catalog? This deletes local songs, mixes, and projects first.
        """
    )
}

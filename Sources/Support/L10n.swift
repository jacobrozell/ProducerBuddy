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

    static let versionsTitle = String(localized: "song.versions", defaultValue: "Versions")
    static let addVersion = String(localized: "song.addVersion", defaultValue: "Add version")
    static let compareTitle = String(localized: "song.compare.title", defaultValue: "Compare")
    static let compareNeedTwoVersions = String(
        localized: "song.compare.needTwo",
        defaultValue: "Need two versions"
    )
    static let compareNeedTwoVersionsHint = String(
        localized: "song.compare.needTwoHint",
        defaultValue: "Import or add another mix to compare side by side."
    )
    static let compareMixA = String(localized: "song.compare.mixA", defaultValue: "Mix A")
    static let compareMixB = String(localized: "song.compare.mixB", defaultValue: "Mix B")
    static let compareWaveform = String(localized: "song.compare.waveform", defaultValue: "Waveform")
    static let compareDuration = String(localized: "song.compare.duration", defaultValue: "Duration")
    static let compareBPM = String(localized: "song.compare.bpm", defaultValue: "BPM")
    static let compareKey = String(localized: "song.compare.key", defaultValue: "Key")
    static let compareLUFS = String(localized: "song.compare.lufs", defaultValue: "LUFS")
    static let compareRole = String(localized: "song.compare.role", defaultValue: "Role")
    static let comparePlayA = String(localized: "song.compare.playA", defaultValue: "Play A")
    static let comparePlayB = String(localized: "song.compare.playB", defaultValue: "Play B")
    static let compareSwitchAtPlayhead = String(
        localized: "song.compare.switch",
        defaultValue: "Switch at playhead"
    )
    static let compareSetAPrimary = String(
        localized: "song.compare.setAPrimary",
        defaultValue: "Set A as primary"
    )
    static let compareSetBPrimary = String(
        localized: "song.compare.setBPrimary",
        defaultValue: "Set B as primary"
    )

    static let shareFormatSquare = String(localized: "share.format.square", defaultValue: "Square")
    static let shareFormatBanner = String(localized: "share.format.banner", defaultValue: "Banner")
    static let shareFormatStory = String(localized: "share.format.story", defaultValue: "Story")

    /// Keys referenced from `L10n` — keep in sync with `LocalizationParityTests`.
    static let catalogKeys: [String] = [
        "tab.library", "tab.projects", "settings.title",
        "common.done", "common.cancel",
        "player.loop.off", "player.loop.track", "player.loop.section", "player.loop.label",
        "settings.exportCatalog", "settings.importCatalog", "settings.catalogExported",
        "settings.catalogImported", "settings.importMerge", "settings.importReplace",
        "settings.importReplaceConfirm",
        "song.versions", "song.addVersion", "song.compare.title", "song.compare.needTwo",
        "song.compare.needTwoHint", "song.compare.mixA", "song.compare.mixB",
        "song.compare.waveform", "song.compare.duration", "song.compare.bpm",
        "song.compare.key", "song.compare.lufs", "song.compare.role",
        "song.compare.playA", "song.compare.playB", "song.compare.switch",
        "song.compare.setAPrimary", "song.compare.setBPrimary",
        "share.format.square", "share.format.banner", "share.format.story"
    ]
}

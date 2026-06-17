import Foundation

/// Stable accessibility identifiers for UI tests. Centralised so test targets
/// and views agree on names. Convention: `screen.element`.
enum A11yID {
    enum Library {
        static let addMenu = "library.addMenu"
        static let importAudio = "library.importAudio"
        static let newSong = "library.newSong"
        static let sortMenu = "library.sortMenu"
        static let vocalFilter = "library.vocalFilter"
        static let filtersButton = "library.filtersButton"
        static let filtersSheet = "library.filtersSheet"
        static let importProgress = "library.importProgress"
        static let importResolution = "library.importResolution"
        static let addToProjectSheet = "library.addToProjectSheet"
    }
    enum Song {
        static let play = "song.play"
        static let detectMetadata = "song.detectMetadata"
        static let shareCard = "song.shareCard"
        static let vocalMeter = "song.vocalMeter"
        static let versionStack = "song.versionStack"
        static let exportPrefix = "song.exportPrefix"
        static let releaseLinks = "song.releaseLinks"
        static let exportAudiogram = "song.exportAudiogram"
        static let analyzeLoudness = "song.analyzeLoudness"
    }
    enum Player {
        static let bar = "player.bar"
        static let playPause = "player.playPause"
        static let stop = "player.stop"
        static let next = "player.next"
        static let previous = "player.previous"
        static let skipForward = "player.skipForward"
        static let skipBackward = "player.skipBackward"
        static let scrubber = "player.scrubber"
    }
    enum Project {
        static let play = "project.play"
        static let menu = "project.menu"
        static let suggestOrder = "project.suggestOrder"
        static let suggestOrderPreview = "project.suggestOrderPreview"
        static let suggestOrderApply = "project.suggestOrderApply"
        static let releaseProgress = "project.releaseProgress"
    }
    enum Settings {
        static let button = "settings.button"
        static let tab = "settings.tab"
        static let deleteAllData = "settings.deleteAllData"
        static let loadDemoTracks = "settings.loadDemoTracks"
        static let organizeLibrary = "settings.organizeLibrary"
        static let tipJar = "settings.tipJar"
        static let brandKit = "settings.brandKit"
        static let exportCatalog = "settings.exportCatalog"
        static let importCatalog = "settings.importCatalog"
    }
    enum Split {
        static let selectSong = "split.selectSong"
        static let selectProject = "split.selectProject"
    }
}

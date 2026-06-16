import Foundation

/// Stable accessibility identifiers for UI tests. Centralised so test targets
/// and views agree on names. Convention: `screen.element`.
enum A11yID {
    enum Library {
        static let addMenu = "library.addMenu"
        static let importAudio = "library.importAudio"
        static let newSong = "library.newSong"
        static let sortMenu = "library.sortMenu"
    }
    enum Song {
        static let play = "song.play"
        static let detectMetadata = "song.detectMetadata"
        static let shareCard = "song.shareCard"
    }
    enum Player {
        static let bar = "player.bar"
        static let playPause = "player.playPause"
        static let stop = "player.stop"
        static let next = "player.next"
        static let previous = "player.previous"
        static let skipForward = "player.skipForward"
        static let skipBackward = "player.skipBackward"
    }
    enum Project {
        static let play = "project.play"
        static let menu = "project.menu"
        static let suggestOrder = "project.suggestOrder"
    }
    enum Settings {
        static let tab = "settings.tab"
        static let deleteAllData = "settings.deleteAllData"
        static let tipJar = "settings.tipJar"
    }
}

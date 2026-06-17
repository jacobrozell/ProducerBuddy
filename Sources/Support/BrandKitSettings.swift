import SwiftUI

/// Card template for exported share surfaces.
enum BrandCardStyle: String, CaseIterable, Identifiable, Sendable {
    case minimal
    case gradient
    case bold

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .minimal: return "Minimal"
        case .gradient: return "Gradient"
        case .bold: return "Bold"
        }
    }
}

/// User-controlled brand identity for share cards and audiograms. Stored in
/// `UserDefaults` so it survives without a SwiftData migration; theme chrome
/// stays separate from brand accent per `BrandKit.md`.
enum BrandKitSettings {
    static let defaultAccentHex = "7C3AED"

    private enum Key {
        static let accentColorHex = "brand.accentColorHex"
        static let displayName = "brand.displayName"
        static let tagline = "brand.tagline"
        static let logoFilename = "brand.logoFilename"
        static let cardStyle = "brand.cardStyle"
    }

    struct Snapshot: Sendable {
        let accentColor: Color
        let accentHex: String
        let displayName: String
        let tagline: String
        let logoFilename: String?
        let cardStyle: BrandCardStyle

        var logoURL: URL? {
            guard let logoFilename else { return nil }
            return BrandStorage.url(for: logoFilename)
        }

        var footerText: String {
            if !tagline.isEmpty { return tagline }
            return "Made with MixStack"
        }

        func creditLine(for song: Song) -> String? {
            if !displayName.isEmpty { return displayName }
            if !song.artist.isEmpty { return song.artist }
            return nil
        }
    }

    static func current() -> Snapshot {
        let defaults = UserDefaults.standard
        let hex = defaults.string(forKey: Key.accentColorHex) ?? defaultAccentHex
        let styleRaw = defaults.string(forKey: Key.cardStyle) ?? BrandCardStyle.gradient.rawValue
        return Snapshot(
            accentColor: Color(hex: hex),
            accentHex: hex,
            displayName: defaults.string(forKey: Key.displayName) ?? "",
            tagline: defaults.string(forKey: Key.tagline) ?? "",
            logoFilename: defaults.string(forKey: Key.logoFilename),
            cardStyle: BrandCardStyle(rawValue: styleRaw) ?? .gradient
        )
    }

    static func restoreDefaults() {
        let defaults = UserDefaults.standard
        if let filename = defaults.string(forKey: Key.logoFilename) {
            BrandStorage.deleteFile(named: filename)
        }
        defaults.removeObject(forKey: Key.accentColorHex)
        defaults.removeObject(forKey: Key.displayName)
        defaults.removeObject(forKey: Key.tagline)
        defaults.removeObject(forKey: Key.logoFilename)
        defaults.removeObject(forKey: Key.cardStyle)
    }
}

/// Bindable storage for the Settings brand kit form.
@MainActor
final class BrandKitStore: ObservableObject {
    @Published var accentHex: String
    @Published var displayName: String
    @Published var tagline: String
    @Published var cardStyle: BrandCardStyle
    @Published var logoFilename: String?

    init() {
        let snapshot = BrandKitSettings.current()
        accentHex = snapshot.accentHex
        displayName = snapshot.displayName
        tagline = snapshot.tagline
        cardStyle = snapshot.cardStyle
        logoFilename = snapshot.logoFilename
    }

    func persist() {
        let defaults = UserDefaults.standard
        defaults.set(accentHex, forKey: "brand.accentColorHex")
        defaults.set(displayName, forKey: "brand.displayName")
        defaults.set(tagline, forKey: "brand.tagline")
        defaults.set(cardStyle.rawValue, forKey: "brand.cardStyle")
        if let logoFilename {
            defaults.set(logoFilename, forKey: "brand.logoFilename")
        } else {
            defaults.removeObject(forKey: "brand.logoFilename")
        }
    }

    func removeLogo() {
        if let logoFilename {
            BrandStorage.deleteFile(named: logoFilename)
        }
        self.logoFilename = nil
        UserDefaults.standard.removeObject(forKey: "brand.logoFilename")
    }

    func restoreDefaults() {
        BrandKitSettings.restoreDefaults()
        let snapshot = BrandKitSettings.current()
        accentHex = snapshot.accentHex
        displayName = snapshot.displayName
        tagline = snapshot.tagline
        cardStyle = snapshot.cardStyle
        logoFilename = snapshot.logoFilename
    }
}

import SwiftUI

/// Mini live preview of the brand kit inside Settings.
struct BrandKitPreviewCard: View {
    let accent: Color
    let displayName: String
    let tagline: String
    let cardStyle: BrandCardStyle
    let logoFilename: String?

    var body: some View {
        let brand = BrandKitSettings.Snapshot(
            accentColor: accent,
            accentHex: "",
            displayName: displayName,
            tagline: tagline,
            logoFilename: logoFilename,
            cardStyle: cardStyle
        )
        ShareCardView(
            content: .song(previewSong),
            format: .square,
            brand: brand
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .frame(height: 160)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Brand kit preview")
    }

    private var previewSong: Song {
        Song(
            title: "Night Drive",
            artist: displayName.isEmpty ? "Your Artist" : displayName,
            genre: "House",
            bpm: 124,
            key: .aMinor,
            category: .mastered
        )
    }
}

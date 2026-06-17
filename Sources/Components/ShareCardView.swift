import SwiftUI

/// Output shape for a generated share image.
enum CardFormat: String, CaseIterable, Identifiable, Sendable {
    case square = "Square"
    case story = "Story"

    var id: String { rawValue }

    /// Point size of the card; rendered at 3× for crisp social-ready pixels.
    var size: CGSize {
        switch self {
        case .square: return CGSize(width: 340, height: 340)
        case .story: return CGSize(width: 340, height: 604) // 9:16
        }
    }
}

/// What a card depicts: a single song or a whole project tracklist.
enum CardContent {
    case song(Song)
    case project(Project)
}

/// A clean, on-brand visual card for sharing a song or project to social media.
/// Designed to be handed to `ImageRenderer`; every value is laid out for a fixed
/// `format.size` so the render is deterministic.
struct ShareCardView: View {
    let content: CardContent
    let format: CardFormat
    var brand: BrandKitSettings.Snapshot = BrandKitSettings.current()

    var body: some View {
        ZStack {
            background
            VStack(alignment: .leading, spacing: 0) {
                header
                Spacer(minLength: 12)
                body(for: content)
                Spacer(minLength: 12)
                footer
            }
            .padding(24)
        }
        .frame(width: format.size.width, height: format.size.height)
        .foregroundStyle(.white)
    }

    // MARK: Sections

    @ViewBuilder
    private var background: some View {
        switch brand.cardStyle {
        case .minimal:
            Rectangle().fill(brand.accentColor)
        case .gradient:
            Rectangle().fill(brand.accentColor.gradient)
        case .bold:
            ZStack {
                Rectangle().fill(brand.accentColor)
                Rectangle()
                    .fill(.black.opacity(0.22))
                    .blendMode(.multiply)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            if let logoURL = brand.logoURL, let uiImage = UIImage(contentsOfFile: logoURL.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .accessibilityHidden(true)
            } else {
                Image(systemName: "music.quarternote.3")
                    .font(.title3)
            }
            Text(kicker)
                .font(.caption.weight(.bold))
                .textCase(.uppercase)
                .tracking(1.5)
            Spacer()
        }
        .opacity(0.85)
    }

    @ViewBuilder
    private func body(for content: CardContent) -> some View {
        switch content {
        case .song(let song):
            songBody(song)
        case .project(let project):
            projectBody(project)
        }
    }

    private func songBody(_ song: Song) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(song.title)
                .font(.system(size: titleSize, weight: .heavy, design: .rounded))
                .lineLimit(3)
                .minimumScaleFactor(0.6)
            if let credit = brand.creditLine(for: song) {
                Text(credit)
                    .font(.title3.weight(.medium))
                    .opacity(0.9)
            }
            HStack(spacing: 8) {
                pill("\(song.bpm) BPM")
                if song.key != .unknown { pill(song.key.displayName) }
                if !song.genre.isEmpty { pill(song.genre) }
            }
            .padding(.top, 4)
            if let dateLine = releaseDateLine(for: song) {
                Text(dateLine)
                    .font(.caption.weight(.semibold))
                    .opacity(0.85)
                    .padding(.top, 2)
            }
        }
    }

    private func projectBody(_ project: Project) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(project.title)
                .font(.system(size: titleSize, weight: .heavy, design: .rounded))
                .lineLimit(2)
                .minimumScaleFactor(0.6)
            if !project.subtitle.isEmpty {
                Text(project.subtitle)
                    .font(.title3.weight(.medium))
                    .opacity(0.9)
            } else if !brand.displayName.isEmpty {
                Text(brand.displayName)
                    .font(.title3.weight(.medium))
                    .opacity(0.9)
            }
            if project.totalTrackCount > 0 {
                Text("\(project.releasedTrackCount)/\(project.totalTrackCount) released")
                    .font(.caption.weight(.semibold))
                    .opacity(0.85)
            }
            VStack(alignment: .leading, spacing: 5) {
                ForEach(visibleTracks(project)) { track in
                    HStack(spacing: 8) {
                        Text("\(track.position + 1).")
                            .font(.footnote.monospacedDigit().weight(.bold))
                            .opacity(0.7)
                        Text(track.song?.title ?? "—")
                            .font(.footnote.weight(.medium))
                            .lineLimit(1)
                    }
                }
                if hiddenTrackCount(project) > 0 {
                    Text("+ \(hiddenTrackCount(project)) more")
                        .font(.caption.weight(.semibold))
                        .opacity(0.7)
                }
            }
            .padding(.top, 4)
        }
    }

    private var footer: some View {
        HStack {
            Text(brand.footerText)
                .font(.caption2.weight(.semibold))
                .opacity(0.8)
            Spacer()
        }
    }

    // MARK: Helpers

    private func pill(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.white.opacity(0.22), in: Capsule())
    }

    private var kicker: String {
        switch content {
        case .song: return "New Music"
        case .project(let project): return project.kind.displayName
        }
    }

    private var titleSize: CGFloat {
        format == .story ? 40 : 32
    }

    private var tint: Color {
        switch content {
        case .song(let song): return song.category.tint
        case .project: return brand.accentColor
        }
    }

    private func releaseDateLine(for song: Song) -> String? {
        guard let date = song.releaseDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "Out \(formatter.string(from: date))"
    }

    private func trackLimit() -> Int {
        format == .story ? 12 : 5
    }

    private func visibleTracks(_ project: Project) -> [ProjectTrack] {
        Array(project.orderedTracks.prefix(trackLimit()))
    }

    private func hiddenTrackCount(_ project: Project) -> Int {
        max(0, project.tracks.count - trackLimit())
    }
}

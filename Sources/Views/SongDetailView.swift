import SwiftUI
import SwiftData

/// Full detail for a single song: metadata, its list of mixes (with import and
/// per-mix actions), and a share entry point for marketing.
struct SongDetailView: View {
    @Bindable var song: Song
    @Environment(\.modelContext) private var modelContext
    @Environment(AudioPlayer.self) private var audioPlayer

    @State private var showingEditor = false
    @State private var showingImporter = false
    @State private var pendingMixName = ""

    var body: some View {
        List {
            headerSection
            metadataSection
            mixesSection
            if !song.notes.isEmpty {
                Section("Notes") {
                    Text(song.notes)
                }
            }
        }
        .navigationTitle(song.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Edit", systemImage: "pencil") { showingEditor = true }
                    Button("Add Mix", systemImage: "waveform.badge.plus") { showingImporter = true }
                    ShareLink(item: shareText) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            SongEditorView(song: song)
        }
        .audioImporter(isPresented: $showingImporter) { fileName, duration in
            addMix(fileName: fileName, duration: duration)
        }
    }

    private var headerSection: some View {
        Section {
            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(song.category.tint.gradient)
                    .frame(height: 120)
                    .overlay {
                        Image(systemName: "music.quarternote.3")
                            .font(.system(size: 44))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                HStack {
                    CategoryBadge(category: song.category)
                    Spacer()
                    StarRatingView(rating: $song.rating)
                }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }

    private var metadataSection: some View {
        Section("Details") {
            LabeledContent("Artist", value: song.artist.isEmpty ? "—" : song.artist)
            LabeledContent("Genre", value: song.genre.isEmpty ? "—" : song.genre)
            LabeledContent("BPM", value: "\(song.bpm)")
            LabeledContent("Key", value: song.key.displayName)
        }
    }

    private var mixesSection: some View {
        Section {
            if song.mixes.isEmpty {
                Button {
                    showingImporter = true
                } label: {
                    Label("Import a Mix", systemImage: "waveform.badge.plus")
                }
            } else {
                ForEach(song.mixes.sorted(by: { $0.dateAdded > $1.dateAdded })) { mix in
                    MixRow(mix: mix, onTogglePrimary: { setPrimary(mix) })
                }
                .onDelete(perform: deleteMixes)
            }
        } header: {
            HStack {
                Text("Mixes")
                Spacer()
                if !song.mixes.isEmpty {
                    Button {
                        showingImporter = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    private var shareText: String {
        var parts = ["🎵 \(song.title)"]
        if !song.artist.isEmpty { parts.append("by \(song.artist)") }
        parts.append("\(song.bpm) BPM")
        if !song.genre.isEmpty { parts.append(song.genre) }
        return parts.joined(separator: " · ") + "\n\nMade with ProducerBuddy"
    }

    private func addMix(fileName: String, duration: Double) {
        let mixNumber = song.mixes.count + 1
        let mix = Mix(
            name: "Mix \(mixNumber)",
            fileName: fileName,
            duration: duration,
            isPrimary: song.mixes.isEmpty
        )
        mix.song = song
        modelContext.insert(mix)
    }

    private func setPrimary(_ mix: Mix) {
        for m in song.mixes {
            m.isPrimary = (m.id == mix.id)
        }
    }

    private func deleteMixes(at offsets: IndexSet) {
        let sorted = song.mixes.sorted(by: { $0.dateAdded > $1.dateAdded })
        for index in offsets {
            let mix = sorted[index]
            if audioPlayer.currentMix?.id == mix.id {
                audioPlayer.stop()
            }
            AudioStorage.deleteFile(named: mix.fileName)
            modelContext.delete(mix)
        }
    }
}

/// One mix within a song's detail list, with play and primary controls.
private struct MixRow: View {
    let mix: Mix
    let onTogglePrimary: () -> Void
    @Environment(AudioPlayer.self) private var audioPlayer

    var body: some View {
        HStack(spacing: 12) {
            Button {
                audioPlayer.play(mix)
            } label: {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title)
                    .foregroundStyle(.accent)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(mix.name)
                    .font(.body.weight(.medium))
                Text(mix.formattedDuration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                onTogglePrimary()
            } label: {
                Image(systemName: mix.isPrimary ? "star.fill" : "star")
                    .foregroundStyle(mix.isPrimary ? .yellow : .secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var isPlaying: Bool {
        audioPlayer.isPlaying && audioPlayer.currentMix?.id == mix.id
    }
}

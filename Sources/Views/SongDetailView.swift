import SwiftUI
import SwiftData

/// Full detail for a single song: metadata, export prefix, version stack, sharing.
struct SongDetailView: View {
    @Bindable var song: Song
    @Environment(\.modelContext) private var modelContext
    @Environment(AudioPlayer.self) private var audioPlayer
    @Query private var allSongs: [Song]

    @State private var showingEditor = false
    @State private var showingImporter = false
    @State private var showingShareCard = false
    @State private var showingAudiogram = false
    @State private var isDetecting = false
    @State private var mixPendingDelete: Mix?
    @State private var songPendingDeleteAfterLastMix = false
    @State private var mixToEdit: Mix?

    var body: some View {
        List {
            headerSection
            SongExportPrefixSection(song: song, allSongs: allSongs)
            metadataSection
            if song.hasReleaseInfo || song.category == .released {
                Section("Release") {
                    ReleaseInfoCard(song: song)
                }
            }
            versionsSection
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
                    Button("Add Version", systemImage: "waveform.badge.plus") { showingImporter = true }
                    if ReleaseSurface.audioAnalysis {
                        Button("Detect Audio Metadata", systemImage: "wand.and.stars") { detectMetadata() }
                            .disabled(song.primaryMix == nil || isDetecting)
                            .accessibilityIdentifier(A11yID.Song.detectMetadata)
                    }
                    if ReleaseSurface.shareCards {
                        Button("Share Card", systemImage: "photo") { showingShareCard = true }
                            .accessibilityIdentifier(A11yID.Song.shareCard)
                    }
                    if ReleaseSurface.audiograms, song.primaryMix != nil {
                        Button("Export Audiogram…", systemImage: "waveform.path") {
                            showingAudiogram = true
                        }
                        .accessibilityIdentifier(A11yID.Song.exportAudiogram)
                    }
                    if song.mixes.contains(where: { $0.integratedLUFS == nil }) {
                        Button("Analyze Loudness", systemImage: "speaker.wave.3") {
                            analyzeAllLoudness()
                        }
                        .disabled(isDetecting)
                        .accessibilityIdentifier(A11yID.Song.analyzeLoudness)
                    }
                    ShareLink(item: shareText) {
                        Label("Share Text", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("More")
            }
        }
        .sheet(isPresented: $showingEditor) {
            SongEditorView(song: song)
        }
        .sheet(isPresented: mixEditorPresented) {
            if let mix = mixToEdit {
                MixEditorView(mix: mix)
            }
        }
        .audioImporter(isPresented: $showingImporter) { fileName, duration, sourceBasename in
            addMix(fileName: fileName, duration: duration, sourceBasename: sourceBasename)
        }
        .sheet(isPresented: $showingShareCard) {
            ShareCardSheet(content: .song(song))
        }
        .sheet(isPresented: $showingAudiogram) {
            if let mix = song.primaryMix {
                AudiogramExportSheet(mix: mix, song: song)
            }
        }
        .overlay(alignment: .bottom) {
            if isDetecting {
                Label("Analyzing audio…", systemImage: "waveform.and.magnifyingglass")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.bottom, 12)
                    .accessibilityLabel("Analyzing audio")
            }
        }
        .confirmationDialog(
            deleteMixDialogTitle,
            isPresented: deleteMixPresented,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let mix = mixPendingDelete { deleteMix(mix) }
            }
            Button("Cancel", role: .cancel) { mixPendingDelete = nil }
        } message: {
            if let mix = mixPendingDelete {
                Text(deleteMixDialogMessage(for: mix))
            }
        }
        .confirmationDialog(
            "Delete \"\(song.title)\"?",
            isPresented: $songPendingDeleteAfterLastMix,
            titleVisibility: .visible
        ) {
            Button("Delete Song", role: .destructive) { deleteSongAfterLastMix() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("That was the only version. Delete the song and its audio from this device?")
        }
    }

    private func analyzeLoudness(_ mix: Mix) {
        let mixID = mix.persistentModelID
        let url = mix.fileURL
        Task { @MainActor in
            guard let lufs = await LoudnessAnalyzer.estimateIntegratedLUFS(url: url),
                  let mix = modelContext.model(for: mixID) as? Mix else { return }
            mix.integratedLUFS = lufs
            mix.loudnessAnalyzedAt = .now
            Haptics.success()
        }
    }

    private func analyzeAllLoudness() {
        for mix in song.mixes where mix.integratedLUFS == nil {
            analyzeLoudness(mix)
        }
    }

    private var deleteMixDialogTitle: String {
        guard mixPendingDelete != nil else { return "Delete version?" }
        return song.mixes.count == 1 ? "Delete only version?" : "Delete version?"
    }

    private func deleteMixDialogMessage(for mix: Mix) -> String {
        if song.mixes.count == 1 {
            return "Remove \"\(mix.displayName)\" — the song will have no audio left."
        }
        return "Remove \"\(mix.displayName)\" and its audio file? This can't be undone."
    }

    private func detectMetadata() {
        guard let mix = song.primaryMix else { return }
        isDetecting = true
        let url = mix.fileURL
        Task { @MainActor in
            let analysis = await AudioAnalyzer.analyze(url: url)
            if let bpm = analysis.bpm { song.bpm = bpm }
            if let key = analysis.key, key != .unknown { song.key = key }
            song.applyDetectedVocals(analysis.vocal)
            isDetecting = false
        }
    }

    private var headerSection: some View {
        Section {
            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(song.category.tint.gradient)
                    .frame(height: 120)
                    .overlay {
                        ZStack(alignment: .bottomTrailing) {
                            Image(systemName: "music.quarternote.3")
                                .font(.system(size: 44))
                                .foregroundStyle(.white.opacity(0.9))
                            Image(systemName: song.category.symbolName)
                                .font(.caption.weight(.bold))
                                .padding(8)
                                .background(.black.opacity(0.22), in: Circle())
                                .padding(10)
                        }
                    }
                    .accessibilityLabel("\(song.title), \(song.category.displayName)")
                HStack {
                    CategoryBadge(category: song.category)
                    if song.mixes.count > 1 {
                        Text("\(song.mixes.count) versions")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
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
            LabeledContent("Vocals") {
                VocalConfidenceMeter(
                    presence: song.vocalPresence,
                    confidence: song.vocalConfidence,
                    isManual: song.vocalPresenceIsManual
                )
            }
        }
    }

    private var versionsSection: some View {
        Section {
            if song.mixes.isEmpty {
                Button {
                    showingImporter = true
                } label: {
                    Label("Import a Version", systemImage: "waveform.badge.plus")
                }
            } else {
                ForEach(song.orderedMixes) { mix in
                    VersionStackRow(
                        mix: mix,
                        onTogglePrimary: { setPrimary(mix) },
                        onEdit: { mixToEdit = mix },
                        onAnalyzeLoudness: { analyzeLoudness(mix) }
                    )
                }
                .onDelete(perform: requestDeleteMixes)
            }
        } header: {
            HStack {
                Text("Versions")
                Spacer()
                if !song.mixes.isEmpty {
                    Button {
                        showingImporter = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add version")
                }
            }
        }
        .accessibilityIdentifier(A11yID.Song.versionStack)
    }

    private var shareText: String {
        var parts = ["🎵 \(song.title)"]
        if !song.artist.isEmpty { parts.append("by \(song.artist)") }
        parts.append("\(song.bpm) BPM")
        if !song.genre.isEmpty { parts.append(song.genre) }
        if !song.spotifyURL.isEmpty { parts.append(song.spotifyURL) }
        return parts.joined(separator: " · ") + "\n\nMade with MixStack"
    }

    private func addMix(fileName: String, duration: Double, sourceBasename: String) {
        let parsed = MixNamingParser.parse(basename: sourceBasename)
        let audio = ImportedAudio(
            fileName: fileName,
            duration: duration,
            title: nil,
            artist: nil,
            suggestedTitle: song.title,
            sourceBasename: sourceBasename
        )
        let mix = SongImportService.attachMix(to: song, audio: audio, parsed: parsed, context: modelContext)
        let mixID = mix.persistentModelID
        let url = mix.fileURL
        Task { @MainActor in
            let peaks = await WaveformGenerator.generate(url: url)
            if !peaks.isEmpty, let mix = modelContext.model(for: mixID) as? Mix {
                mix.waveform = peaks
            }
            if let lufs = await LoudnessAnalyzer.estimateIntegratedLUFS(url: url),
               let mix = modelContext.model(for: mixID) as? Mix {
                mix.integratedLUFS = lufs
                mix.loudnessAnalyzedAt = .now
            }
        }
    }

    private func setPrimary(_ mix: Mix) {
        for existing in song.mixes {
            existing.isPrimary = (existing.id == mix.id)
        }
        Haptics.tap()
    }

    private func requestDeleteMixes(at offsets: IndexSet) {
        let ordered = song.orderedMixes
        if let index = offsets.first {
            mixPendingDelete = ordered[index]
        }
    }

    private func deleteMix(_ mix: Mix) {
        if audioPlayer.currentMix?.id == mix.id {
            audioPlayer.stop()
        }
        let wasLastMix = song.mixes.count == 1
        AudioStorage.deleteFile(named: mix.fileName)
        modelContext.delete(mix)
        mixPendingDelete = nil
        if wasLastMix {
            songPendingDeleteAfterLastMix = true
        }
    }

    private func deleteSongAfterLastMix() {
        modelContext.delete(song)
        songPendingDeleteAfterLastMix = false
        Haptics.tap()
    }

    private var deleteMixPresented: Binding<Bool> {
        Binding(
            get: { mixPendingDelete != nil },
            set: { if !$0 { mixPendingDelete = nil } }
        )
    }

    private var mixEditorPresented: Binding<Bool> {
        Binding(
            get: { mixToEdit != nil },
            set: { if !$0 { mixToEdit = nil } }
        )
    }
}

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
    @State private var isDetecting = false
    @State private var mixPendingDelete: Mix?
    @State private var mixToEdit: Mix?
    @State private var exportPrefixDraft = ""
    @State private var prefixValidation: ExportPrefixValidation?

    var body: some View {
        List {
            headerSection
            exportPrefixSection
            metadataSection
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
        .overlay(alignment: .bottom) {
            if isDetecting {
                Label("Analyzing audio…", systemImage: "waveform.and.magnifyingglass")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.bottom, 12)
            }
        }
        .confirmationDialog(
            "Delete version?",
            isPresented: deleteMixPresented,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let mix = mixPendingDelete { deleteMix(mix) }
            }
            Button("Cancel", role: .cancel) { mixPendingDelete = nil }
        } message: {
            if let mix = mixPendingDelete {
                Text("Remove \"\(mix.displayName)\" and its audio file? This can't be undone.")
            }
        }
        .onAppear {
            exportPrefixDraft = song.exportPrefix
        }
    }

    private var exportPrefixSection: some View {
        Section {
            HStack {
                TextField("NightDrive_", text: $exportPrefixDraft)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier(A11yID.Song.exportPrefix)
                    .onChange(of: exportPrefixDraft) { _, newValue in
                        validatePrefix(newValue)
                    }
                if !exportPrefixDraft.isEmpty {
                    Button("Copy", systemImage: "doc.on.doc") {
                        UIPasteboard.general.string = exportPrefixDraft
                    }
                    .labelStyle(.iconOnly)
                }
            }
            if let prefixValidation {
                if let error = prefixValidation.error {
                    Text(error).font(.caption).foregroundStyle(.red)
                } else if let warning = prefixValidation.warning {
                    Text(warning).font(.caption).foregroundStyle(.orange)
                }
            }
            Text(
                "Name FL exports like \(exportPrefixDraft.isEmpty ? "YourBeat_" : exportPrefixDraft)"
                + "master.mp3 and they stack here automatically."
            )
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Save Prefix") { saveExportPrefix() }
                .disabled(!(prefixValidation?.isValid ?? true))
        } header: {
            Text("Export Naming")
        }
    }

    private func validatePrefix(_ value: String) {
        prefixValidation = ExportPrefixValidator.validate(
            value,
            excludingSongID: song.id,
            existingSongs: allSongs
        )
    }

    private func saveExportPrefix() {
        let trimmed = exportPrefixDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        validatePrefix(trimmed)
        guard prefixValidation?.isValid ?? true else { return }
        song.exportPrefix = trimmed
        song.exportPrefixIsManual = !trimmed.isEmpty
        Haptics.success()
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
                        Image(systemName: "music.quarternote.3")
                            .font(.system(size: 44))
                            .foregroundStyle(.white.opacity(0.9))
                    }
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
                        onEdit: { mixToEdit = mix }
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
            guard !peaks.isEmpty, let mix = modelContext.model(for: mixID) as? Mix else { return }
            mix.waveform = peaks
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
        AudioStorage.deleteFile(named: mix.fileName)
        modelContext.delete(mix)
        mixPendingDelete = nil
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

/// One row in the song's version stack.
struct VersionStackRow: View {
    let mix: Mix
    let onTogglePrimary: () -> Void
    let onEdit: () -> Void
    @Environment(AudioPlayer.self) private var audioPlayer

    var body: some View {
        HStack(spacing: 12) {
            Button {
                Haptics.tap()
                audioPlayer.play(mix)
            } label: {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(mix.displayName)
                        .font(.body.weight(.medium))
                    Text(mix.role.displayName)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(mix.role.tint.opacity(0.2), in: Capsule())
                        .foregroundStyle(mix.role.tint)
                }
                Text(mix.formattedDuration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .layoutPriority(1)

            Spacer(minLength: 8)

            if mix.hasWaveform {
                WaveformView(
                    samples: mix.waveform,
                    progress: isCurrent ? playedFraction : 0,
                    playedColor: .accentColor,
                    unplayedColor: Color(.systemGray4)
                )
                .frame(width: 72, height: 24)
                .allowsHitTesting(false)
            }

            Button(action: onTogglePrimary) {
                Image(systemName: mix.isPrimary ? "star.fill" : "star")
                    .foregroundStyle(mix.isPrimary ? .yellow : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(mix.isPrimary ? "Primary version" : "Set as primary")
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2, perform: onEdit)
        .accessibilityHint("Double tap to edit")
    }

    private var isPlaying: Bool {
        audioPlayer.isPlaying && audioPlayer.currentMix?.id == mix.id
    }

    private var isCurrent: Bool {
        audioPlayer.currentMix?.id == mix.id
    }

    private var playedFraction: Double {
        guard isCurrent, audioPlayer.duration > 0 else { return 0 }
        return audioPlayer.currentTime / audioPlayer.duration
    }
}

import SwiftUI
import SwiftData

/// Create or edit a song's metadata. When `song` is nil a new song is inserted
/// on save; otherwise the passed song is edited in place.
struct SongEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let song: Song?

    @State private var title = ""
    @State private var artist = ""
    @State private var genre = ""
    @State private var bpm = 120
    @State private var key: MusicalKey = .unknown
    @State private var vocalPresence: VocalPresence = .unknown
    @State private var category: SongCategory = .idea
    @State private var rating = 0
    @State private var notes = ""
    @State private var exportPrefix = ""
    @State private var prefixValidation: ExportPrefixValidation?

    @Query private var allSongs: [Song]

    private var isEditing: Bool { song != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Artist", text: $artist)
                    TextField("Genre", text: $genre)
                }

                Section {
                    Stepper("BPM: \(bpm)", value: $bpm, in: 40...300)
                    Picker("Key", selection: $key) {
                        ForEach(MusicalKey.allCases) { key in
                            Text(key.displayName).tag(key)
                        }
                    }
                    Picker("Vocals", selection: $vocalPresence) {
                        ForEach(VocalPresence.allCases) { option in
                            Label(option.pickerName, systemImage: option.symbolName)
                                .tag(option)
                        }
                    }
                } header: {
                    Text("Musical")
                } footer: {
                    Text(
                        "Choose Unknown to use automatic detection on import or re-analysis. "
                        + "Other options override detection."
                    )
                }

                Section("Workflow") {
                    Picker("Category", selection: $category) {
                        ForEach(SongCategory.allCases) { category in
                            Label(category.displayName, systemImage: category.symbolName)
                                .tag(category)
                        }
                    }
                    LabeledContent("Rating") {
                        StarRatingView(rating: $rating)
                    }
                }

                Section {
                    TextField("Export prefix", text: $exportPrefix)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier(A11yID.Song.exportPrefix)
                        .onChange(of: exportPrefix) { _, newValue in
                            validatePrefix(newValue)
                        }
                    if let prefixValidation {
                        if let error = prefixValidation.error {
                            Text(error).font(.caption).foregroundStyle(.red)
                        } else if let warning = prefixValidation.warning {
                            Text(warning).font(.caption).foregroundStyle(.orange)
                        }
                    }
                } header: {
                    Text("Export Naming")
                } footer: {
                    Text("Files starting with this prefix import as new versions of this song.")
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle(isEditing ? "Edit Song" : "New Song")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: loadIfEditing)
            .onChange(of: title) { _, newValue in
                if !isEditing, exportPrefix.isEmpty {
                    exportPrefix = ExportPrefixSuggester.suggest(from: newValue)
                    validatePrefix(exportPrefix)
                }
            }
        }
    }

    private func loadIfEditing() {
        if let song {
            title = song.title
            artist = song.artist
            genre = song.genre
            bpm = song.bpm
            key = song.key
            vocalPresence = song.vocalPresence
            category = song.category
            rating = song.rating
            notes = song.notes
            exportPrefix = song.exportPrefix
            validatePrefix(exportPrefix)
        } else if VersionImportSettings.autoSuggestExportPrefix {
            exportPrefix = ExportPrefixSuggester.suggest(from: title)
        }
    }

    private func validatePrefix(_ value: String) {
        prefixValidation = ExportPrefixValidator.validate(
            value,
            excludingSongID: song?.id,
            existingSongs: allSongs
        )
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedPrefix = exportPrefix.trimmingCharacters(in: .whitespacesAndNewlines)
        validatePrefix(trimmedPrefix)
        guard prefixValidation?.isValid ?? true else { return }

        if let song {
            song.title = trimmedTitle
            song.artist = artist
            song.genre = genre
            song.bpm = bpm
            song.key = key
            applyVocalPresence(to: song)
            song.category = category
            song.rating = rating
            song.notes = notes
            song.exportPrefix = trimmedPrefix
            song.exportPrefixIsManual = !trimmedPrefix.isEmpty
            song.refreshNormalizedTitle()
        } else {
            let new = Song(
                title: trimmedTitle,
                artist: artist,
                genre: genre,
                bpm: bpm,
                key: key,
                category: category,
                rating: rating,
                notes: notes,
                exportPrefix: trimmedPrefix,
                exportPrefixIsManual: !trimmedPrefix.isEmpty
            )
            applyVocalPresence(to: new)
            modelContext.insert(new)
        }
        dismiss()
    }

    private func applyVocalPresence(to song: Song) {
        song.vocalPresence = vocalPresence
        if vocalPresence == .unknown {
            song.vocalPresenceIsManual = false
        } else {
            song.vocalPresenceIsManual = true
            song.vocalConfidence = nil
        }
    }
}

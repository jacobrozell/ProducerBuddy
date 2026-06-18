import SwiftUI
import SwiftData

/// Create or edit a song's metadata. When `song` is nil a new song is inserted
/// on save; otherwise the passed song is edited in place.
struct SongEditorView: View {
    private enum Field: Hashable {
        case title, artist, genre, exportPrefix, notes
        case spotify, appleMusic, soundcloud, releaseNotes, distributorOther
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let song: Song?

    @FocusState private var focusedField: Field?

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
    @State private var hasReleaseDate = false
    @State private var releaseDate = Date()
    @State private var distributorPreset: DistributorPreset = .none
    @State private var distributorOther = ""
    @State private var spotifyURL = ""
    @State private var appleMusicURL = ""
    @State private var soundcloudURL = ""
    @State private var releaseNotes = ""

    @Query private var allSongs: [Song]

    private var isEditing: Bool { song != nil }

    private func dismissKeyboard() {
        focusedField = nil
    }

    private var bpmBinding: Binding<Double> {
        Binding(
            get: { Double(bpm) },
            set: { bpm = Int($0.rounded()) }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                        .focused($focusedField, equals: .title)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .artist }
                    TextField("Artist", text: $artist)
                        .focused($focusedField, equals: .artist)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .genre }
                    TextField("Genre", text: $genre)
                        .focused($focusedField, equals: .genre)
                        .submitLabel(.done)
                        .onSubmit(dismissKeyboard)
                }
                .brandFormRowBackground()

                Section {
                    bpmControl
                    Picker("Key", selection: $key) {
                        ForEach(MusicalKey.allCases) { key in
                            Text(key.displayName).tag(key)
                        }
                    }
                    .dismissesKeyboardOnChange(of: key, using: dismissKeyboard)
                    Picker("Vocals", selection: $vocalPresence) {
                        ForEach(VocalPresence.allCases) { option in
                            Label(option.pickerName, systemImage: option.symbolName)
                                .tag(option)
                        }
                    }
                    .dismissesKeyboardOnChange(of: vocalPresence, using: dismissKeyboard)
                } header: {
                    Text("Musical")
                } footer: {
                    Text(
                        "Choose Unknown to use automatic detection on import or re-analysis. "
                        + "Other options override detection."
                    )
                }
                .brandFormRowBackground()

                Section("Workflow") {
                    Picker("Category", selection: $category) {
                        ForEach(SongCategory.allCases) { category in
                            Label(category.displayName, systemImage: category.symbolName)
                                .tag(category)
                        }
                    }
                    .dismissesKeyboardOnChange(of: category, using: dismissKeyboard)
                    LabeledContent("Rating") {
                        StarRatingView(rating: $rating)
                    }
                    .dismissesKeyboardOnChange(of: rating, using: dismissKeyboard)
                }
                .brandFormRowBackground()

                Section {
                    TextField("Export prefix", text: $exportPrefix)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .exportPrefix)
                        .submitLabel(.done)
                        .onSubmit(dismissKeyboard)
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
                .brandFormRowBackground()

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                        .focused($focusedField, equals: .notes)
                        .submitLabel(.done)
                        .onSubmit(dismissKeyboard)
                }
                .brandFormRowBackground()

                releaseSection
            }
            .scrollDismissesKeyboard(.immediately)
            .brandFormChrome()
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
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done", action: dismissKeyboard)
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

    private var bpmControl: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("BPM")
                Spacer()
                Text("\(bpm)")
                    .font(.body.monospacedDigit().weight(.medium))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            Slider(value: bpmBinding, in: 40...300, step: 1)
                .accessibilityLabel("BPM")
                .accessibilityValue("\(bpm) beats per minute")
                .dismissesKeyboardOnChange(of: bpm, using: dismissKeyboard)
        }
    }

    private var releaseSection: some View {
        Section {
            Toggle("Release date", isOn: $hasReleaseDate)
                .dismissesKeyboardOnChange(of: hasReleaseDate, using: dismissKeyboard)
            if hasReleaseDate {
                DatePicker("Date", selection: $releaseDate, displayedComponents: .date)
                    .dismissesKeyboardOnChange(of: releaseDate, using: dismissKeyboard)
            }
            Picker("Distributor", selection: $distributorPreset) {
                ForEach(DistributorPreset.allCases) { preset in
                    Text(preset.displayName).tag(preset)
                }
            }
            .dismissesKeyboardOnChange(of: distributorPreset, using: dismissKeyboard)
            if distributorPreset == .other {
                TextField("Distributor name", text: $distributorOther)
                    .focused($focusedField, equals: .distributorOther)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .spotify }
            }
            TextField("Spotify URL", text: $spotifyURL)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                .focused($focusedField, equals: .spotify)
                .submitLabel(.next)
                .onSubmit { focusedField = .appleMusic }
            urlValidationText(spotifyURL)
            TextField("Apple Music URL", text: $appleMusicURL)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                .focused($focusedField, equals: .appleMusic)
                .submitLabel(.next)
                .onSubmit { focusedField = .soundcloud }
            urlValidationText(appleMusicURL)
            TextField("SoundCloud URL", text: $soundcloudURL)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                .focused($focusedField, equals: .soundcloud)
                .submitLabel(.next)
                .onSubmit { focusedField = .releaseNotes }
            urlValidationText(soundcloudURL)
            TextField("Release notes", text: $releaseNotes, axis: .vertical)
                .lineLimit(2...6)
                .focused($focusedField, equals: .releaseNotes)
                .submitLabel(.done)
                .onSubmit(dismissKeyboard)
        } header: {
            Text("Release")
        } footer: {
            Text("Paste streaming links after your distributor upload goes live.")
        }
        .brandFormRowBackground()
    }

    @ViewBuilder
    private func urlValidationText(_ value: String) -> some View {
        if let message = ReleaseURLValidator.validationMessage(for: value) {
            Text(message).font(.caption).foregroundStyle(.red)
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
            if let date = song.releaseDate {
                hasReleaseDate = true
                releaseDate = date
            }
            distributorPreset = DistributorPreset.allCases.first {
                $0.rawValue == song.distributor
            } ?? (song.distributor.isEmpty ? .none : .other)
            distributorOther = distributorPreset == .other ? song.distributor : ""
            spotifyURL = song.spotifyURL
            appleMusicURL = song.appleMusicURL
            soundcloudURL = song.soundcloudURL
            releaseNotes = song.releaseNotes
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
        guard [spotifyURL, appleMusicURL, soundcloudURL].allSatisfy(ReleaseURLValidator.isValid) else { return }

        let distributorValue: String = {
            switch distributorPreset {
            case .none: return ""
            case .other: return distributorOther.trimmingCharacters(in: .whitespacesAndNewlines)
            default: return distributorPreset.rawValue
            }
        }()

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
            applyReleaseFields(to: song, distributor: distributorValue)
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
            applyReleaseFields(to: new, distributor: distributorValue)
            modelContext.insert(new)
        }
        dismiss()
    }

    private func applyReleaseFields(to song: Song, distributor: String) {
        song.releaseDate = hasReleaseDate ? releaseDate : nil
        song.distributor = distributor
        song.spotifyURL = ReleaseURLValidator.normalized(spotifyURL)
        song.appleMusicURL = ReleaseURLValidator.normalized(appleMusicURL)
        song.soundcloudURL = ReleaseURLValidator.normalized(soundcloudURL)
        song.releaseNotes = releaseNotes
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

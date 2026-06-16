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
    @State private var category: SongCategory = .idea
    @State private var rating = 0
    @State private var notes = ""

    private var isEditing: Bool { song != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Artist", text: $artist)
                    TextField("Genre", text: $genre)
                }

                Section("Musical") {
                    Stepper("BPM: \(bpm)", value: $bpm, in: 40...300)
                    Picker("Key", selection: $key) {
                        ForEach(MusicalKey.allCases) { key in
                            Text(key.displayName).tag(key)
                        }
                    }
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
        }
    }

    private func loadIfEditing() {
        guard let song else { return }
        title = song.title
        artist = song.artist
        genre = song.genre
        bpm = song.bpm
        key = song.key
        category = song.category
        rating = song.rating
        notes = song.notes
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        if let song {
            song.title = trimmedTitle
            song.artist = artist
            song.genre = genre
            song.bpm = bpm
            song.key = key
            song.category = category
            song.rating = rating
            song.notes = notes
        } else {
            let new = Song(
                title: trimmedTitle,
                artist: artist,
                genre: genre,
                bpm: bpm,
                key: key,
                category: category,
                rating: rating,
                notes: notes
            )
            modelContext.insert(new)
        }
        dismiss()
    }
}

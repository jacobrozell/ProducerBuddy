import SwiftUI
import SwiftData

/// How the library list is ordered.
enum LibrarySort: String, CaseIterable, Identifiable {
    case dateAdded = "Recently Added"
    case title = "Title"
    case bpm = "BPM"
    case rating = "Rating"

    var id: String { rawValue }
}

/// The main library screen: a searchable, sortable, filterable list of every
/// song the producer has imported.
struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var songs: [Song]

    @State private var searchText = ""
    @State private var sort: LibrarySort = .dateAdded
    @State private var categoryFilter: SongCategory?
    @State private var showingNewSong = false
    @State private var showingImporter = false
    /// Count of songs from the most recent import, surfaced as a brief banner.
    @State private var lastImportCount = 0

    var body: some View {
        NavigationStack {
            Group {
                if filteredSongs.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Library")
            .searchable(text: $searchText, prompt: "Search songs, artists, genres")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    sortMenu
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Import Audio…", systemImage: "square.and.arrow.down") {
                            showingImporter = true
                        }
                        Button("New Song", systemImage: "square.and.pencil") {
                            showingNewSong = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .safeAreaInset(edge: .top) { categoryFilterBar }
            .sheet(isPresented: $showingNewSong) {
                SongEditorView(song: nil)
            }
            .songImporter(isPresented: $showingImporter) { results in
                importSongs(results)
            }
            .overlay(alignment: .bottom) {
                if lastImportCount > 0 {
                    importBanner
                }
            }
        }
    }

    private var list: some View {
        List {
            ForEach(filteredSongs) { song in
                NavigationLink {
                    SongDetailView(song: song)
                } label: {
                    SongRow(song: song)
                }
            }
            .onDelete(perform: deleteSongs)
        }
        .listStyle(.plain)
    }

    private var sortMenu: some View {
        Menu {
            Picker("Sort", selection: $sort) {
                ForEach(LibrarySort.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
    }

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isOn: categoryFilter == nil) {
                    categoryFilter = nil
                }
                ForEach(SongCategory.allCases) { category in
                    FilterChip(title: category.displayName, isOn: categoryFilter == category) {
                        categoryFilter = (categoryFilter == category) ? nil : category
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.bar)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Songs Yet", systemImage: "music.note")
        } description: {
            Text("Import audio straight from your DAW or Files, and start building your catalog.")
        } actions: {
            Button("Import Audio") { showingImporter = true }
                .buttonStyle(.borderedProminent)
            Button("Add Manually") { showingNewSong = true }
        }
    }

    /// Transient confirmation shown after an import; clears itself after a beat.
    private var importBanner: some View {
        Label(
            "Imported \(lastImportCount) song\(lastImportCount == 1 ? "" : "s")",
            systemImage: "checkmark.circle.fill"
        )
        .font(.subheadline.weight(.semibold))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: Capsule())
        .foregroundStyle(.green)
        .padding(.bottom, 12)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .task(id: lastImportCount) {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { lastImportCount = 0 }
        }
    }

    /// Creates one song (with a primary mix) per imported file, pre-filling the
    /// title/artist from embedded tags or the filename.
    private func importSongs(_ results: [ImportedAudio]) {
        for audio in results {
            let song = Song(title: audio.suggestedTitle, artist: audio.artist ?? "")
            modelContext.insert(song)

            let mix = Mix(
                name: "Original",
                fileName: audio.fileName,
                duration: audio.duration,
                isPrimary: true
            )
            mix.song = song
            modelContext.insert(mix)
        }
        withAnimation { lastImportCount = results.count }
    }

    /// Search + category filter, then sort.
    private var filteredSongs: [Song] {
        songs
            .filter { categoryFilter == nil || $0.category == categoryFilter }
            .filter { song in
                guard !searchText.isEmpty else { return true }
                let q = searchText.lowercased()
                return song.title.lowercased().contains(q)
                    || song.artist.lowercased().contains(q)
                    || song.genre.lowercased().contains(q)
            }
            .sorted(by: sortComparator)
    }

    private func sortComparator(_ a: Song, _ b: Song) -> Bool {
        switch sort {
        case .dateAdded: return a.dateAdded > b.dateAdded
        case .title: return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
        case .bpm: return a.bpm < b.bpm
        case .rating: return a.rating > b.rating
        }
    }

    private func deleteSongs(at offsets: IndexSet) {
        for index in offsets {
            let song = filteredSongs[index]
            for mix in song.mixes {
                AudioStorage.deleteFile(named: mix.fileName)
            }
            modelContext.delete(song)
        }
    }
}

/// Toggleable pill used in the category filter bar.
private struct FilterChip: View {
    let title: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isOn ? Color.accentColor : Color(.secondarySystemBackground), in: Capsule())
                .foregroundStyle(isOn ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

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
                    Button {
                        showingNewSong = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .safeAreaInset(edge: .top) { categoryFilterBar }
            .sheet(isPresented: $showingNewSong) {
                SongEditorView(song: nil)
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
            Text("Add your first track and start building your catalog.")
        } actions: {
            Button("Add Song") { showingNewSong = true }
                .buttonStyle(.borderedProminent)
        }
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

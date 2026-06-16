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
    @State private var vocalFilter: VocalLibraryFilter = .all
    @AppStorage("library.bpmMin") private var bpmMin = LibraryFilterLogic.bpmRangeLimit.lowerBound
    @AppStorage("library.bpmMax") private var bpmMax = LibraryFilterLogic.bpmRangeLimit.upperBound
    @State private var selectedKeys: Set<MusicalKey> = []
    @State private var favoritesOnly = false
    @State private var showingFilters = false
    @State private var showingNewSong = false
    @State private var showingImporter = false
    @State private var lastImportMessage = ""
    @State private var importProgress: (current: Int, total: Int)?
    @State private var importTask: Task<Void, Never>?
    @State private var importFailures: [String] = []
    @State private var songPendingDelete: Song?
    @State private var songForProject: Song?
    @State private var pendingImportPlan: ImportPlan?
    @State private var pendingImportFailures: [String] = []

    var body: some View {
        NavigationStack {
            List {
                if let progress = importProgress {
                    Section {
                        importProgressBanner(current: progress.current, total: progress.total)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                }

                Section {
                    LibraryCategoryFilterBar(
                        categoryFilter: $categoryFilter,
                        filtersAreActive: filtersAreActive,
                        onShowFilters: { showingFilters = true }
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                }

                if filteredSongs.isEmpty {
                    Section {
                        emptyState
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                } else {
                    ForEach(listSections) { section in
                        if section.title.isEmpty {
                            ForEach(section.songs) { song in
                                songRow(song)
                            }
                        } else {
                            Section(section.title) {
                                ForEach(section.songs) { song in
                                    songRow(song)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Library")
            .searchable(text: $searchText, prompt: "Search songs, artists, genres, notes")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    sortMenu
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Import Audio…", systemImage: "square.and.arrow.down") {
                            showingImporter = true
                        }
                        .accessibilityIdentifier(A11yID.Library.importAudio)
                        Button("New Song", systemImage: "square.and.pencil") {
                            showingNewSong = true
                        }
                        .accessibilityIdentifier(A11yID.Library.newSong)
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add")
                    .accessibilityIdentifier(A11yID.Library.addMenu)
                }
            }
            .sheet(isPresented: $showingNewSong) {
                SongEditorView(song: nil)
            }
            .sheet(isPresented: $showingFilters) {
                LibraryFiltersSheet(
                    bpmMin: $bpmMin,
                    bpmMax: $bpmMax,
                    selectedKeys: $selectedKeys,
                    vocalFilter: $vocalFilter,
                    favoritesOnly: $favoritesOnly
                )
            }
            .sheet(isPresented: addToProjectPresented) {
                if let song = songForProject {
                    AddToProjectSheet(song: song)
                }
            }
            .sheet(isPresented: importResolutionPresented) {
                ImportResolutionSheet(
                    plan: Binding(
                        get: { pendingImportPlan ?? ImportPlan(items: []) },
                        set: { pendingImportPlan = $0 }
                    ),
                    songs: songs,
                    onConfirm: commitImportPlan
                )
            }
            .songImporter(isPresented: $showingImporter, importTask: $importTask) { current, total in
                importProgress = (current, total)
            } onImport: { results, failures in
                finishImport(results: results, failures: failures)
            }
            .overlay(alignment: .bottom) {
                if !lastImportMessage.isEmpty {
                    importSuccessBanner
                }
            }
            .confirmationDialog(
                deleteDialogTitle,
                isPresented: deleteDialogPresented,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let song = songPendingDelete { deleteSong(song) }
                }
                Button("Cancel", role: .cancel) { songPendingDelete = nil }
            } message: {
                if let song = songPendingDelete {
                    Text(deleteDialogMessage(for: song))
                }
            }
            .alert("Import Failed", isPresented: importFailureAlertPresented) {
                Button("OK") { importFailures = [] }
            } message: {
                Text(importFailureMessage)
            }
        }
    }

    @ViewBuilder
    private func songRow(_ song: Song) -> some View {
        NavigationLink {
            SongDetailView(song: song)
        } label: {
            SongRow(song: song)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                toggleFavorite(song)
            } label: {
                Label(
                    song.isFavorite ? "Unfavorite" : "Favorite",
                    systemImage: song.isFavorite ? "star.slash" : "star.fill"
                )
            }
            .tint(.yellow)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                songForProject = song
            } label: {
                Label("Add to Project", systemImage: "plus.square.on.square")
            }
            .tint(.accentColor)

            Button(role: .destructive) {
                songPendingDelete = song
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
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
        .accessibilityIdentifier(A11yID.Library.sortMenu)
    }

    private var filtersAreActive: Bool {
        LibraryFilterLogic.isBPMFilterActive(min: bpmMin, max: bpmMax)
            || !selectedKeys.isEmpty
            || vocalFilter != .all
            || favoritesOnly
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Songs Yet", systemImage: "music.note")
        } description: {
            if songs.isEmpty {
                Text("Import audio straight from your DAW or Files, and start building your catalog.")
            } else {
                Text("No songs match your filters. Try adjusting filters or search.")
            }
        } actions: {
            if songs.isEmpty {
                Button("Import Audio") { showingImporter = true }
                    .buttonStyle(.borderedProminent)
                Button("Add Manually") { showingNewSong = true }
            } else {
                Button("Clear Filters") { resetFilters() }
            }
        }
    }

    private func importProgressBanner(current: Int, total: Int) -> some View {
        HStack(spacing: 10) {
            ProgressView()
            Text("Importing \(current) of \(total)…")
                .font(.subheadline)
            Spacer()
            Button("Cancel", role: .cancel) { cancelImport() }
                .font(.subheadline)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
        .accessibilityIdentifier(A11yID.Library.importProgress)
    }

    private var importSuccessBanner: some View {
        Label(lastImportMessage, systemImage: "checkmark.circle.fill")
        .font(.subheadline.weight(.semibold))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: Capsule())
        .foregroundStyle(.green)
        .padding(.bottom, 12)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .task(id: lastImportMessage) {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { lastImportMessage = "" }
        }
    }

    private var listSections: [LibraryFilterLogic.Section] {
        LibraryFilterLogic.sections(for: filteredSongs, sort: sort)
    }

    private var filteredSongs: [Song] {
        songs
            .filter { categoryFilter == nil || $0.category == categoryFilter }
            .filter { $0.matches(vocalFilter: vocalFilter) }
            .filter { LibraryFilterLogic.matchesBPMRange(song: $0, min: bpmMin, max: bpmMax) }
            .filter { LibraryFilterLogic.matchesKeyFilter(song: $0, selectedKeys: selectedKeys) }
            .filter { LibraryFilterLogic.matchesFavoritesOnly(song: $0, favoritesOnly: favoritesOnly) }
            .filter { LibraryFilterLogic.matchesSearch(song: $0, query: searchText) }
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

    private func toggleFavorite(_ song: Song) {
        song.isFavorite.toggle()
        Haptics.tap()
    }

    private func deleteSong(_ song: Song) {
        for mix in song.mixes {
            AudioStorage.deleteFile(named: mix.fileName)
        }
        modelContext.delete(song)
        songPendingDelete = nil
    }

    private var deleteDialogTitle: String {
        guard let song = songPendingDelete else { return "Delete Song?" }
        return "Delete \"\(song.title)\"?"
    }

    private var addToProjectPresented: Binding<Bool> {
        Binding(
            get: { songForProject != nil },
            set: { if !$0 { songForProject = nil } }
        )
    }

    private var deleteDialogPresented: Binding<Bool> {
        Binding(
            get: { songPendingDelete != nil },
            set: { if !$0 { songPendingDelete = nil } }
        )
    }

    private func deleteDialogMessage(for song: Song) -> String {
        let mixCount = song.mixes.count
        let mixWord = mixCount == 1 ? "mix" : "mixes"
        return "This removes \(mixCount) \(mixWord) and audio files from this device. This can't be undone."
    }

    private func finishImport(results: [ImportedAudio], failures: [String]) {
        importProgress = nil
        importTask = nil
        guard !results.isEmpty else {
            importFailures = failures
            return
        }

        let plan = ImportPlanner.plan(results, existing: songs)
        if plan.needsReview {
            pendingImportPlan = plan
            pendingImportFailures = failures
            return
        }

        applyImport(plan: plan, failures: failures)
    }

    private func commitImportPlan() {
        guard let plan = pendingImportPlan else { return }
        let failures = pendingImportFailures
        pendingImportPlan = nil
        pendingImportFailures = []
        applyImport(plan: plan, failures: failures)
    }

    private func applyImport(plan: ImportPlan, failures: [String]) {
        let outcome = SongImportService.execute(plan, into: modelContext)
        var parts: [String] = []
        if outcome.newSongs > 0 {
            parts.append("\(outcome.newSongs) new song\(outcome.newSongs == 1 ? "" : "s")")
        }
        if outcome.addedVersions > 0 {
            parts.append("\(outcome.addedVersions) new version\(outcome.addedVersions == 1 ? "" : "s")")
        }
        withAnimation { lastImportMessage = "Imported " + parts.joined(separator: ", ") }
        Haptics.success()
        if !failures.isEmpty {
            importFailures = failures
        }
    }

    private var importResolutionPresented: Binding<Bool> {
        Binding(
            get: { pendingImportPlan != nil },
            set: { if !$0 { pendingImportPlan = nil; pendingImportFailures = [] } }
        )
    }

    private func cancelImport() {
        importTask?.cancel()
        importTask = nil
        importProgress = nil
    }

    private var importFailureAlertPresented: Binding<Bool> {
        Binding(get: { !importFailures.isEmpty }, set: { if !$0 { importFailures = [] } })
    }

    private var importFailureMessage: String {
        if importFailures.count == 1 {
            return "Could not import \"\(importFailures[0])\"."
        }
        return "Could not import \(importFailures.count) files: \(importFailures.joined(separator: ", "))."
    }

    private func resetFilters() {
        bpmMin = LibraryFilterLogic.bpmRangeLimit.lowerBound
        bpmMax = LibraryFilterLogic.bpmRangeLimit.upperBound
        selectedKeys.removeAll()
        vocalFilter = .all
        favoritesOnly = false
        categoryFilter = nil
        searchText = ""
    }
}

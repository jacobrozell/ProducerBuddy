import SwiftUI
import SwiftData

/// App settings: appearance, feedback, external links, and data management.
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AudioPlayer.self) private var audioPlayer

    @AppStorage("appearance") private var appearance: AppAppearance = .system
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("versionImport.autoAddOnPrefixMatch") private var autoAddOnPrefixMatch = true
    @AppStorage("versionImport.autoSuggestExportPrefix") private var autoSuggestExportPrefix = true
    @AppStorage("versionImport.autoMatchVersions") private var autoMatchVersions = true
    @AppStorage("versionImport.askWhenDurationDiffers") private var askWhenDurationDiffers = true

    @Query private var songs: [Song]
    @Query private var projects: [Project]

    @State private var showingDeleteConfirm = false
    @State private var isLoadingDemoTracks = false
    @State private var isOrganizingLibrary = false
    @State private var organizeResultMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                importSection
                feedbackSection
                aboutSection
                dataSection
            }
            .brandFormChrome()
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Library Organized", isPresented: organizeResultPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(organizeResultMessage ?? "")
            }
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: $appearance) {
                ForEach(AppAppearance.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var importSection: some View {
        Section {
            Toggle("Auto-add on export prefix match", isOn: $autoAddOnPrefixMatch)
            Toggle("Suggest export prefix", isOn: $autoSuggestExportPrefix)
            Toggle("Auto-match similar titles", isOn: $autoMatchVersions)
            Toggle("Ask when length differs", isOn: $askWhenDurationDiffers)
        } header: {
            Text("Import & Versions")
        } footer: {
            Text(
                "Prefix matches add a version automatically when enabled. "
                + "Uncertain matches open an import review sheet."
            )
        }
    }

    private var feedbackSection: some View {
        Section("Feedback") {
            Toggle("Haptics", isOn: $hapticsEnabled)
        }
    }

    private var aboutSection: some View {
        Section("About") {
            Link(destination: AppLinks.privacy) {
                Label("Privacy Policy", systemImage: "hand.raised")
            }
            Link(destination: AppLinks.support) {
                Label("Support", systemImage: "questionmark.circle")
            }
            Link(destination: AppLinks.accessibility) {
                Label("Accessibility Statement", systemImage: "accessibility")
            }
            if let tipJar = AppLinks.tipJar {
                Link(destination: tipJar) {
                    Label("Leave a Tip", systemImage: "cup.and.saucer")
                }
                .accessibilityIdentifier(A11yID.Settings.tipJar)
            }
            Button {
                hasCompletedOnboarding = false
            } label: {
                Label("Show Intro Again", systemImage: "sparkles")
            }
            LabeledContent("Version", value: appVersion)
        }
    }

    private var dataSection: some View {
        Section {
            if DemoAudioSeeder.hasBundleTracks {
                Button {
                    loadDemoTracks()
                } label: {
                    Label(
                        isLoadingDemoTracks ? "Loading Demo Tracks…" : "Load Demo Tracks",
                        systemImage: "music.note.list"
                    )
                }
                .disabled(isLoadingDemoTracks || isOrganizingLibrary)
                .accessibilityIdentifier(A11yID.Settings.loadDemoTracks)
            }
            Button {
                organizeLibrary()
            } label: {
                Label(
                    isOrganizingLibrary ? "Organizing Library…" : "Organize Library",
                    systemImage: "rectangle.stack.badge.person.crop"
                )
            }
            .disabled(isOrganizingLibrary || isLoadingDemoTracks || songs.isEmpty)
            .accessibilityIdentifier(A11yID.Settings.organizeLibrary)
            Button(role: .destructive) {
                showingDeleteConfirm = true
            } label: {
                Label("Delete All Data", systemImage: "trash")
            }
            .accessibilityIdentifier(A11yID.Settings.deleteAllData)
            .confirmationDialog(
                "Delete all songs, mixes, and projects? This also removes imported audio and can't be undone.",
                isPresented: $showingDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete Everything", role: .destructive) { deleteAllData() }
                Button("Cancel", role: .cancel) {}
            }
        } header: {
            Text("Data")
        } footer: {
            Text("\(songs.count) songs · \(projects.count) projects")
        }
    }

    private var organizeResultPresented: Binding<Bool> {
        Binding(
            get: { organizeResultMessage != nil },
            set: { if !$0 { organizeResultMessage = nil } }
        )
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    /// Stops playback, deletes every model, and clears stored audio files.
    private func deleteAllData() {
        audioPlayer.stop()
        for song in songs {
            for mix in song.mixes { AudioStorage.deleteFile(named: mix.fileName) }
            modelContext.delete(song)
        }
        for project in projects {
            modelContext.delete(project)
        }
        Haptics.success()
    }

    @MainActor
    private func loadDemoTracks() {
        guard !isLoadingDemoTracks else { return }
        isLoadingDemoTracks = true
        Task {
            let imported = await DemoAudioSeeder.importBundleTracks()
            _ = SongImportService.importSongs(imported, into: modelContext)
            let allSongs = (try? modelContext.fetch(FetchDescriptor<Song>())) ?? []
            let organized = SongCatalogOrganizer.organize(songs: allSongs, into: modelContext)
            DemoAudioSeeder.createDemoProjectIfNeeded(into: modelContext)
            try? modelContext.save()
            isLoadingDemoTracks = false
            if !imported.isEmpty { Haptics.success() }
            if organized.prefixesAssigned > 0 || organized.songsMerged > 0 {
                organizeResultMessage = organizeSummary(organized)
            }
        }
    }

    @MainActor
    private func organizeLibrary() {
        guard !isOrganizingLibrary, !songs.isEmpty else { return }
        isOrganizingLibrary = true
        let allSongs = (try? modelContext.fetch(FetchDescriptor<Song>())) ?? []
        let result = SongCatalogOrganizer.organize(songs: allSongs, into: modelContext)
        isOrganizingLibrary = false
        if result.prefixesAssigned > 0 || result.songsMerged > 0 {
            Haptics.success()
            organizeResultMessage = organizeSummary(result)
        } else {
            organizeResultMessage = "Nothing to change — your library is already organized."
        }
    }

    private func organizeSummary(_ result: CatalogOrganizeResult) -> String {
        var parts: [String] = []
        if result.prefixesAssigned > 0 {
            parts.append("\(result.prefixesAssigned) export prefix\(result.prefixesAssigned == 1 ? "" : "es") assigned")
        }
        if result.songsMerged > 0 {
            parts.append("\(result.songsMerged) duplicate song\(result.songsMerged == 1 ? "" : "s") merged")
        }
        return parts.joined(separator: " · ")
    }
}

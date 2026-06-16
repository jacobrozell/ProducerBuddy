import SwiftUI
import SwiftData

/// App settings: appearance, feedback, external links, and data management.
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AudioPlayer.self) private var audioPlayer

    @AppStorage("appearance") private var appearance: AppAppearance = .system
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    @Query private var songs: [Song]
    @Query private var projects: [Project]

    @State private var showingDeleteConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                feedbackSection
                aboutSection
                dataSection
            }
            .navigationTitle("Settings")
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
            LabeledContent("Version", value: appVersion)
        }
    }

    private var dataSection: some View {
        Section {
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
}

import SwiftUI
import SwiftData

/// The sequencing workspace for a project. Shows the running order with each
/// track's energy move (rise/fall) versus the previous track, surfaces flow
/// warnings, supports drag-to-reorder, and can auto-suggest an order.
struct ProjectDetailView: View {
    @Bindable var project: Project
    @Environment(\.modelContext) private var modelContext

    @State private var showingEditor = false
    @State private var showingAddTracks = false
    @State private var showingShareCard = false

    var body: some View {
        List {
            summarySection
            tracksSection
        }
        .navigationTitle(project.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Add Tracks", systemImage: "plus") { showingAddTracks = true }
                    Button("Suggest Order", systemImage: "wand.and.stars") { suggestOrder() }
                        .disabled(project.tracks.count < 3)
                    Button("Edit Project", systemImage: "pencil") { showingEditor = true }
                    Button("Share Card", systemImage: "photo") { showingShareCard = true }
                    ShareLink(item: tracklistText) {
                        Label("Share Tracklist", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            ProjectEditorView(project: project)
        }
        .sheet(isPresented: $showingAddTracks) {
            AddTracksView(project: project)
        }
        .sheet(isPresented: $showingShareCard) {
            ShareCardSheet(content: .project(project))
        }
    }

    private var summarySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                if !project.subtitle.isEmpty {
                    Text(project.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 16) {
                    stat(value: "\(project.tracks.count)", label: "Tracks")
                    stat(value: runtime, label: "Runtime")
                    stat(value: project.kind.displayName, label: "Type")
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var tracksSection: some View {
        Section("Running Order") {
            if project.tracks.isEmpty {
                Button {
                    showingAddTracks = true
                } label: {
                    Label("Add Tracks", systemImage: "plus")
                }
            } else {
                ForEach(Array(zip(orderedTracks, flow)), id: \.0.id) { track, analysis in
                    TrackFlowRow(
                        position: track.position + 1,
                        song: track.song,
                        analysis: analysis
                    )
                }
                .onMove(perform: moveTracks)
                .onDelete(perform: deleteTracks)
            }
        }
    }

    private func stat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.headline)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }

    private var orderedTracks: [ProjectTrack] {
        project.orderedTracks
    }

    /// Flow analysis for the current order, computed from each song's BPM.
    private var flow: [FlowAnalysis] {
        SequencingEngine.analyze(bpms: orderedTracks.map { $0.song?.bpm ?? 0 })
    }

    private var runtime: String {
        let total = Int(project.totalDuration.rounded())
        guard total > 0 else { return "0:00" }
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    private var tracklistText: String {
        var lines = ["\(project.title) — \(project.kind.displayName)"]
        for track in orderedTracks {
            guard let song = track.song else { continue }
            lines.append("\(track.position + 1). \(song.title)")
        }
        lines.append("\nMade with ProducerBuddy")
        return lines.joined(separator: "\n")
    }

    private func moveTracks(from source: IndexSet, to destination: Int) {
        var tracks = orderedTracks
        tracks.move(fromOffsets: source, toOffset: destination)
        renumber(tracks)
    }

    private func deleteTracks(at offsets: IndexSet) {
        var tracks = orderedTracks
        let toDelete = offsets.map { tracks[$0] }
        tracks.remove(atOffsets: offsets)
        for track in toDelete {
            modelContext.delete(track)
        }
        renumber(tracks)
    }

    private func suggestOrder() {
        let pairs = orderedTracks.map { (id: $0.id, bpm: $0.song?.bpm ?? 0) }
        let suggested = SequencingEngine.suggestOrder(for: pairs)
        let byID = Dictionary(uniqueKeysWithValues: orderedTracks.map { ($0.id, $0) })
        let reordered = suggested.compactMap { byID[$0] }
        withAnimation {
            renumber(reordered)
        }
    }

    /// Writes sequential positions back onto the tracks in the given order.
    private func renumber(_ tracks: [ProjectTrack]) {
        for (index, track) in tracks.enumerated() {
            track.position = index
        }
    }
}

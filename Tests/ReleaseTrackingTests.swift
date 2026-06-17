import Testing
@testable import MixStack

@Suite("Release URL validation")
struct ReleaseURLValidatorTests {
    @Test("Empty URL is allowed")
    func emptyAllowed() {
        #expect(ReleaseURLValidator.isValid(""))
        #expect(ReleaseURLValidator.isValid("   "))
    }

    @Test("HTTPS links pass")
    func httpsPasses() {
        #expect(ReleaseURLValidator.isValid("https://open.spotify.com/track/abc"))
        #expect(ReleaseURLValidator.isValid("http://example.com"))
    }

    @Test("Invalid schemes fail")
    func invalidSchemesFail() {
        #expect(ReleaseURLValidator.isValid("spotify:track") == false)
        #expect(ReleaseURLValidator.isValid("not a url") == false)
    }
}

@Suite("Waveform slice")
struct WaveformSliceTests {
    @Test("Peak index maps time into buckets")
    func peakIndexMapsTime() {
        #expect(WaveformSlice.peakIndex(for: 0, trackDuration: 100, sampleCount: 100) == 0)
        #expect(WaveformSlice.peakIndex(for: 50, trackDuration: 100, sampleCount: 100) == 50)
        #expect(WaveformSlice.peakIndex(for: 124, trackDuration: 124, sampleCount: 62) == 61)
    }

    @Test("Visible peaks returns requested bar count")
    func visiblePeaksCount() {
        let samples = (0..<100).map { Float($0) / 100 }
        let bars = WaveformSlice.visiblePeaks(
            samples: samples,
            centerTime: 50,
            trackDuration: 100,
            barCount: 48
        )
        #expect(bars.count == 48)
    }
}

@Suite("Project release progress")
struct ProjectReleaseTests {
    @Test("Released track count ignores unreleased songs")
    func releasedCount() {
        let project = Project(title: "EP")
        let released = Song(title: "A", category: .released)
        released.releaseDate = .now
        let wip = Song(title: "B", category: .workInProgress)
        project.tracks = [
            ProjectTrack(position: 0, song: released),
            ProjectTrack(position: 1, song: wip)
        ]
        #expect(project.releasedTrackCount == 1)
        #expect(project.totalTrackCount == 2)
        #expect(project.isFullyReleased == false)
    }
}

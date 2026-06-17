import Testing
@testable import MixStack

@Suite("Playback loop logic")
struct PlaybackLoopLogicTests {

    @Test("Normalizes section within track duration")
    func normalizedSection() {
        let section = PlaybackLoopLogic.normalizedSection(start: 10, end: 45, duration: 60)
        #expect(section?.start == 10)
        #expect(section?.end == 45)
    }

    @Test("Rejects sections shorter than minimum length")
    func rejectsShortSection() {
        #expect(PlaybackLoopLogic.normalizedSection(start: 10, end: 10.2, duration: 60) == nil)
    }

    @Test("Default section wraps current playhead")
    func defaultSection() {
        let section = PlaybackLoopLogic.defaultSection(around: 20, duration: 120, length: 30)
        #expect(section?.start == 20)
        #expect(section?.end == 50)
    }

    @Test("Restart triggers near section end")
    func shouldRestart() {
        #expect(PlaybackLoopLogic.shouldRestart(currentTime: 29.96, end: 30))
        #expect(PlaybackLoopLogic.shouldRestart(currentTime: 10, end: 30) == false)
    }
}

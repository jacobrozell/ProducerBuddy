import Testing
@testable import MixStack

@Suite("Audio Player", .serialized)
@MainActor
struct AudioPlayerTests {

    @Test("A fresh player is idle with no loaded mix")
    func startsIdle() {
        let player = AudioPlayer()
        #expect(player.currentMix == nil)
        #expect(player.isPlaying == false)
        #expect(player.currentTime == 0)
        #expect(player.isLooping == false)
    }

    @Test("Toggling loop flips the flag")
    func loopToggles() {
        let player = AudioPlayer()
        player.isLooping = true
        #expect(player.isLooping)
        player.isLooping = false
        #expect(player.isLooping == false)
    }

    @Test("Seek and skip are no-ops without a loaded track")
    func transportSafeWhenEmpty() {
        let player = AudioPlayer()
        // Should not crash or move time when nothing is loaded.
        player.seek(to: 30)
        player.skip(by: 15)
        #expect(player.currentTime == 0)
    }

    @Test("Switching to a mix with no backing file fails gracefully")
    func switchWithMissingFile() {
        let player = AudioPlayer()
        let mix = Mix(name: "Original", fileName: "missing.m4a")
        // No file backs this mix, so playback can't start; the call must leave
        // the player idle rather than crash.
        player.switchMix(to: mix)
        #expect(player.currentMix == nil)
        #expect(player.isPlaying == false)
    }

    @Test("Queuing mixes sets up next/previous availability")
    func queueTracksNavigation() {
        let player = AudioPlayer()
        let mixes = [
            Mix(name: "A", fileName: "a.m4a"),
            Mix(name: "B", fileName: "b.m4a"),
            Mix(name: "C", fileName: "c.m4a")
        ]
        player.playQueue(mixes)
        #expect(player.queue.count == 3)
        #expect(player.queueIndex == 0)
        #expect(player.hasPrevious == false)
        #expect(player.hasNext)
    }

    @Test("playNext and playPrevious move through the queue")
    func queueAdvance() {
        let player = AudioPlayer()
        let mixes = [Mix(name: "A", fileName: "a.m4a"), Mix(name: "B", fileName: "b.m4a")]
        player.playQueue(mixes)
        player.playNext()
        #expect(player.queueIndex == 1)
        #expect(player.hasNext == false)
        player.playPrevious()
        #expect(player.queueIndex == 0)
    }

    @Test("Empty queue is rejected")
    func emptyQueueIgnored() {
        let player = AudioPlayer()
        player.playQueue([])
        #expect(player.queue.isEmpty)
        #expect(player.hasNext == false)
    }

    @Test("Stop clears the queue")
    func stopClearsQueue() {
        let player = AudioPlayer()
        player.playQueue([Mix(name: "A", fileName: "a.m4a"), Mix(name: "B", fileName: "b.m4a")])
        player.stop()
        #expect(player.queue.isEmpty)
        #expect(player.queueIndex == 0)
    }
}

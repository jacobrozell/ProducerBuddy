import Testing
@testable import ProducerBuddy

@Suite("Audio Player")
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
}

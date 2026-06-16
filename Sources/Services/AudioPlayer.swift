import Foundation
import AVFoundation
import Observation

/// A small observable wrapper around `AVAudioPlayer` that drives the app's
/// playback UI. A single instance is shared through the environment so the now-
/// playing bar and detail screens stay in sync.
@Observable
@MainActor
final class AudioPlayer: NSObject {
    /// The mix currently loaded into the player, if any.
    private(set) var currentMix: Mix?
    private(set) var isPlaying = false
    private(set) var currentTime: Double = 0
    private(set) var duration: Double = 0
    /// When true the current mix repeats on completion — handy for A/B'ing a
    /// section of a track on loop.
    var isLooping = false {
        didSet { player?.numberOfLoops = isLooping ? -1 : 0 }
    }

    private var player: AVAudioPlayer?
    private var timer: Timer?

    /// Loads and begins playing a mix. Re-tapping the same mix toggles pause.
    func play(_ mix: Mix) {
        if currentMix?.id == mix.id, player != nil {
            togglePlayPause()
            return
        }

        stop()
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            let player = try AVAudioPlayer(contentsOf: mix.fileURL)
            player.delegate = self
            player.prepareToPlay()
            self.player = player
            self.currentMix = mix
            self.duration = player.duration
            player.numberOfLoops = isLooping ? -1 : 0
            player.play()
            isPlaying = true
            startTimer()
        } catch {
            // Leaves the player in a stopped state; the UI reflects !isPlaying.
            currentMix = nil
        }
    }

    func togglePlayPause() {
        guard let player else { return }
        if player.isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    func seek(to time: Double) {
        guard let player else { return }
        player.currentTime = max(0, min(time, player.duration))
        currentTime = player.currentTime
    }

    /// Jumps forward (positive) or backward (negative) by `seconds`, clamped to
    /// the track bounds.
    func skip(by seconds: Double) {
        guard let player else { return }
        seek(to: player.currentTime + seconds)
    }

    /// Swaps to a different mix while keeping the current playback position and
    /// play/pause state — the core of A/B comparing two versions of a song.
    func switchMix(to mix: Mix) {
        guard mix.id != currentMix?.id else { return }
        let resumeTime = currentTime
        let wasPlaying = isPlaying
        play(mix)
        seek(to: resumeTime)
        if !wasPlaying { togglePlayPause() }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        player?.stop()
        player = nil
        isPlaying = false
        currentTime = 0
        currentMix = nil
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let player = self.player else { return }
                self.currentTime = player.currentTime
            }
        }
    }
}

extension AudioPlayer: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.currentTime = 0
        }
    }
}

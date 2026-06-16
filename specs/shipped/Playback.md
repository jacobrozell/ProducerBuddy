# Playback (shipped)

Shared `AudioPlayer` in environment. Drives now-playing bar, detail play
buttons, and project queue.

## AudioPlayer (`Sources/Services/AudioPlayer.swift`)

`@Observable @MainActor` wrapper around `AVAudioPlayer`.

### State

| Property | Purpose |
|----------|---------|
| `currentMix` | Loaded mix |
| `isPlaying`, `currentTime`, `duration` | Transport (timer 0.25s) |
| `isLooping` | `numberOfLoops = -1` when true |
| `queue`, `queueIndex` | Project playback |
| `hasNext`, `hasPrevious` | Queue nav |

### Modes

**Single:** `play(mix)` clears queue. Same mix again → toggle pause.

**Queue:** `playQueue(mixes, startAt:)` — auto-advance on
`audioPlayerDidFinishPlaying` via `playNext()`.

### switchMix(to:)

A/B compare without losing position:

1. Save `currentTime`, `wasPlaying`
2. `start(newMix)` → `seek(resumeTime)`
3. Restore pause if needed
4. **Queue preserved**

### stop()

Clears player, queue, `MPNowPlayingInfoCenter`.

## UI

### NowPlayingBar (`Sources/Components/NowPlayingBar.swift`)

Progress, title/mix, time, play/pause, stop. Tap row → `FullPlayerView` sheet.
`Haptics.tap()` on play/pause.

### FullPlayerView (`Sources/Views/FullPlayerView.swift`)

| Control | Behavior |
|---------|----------|
| Waveform scrubber | `WaveformView` + `onSeek` |
| ±15s | when `queue.isEmpty` |
| Prev/next | when queue active |
| Loop | binds `isLooping` |
| Mix picker | segmented; `switchMix` when >1 mix |

`ensureWaveform()` backfills missing `mix.waveform` on appear.

Fallback `Slider` until waveform exists.

## Lock screen / background

First `start()` configures:

- `AVAudioSession` `.playback`
- `MPNowPlayingInfoCenter` — title, artist, album (mix name), duration, elapsed, rate
- `MPRemoteCommandCenter` — play, pause, toggle, ±15s, prev/next, scrub position

Info.plist `audio` background mode required.

## Verification

- Last verified: 2026-06-16
- Code: `AudioPlayer.swift`, `NowPlayingBar.swift`, `FullPlayerView.swift`
- Tests: `AudioPlayerTests.swift`

# Waveforms (shipped)

Cached peak arrays on `Mix` for drawing and scrubbing.

## Generation — WaveformGenerator

`Sources/Services/WaveformGenerator.swift`

```swift
static func generate(url: URL, buckets: Int = 240) async -> [Float]
```

1. Stream `AVAudioFile` in 65,536-frame blocks
2. Per sample: peak of downmixed channel abs values
3. Map position → bucket index; keep max per bucket
4. `normalized()` — divide by global max (0…1)

Pure helper `peaks(from:buckets:)` for unit tests without files.

## Storage

`Mix.waveform: [Float]`. `hasWaveform` = non-empty.

## When generated

| Trigger | Code |
|---------|------|
| Library import | `SongImportService.scheduleWaveformGeneration` |
| Add mix on detail | `SongDetailView.addMix` Task |
| Full player open | `FullPlayerView.ensureWaveform` (backfill) |

## Rendering — WaveformView

`Sources/Components/WaveformView.swift` — SwiftUI `Canvas`:

- Vertical bars per sample bucket
- `progress` 0…1 splits played vs unplayed color
- `DragGesture(minimumDistance: 0)` → `onSeek(fraction)` when provided

## Surfaces

| Location | Size | Seeks? |
|----------|------|--------|
| FullPlayerView | height 64 | yes |
| MixRow (detail) | 90×28 | no (display progress) |

VoiceOver on full player: adjustable element, ±15s steps (bar decorative).

## Verification

- Last verified: 2026-06-16
- Code: `WaveformGenerator.swift`, `WaveformView.swift`
- Tests: `WaveformTests.swift`

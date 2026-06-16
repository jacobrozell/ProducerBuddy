# Audio Analysis — BPM & Key (shipped)

`AudioAnalyzer` (`Sources/Services/AudioAnalyzer.swift`) — lightweight on-device
estimates. **Not** commercial-grade. User can correct in editor.

Vocal detection shares the same loader; see [VocalDetection](../VocalDetection.md).

## API

```swift
struct AudioAnalysis: Sendable {
    let bpm: Int?
    let key: MusicalKey?
    let vocal: VocalAnalysis
}

static func analyze(url: URL) async -> AudioAnalysis
```

Runs off main actor (static methods on global executor).

## Pipeline

```
url → loadMonoSamples → estimateBPM / estimateKey / estimateVocalPresence
```

### loadMonoSamples

- Max 90s via `AVAudioFile`
- Downmix to mono
- Decimate toward 11,025 Hz (block average)
- Nil if unreadable or < ~1s

## BPM (`estimateBPM`)

1. Short-time energy: 512-sample window, 256 hop
2. Onset envelope: `max(0, energy[i] - energy[i-1])`
3. Subtract mean
4. Autocorrelate lags for 70–180 BPM
5. `bpm = 60 * framesPerSecond / bestLag`
6. Fold octaves into range

Returns `nil` if too short or no positive autocorrelation score.

## Key (`estimateKey`)

1. 12-bin chromagram: Goertzel power at MIDI C2–B5
2. Normalize chroma
3. Score 24 keys (12 tonics × maj/min) via Pearson correlation with
   Krumhansl–Schmuckler profiles (rotated per tonic)
4. Best `MusicalKey` via `MusicalKey.from(pitchClass:isMajor:)`

## When it runs

| Trigger | Code |
|---------|------|
| Library import | `SongImportService.scheduleMetadataDetection` |
| On demand | `SongDetailView.detectMetadata()` |
| Secondary mix add | **not** run |

Writes `song.bpm`, `song.key` when non-nil. Vocal via `applyDetectedVocals`
unless manual.

## Verification

- Last verified: 2026-06-16
- Code: `AudioAnalyzer.swift`, `MusicalKey.swift`
- Tests: `AudioAnalyzerTests.swift`

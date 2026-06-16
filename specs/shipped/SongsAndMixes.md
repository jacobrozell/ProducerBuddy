# Songs & Mixes (shipped)

Song detail, editing, and multiple audio versions.

## SongDetailView (`Sources/Views/SongDetailView.swift`)

### Sections

1. Header — category gradient, `CategoryBadge`, `StarRatingView`
2. Details — artist, genre, BPM, key, `VocalConfidenceMeter`
3. Mixes — `MixRow` list or "Import a Mix"
4. Notes — if non-empty

### Toolbar menu

| Action | Notes |
|--------|-------|
| Edit | `SongEditorView` sheet |
| Add Mix | `audioImporter` single file |
| Detect Audio Metadata | `AudioAnalyzer` on primary mix; `ReleaseSurface.audioAnalysis` |
| Share Card | `ShareCardSheet`; `ReleaseSurface.shareCards` |
| Share Text | `ShareLink` blurb |

### detectMetadata()

Sets `isDetecting` overlay. On primary mix URL:

```swift
let analysis = await AudioAnalyzer.analyze(url:)
// bpm, key, song.applyDetectedVocals(analysis.vocal)
```

### addMix(fileName:duration:)

Creates `Mix(name: "Mix N", isPrimary: mixes.isEmpty)`. Schedules waveform
generation only (no BPM/key re-run on secondary mixes).

### setPrimary / deleteMixes

- Star toggles `isPrimary` on one mix, clears others
- Delete stops player if current mix; removes file from disk

## MixRow (private in SongDetailView)

Play/pause → `audioPlayer.play(mix)`. Mini `WaveformView` when `hasWaveform`.

## SongEditorView (`Sources/Views/SongEditorView.swift`)

Create (`song: nil`) or edit. Fields: title*, artist, genre, BPM 40–300, key,
vocals picker, category, rating, notes.

**Vocal manual override** (`applyVocalPresence`):

- `instrumental` / `vocals` → `vocalPresenceIsManual = true`, `vocalConfidence = nil`
- `unknown` → `vocalPresenceIsManual = false`

Blocks auto-detect overwrite. See [VocalDetection](../VocalDetection.md).

## Primary mix rules

| Rule | Behavior |
|------|----------|
| First mix | `isPrimary = true` |
| Library play | `song.primaryMix` |
| Project playback | each track's `song.primaryMix` |
| Analysis | primary mix only at import |

## Verification

- Last verified: 2026-06-16
- Code: `SongDetailView`, `SongEditorView`, `VocalConfidenceMeter`, `CategoryBadge`, `StarRatingView`
- Tests: `VocalDetectionTests` (manual override), `ModelTests`

# Data Model (shipped)

SwiftData persistence. See also [Architecture](../Architecture.md) for layer rules.

## Relationships

```
Song 1──* Mix              (cascade delete)
Song 1──* ProjectTrack
Project 1──* ProjectTrack  (position-ordered join)
```

Same `Song` can appear in multiple projects via `ProjectTrack`. Deleting a
`Song` removes its mixes and project track rows.

## Song (`Sources/Models/Song.swift`)

| Field | Notes |
|-------|-------|
| `title`, `artist`, `genre` | Display |
| `bpm` | Int; sequencing input |
| `keyRaw` / `key` | `MusicalKey` |
| `categoryRaw` / `category` | `SongCategory` workflow stage |
| `rating` | 0–5 |
| `vocalPresenceRaw`, `vocalConfidence`, `vocalPresenceIsManual` | See [VocalDetection](../VocalDetection.md) |
| `mixes` | `[Mix]` cascade |
| `primaryMix` | computed: `isPrimary` else newest by `dateAdded` |

Key methods: `applyDetectedVocals(_:)`, `matches(vocalFilter:)`,
`hasConfidentVocalLabel`.

## Mix (`Sources/Models/Mix.swift`)

| Field | Notes |
|-------|-------|
| `fileName` | Relative to `Documents/Audio/` |
| `duration` | Cached at import |
| `waveform` | `[Float]` 0…1 peaks, empty until generated |
| `isPrimary` | User's best version |
| `fileURL` | computed via `AudioStorage.audioDirectory` |

Audio is **copied** at import; external URLs are not kept.

## Project (`Sources/Models/Project.swift`)

| Field | Notes |
|-------|-------|
| `kind` | `ProjectKind`: single, ep, album, mixtape |
| `tracks` | `[ProjectTrack]` |
| `orderedTracks` | sorted by `position` |
| `totalDuration` | sum of primary mix durations |

## ProjectTrack (`Sources/Models/ProjectTrack.swift`)

`position` (0-based), `song`, `project`.

## Enums

**SongCategory** — `idea` → `demo` → `workInProgress` → `readyToMix` →
`mastered` → `released`. Each has `displayName`, `symbolName`, `tint` (SwiftUI
color for rows/cards).

**MusicalKey** — 24 keys + `unknown`. `camelot` / `camelotCode` for harmonic
mixing. `from(pitchClass:isMajor:)` used by analyzer.

**VocalPresence** — `unknown`, `instrumental`, `vocals`.

## Verification

- Last verified: 2026-06-16
- Code: `Sources/Models/*.swift`
- Tests: `ModelTests.swift`

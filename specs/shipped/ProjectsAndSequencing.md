# Projects & Sequencing (shipped)

Release projects and BPM/key flow analysis.

## Project list

`ProjectListView` — `@Query` projects by `dateCreated` desc. `ProjectEditorView`
sheet for create. Row shows kind, track count, runtime.

## Project detail

`ProjectDetailView` — sequencing workspace.

### Sections

1. Summary — subtitle, tracks, runtime, kind
2. Energy Flow — `EnergyCurveChart` + `FlowLegend` if ≥2 tracks
3. Running Order — `TrackFlowRow`, drag reorder, delete

### Actions

| Action | Condition |
|--------|-----------|
| Play in Order | `playableMixes` non-empty → `audioPlayer.playQueue` |
| Add Tracks | `AddTracksView` sheet |
| Suggest Order | ≥3 tracks |
| Share Card / Tracklist | see [Sharing](Sharing.md) |

`playableMixes` = ordered `song.primaryMix` compactMap.

### Reorder

`moveTracks` / `deleteTracks` → `renumber` writes `position` 0…n-1.

## SequencingEngine

`Sources/Services/SequencingEngine.swift` — pure, no SwiftData.

### Energy moves (BPM proxy)

| Move | Rule |
|------|------|
| opener | index 0 |
| steady | \|ΔBPM\| ≤ 4 |
| rise | ΔBPM > 4 |
| fall | ΔBPM < -4 |

`abruptBPMThreshold = 30` → warning.

### Key clashes

`analyze(bpms:keys:)` adds `keyClash` when adjacent keys known and not
Camelot-compatible.

`areHarmonicallyCompatible(a,b)`:

- Same Camelot number (relative maj/min OK)
- Same ring, adjacent number (±1, wrap 12↔1)
- Unknown → never clash

### suggestOrder

For >2 tracks:

1. Sort by BPM ascending
2. Peak = top third (min 1 track)
3. Return: body ascending + peak reversed

Applied via `SuggestOrderPreviewSheet` — shows `orderMoves` diff and new order
before commit (`ProjectDetailView`).

### peakIndex

Highest BPM; ties → earliest index. Used by `EnergyCurveChart`.

## UI components

- `EnergyCurveChart` — Swift Charts BPM line/area, orange peak marker
- `TrackFlowRow` — position, title, BPM, Camelot, delta, clash/warning icons, move badge (tap for popover)
- `FlowLegend` — explains badges under chart
- `AddTracksView` — pick library songs not in project

## Verification

- Last verified: 2026-06-17
- Code: `ProjectListView`, `ProjectDetailView`, `SuggestOrderPreviewSheet`, `SequencingEngine`, `EnergyCurveChart`, `TrackFlowRow`, `FlowLegend`
- Tests: `SequencingEngineTests.swift`

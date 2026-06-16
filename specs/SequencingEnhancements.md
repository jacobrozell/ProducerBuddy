# Sequencing Enhancements Spec

Deepen **project running-order** workflows for EPs, mixtapes, and beat tapes —
beyond today's BPM energy chart and Camelot clash warnings.

---

## Goals

| Goal | Success looks like |
|------|-------------------|
| Trust auto-suggest | I preview order changes before committing |
| Match intent | Pick "slow burn" vs "front-loaded" arc, not one algorithm |
| Remember DJ brain | Transition notes between tracks survive export |
| Hear the sequence | Gapless or short-gap project playback feels like a listen-through |

## Non-goals

- Automatic beatmatching or tempo sync playback.
- Stem-aware transitions.
- Replacing Rekordbox/Serato for live DJ sets.

---

## Features

### 1. Suggest Order — diff preview

**Current:** `SequencingEngine.suggestOrder` rewrites positions immediately.

**New flow:**

1. User taps **Suggest Order…**
2. Sheet shows side-by-side or unified list:
   - Tracks that moved: old position → new position
   - Unchanged tracks collapsed
3. Actions: **Apply** · **Cancel**
4. After apply: brief toast + undo snackbar (5 s) restoring previous positions

Engine unchanged; only commit layer is new.

### 2. Arc templates

User picks a target **energy shape** before suggest:

| Template | Behavior |
|----------|----------|
| **Classic build** (default) | Current algorithm: rise to peak ~70% through, wind down |
| **Slow burn** | Delay peak to ~85%; gentler early rises |
| **Front-loaded** | Peak in first third; gradual fade |
| **Two peaks** | Local max at ~35% and ~70% |
| **DJ continuous** | Minimize BPM drops; prefer steady or rising only |

Implementation: weight function over track index when scoring permutations or
greedy swaps — still O(n²) greedy, not TSP optimal.

UI: picker in suggest sheet + optional default in `@AppStorage`.

### 3. Harmonic suggest (stretch)

When adding a track to project, optional **"Compatible keys"** filter using
Camelot neighbours of previous track.

### 4. Transition notes

**Model:** `ProjectTrack.transitionNote: String` (free text, ≤ 280 chars)

- Shown between rows in running order UI
- Included in text blurb export: `→ crossfade 8 bars / key lift`
- Not used by engine in v1

**Stretch:** `introEnergy` / `outroEnergy` enums (low/medium/high) on
`ProjectTrack` for future multi-signal energy model.

### 5. Gapless / gap project playback

**Settings:** Project playback gap — **0 s · 2 s · 4 s** (default 2 s)

- `AudioPlayer` queue: on track end, wait gap then advance
- **Crossfade** (v2): 2 s overlap with `AVAudioEngine` — spec only, defer

Full player shows **Track 2 of 5 · Project Name** in queue mode (may exist ✅).

---

## UI surfaces

### Project detail

- Between `TrackFlowRow`s: collapsed transition note; tap to edit inline
- Suggest Order → preview sheet with arc template picker
- Settings gear on project: playback gap

### Flow legend

- Add arc template name when user last applied suggest (informational)

---

## Integration

| Location | Change |
|----------|--------|
| `SequencingEngine` | Arc template parameter on `suggestOrder` |
| `ProjectTrack` | `transitionNote` |
| `ProjectDetailView` | Preview sheet, transition UI |
| `AudioPlayer` | Inter-track gap |
| `SequencingEngineTests` | Template fixtures |

---

## Testing

- Unit: each arc template produces different order on fixed 5-track fixture
- Unit: diff preview lists only moved tracks
- Unit: undo restores positions
- Manual: Play in Order respects 2 s gap

---

## Verification

- Target release: post-v1 sequencing batch
- Last verified: 2026-06-16 (spec only; **not implemented**)
- Primary code paths: `SequencingEngine`, `ProjectDetailView`, `ProjectTrack`,
  `AudioPlayer`

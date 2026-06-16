# Vocal Detection Spec

Auto-detect whether a song's primary mix contains vocals and surface a
**confidence score** so producers can tag instrumentals vs. vocal demos, filter
the library, and scan a catalog at a glance — without manual listening passes.

**Shipped behavior index:** [`shipped/README.md`](shipped/README.md) · BPM/key
sibling: [`shipped/AudioAnalysis.md`](shipped/AudioAnalysis.md)

Follows the same philosophy as BPM/key detection: a lightweight, on-device
**estimate** the user can correct, not a commercial-grade classifier.

---

## Goals

| Goal | Success looks like |
|------|-------------------|
| Reduce manual tagging | After import, most tracks show a plausible vocal / instrumental label without user action |
| Honest uncertainty | Low-confidence results stay visible as "uncertain" rather than a wrong binary tag |
| Fits existing flows | Runs with import + "Detect BPM & Key"; stored on `Song`; editable in the song editor |
| Library utility | Filter chips: **All · With vocals · Instrumental · Uncertain** |
| Producer trust | Confidence meter explains *why* the app is guessing, and manual override always wins |

## Non-goals

- **Lyric transcription, speaker ID, or language detection.**
- **Stem separation** or isolating the vocal track for playback.
- **Per-mix vocal labels** in v1 — detection runs on the primary mix only; secondary mixes inherit until re-detected.
- **Replacing the user's ears** for release decisions — this is catalog metadata, not mastering QA.
- **Cloud inference** or bundled Core ML models in v1 (see Phase 2).

---

## User stories

1. **Import-first producer** — I drop ten exports off my DAW; the library sorts itself into beats vs. vocal sketches so I can find the instrumentals quickly.
2. **Skeptical producer** — The app says "instrumental (72%)" on a track with a chopped vocal sample; I tap Edit and set **With vocals**; my choice sticks and filters use my label.
3. **Detail reviewer** — On song detail I see a confidence meter next to BPM/key after detection, and I can re-run detection if I swap the primary mix.
4. **Sequencer (later)** — When building a project I can spot vocal-heavy vs. instrumental tracks in the running order (stretch; not required for v1).

---

## Data model

Vocal metadata lives on **`Song`**, mirroring BPM/key: detected from the
**primary mix**, user-overridable.

### `VocalPresence` (value enum)

| Case | Meaning |
|------|---------|
| `unknown` | Not yet analyzed, analysis failed, or confidence below display threshold |
| `instrumental` | No meaningful vocal content detected |
| `vocals` | Sustained or prominent vocal content detected |

### New `Song` fields

| Field | Type | Notes |
|-------|------|-------|
| `vocalPresenceRaw` | `String` | Raw value of `VocalPresence` |
| `vocalConfidence` | `Double?` | `0…1` when analyzed; `nil` when unknown / failed |
| `vocalPresenceIsManual` | `Bool` | `true` after user sets presence in editor; blocks auto-overwrite on re-detect |

Computed property `vocalPresence: VocalPresence` (same pattern as `key` /
`category`).

### `AudioAnalysis` extension

```swift
struct VocalAnalysis: Sendable {
    let presence: VocalPresence  // .unknown when inconclusive
    let confidence: Double?    // 0…1, nil when presence is .unknown
}

struct AudioAnalysis: Sendable {
    let bpm: Int?
    let key: MusicalKey?
    let vocal: VocalAnalysis
}
```

### Persistence rules

1. **On import / background detect** — write `vocalPresence` + `vocalConfidence`
   only when `vocalPresenceIsManual == false`.
2. **Auto-apply threshold** — set a definite label (`instrumental` / `vocals`)
   only when `confidence >= 0.65`; otherwise store `unknown` but **retain**
   the raw confidence for the meter (see UI).
3. **Manual edit** — user picker in `SongEditorView` sets presence, clears
   confidence display to manual state (`vocalPresenceIsManual = true`,
   `vocalConfidence = nil` or keep last auto value read-only — **pick: clear
   confidence when manual** so filters stay trustworthy).
4. **Re-detect** — "Detect BPM & Key" also refreshes vocal analysis unless
   `vocalPresenceIsManual`.

### Schema migration

Pre-release: lightweight add of stored properties (same as waveform on `Mix`).
Before App Store: versioned schema per `Architecture.md` debt note.

---

## Detection — phased approach

### Phase 1 (v1): Heuristic detector in `AudioAnalyzer`

Reuse `loadMonoSamples` (mono, decimated, up to **90 s** — same window as
BPM/key). No new dependencies; pure Swift + Accelerate optional for FFT.

**Frame pipeline** (≈ 2048-sample window, 512-sample hop @ ~11 kHz):

1. **Band energy ratio** — energy in **300–3,400 Hz** (telephone-band proxy for
   formants) vs. full-band energy. Vocals concentrate here; sub-bass and
   airy highs are down-weighted.
2. **Harmonicity in fundamentals** — autocorrelation peak strength in **80–300 Hz**
   range (typical spoken/sung pitch). Strong, stable peaks suggest voiced
   content.
3. **Spectral flatness** (per frame) — vocals are less noise-like than cymbal
   washes or white noise; flatness penalizes "vocal" score.
4. **Modulation** — RMS envelope variance across 200 ms blocks; speech/singing
   has characteristic amplitude modulation vs. steady pads.

Per frame, combine features into `frameScore ∈ [0, 1]`. Aggregate:

- `vocalFraction` = fraction of frames with `frameScore > 0.5`
- `meanScore` = average `frameScore`
- `consistency` = `1 - stdDev(frameScore)` (clamped)

**Decision:**

```
rawScore = 0.5 * vocalFraction + 0.35 * meanScore + 0.15 * consistency
presence = rawScore >= 0.5 ? .vocals : .instrumental
confidence = min(1, abs(rawScore - 0.5) * 2 * consistencyBoost)
```

Where `consistencyBoost` scales confidence down when frame scores disagree
(e.g. a 10 s vocal hook on an otherwise instrumental beat).

**Return `.unknown`** when:

- Audio shorter than ~1 s (same guard as BPM/key)
- `confidence < 0.35` after computation (too ambiguous to label)
- File unreadable

Public API:

```swift
static func estimateVocalPresence(
    samples: [Float], sampleRate: Double
) -> VocalAnalysis

static func analyze(url: URL) async -> AudioAnalysis  // includes vocal
```

### Phase 2 (stretch): Core ML / Sound Analysis upgrade

If heuristics prove too brittle on real catalogs:

- Evaluate **Apple SoundAnalysis** (`SNClassifySoundRequest`) for
  `speech` / `singing` labels on sliding windows.
- Or bundle a small Core ML model (YAMNet-derived vocal probability).
- Keep the same `VocalAnalysis` surface; swap implementation behind
  `AudioAnalyzer` and re-tune thresholds from fixture tests.

**Gate for Phase 2:** v1 heuristic fails >30% on a labeled fixture set of ≥20
real producer exports.

---

## Confidence meter — semantics

| Confidence | Label shown | Filter bucket | Color cue |
|------------|-------------|---------------|-----------|
| `nil` / manual | User's choice only | User's bucket | Neutral |
| `0.35…0.64` | **Uncertain** + meter | **Uncertain** | Secondary / dashed meter |
| `0.65…0.84` | **With vocals** or **Instrumental** + meter | Matching bucket | Accent fill |
| `0.85…1.0` | Same + optional checkmark on row icon | Matching bucket | Strong accent |

The meter is **symmetric**: high confidence means "sure either way." Display
`confidence * 100` rounded (e.g. "Instrumental · 78% confident").

VoiceOver: *"Instrumental, 78 percent confidence, automatically detected"* or
*"Vocals, uncertain, 52 percent confidence."*

Do **not** show the meter on library rows — only an icon when
`confidence >= 0.65` to avoid clutter. Full meter on song detail.

---

## UI surfaces

### Song detail (`SongDetailView`)

- In the metadata section (near BPM/key): **Vocal** row with presence label +
  horizontal confidence bar (`ProgressView` or custom capsule).
- While detecting (shared `isDetecting` flag): indeterminate progress + label
  *"Analyzing audio…"* (existing pattern).
- Toolbar action stays **"Detect BPM & Key"** (v1) — vocal is bundled; rename
  to **"Detect Audio Metadata"** when shipped (optional copy tweak).

### Song editor (`SongEditorView`)

- New **Musical** section row: `Picker("Vocals", …)` → Unknown / Instrumental /
  With vocals.
- Choosing anything other than Unknown sets `vocalPresenceIsManual = true`.

### Library (`LibraryView`)

- Filter bar chip: **Vocals** menu or fourth chip group:
  - All (default)
  - With vocals (`presence == .vocals` and not uncertain)
  - Instrumental
  - Uncertain (`confidence` in 0.35…0.64 or `unknown` with stored confidence)

### Library row (`SongRow`)

- Trailing icon when `confidence >= 0.65`:
  - `mic.fill` — vocals
  - `waveform` — instrumental
- Hidden when uncertain/unknown. Pair icon + category color per `Accessibility.md` A5.

### Share card (stretch, post-v1)

- Small "Instrumental" / "Vocals" badge on `ShareCardView` when confident.
  Not required for initial ship.

---

## Integration points

| Location | Change |
|----------|--------|
| `AudioAnalyzer` | `estimateVocalPresence`, extend `analyze` |
| `SongImportService.scheduleMetadataDetection` | Apply vocal fields when not manual |
| `SongDetailView.detectMetadata` | Apply vocal fields |
| `Song`, `VocalPresence` | Model + enum |
| `SongEditorView` | Picker + manual flag |
| `LibraryView` | Filter + query |
| `SongRow` | Optional icon |
| `A11yID` | `song.vocalMeter`, `library.vocalFilter` |
| `docs/feature-inventory.md` | Row when implemented |
| `ROADMAP.md` §4 / §6 | Link here; move from "unscoped" when scheduled |

Rename detect menu item and inventory wording in the same PR as implementation.

---

## Accessibility

| # | Requirement |
|---|-------------|
| V1 | Confidence bar is decorative when label already states presence + %; use `.accessibilityHidden(true)` on the bar, full phrase on container |
| V2 | If bar is adjustable N/A — display only |
| V3 | Filter chips have `accessibilityLabel` ("Show instrumental tracks") |
| V4 | Row mic/waveform icons have labels; not color-only (pair with symbol) |

---

## Testing

### Unit tests (`AudioAnalyzerTests` + `VocalDetectionTests`)

| Fixture | Expected |
|---------|----------|
| Silence | `.unknown`, nil confidence |
| Pure sine / pad (no modulation, no vocal band dominance) | `.instrumental`, confidence ≥ 0.65 |
| AM-modulated band-limited noise 300–3k Hz (speech proxy) | `.vocals`, confidence ≥ 0.5 |
| Short burst (<1 s) | `.unknown` |
| Synthetic "hook" — 5 s vocal proxy in 60 s instrumental | `.instrumental` or `.unknown` with confidence < 0.65 (ambiguous case) |

Use synthesized signals first (same style as click-track BPM tests). Add
**labeled real MP3 fixtures** in test bundle once heuristic stabilizes (not
committed to repo if large — document in CONTRIBUTING).

### Integration

- Import flow writes vocal fields on seeded fixture.
- Manual override survives re-import detect on *other* fields (re-detect respects
  `vocalPresenceIsManual`).

### Acceptance (manual)

- [ ] Import vocal demo → detail shows vocals + meter ≥ 65%
- [ ] Import beat → instrumental + meter ≥ 65%
- [ ] Chopped-vocal beat → uncertain or instrumental; user can override
- [ ] Filter "Instrumental" hides vocal demos
- [ ] VoiceOver reads presence + confidence on detail

---

## Risks & mitigations

| Risk | Mitigation |
|------|------------|
| Lead synth mistaken for vocals | Phase 2 ML; show uncertainty band; user override |
| Buried background vocals missed | Accept as limitation; label copy says "prominent vocals" |
| Primary mix swap invalidates label | Re-run detect on primary mix change (future hook) |
| Performance on 90 s file | Reuse decimated buffer; vocal pass shares load with BPM/key |

---

## Open questions

1. **Rename "Detect BPM & Key"?** → "Analyze Track" / "Detect Metadata" when vocal ships.
2. **Store confidence when manual?** Spec recommends clearing so filters stay binary-clean.
3. **Per-mix detection** — defer until A/B vocal vs. instrumental mixes is a reported need.
4. **Sequencing integration** — vocal badge on `TrackFlowRow`? Track after library filter proves useful.

---

## Suggested implementation order

1. `VocalPresence` + `Song` fields + `VocalAnalysis` / `AudioAnalyzer.estimateVocalPresence`
2. Unit tests with synthesized fixtures; tune thresholds
3. Wire `SongImportService` + `SongDetailView`
4. Song detail meter UI
5. `SongEditorView` manual picker
6. Library filter + row icon
7. Inventory + ROADMAP status update

---

## Verification

- Target release: post-v1 feature (schedule after SwiftLint strict / CI green)
- Last verified: 2026-06-16 (implemented; unit-tested)
- Primary code paths (when built): `AudioAnalyzer`, `Song`, `SongImportService`,
  `SongDetailView`, `SongEditorView`, `LibraryView`, `SongRow`

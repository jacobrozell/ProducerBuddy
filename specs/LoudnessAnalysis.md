# Loudness Analysis (LUFS) Spec

Show **integrated loudness (LUFS)** per mix so producers can spot masters that
are too quiet or clipped-hot before uploading to DistroKid — analysis only, not
a mastering engine.

---

## Goals

| Goal | Success looks like |
|------|-------------------|
| Pre-upload sanity check | Master mix shows ~−14 LUFS integrated; demo mix shows −18 and I know to revisit |
| Compare mixes | A/B two versions and see which is louder without ear fatigue |
| Honest limits | Label says "estimate"; user can still trust their meters in FL |

## Non-goals

- **True peak limiting**, normalization, or export-at-target-LUFS.
- **EBU R128 broadcast** compliance certification.
- **Per-platform loudness targets** with auto-fix (inform only).
- **Real-time loudness metering** during playback (integrated only, on demand).

---

## User stories

1. **DistroKid Saturday** — Before upload I run **Analyze Loudness** on my
   primary mix; −9 LUFS tells me I crushed it; I swap to master v2 at −13.
2. **Beat lease pack** — Instrumental and tagged versions differ by 0.5 LUFS; I
   confirm they're matched enough for the zip I send buyers.
3. **Rough vs master** — Song detail shows LUFS on each mix row next to duration.

---

## Technical approach

### Measurement

- **Integrated loudness** (approximate LUFS) over the full file using K-weighting
  and mean-square gating per ITU-R BS.1770 **simplified**:
  - Mono downmix (reuse `AudioAnalyzer.loadMonoSamples`)
  - 400 ms blocks, 75% overlap
  - K-weighting via biquad filters (or Accelerate when available)
  - Gate at −70 LUFS relative to ungated mean; integrate gated blocks
- **True peak** (optional v1.1): max inter-sample peak estimate for clipping hint
- **Analysis window**: full file up to **10 min**; longer files analyze first 10 min
  with footnote in UI

### Caching on `Mix`

| Field | Type | Notes |
|-------|------|-------|
| `integratedLUFS` | `Double?` | e.g. −14.2; nil until analyzed |
| `truePeakDBFS` | `Double?` | stretch v1.1 |
| `loudnessAnalyzedAt` | `Date?` | invalidate when audio file replaced |

Re-run on import (background, low priority) or on demand per mix.

### Display semantics

| LUFS (integrated) | Copy | Color cue |
|-------------------|------|-----------|
| > −9 | "Very loud — may be limited on streaming" | Warning |
| −9 … −11 | "Louder than typical streaming target" | Caution |
| −11 … −16 | "In streaming ballpark" | Neutral / good |
| < −16 | "Quiet — may sound soft after normalization" | Caution |

Footnote always: *"Streaming services normalize to ~−14 LUFS. This is an
estimate."*

---

## UI surfaces

### Mix row (`SongDetailView`)

- Trailing: `−14.2 LUFS` when cached; **Analyze** button when nil
- Long-press / swipe: Re-analyze

### Song detail metadata

- Primary mix LUFS in the stats row with BPM/key/vocals

### Full player (stretch)

- Small badge under title when LUFS available

### A/B compare

- When switching mixes, update displayed LUFS for active mix

---

## Integration

| Location | Change |
|----------|--------|
| `AudioAnalyzer` | `estimateIntegratedLUFS(samples:sampleRate:) -> Double?` |
| `Mix` | Cache fields |
| `SongImportService` | Schedule loudness after waveform (same task chain) |
| `SongDetailView` | Display + on-demand analyze |

Run loudness **after** waveform generation in the import pipeline to avoid
blocking first paint.

---

## Testing

| Fixture | Expected |
|---------|----------|
| Silence | nil or −∞ handled as nil |
| Sine at known RMS | LUFS within ±1.5 dB of reference |
| Two fixtures, 6 dB level difference | Measured delta within ±1 dB |

Synthetic signals first; one real mastered MP3 in test bundle optional.

---

## Risks

| Risk | Mitigation |
|------|------------|
| BS.1770 simplification drifts from DAW meters | Label as estimate; tune against 3 reference masters |
| CPU on long files | Cap window; run off main actor |
| MP3 encoder loudness vs WAV | Same as any streaming upload — still useful |

---

## Verification

- Target release: post-v1 audio power tools batch
- Last verified: 2026-06-16 (spec only; **not implemented**)
- Primary code paths: `AudioAnalyzer`, `Mix`, `SongDetailView`, `SongImportService`

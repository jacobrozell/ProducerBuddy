# Timeline Markers Spec

Let producers drop **markers** on a mix timeline — drop, breakdown, hook, intro —
for quick navigation, loop selection, and audiogram snippet picking.

---

## Goals

| Goal | Success looks like |
|------|-------------------|
| Navigate long beats | Tap "Drop" → playhead jumps to 1:24 |
| Better A/B loops | Loop between Hook and Drop markers, not whole track |
| Audiogram input | Export snippet defaults to marker range |

## Non-goals

- Beat grid / bar-aligned markers (manual time only in v1).
- FL Studio `.flp` marker import.
- Multiple marker lanes or regions with labels on waveform export image.

---

## Data model

### `MixMarker` (child of `Mix` or codable array on `Mix`)

| Field | Type | Notes |
|-------|------|-------|
| `id` | `UUID` | |
| `timeSeconds` | `Double` | ≥ 0, < mix duration |
| `label` | `String` | Preset or custom: Intro, Verse, Hook, Drop, Breakdown, Outro, Custom |
| `colorHex` | `String?` | Optional; preset colors per label |

Stored as JSON on `Mix.markersJSON` or `@Relationship` cascade — prefer JSON
for lightweight migration.

Max **20 markers** per mix.

---

## UI surfaces

### Full player

- Long-press waveform → **Add marker here** context menu
- Marker ticks on waveform scrubber (colored pins)
- Chips below scrubber: tap to seek; long-press to rename/delete
- Loop mode: **Loop between markers** when two selected (replaces whole-track
  loop toggle behavior)

### Song detail

- Marker list per mix row (read-only summary)

### Audiogram export

- Snippet handles snap to nearest markers when within 2 s

---

## Presets

| Label | Default color |
|-------|---------------|
| Intro | Blue |
| Verse | Gray |
| Hook | Orange |
| Drop | Red |
| Breakdown | Purple |
| Outro | Blue |

---

## Integration

| Location | Change |
|----------|--------|
| `Mix` | `markersJSON` |
| `FullPlayerView` | Marker UI + loop between |
| `AudiogramExport` | Snippet defaults |
| `WaveformView` | Draw marker ticks |

---

## Accessibility

- Markers: "Drop, at 1 minute 24 seconds, double tap to seek"
- Add marker: adjustable via rotor when playhead focused (stretch)

---

## Testing

- Codable round-trip markers JSON
- Loop between markers seeks correctly at end of range

---

## Verification

- Target release: with audiogram or full-player v2
- Last verified: 2026-06-16 (spec only; **not implemented**)
- Primary code paths: `Mix`, `FullPlayerView`, `WaveformView`

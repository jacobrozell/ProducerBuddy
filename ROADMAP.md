# MixStack — UX Polish & Feature Roadmap

This document looks at the app the way a working producer would actually use it,
calls out the friction in today's build, and lays out where it should go next.
It's organized by **how much it improves the experience per unit of effort** so
the highest-leverage work floats to the top.

The guiding principle from the original brief: a producer should be able to go
from *raw idea → organized catalog → sequenced release → clean, visual share*
without ever leaving the app or fighting the tools.

---

## 1. UX Polish (near-term, high leverage)

Small changes that make the current screens feel finished. Most are a few hours
each and don't need new data models.

### Capture & import
- ✅ **Import audio first, song second.** *(Shipped.)* See [LibraryAndImport](specs/shipped/LibraryAndImport.md).
- 🟡 **Version-aware import.** Export-prefix matching, resolution sheet, and mix
  roles ship today; full compare UI and smarter filename scoring remain. **Spec:**
  [`specs/VersionStack.md`](specs/VersionStack.md).
- ✅ **Read embedded metadata on import.** Title/artist pulled from ID3/MP4 tags
  via `AVAsset` `commonMetadata` (`AudioStorage`).
- ✅ **Batch import progress.** Inline progress row while multiple files import.

### Library legibility
- ✅ **BPM/key/rating filters and ranges.** `LibraryFiltersSheet` + category bar.
- ✅ **Section headers when sorting.** BPM and rating buckets via `LibraryFilterLogic`.
- ✅ **Swipe actions.** Favorite, add to project, delete on song rows.
- ✅ **Confirm destructive deletes.** Dialog notes mixes/files removed.

### Playback
- ✅ **Tap-to-expand full player.** Now-playing bar opens `FullPlayerView`.
- ✅ **Drag-to-scrub on the bar itself.** Slider on the mini bar.
- ✅ **A/B mix compare.** Switch mixes without losing position; **section loop**
  mode in the full player for auditioning a region.
- ✅ **Haptics** on play/pause, stop, mix switch, scrub release, and reorder drops.

### Sequencing clarity
- ✅ **Energy curve graph.** Swift Charts BPM-over-tracklist with peak marker.
- ✅ **Explain the badges.** `FlowLegend` plus tap-to-explain popovers on each
  row badge (rise/fall, warnings, key clash).
- ✅ **Diff preview for "Suggest Order."** `SuggestOrderPreviewSheet` before apply.

### Accessibility & visual baseline
- ✅ **VoiceOver labels** on transport, rows, and icon-only controls.
- 🟡 **Dynamic Type passes** — rows reflow at accessibility sizes in code; manual
  VoiceOver + AXXXL sign-off on a physical device still pending.
- ✅ **Don't rely on color alone.** Category symbol paired with tint on play buttons.
- ✅ **Larger star hit targets** in `StarRatingView`.

---

## 2. Visual Sharing (the brief's headline ask)

PNG release cards, brand kit, and audiograms ship today. Remaining gaps are extra
formats and link-in-bio tooling.

- ✅ **Generated release cards.** `ImageRenderer` → square/story PNG. See
  [Sharing](specs/shipped/Sharing.md).
- ✅ **Brand kit.** Accent, logo, tagline, and card style in Settings; inherited by
  share cards and audiograms. See [BrandKit](specs/BrandKit.md).
- ✅ **Audiogram export.** Branded MP4 teaser with animated waveform. See
  [AudiogramExport](specs/AudiogramExport.md).
- 🟡 **Per-platform presets.** Square (1:1) and story (9:16) ship; **banner (16:9)**
  still open.
- ⛔ **Pre-save / link-in-bio page** generator for an upcoming release.

---

## 3. Smarter Sequencing

Deepen the feature that makes this app more than a file manager.

- ✅ **Harmonic mixing (Camelot wheel).** Key clashes flagged in flow analysis.
  *Still open:* actively *suggesting* harmonically compatible neighbours.
- ⛔ **Multi-signal energy model.** Blend BPM with rating, duration, manual energy tag.
- ⛔ **Multiple arc templates.** "Slow burn," "front-loaded," "two peaks," etc.
- ⛔ **Intro/outro & transition notes.** Per-track fields for crossfade/key-change notes.
- ⛔ **Gapless / crossfade preview.** Hear the sequence end-to-end with configurable gaps.

---

## 4. Audio Power Tools (stretch, from the brief's "Possible" list)

Heavier lifts that move the app toward a real production companion.

- ✅ **Waveform views** for every mix. Cached peaks + `Canvas` scrubber.
- ✅ **Auto BPM & key detection.** `AudioAnalyzer` on import and on demand.
- ✅ **Vocal detection with confidence meter.** See [`specs/VocalDetection.md`](specs/VocalDetection.md).
- ✅ **Reference-loudness check.** Integrated LUFS per mix (`LoudnessAnalyzer`). Analysis
  only — not a mastering engine. See [LoudnessAnalysis](specs/LoudnessAnalysis.md).
- ⛔ **Pitch / tempo preview** (non-destructive) via `AVAudioEngine`.
- ⛔ **Stem/section markers.** Drop/breakdown/hook markers on the timeline. See
  [TimelineMarkers](specs/TimelineMarkers.md).
- *(Explicitly out of scope: a full EQ/mastering chain or true stem separation.)*

---

## 5. Platform & Trust

The things that make people keep their catalog in the app long-term.

- ✅ **Background audio + lock-screen controls.** `MPNowPlayingInfoCenter` + remote commands.
- ✅ **Queue & project playback.** "Play in Order" with prev/next.
- ⛔ **iCloud sync & backup.** CloudKit store + Documents audio sync.
- ✅ **First-run experience.** Skippable onboarding + optional demo seed.
- ✅ **Data export/import.** Portable catalog ZIP (metadata + audio). See
  [CatalogSync](specs/CatalogSync.md). *iCloud is Phase 2.*
- ⛔ **Files-app & AirDrop awareness.** Surface audio shared into Documents; accept AirDrop.

---

## Suggested sequencing of the work

A rough order that delivers visible value early and builds toward the vision:

1. ~~**Import-first flow + embedded metadata**~~ — ✅ shipped.
2. ~~**Full-screen player with scrubbing + A/B mix compare + section loops**~~ — ✅ shipped.
3. ~~**Visual release cards + brand kit + audiograms**~~ — ✅ shipped (banner preset still open).
4. ~~**Energy curve graph + badge explanations + suggest-order preview**~~ — ✅ shipped.
5. ~~**Background audio + lock-screen controls + project queue**~~ — ✅ shipped.
6. ~~**Harmonic mixing (Camelot wheel)**~~ — ✅ shipped. *(Arc templates + neighbour suggestions still open.)*
7. ~~**Auto BPM/key + waveforms + LUFS + release tracking**~~ — ✅ shipped.
8. ~~**Catalog export/import (pre-iCloud)**~~ — ✅ shipped.
9. **iCloud sync** — makes it trustworthy for a real catalog long-term.
10. **Version stack compare UI + arc templates** — deepen daily producer workflows.

Items still in §1 that are 🟡 (device a11y sign-off, version-stack compare) can
ride along with whichever release touches those screens.

---

## 6. Future ideas (specced)

Prioritized from a hobbyist FL Studio → streaming workflow. Each has a spec in
[`specs/`](specs/README.md).

| Priority | Feature | Spec | Status |
|----------|---------|------|--------|
| Now | Version stack compare + smarter import | [VersionStack](specs/VersionStack.md) | 🟡 partial |
| Next | Sequencing arcs + transition notes | [SequencingEnhancements](specs/SequencingEnhancements.md) | 🟡 preview shipped |
| Next | Timeline markers (drop, hook) | [TimelineMarkers](specs/TimelineMarkers.md) | ⛔ |
| Soon | iCloud catalog sync | [CatalogSync](specs/CatalogSync.md) | 🟡 export/import shipped |
| Soon | Banner (16:9) share preset | [Sharing](specs/shipped/Sharing.md) | ⛔ |
| Later | Localization (full String Catalog) | ROADMAP §Platform | 🟡 scaffolding |
| Explore | Drop `.flp` for stem paths? | — | — |

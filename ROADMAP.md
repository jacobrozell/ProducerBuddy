# ProducerBuddy — UX Polish & Feature Roadmap

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
- **Version-aware import.** Re-exports of the same beat should attach as a new
  **mix**, not a duplicate song — filename parsing, match scoring, resolution
  sheet. **Spec:** [`specs/VersionStack.md`](specs/VersionStack.md).
- **Read embedded metadata on import.** Pull title/artist/artwork from the
  file's ID3/MP4 tags (`AVAsset` `commonMetadata`) instead of leaving every
  field blank.
- **Batch import progress.** When importing several files, show a small inline
  progress row rather than a silent pause while durations are measured.

### Library legibility
- **BPM/key/rating filters and ranges.** Search is substring-only. Producers
  think in ranges ("show me my 120–128 house tracks"). Add filter chips for key
  and a BPM range slider alongside the existing category bar.
- **Section headers when sorting.** When sorted by BPM or rating, break the list
  into labeled sections (e.g. "90–110 BPM") so the list scans at a glance.
- **Swipe actions.** Add leading/trailing swipes on song rows for Favorite and
  "Add to Project…" so common actions don't require opening detail.
- **Confirm destructive deletes.** Deleting a song silently removes all its
  mixes and audio files. Add a confirmation dialog noting how many mixes/files
  will be removed.

### Playback
- **Tap-to-expand full player.** The now-playing bar shows progress but you
  can't scrub it. Make the bar tappable to present a full-screen player with a
  draggable scrubber, skip ±15s, and a loop toggle.
- **Drag-to-scrub on the bar itself** as a lighter alternative.
- **A/B mix compare.** When a song has multiple mixes, let the user switch mixes
  *without losing playback position* and optionally loop a section — the single
  most-requested producer workflow for picking the best mix.
- **Haptics** on play/pause, primary-mix toggle, and reorder drops.

### Sequencing clarity
- ✅ **Energy curve graph.** *(Shipped.)* The project's BPM-over-tracklist is
  drawn as a Swift Charts area/line above the running order with the peak track
  marked — seeing the *shape* of the record (the rise to a peak, the wind-down)
  is far more intuitive than per-row badges alone.
- ✅ **Explain the badges.** *(Shipped.)* A `FlowLegend` under the chart keys the
  Rise/Fall/Steady badges and the abrupt-jump warning. *Still open:* a tap-to-
  explain popover on each individual badge.
- **Diff preview for "Suggest Order."** Before committing the auto-sequence,
  show what's moving where and let the user accept or undo, rather than
  silently rewriting their order.

### Accessibility & visual baseline
- **VoiceOver labels** on the icon-only buttons (play, primary star, stop) and
  combined labels on song rows.
- **Dynamic Type passes** — verify rows reflow at accessibility text sizes; the
  fixed 46pt artwork and trailing rating column are the risky spots.
- **Don't rely on color alone.** Category is color-coded in `SongRow`'s play
  button; pair it with the category symbol for colorblind users.
- **Larger star hit targets** — the 0–5 star control taps are currently small.

---

## 2. Visual Sharing (the brief's headline ask)

The original spec stressed sharing music "in a clean, consistent, and visual
way" and exporting "directly to social media." Today sharing is plain text —
this is the biggest gap between the build and the vision.

- ✅ **Generated release cards.** *(Shipped.)* `ImageRenderer` turns a song or
  project into a polished, on-brand image card (title, BPM/key, tracklist) in
  square or story format, shared as a PNG. This is the visual, consistent share
  the brief wanted. *Next:* an editable artwork slot instead of the gradient.
- **Brand kit.** Let the user set an accent color, logo, and font once; every
  card inherits it so their releases look consistent across posts.
- **Audiogram export.** Render a short video clip (waveform animating over a
  card) for a chosen 15–30s snippet — the format that actually performs on
  social.
- **Per-platform presets.** Story (9:16), post (1:1), and banner (16:9) layouts
  from the same content.
- **Pre-save / link-in-bio page** generator for an upcoming release.

---

## 3. Smarter Sequencing

Deepen the feature that makes this app more than a file manager.

- ✅ **Harmonic mixing (Camelot wheel).** *(Shipped.)* Each key maps to a Camelot
  code; the flow analysis flags key clashes between adjacent tracks (a 🎵 marker
  plus a legend entry), and the running order shows each track's code. *Still
  open:* actively *suggesting* harmonically compatible neighbours.
- **Multi-signal energy model.** Blend BPM with rating, song duration, and an
  optional manual "energy" tag instead of using BPM alone as the proxy.
- **Multiple arc templates.** Beyond the single build-to-peak suggestion, offer
  named arcs — "slow burn," "front-loaded," "two peaks," "DJ set / continuous
  rise" — and let the user pick the shape they're going for.
- **Intro/outro & transition notes.** Per-track fields for intro/outro energy
  and a free-text transition note between tracks (the crossfade idea, the key
  change) so sequencing decisions are remembered.
- **Gapless / crossfade preview.** Play the project end-to-end with configurable
  gaps or crossfades to *hear* the sequence, not just read it.

---

## 4. Audio Power Tools (stretch, from the brief's "Possible" list)

Heavier lifts that move the app toward a real production companion.

- ✅ **Waveform views** for every mix. *(Shipped.)* Audio is streamed into
  normalized peak buckets, cached on the `Mix`, and drawn with `Canvas`; the full
  player uses it as an interactive scrubber and mix rows show a mini waveform.
  Still a prerequisite for audiograms and section-loop A/B.
- ✅ **Auto BPM & key detection.** *(Shipped.)* On import (and on demand via
  "Detect Audio Metadata"), `AudioAnalyzer` estimates tempo by autocorrelating an
  onset-energy envelope and key via a Goertzel chromagram correlated against the
  Krumhansl–Schmuckler profiles — a lightweight estimate the user can correct,
  computed off the main actor. *Next:* tightening accuracy with a proper
  spectral-flux onset detector.
- ✅ **Vocal detection with confidence meter.** *(Shipped.)* Heuristic detector
  in `AudioAnalyzer` tags mixes as instrumental or with vocals, surfaces a
  confidence score on song detail, supports manual override, and filters the
  library. See [`specs/VocalDetection.md`](specs/VocalDetection.md).
- **Reference-loudness check.** Show integrated LUFS per mix so the user can
  spot a master that's too quiet/hot before release. (Analysis only — not a
  mastering engine.)
- **Pitch / tempo preview** (non-destructive) using `AVAudioEngine` time/pitch
  units to audition a track sped up/slowed down for a sequence.
- **Stem/section markers.** Let users drop markers (drop, breakdown, hook) on a
  mix's timeline for quick navigation and snippet selection.
- *(Explicitly out of scope: a full EQ/mastering chain or true stem separation —
  these are large enough to be their own apps.)*

---

## 5. Platform & Trust

The things that make people keep their catalog in the app long-term.

- ✅ **Background audio + lock-screen controls.** *(Shipped.)*
  `MPNowPlayingInfoCenter` + `MPRemoteCommandCenter` are wired up and the `audio`
  background mode keeps playback running when backgrounded.
- ✅ **Queue & project playback.** *(Shipped.)* "Play in Order" plays a whole
  project as an auto-advancing queue, with prev/next in the full player and on
  the lock screen.
- **iCloud sync & backup.** Move the SwiftData store to CloudKit so a catalog
  survives device loss and syncs iPad↔iPhone. Audio files sync via iCloud
  Documents.
- **First-run experience.** A brief, skippable walkthrough plus an optional
  "load sample project" so the app isn't an empty list on launch.
- **Data export/import.** Export the catalog (metadata + audio) as a portable
  bundle for backup or moving between devices before iCloud lands.
- **Files-app & AirDrop awareness.** Surface audio already shared into the app's
  Documents folder; accept AirDrop'd audio directly.

---

## Suggested sequencing of the work

A rough order that delivers visible value early and builds toward the vision:

1. ~~**Import-first flow + embedded metadata**~~ — ✅ shipped. The Library's
   "Import Audio…" action ingests multiple files at once, creating a song +
   primary "Original" mix each, with title/artist pulled from embedded tags
   (falling back to the filename).
2. ~~**Full-screen player with scrubbing + A/B mix compare**~~ — ✅ shipped.
   Tap the now-playing bar for a full player with a draggable scrubber, ±15s
   skip, a loop toggle, and a segmented A/B control that swaps mixes without
   losing position. *(Still open: looping a chosen section rather than the whole
   track.)*
3. ~~**Visual release cards (`ImageRenderer`)**~~ — ✅ shipped. Song and project
   detail screens have a "Share Card" action that renders a polished, on-brand
   image (square or story format) to a PNG and shares it via the system sheet.
   *(Still open: brand kit, audiograms, banner preset, pre-save page.)*
4. ~~**Energy curve graph + badge explanations**~~ — ✅ shipped. The project
   screen plots BPM across the running order with Swift Charts, marks the peak,
   and shows a legend explaining the Rise/Fall/Steady badges.
5. ~~**Background audio + lock-screen controls + project queue**~~ — ✅ shipped.
   Playback continues in the background; the lock screen / Control Center show
   metadata with working play, pause, ±15s, scrub, and prev/next; and "Play in
   Order" plays a project as an auto-advancing queue.
6. ~~**Harmonic mixing (Camelot wheel)**~~ — ✅ shipped. Key-aware flow analysis
   flags clashes between adjacent tracks. *(Still open: arc templates and
   actively suggesting compatible neighbours.)*
7. **iCloud sync** — makes it trustworthy for a real catalog.
8. ~~**Auto BPM/key detection**~~ — ✅ shipped (see §4). Runs on import and on
   demand, pre-filling metadata so users rarely type tempo/key by hand.
9. ~~**Waveforms**~~ — ✅ shipped. Mixes get a cached waveform (streamed into
   peak buckets) drawn with `Canvas`; the full player uses it as an interactive
   scrubber and each mix row shows a mini waveform. *Next:* audiograms built on
   top of the same peaks.

Items in §1 (accessibility, swipe actions, delete confirmation, haptics) are
small enough to fold into whichever release touches the relevant screen.

---

## 6. Future ideas (specced)

Prioritized from a hobbyist FL Studio → streaming workflow. Each has a spec in
[`specs/`](specs/README.md).

| Priority | Feature | Spec | Why it matters |
|----------|---------|------|----------------|
| Now | Vocal detection + library filter | [VocalDetection](specs/VocalDetection.md) | Sort beats vs vocal demos without listening to every export |
| Next | Library polish (filters, swipes, confirm) | [LibraryPolish](specs/LibraryPolish.md) | Daily friction — find 120–128 house tracks in two taps |
| Next | Version stack (roles, smart import, compare) | [VersionStack](specs/VersionStack.md) | FL exports `_v2_master` land on the right song, not duplicate #4 |
| Next | Release tracking (date, links, distributor) | [ReleaseTracking](specs/ReleaseTracking.md) | Close the loop after DistroKid/TuneCore upload |
| Soon | Loudness (LUFS) per mix | [LoudnessAnalysis](specs/LoudnessAnalysis.md) | Catch crushed masters before streaming normalization |
| Soon | Brand kit for share cards | [BrandKit](specs/BrandKit.md) | Consistent Instagram/Spotify promo look |
| Soon | Audiogram video export | [AudiogramExport](specs/AudiogramExport.md) | The format that actually gets plays on Stories/TikTok |
| Later | Sequencing (preview, arcs, transitions) | [SequencingEnhancements](specs/SequencingEnhancements.md) | EP/mixtape order you can trust and remember |
| Later | Timeline markers (drop, hook) | [TimelineMarkers](specs/TimelineMarkers.md) | Navigate 3-minute beats; better loops and audiogram clips |
| Later | Catalog export + iCloud sync | [CatalogSync](specs/CatalogSync.md) | Trust — catalog survives device upgrades |
| Explore | Drop `.flp` for stem paths? | — | FL-specific import if format is tractable without a separation engine |

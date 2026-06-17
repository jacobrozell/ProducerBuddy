# Feature Inventory

What actually ships in the build today (reality, not aspiration). **Agents:**
start at [`specs/shipped/README.md`](../specs/shipped/README.md). For a human
index see [`features-guide.md`](features-guide.md); for where things are headed,
see [`ROADMAP.md`](../ROADMAP.md); for how to build, see
[`CONTRIBUTING.md`](../CONTRIBUTING.md).

Status legend: ✅ shipped · 🟡 partial · 🧪 unverified · ⛔ not started

> **Build column (2026-06-17):** `Scripts/ci/verify-local.sh` green — SwiftLint
> strict ✅ · **116** unit tests + **10** UI tests on iPhone 17 / iPad (A16) sims.
> ✅ = verified in sim or tests · 🧪 = implemented but not re-tested this session ·
> ⛔ = not built.

| Area | Feature | Status | Build | Primary code |
|------|---------|--------|-------|--------------|
| Library | Import audio (multi-file, metadata) | ✅ | ✅ | `LibraryView`, `AudioStorage`, `SongImportService` |
| Library | Manual song create/edit | ✅ | ✅ | `SongEditorView` |
| Library | Search / sort / category filter | ✅ | ✅ | `LibraryView` |
| Library | Swipe actions (favorite, add to project, delete) | ✅ | ✅ | `LibraryView` |
| Library | Advanced filters (BPM range, key, favorites) | ✅ | ✅ | `LibraryFiltersSheet`, `LibraryFilterLogic` |
| Library | Section headers (BPM / rating sort) | ✅ | ✅ | `LibraryFilterLogic` |
| Library | Import progress + failure alerts | ✅ | ✅ | `AudioImporter`, `ImportProgressBannerView` |
| Library | Version-aware import (prefix, resolution) | 🟡 | ✅ | `ImportPlanner`, `ImportResolutionSheet`, `VersionStackTests` |
| Projects | Delete confirmation | ✅ | ✅ | `ProjectListView`, `LibraryView` |
| Library | Auto BPM & key detection | ✅ | ✅ | `AudioAnalyzer` |
| Library | Vocal detection + confidence | ✅ | ✅ | `AudioAnalyzer`, `VocalConfidenceMeter` |
| Library | LUFS loudness per mix | ✅ | ✅ | `LoudnessAnalyzer`, `SongDetailView` |
| Songs | Multiple mixes, primary mix, roles | 🟡 | ✅ | `Mix`, `SongDetailView`, `VersionStackRow` |
| Songs | Release tracking (date, links, distributor) | ✅ | ✅ | `Song`, `SongEditorView`, `ReleaseInfoCard` |
| Songs | Star rating, workflow category | ✅ | ✅ | `Song`, `StarRatingView` |
| Playback | Now-playing bar + full player | ✅ | ✅ | `NowPlayingBar`, `FullPlayerView` |
| Playback | Mini-bar + waveform scrubber | ✅ | ✅ | `NowPlayingBar`, `WaveformView` |
| Playback | A/B mix compare | ✅ | ✅ | `AudioPlayer.switchMix` |
| Playback | Section loop mode | ✅ | ✅ | `PlayerLoopControls`, `PlaybackLoopLogicTests` |
| Playback | Background audio + lock screen | ✅ | ✅ | `AudioPlayer` (MediaPlayer) |
| Playback | Project queue + auto-advance | ✅ | ✅ | `AudioPlayer`, `ProjectDetailView` |
| Projects | Create/edit, drag-reorder | ✅ | ✅ | `ProjectDetailView` |
| Projects | Energy flow analysis (rise/fall) | ✅ | ✅ | `SequencingEngine`, `TrackFlowRow` |
| Projects | Harmonic (Camelot) key clashes | ✅ | ✅ | `SequencingEngine` |
| Projects | Energy curve chart + badge popovers | ✅ | ✅ | `EnergyCurveChart`, `TrackFlowRow` |
| Projects | Suggest order + diff preview | ✅ | ✅ | `SuggestOrderPreviewSheet`, `SequencingEngine.orderMoves` |
| Sharing | Text blurb / tracklist | ✅ | ✅ | `SongDetailView`, `ProjectDetailView` |
| Sharing | Visual release cards (PNG) | ✅ | ✅ | `ShareCardView`, `ReleaseCardRenderer` |
| Sharing | Brand kit on share surfaces | ✅ | ✅ | `BrandKitStore`, `SettingsView` |
| Sharing | Audiogram video export | ✅ | 🧪 | `AudiogramRenderer`, `AudiogramExportSheet` |
| Settings | Appearance, haptics, links, delete-all | ✅ | ✅ | `SettingsView` |
| Settings | Catalog export / import (ZIP) | ✅ | ✅ | `CatalogExporter`, `CatalogImporter`, `CatalogSyncTests` |
| Platform | Release-surface gating | ✅ | ✅ | `ReleaseSurface` |
| Platform | Accessibility (engineering pass) | ✅ | ✅ | `MixStackUIAccessibility` (4 tests) |
| Platform | Localization | 🟡 | — | `L10n.swift` + `Localizable.xcstrings` (partial; most UI en hard-coded) |
| Platform | iCloud sync | ⛔ | — | — |
| Platform | Onboarding / first-run | ✅ | ✅ | `OnboardingView`, `RootView` |
| Platform | Repository layer / DI container | ⛔ | — | views use `modelContext` directly |
| Platform | Schema versioning / migration | ⛔ | — | single implicit schema |
| Platform | Unit tests / local build | ✅ | ✅ | 116 unit + 10 UI; SwiftLint strict ✅ |
| Platform | GitHub Actions CI | ✅ | 🧪 | `.github/workflows/ci.yml` mirrors `verify-local.sh` |

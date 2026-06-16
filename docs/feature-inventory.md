# Feature Inventory

What actually ships in the build today (reality, not aspiration). **Agents:**
start at [`specs/shipped/README.md`](../specs/shipped/README.md). For a human
index see [`features-guide.md`](features-guide.md); for where things are headed,
see [`ROADMAP.md`](../ROADMAP.md); for how to build, see
[`CONTRIBUTING.md`](../CONTRIBUTING.md).

Status legend: ✅ shipped · 🟡 partial · 🧪 unverified · ⛔ not started

> **Build column (2026-06-16):** Debug + Release compile; 57 unit tests pass on
> `ProducerBuddy` simulator. ✅ = verified in sim or tests · 🧪 = implemented but
> not re-tested this session · ⛔ = not built.

| Area | Feature | Status | Build | Primary code |
|------|---------|--------|-------|--------------|
| Library | Import audio (multi-file, metadata) | ✅ | 🧪 | `LibraryView`, `AudioStorage` — picker not exercised in sim |
| Library | Manual song create/edit | ✅ | ✅ | `SongEditorView` — verified MCP |
| Library | Search / sort / category filter | ✅ | 🟡 | `LibraryView` — notes search, BPM/key/vocal filters |
| Library | Swipe actions (favorite, add to project, delete) | ✅ | 🧪 | `LibraryView` |
| Library | Advanced filters (BPM range, key, favorites) | ✅ | 🧪 | `LibraryFiltersSheet`, `LibraryFilterLogic` |
| Library | Section headers (BPM / rating sort) | ✅ | 🧪 | `LibraryFilterLogic` |
| Library | Import progress + failure alerts | ✅ | 🧪 | `AudioImporter`, `LibraryView` |
| Projects | Delete confirmation | ✅ | 🧪 | `ProjectListView` |
| Library | Auto BPM & key detection | ✅ | 🧪 | `AudioAnalyzer` — unit-tested; UI needs mix + file |
| Library | Vocal detection + confidence | ✅ | 🧪 | `AudioAnalyzer`, `VocalConfidenceMeter` — unit-tested |
| Songs | Multiple mixes, primary mix | ✅ | 🧪 | `Mix`, `SongDetailView` |
| Songs | Star rating, workflow category | ✅ | ✅ | `Song`, `StarRatingView` |
| Playback | Now-playing bar + full player | ✅ | 🧪 | `NowPlayingBar`, `FullPlayerView` |
| Playback | Waveform scrubber | ✅ | 🧪 | `WaveformView`, `WaveformGenerator` |
| Playback | A/B mix compare | ✅ | 🧪 | `AudioPlayer.switchMix` |
| Playback | Background audio + lock screen | ✅ | 🧪 | `AudioPlayer` (MediaPlayer) |
| Playback | Project queue + auto-advance | ✅ | 🧪 | `AudioPlayer`, `ProjectDetailView` |
| Projects | Create/edit, drag-reorder | ✅ | 🟡 | `ProjectDetailView` — create + add track ✅; reorder not tested |
| Projects | Energy flow analysis (rise/fall) | ✅ | ✅ | `SequencingEngine`, `TrackFlowRow` — "Opener" label in sim |
| Projects | Harmonic (Camelot) key clashes | ✅ | ✅ | unit tests |
| Projects | Energy curve chart | ✅ | 🧪 | needs 2+ tracks in project |
| Projects | Suggest order | ✅ | 🧪 | needs 3+ tracks |
| Sharing | Text blurb / tracklist | ✅ | 🧪 | `SongDetailView`, `ProjectDetailView` |
| Sharing | Visual release cards (PNG) | ✅ | ✅ | `ShareCardView`, `ReleaseCardRenderer` — sheet + render |
| Settings | Appearance, haptics, links, delete-all | ✅ | ✅ | `SettingsView` — delete-all + counts verified |
| Platform | Release-surface gating | 🟡 | ✅ | `ReleaseSurface` — Settings tab visible |
| Platform | Accessibility pass (labels, Reduce Motion) | 🟡 | 🟡 | MCP AX pass; no dated audit doc |
| Platform | Localization | ⛔ | — | strings hard-coded (en only) |
| Platform | iCloud sync | ⛔ | — | — |
| Platform | Onboarding / first-run | ✅ | ✅ | `OnboardingView`, `RootView` |
| Platform | Repository layer / DI container | ⛔ | — | views use `modelContext` directly |
| Platform | Schema versioning / migration | ⛔ | — | single implicit schema |
| Platform | Unit tests / local build | ✅ | ✅ | 57 tests; SwiftLint strict ❌ |
| Platform | GitHub Actions CI | 🟡 | 🧪 | workflow present; not run on GHA this session |

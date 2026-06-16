# Feature Inventory

What actually ships in the build today (reality, not aspiration). For where
things are headed, see [`ROADMAP.md`](../ROADMAP.md); for how to build, see
[`CONTRIBUTING.md`](../CONTRIBUTING.md).

Status legend: ✅ shipped · 🟡 partial · 🧪 unverified (not yet built/run) · ⛔ not started

> Note: as of this writing nothing has been compiled in CI yet, so every "shipped"
> item is more precisely "implemented, pending a green build" — tracked as 🧪 in
> the Build column.

| Area | Feature | Status | Build | Primary code |
|------|---------|--------|-------|--------------|
| Library | Import audio (multi-file, metadata) | ✅ | 🧪 | `LibraryView`, `AudioStorage` |
| Library | Manual song create/edit | ✅ | 🧪 | `SongEditorView` |
| Library | Search / sort / category filter | ✅ | 🧪 | `LibraryView` |
| Library | Auto BPM & key detection | ✅ | 🧪 | `AudioAnalyzer` |
| Songs | Multiple mixes, primary mix | ✅ | 🧪 | `Mix`, `SongDetailView` |
| Songs | Star rating, workflow category | ✅ | 🧪 | `Song`, `StarRatingView` |
| Playback | Now-playing bar + full player | ✅ | 🧪 | `NowPlayingBar`, `FullPlayerView` |
| Playback | Waveform scrubber | ✅ | 🧪 | `WaveformView`, `WaveformGenerator` |
| Playback | A/B mix compare | ✅ | 🧪 | `AudioPlayer.switchMix` |
| Playback | Background audio + lock screen | ✅ | 🧪 | `AudioPlayer` (MediaPlayer) |
| Playback | Project queue + auto-advance | ✅ | 🧪 | `AudioPlayer`, `ProjectDetailView` |
| Projects | Create/edit, drag-reorder | ✅ | 🧪 | `ProjectDetailView` |
| Projects | Energy flow analysis (rise/fall) | ✅ | 🧪 | `SequencingEngine`, `TrackFlowRow` |
| Projects | Harmonic (Camelot) key clashes | ✅ | 🧪 | `SequencingEngine`, `MusicalKey` |
| Projects | Energy curve chart | ✅ | 🧪 | `EnergyCurveChart` |
| Projects | Suggest order | ✅ | 🧪 | `SequencingEngine.suggestOrder` |
| Sharing | Text blurb / tracklist | ✅ | 🧪 | `SongDetailView`, `ProjectDetailView` |
| Sharing | Visual release cards (PNG) | ✅ | 🧪 | `ShareCardView`, `ReleaseCardRenderer` |
| Settings | Appearance, haptics, links, delete-all | ✅ | 🧪 | `SettingsView` |
| Platform | Release-surface gating | 🟡 | 🧪 | `ReleaseSurface` |
| Platform | Accessibility pass (labels, Reduce Motion) | 🟡 | 🧪 | across views, `A11yID` |
| Platform | Localization | ⛔ | — | strings hard-coded (en only) |
| Platform | iCloud sync | ⛔ | — | — |
| Platform | Onboarding / first-run | ✅ | 🧪 | `OnboardingView`, `RootView` |
| Platform | Repository layer / DI container | ⛔ | — | views use `modelContext` directly |
| Platform | Schema versioning / migration | ⛔ | — | single implicit schema |
| Platform | UI tests / CI green | ⛔ | — | unit tests only; CI added, unverified |

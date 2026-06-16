# Specs

Authoritative descriptions of system behavior. Source-of-truth hierarchy:

```
governance (this file) → system specs → shipped behavior → planned behavior
        → docs/feature-inventory.md (what ships today)
        → ROADMAP.md (maybe / future)
```

When a spec and the code disagree, the spec wins for *intended* behavior and the
inventory wins for *current* behavior — fix whichever is wrong and note it.

## Agent entry point

**[`shipped/README.md`](shipped/README.md)** — routing table. Read one shipped
spec per task area (~1–2k tokens). Do not load the full monolith.

## System specs

- [Architecture](Architecture.md) — layers, dependency rules, module map.
- [Accessibility](Accessibility.md) — release-gate requirements and screen tracker.

## Shipped behavior (`specs/shipped/`)

| Spec | Topic |
|------|-------|
| [AppShell](shipped/AppShell.md) | Tabs, bootstrap, onboarding, demo seed |
| [DataModel](shipped/DataModel.md) | Song, Mix, Project, enums |
| [LibraryAndImport](shipped/LibraryAndImport.md) | Catalog list, multi/single import |
| [SongsAndMixes](shipped/SongsAndMixes.md) | Detail, editor, primary mix |
| [AudioAnalysis](shipped/AudioAnalysis.md) | BPM & key (`AudioAnalyzer`) |
| [VocalDetection](VocalDetection.md) | Vocals + confidence (same analyzer) |
| [Playback](shipped/Playback.md) | Player, queue, A/B, lock screen |
| [Waveforms](shipped/Waveforms.md) | Generate, cache, scrub |
| [ProjectsAndSequencing](shipped/ProjectsAndSequencing.md) | Flow analysis, suggest order |
| [Sharing](shipped/Sharing.md) | PNG cards, text share |
| [Platform](shipped/Platform.md) | Settings, gating, tests |
| [Library Polish](LibraryPolish.md) | Filters, swipes, import progress (shipped) |

## Planned features (not shipped)

- [Version Stack](VersionStack.md) — mix roles, **export prefix** matching, version stack UI (🟡 Phase 1–2A/B shipped).
- [Release Tracking](ReleaseTracking.md) — release dates, distributor, links.
- [Brand Kit](BrandKit.md) — accent, logo for share cards.
- [Audiogram Export](AudiogramExport.md) — story/square video teasers.
- [Loudness Analysis](LoudnessAnalysis.md) — LUFS per mix.
- [Sequencing Enhancements](SequencingEnhancements.md) — suggest preview, arcs, transitions.
- [Timeline Markers](TimelineMarkers.md) — drop/hook markers.
- [Catalog Sync & Backup](CatalogSync.md) — export/import, iCloud.

## Conventions

- Each shipped spec ends with a **Verification** block: date + code paths + tests.
- Planned specs end with **Verification** when implemented.
- New user-visible strings land in every bundled locale at once (currently `en`
  only; see ROADMAP §Localization).

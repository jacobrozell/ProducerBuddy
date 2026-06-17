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
- [PlatformParity](PlatformParity.md) — engineering bar vs sibling apps.

## Shipped behavior (`specs/shipped/`)

| Spec | Topic |
|------|-------|
| [AppShell](shipped/AppShell.md) | Tabs, bootstrap, onboarding, demo seed |
| [DataModel](shipped/DataModel.md) | Song, Mix, Project, enums |
| [LibraryAndImport](shipped/LibraryAndImport.md) | Catalog list, multi/single import |
| [SongsAndMixes](shipped/SongsAndMixes.md) | Detail, editor, primary mix |
| [AudioAnalysis](shipped/AudioAnalysis.md) | BPM & key (`AudioAnalyzer`) |
| [VocalDetection](VocalDetection.md) | Vocals + confidence (same analyzer) |
| [Playback](shipped/Playback.md) | Player, queue, A/B, loops, lock screen |
| [Waveforms](shipped/Waveforms.md) | Generate, cache, scrub |
| [ProjectsAndSequencing](shipped/ProjectsAndSequencing.md) | Flow analysis, suggest order |
| [Sharing](shipped/Sharing.md) | PNG cards, brand kit, text share |
| [Platform](shipped/Platform.md) | Settings, gating, catalog backup, tests |

## Shipped features (full specs at repo root)

These behaviors ship; detailed specs live alongside planned work:

| Spec | Topic | Status |
|------|-------|--------|
| [LibraryPolish](LibraryPolish.md) | Filters, swipes, import progress | ✅ |
| [ReleaseTracking](ReleaseTracking.md) | Release date, distributor, links | ✅ |
| [BrandKit](BrandKit.md) | Accent, logo, tagline for share surfaces | ✅ |
| [AudiogramExport](AudiogramExport.md) | Story/square MP4 teasers | ✅ |
| [LoudnessAnalysis](LoudnessAnalysis.md) | LUFS per mix | ✅ |
| [CatalogSync](CatalogSync.md) | Export/import ZIP | 🟡 Phase 1 ✅; iCloud ⛔ |

## Planned / partial features

- [Version Stack](VersionStack.md) — mix roles, export prefix, resolution sheet (🟡 compare UI open).
- [Sequencing Enhancements](SequencingEnhancements.md) — arc templates, transitions (🟡 suggest preview ✅).
- [Timeline Markers](TimelineMarkers.md) — drop/hook markers (⛔).

## Conventions

- Each shipped spec ends with a **Verification** block: date + code paths + tests.
- Planned specs end with **Verification** when implemented.
- New user-visible strings land in every bundled locale at once (currently `en`
  only; `L10n` scaffolding exists).

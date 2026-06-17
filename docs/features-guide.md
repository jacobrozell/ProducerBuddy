# MixStack — Features Guide (index)

**Agents: start at [`specs/shipped/README.md`](../specs/shipped/README.md)** — routing
table to small, focused specs (~1–2k tokens each). Do not read this file for
implementation detail.

## Quick routing

| Task | Spec |
|------|------|
| App entry, tabs, onboarding | [AppShell](../specs/shipped/AppShell.md) |
| Models, relationships | [DataModel](../specs/shipped/DataModel.md) |
| Library, import, filters | [LibraryAndImport](../specs/shipped/LibraryAndImport.md) · [LibraryPolish](../specs/LibraryPolish.md) |
| Song detail, mixes, editor, release | [SongsAndMixes](../specs/shipped/SongsAndMixes.md) · [ReleaseTracking](../specs/ReleaseTracking.md) |
| BPM, key, LUFS | [AudioAnalysis](../specs/shipped/AudioAnalysis.md) · [LoudnessAnalysis](../specs/LoudnessAnalysis.md) |
| Vocals | [VocalDetection](../specs/VocalDetection.md) |
| Player, queue, lock screen, loops | [Playback](../specs/shipped/Playback.md) |
| Waveforms | [Waveforms](../specs/shipped/Waveforms.md) |
| Projects, sequencing | [ProjectsAndSequencing](../specs/shipped/ProjectsAndSequencing.md) |
| Share cards, brand kit, audiograms | [Sharing](../specs/shipped/Sharing.md) · [BrandKit](../specs/BrandKit.md) · [AudiogramExport](../specs/AudiogramExport.md) |
| Settings, catalog backup, tests | [Platform](../specs/shipped/Platform.md) · [CatalogSync](../specs/CatalogSync.md) |

## Other docs

| Doc | Use |
|-----|-----|
| [feature-inventory.md](feature-inventory.md) | What ships today (status table) |
| [ROADMAP.md](../ROADMAP.md) | Future work |
| [specs/README.md](../specs/README.md) | Spec governance + planned features |
| [Architecture.md](../specs/Architecture.md) | Layer rules |
| [agent-build-checklist.md](agent-build-checklist.md) | Build verification |

## Workflow (one line)

Import → Library → Song/Mixes → Project sequencing → Share · Playback throughout

**Last updated:** 2026-06-17

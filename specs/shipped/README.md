# Shipped features — agent index

**Read only the spec for the area you're touching.** Each file is self-contained
and lists primary code paths at the bottom.

## Routing table

| If you're working on… | Read |
|------------------------|------|
| Tabs, onboarding, app entry, demo seed | [AppShell](AppShell.md) |
| SwiftData models, relationships, enums | [DataModel](DataModel.md) |
| Library list, filters, import audio | [LibraryAndImport](LibraryAndImport.md) · [LibraryPolish](../LibraryPolish.md) |
| Song detail, editor, mixes, release fields | [SongsAndMixes](SongsAndMixes.md) · [ReleaseTracking](../ReleaseTracking.md) |
| BPM/key detection, `AudioAnalyzer` | [AudioAnalysis](AudioAnalysis.md) |
| LUFS loudness | [LoudnessAnalysis](../LoudnessAnalysis.md) |
| Vocal detection, confidence meter, vocal filter | [VocalDetection](../VocalDetection.md) |
| Player, queue, A/B, section loops, lock screen | [Playback](Playback.md) |
| Waveform generate/draw/scrub | [Waveforms](Waveforms.md) |
| Projects, sequencing, energy curve, suggest preview | [ProjectsAndSequencing](ProjectsAndSequencing.md) |
| Share cards, brand kit, audiograms, text share | [Sharing](Sharing.md) · [BrandKit](../BrandKit.md) · [AudiogramExport](../AudiogramExport.md) |
| Settings, catalog export/import, haptics, tests | [Platform](Platform.md) · [CatalogSync](../CatalogSync.md) |
| Layers, dependency rules | [Architecture](../Architecture.md) |
| What ships vs not | [feature-inventory](../../docs/feature-inventory.md) |
| Future work | [ROADMAP](../../ROADMAP.md) |

## Conventions

- **Status:** everything in `specs/shipped/` is ✅ shipped unless noted.
- **Verification block** at the end of each file: code paths + test file.
- Vocal detection has a full product spec at `VocalDetection.md`; shipped
  behavior summary is there, not duplicated in `AudioAnalysis.md`.

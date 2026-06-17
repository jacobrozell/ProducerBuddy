# Architecture Spec

## Layers

MixStack is a single-target SwiftUI + SwiftData app. Dependencies point
downward only:

| Layer | Folder | Responsibility | May import |
|-------|--------|----------------|------------|
| Views / Components | `Sources/Views`, `Sources/Components` | SwiftUI screens and reusable UI | Services, Models, Support |
| Services | `Sources/Services` | Pure logic, audio I/O, rendering | Models, Foundation/AVFoundation |
| Models | `Sources/Models` | SwiftData `@Model`s and value enums | Foundation, SwiftData |
| Support | `Sources/Support` | Cross-cutting helpers | Foundation/UIKit |

### Dependency rules

1. **Services must not import SwiftUI/UIKit.** `SequencingEngine`,
   `AudioAnalyzer`, and `WaveformGenerator` are pure and unit-tested.
   (`AudioPlayer` is the deliberate exception — it's a `@MainActor @Observable`
   playback controller and may use MediaPlayer/AVFoundation.)
2. **No business rules in `View.body`** — compute in services or view helpers.
3. **Single source of truth per concern:** `AppLinks` (URLs), `ReleaseSurface`
   (surface gating), `A11yID` (UI-test identifiers), `AppAppearance` (theme).

## Data model

```
Song 1──* Mix          (cascade delete; Song.primaryMix picks the best version)
Song 1──* ProjectTrack
Project 1──* ProjectTrack   (ordered by `position`; join model allows reuse)
```

`Mix` caches a normalized `[Float]` waveform and the audio file is stored by
relative filename under Documents/Audio (`AudioStorage`).

## Known architectural debt

Tracked so it isn't forgotten:

- **No repository layer / DI container.** Views talk to `modelContext` directly.
  Introducing `any …Repository` protocols would isolate persistence for testing.
- **No versioned schema / migration plan.** Currently relies on SwiftData
  lightweight migration during pre-release development.
- **Flat folders**, not the `Domain/Data/Persistence` split; acceptable at this
  size, revisit if the app grows.

## Verification

- Target release: v1.0
- Last verified: 2026-06-16 (by inspection; **not yet compiled in CI**)
- Primary code paths: `Sources/` as mapped above.

# Platform (shipped)

Settings, cross-cutting support, demo seeding, testing.

## ReleaseSurface (`Sources/Support/ReleaseSurface.swift`)

```swift
static func isEnabled(_ shipDefault: Bool) -> Bool {
    shipDefault || CommandLine.arguments.contains("-enable_full_product_surface")
}
```

| Flag | Default | Gates |
|------|---------|-------|
| `settings` | true | Settings tab |
| `shareCards` | true | Share Card menu items |
| `audioAnalysis` | true | Detect Audio Metadata |

## SettingsView

| Section | Keys / behavior |
|---------|-----------------|
| Appearance | `@AppStorage("appearance")` → `AppAppearance` |
| Feedback | `@AppStorage("hapticsEnabled")` |
| About | `AppLinks` (privacy, support, a11y, tip jar), replay onboarding, version |
| Data | Load demo tracks; delete all with confirmation |

`deleteAllData()` — stop player, delete all songs/projects, remove audio files.

## Haptics (`Sources/Support/Haptics.swift`)

Respects `hapticsEnabled`. Used on play/pause, primary toggle, delete success.

## DemoAudioSeeder

- Bundle `Resources/*.mp3` (gitignored)
- `-seed_demo_tracks` on empty library (`RootView`)
- Settings "Load Demo Tracks" if `hasBundleTracks`
- `createDemoProjectIfNeeded` — "Demo EP" when no projects and ≥2 songs

## Onboarding

`OnboardingView` — 5 pages. `@AppStorage("hasCompletedOnboarding")`.

## Accessibility

- `A11yID` — UI test identifiers
- VoiceOver on transport, vocal meter, filters
- Reduce Motion in `RootView`, `OnboardingView`

Full gate requirements: [Accessibility](../Accessibility.md).

## Not shipped

Localization, iCloud, schema migrations, repository/DI layer.

## Tests (57 total, 2026-06-16)

| File | Area |
|------|------|
| `AudioAnalyzerTests` | BPM/key |
| `VocalDetectionTests` | Vocals |
| `SequencingEngineTests` | Flow/suggest |
| `WaveformTests` | Peaks |
| `AudioPlayerTests` | Queue/A/B |
| `SongImportServiceTests` | Import |
| `ShareCardTests` | Cards |
| `ModelTests` | Models |
| `SupportTests` | Helpers |

Build: `ProducerBuddy` scheme, simulator.

## Verification

- Last verified: 2026-06-16
- Code: `SettingsView`, `ReleaseSurface`, `DemoAudioSeeder`, `Haptics`, `AppLinks`, `A11yID`, `AppAppearance`
- Tests: `SupportTests.swift`

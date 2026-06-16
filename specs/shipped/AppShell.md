# App Shell (shipped)

Navigation, bootstrap, and shared environment.

## Entry

`ProducerBuddyApp` (`Sources/ProducerBuddyApp.swift`):

1. Creates `ModelContainer` for `Song`, `Mix`, `Project`, `ProjectTrack`
2. Creates `@State audioPlayer = AudioPlayer()`
3. Injects `.environment(audioPlayer)` + `.modelContainer`

## RootView

`Sources/Views/RootView.swift` — top-level `TabView`:

| Tab | View | Gated by |
|-----|------|----------|
| Library | `LibraryView` | always |
| Projects | `ProjectListView` | always |
| Settings | `SettingsView` | `ReleaseSurface.settings` |

**Now-playing bar:** `safeAreaInset(edge: .bottom)` shows `NowPlayingBar` when
`audioPlayer.currentMix != nil`. Animates in/out unless Reduce Motion.

**Onboarding:** `fullScreenCover` when `!hasCompletedOnboarding`
(`@AppStorage`). `OnboardingView` sets flag on finish/skip.

**Appearance:** `@AppStorage("appearance")` → `preferredColorScheme`.

## Demo seed (agent builds)

`.task` in `RootView` calls `seedDemoTracksIfNeeded()` when:

- Launch arg `-seed_demo_tracks` (`DemoAudioSeeder.isRequested`)
- Library song count is 0

Uses `DemoAudioSeeder.importBundleTracks()` → `SongImportService` → optional
`createDemoProjectIfNeeded`. Also sets `hasCompletedOnboarding = true`.

## Workflow (context)

```
Import → Library → Song detail → Project → Share
                    ↘ Playback ↗
```

## Verification

- Last verified: 2026-06-16
- Code: `ProducerBuddyApp.swift`, `RootView.swift`, `OnboardingView.swift`
- Tests: `SupportTests` (surface gating)

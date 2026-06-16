# Platform parity roadmap

Adoption plan to bring MixStack to the same engineering bar as **Dart Buddy** and
**MiniMuster**. Reference repos: `Dart-Buddy`, `WarhammerTracker/ios/MiniMuster`.

## Status legend

✅ shipped · 🟡 in progress · ⛔ planned

| Area | Dart Buddy / MiniMuster pattern | MixStack status |
|------|----------------------------------|-----------------|
| Design tokens | `Brand` + `DS` layers, README | 🟡 `Sources/DesignSystem/` |
| Tab shell | Content tabs + settings sheet | 🟡 Library/Projects + gear sheet |
| Logging | `AppLogger` → sinks | 🟡 Console + analytics stub |
| Analytics | Firebase allowlist (opt-in) | ⛔ Stub only; privacy-first |
| CI split jobs | build-for-testing + test artifact | 🟡 `.github/workflows/ci.yml` |
| Coverage artifact | informational summary, no gate | 🟡 `Scripts/ci/coverage-summary.sh` |
| Unit + a11y tests | Swift Testing tags + contrast | 🟡 `Tests/Accessibility/` |
| UI test matrix | Nightly parallel schemes | ⛔ |
| GitHub Pages | Shared CSS, legal pages | 🟡 `docs/assets/style.css` |
| A11y audits | Dated VoiceOver reports | 🟡 `accessibility/audits/` |
| Localization | String Catalog + parity test | ⛔ |
| Repository layer | `any …Repository` DI | ⛔ |
| Brand Kit | Share-surface accent | ⛔ spec only |

## Phase 1 — Foundations (this pass)

- Design system tokens and chrome modifiers
- Settings as toolbar sheet (MiniMuster pattern)
- Logging sink architecture with analytics off by default
- CI build/test split + coverage artifact
- WCAG contrast + identifier contract tests
- GitHub Pages stylesheet aligned with brand

## Phase 2 — Quality gates

- Fix remaining SwiftLint strict issues (if any regress)
- Integration test: seed library via launch args, relaunch asserts persistence
- VoiceOver audit artifact for Library, Song detail, Player, Settings
- `MixStackCI` scheme: unit + accessibility only (fast PR path)

## Phase 3 — UI test matrix

- `MixStackUITestCase` with `-ui_test_reset`, `-disable_analytics`
- Nightly workflow: smoke, library import, player, accessibility audit
- Split UI targets in `project.yml` (mirror Dart Buddy)

## Phase 4 — Optional telemetry

- `GoogleService-Info.plist.example` + `FirebaseBootstrap`
- `FirebaseAnalyticsLogSink` adapter behind `FeatureFlags.analyticsEnabled`
- Update App Store privacy nutrition label if analytics ships

## Phase 5 — Polish & ship

- String Catalog (en → es/de later)
- iPad `NavigationSplitView` for library + detail
- Brand Kit for share cards
- App Store metadata + screenshots

## References

| App | Key paths |
|-----|-----------|
| Dart Buddy | `DesignSystem/`, `Support/Logging/`, `.github/workflows/ci.yml`, `Tests/TestTags.swift` |
| MiniMuster | `DesignSystem/Tokens.swift`, settings sheet, `StatTile`, warm archive palette |

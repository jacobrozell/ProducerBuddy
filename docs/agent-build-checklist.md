# Agent Build Checklist — MixStack

Living status of this app against the 0→Ship engineering checklist. The full
generic template (all 18 phases, agent prompt library, query template) is the
canonical reference — paste it to start a new session or store a copy in your
docs repo. **This file tracks where MixStack actually is.**

Legend: ✅ done · 🟡 partial · ⛔ not started · ⚪ N/A (pre-v1)

## Phase status

| Phase | Title | Status | Notes |
|-------|-------|--------|-------|
| 0 | Repo & agent infra | 🟡 | XcodeGen, .gitignore, SwiftLint, CONTRIBUTING, CI, secret hooks ✅. XcodeBuildMCP via `verify-local.sh` ✅. Layered `Domain/Data/Persistence` folders 🟡 (`Sources/Data/Repositories` started). |
| 1 | Spec system | 🟡 | `specs/` shipped + planned specs, `docs/feature-inventory.md`, ROADMAP ✅. Drift script ✅ (`Scripts/ci/check-spec-drift.py`). |
| 2 | Design system & a11y foundations | 🟡 | `Sources/DesignSystem/`, Reduce Motion, theme picker, non-color cues ✅. WCAG contrast tests ✅. |
| 3 | Domain layer (test-first) | ✅ | `SequencingEngine`, `AudioAnalyzer`, `WaveformGenerator`, `LoudnessAnalyzer` pure + unit-tested. |
| 4 | Persistence & repositories | 🟡 | SwiftData models + container ✅. Repository protocols + `AppDependencies` DI ✅. Versioned schema/migration ⛔. |
| 5 | App shell & navigation | 🟡 | `@main`, TabView, now-playing chrome, release-surface gate, onboarding ✅. Router/deep links ⛔. |
| 6 | First vertical slice | ✅ | Import → library → detail → project → sequence → share → playback ✅. Integration + relaunch tests ✅. |
| 7 | Shared chrome & adaptive layout | 🟡 | Empty states, banners, badges ✅. iPad split ✅ (`MixStackUIPad`). |
| 8 | Entity mgmt & settings | ✅ | CRUD, brand kit, catalog export/import, delete-all ✅. |
| 9 | Lists, history & derived views | ✅ | Library/Projects lists, energy chart, filters, section headers ✅. |
| 10 | Localization | 🟡 | `L10n` + `Localizable.xcstrings` + parity test ✅; most strings still hard-coded. |
| 11 | Accessibility hardening (gate) | 🟡 | Engineering pass ✅; automated UI a11y audits ✅; physical VoiceOver sign-off ⛔. |
| 12 | Test matrix & CI | ✅ | **121** unit + **10** UI tests; SwiftLint strict ✅; split UI schemes + `MixStackCI` ✅; drift script in CI ✅. |
| 13 | Release surface / lean ship | 🟡 | `ReleaseSurface` gate + `-enable_full_product_surface` ✅. App Store metadata ⛔. |
| 14 | Telemetry/deep links/extensions | ⚪ | Analytics stub only; off by default. |
| 15 | Legal pages & store URLs | 🟡 | `docs/*.html` + `AppLinks` ✅. Pages deploy workflow 🧪. |
| 16 | Release QA & ship | ⛔ | No device matrix / RC sign-off. |
| 17 | Expand surface (post-v1) | ⚪ | Pre-v1. |
| 18 | Doc hygiene | 🟡 | README/ROADMAP/inventory updated ✅. Drift script ✅. |

## Verification snapshot (2026-06-20)

Full gate on **iPhone 17** + **iPad (A16)** sims via `bash Scripts/ci/verify-local.sh`
(xcodebuildmcp).

| Check | Result |
|-------|--------|
| `xcodegen generate` | ✅ |
| `swiftlint --strict` | ✅ |
| `check-spec-drift.py` | ✅ |
| `MixStackCI` (121 unit tests) | ✅ |
| `MixStackUISmoke` | ✅ 2/2 |
| `MixStackUIAccessibility` | ✅ 4/4 |
| `MixStackUILandscape` | ✅ 2/2 |
| `MixStackUIPad` | ✅ 2/2 |

**Simulator UI exercised:** onboarding · library filters/swipes · song detail ·
full player · project sequencing · suggest-order preview · share card · audiogram
sheet · brand kit · catalog export · settings · delete-all · version compare.

**Still manual / device:** VoiceOver walkthrough (see `accessibility/audits/`).

## Top of the backlog (highest leverage)

1. **Physical VoiceOver sign-off (11)** — `accessibility/audits/2026-06-16-voiceover-core-flows.md`.
2. **iCloud catalog sync** — Phase 2 of [CatalogSync](../specs/CatalogSync.md).
3. **Merge duplicates UI** — finish [VersionStack](../specs/VersionStack.md) Phase 3 `MergeSongsSheet`.
4. **Localization (10)** — migrate remaining strings to String Catalog.
5. **Schema versioning (4)** — migration plan before App Store schema lock.
6. **Router / deep links (5)** — gated navigation for share URLs.

## Progress log

| Date | Change | Commit / notes |
|------|--------|----------------|
| 2026-06-16 | Initial app through waveforms + CI scaffolding | multiple |
| 2026-06-16 | Library polish, release tracking, brand kit, LUFS, audiograms, catalog sync, section loops | multiple |
| 2026-06-17 | Doc hygiene pass; 126 tests green; SwiftLint strict clean | docs |
| 2026-06-20 | Version compare UI, banner share preset, repository layer, drift script, L10n parity | agent |

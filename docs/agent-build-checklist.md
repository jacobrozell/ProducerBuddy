# Agent Build Checklist — ProducerBuddy

Living status of this app against the 0→Ship engineering checklist. The full
generic template (all 18 phases, agent prompt library, query template) is the
canonical reference — paste it to start a new session or store a copy in your
docs repo. **This file tracks where ProducerBuddy actually is.**

Legend: ✅ done · 🟡 partial · ⛔ not started · ⚪ N/A (pre-v1)

## Phase status

| Phase | Title | Status | Notes |
|-------|-------|--------|-------|
| 0 | Repo & agent infra | 🟡 | XcodeGen, .gitignore, SwiftLint, CONTRIBUTING, CI, secret hooks ✅. **0.11 verified locally** (build + 57 tests green, Release build OK). `.cursor/mcp.json` + XcodeBuildMCP + ios-simulator ✅. Named sim `ProducerBuddy` (iPhone 16 Pro, iOS 26.5). Layered `Domain/Data/Persistence` folders ⛔ (flat `Sources/`). |
| 1 | Spec system | 🟡 | `specs/` (Architecture, Accessibility), `docs/feature-inventory.md`, ROADMAP backlog ✅. Full system-spec set (design tokens, test plan, governance) ⛔. |
| 2 | Design system & a11y foundations | 🟡 | Reduce Motion, theme picker, non-color cues ✅. Token layers, contrast tracking, `Tests/Accessibility/` ⛔. |
| 3 | Domain layer (test-first) | ✅ | `SequencingEngine`, `AudioAnalyzer`, `WaveformGenerator` pure + unit-tested. Typed errors / command pattern ⛔. |
| 4 | Persistence & repositories | 🟡 | SwiftData models + container ✅. Repository protocols, DI container, versioned schema/migration ⛔. |
| 5 | App shell & navigation | 🟡 | `@main`, TabView, now-playing chrome, release-surface gate, first-run onboarding ✅. Router/deep links ⛔. |
| 6 | First vertical slice | 🟡 | Import → library → detail → project → sequence → share implemented ✅. **Simulator MCP pass** (manual song, project, add tracks, share card, delete-all) ✅. Audio import / playback / detect BPM ⛔ (needs real files). Integration test + relaunch test ⛔. |
| 7 | Shared chrome & adaptive layout | 🟡 | Empty states, banners, badges ✅. Orientation/idiom logic, iPad layout ⛔. |
| 8 | Entity mgmt & settings | ✅ | CRUD ✅. Settings + AppLinks + delete-all ✅ (verified wipe → `0 songs · 0 projects`). Tip jar wired (nil = hidden). Onboarding replay ✅. |
| 9 | Lists, history & derived views | ✅ | Library/Projects lists, energy chart, search/filter. Sort menu ✅ (simulator). Pagination ⛔ (fine at scale). |
| 10 | Localization | ⛔ | All strings hard-coded (en). No catalog/parity test. |
| 11 | Accessibility hardening (gate) | 🟡 | Engineering pass done (labels, adjustable scrubber, Reduce Motion). **MCP AX audit** on Library/Projects/Settings/detail ✅ (no blockers found). Dated VoiceOver audit doc, large-text, contrast evidence, orientation matrix ⛔. |
| 12 | Test matrix & CI | 🟡 | **57 unit tests pass** locally; secret scan ✅; SwiftLint default ✅ (18 warnings); **`swiftlint --strict` fails** (CI lint job would fail). ~16.5% app line coverage. UI test targets, nightly matrix, GHA run on push ⛔. |
| 13 | Release surface / lean ship | 🟡 | `ReleaseSurface` gate + `-enable_full_product_surface` ✅. Branch model, lean v1 plan, QA matrix ⛔. |
| 14 | Telemetry/deep links/extensions | ⚪ | None by design (no analytics). Deferred. |
| 15 | Legal pages & store URLs | 🟡 | `docs/*.html` + `AppLinks` ✅. Pages deploy workflow (`pages.yml`) 🧪 (needs default-branch push). App Store metadata/screenshots ⛔. |
| 16 | Release QA & ship | ⛔ | Owner decisions open; no device matrix / RC sign-off. |
| 17 | Expand surface (post-v1) | ⚪ | Pre-v1. |
| 18 | Doc hygiene | 🟡 | README/ROADMAP/specs/inventory maintained. Drift script ⛔. |

## Verification snapshot (2026-06-16)

First agent build + simulator session on **`ProducerBuddy`** sim (`B9B740EB-…`).

| Check | Result |
|-------|--------|
| `xcodegen generate` | ✅ |
| `test_sim` (57 tests) | ✅ ×2 |
| Release `build_sim` | ✅ |
| `Scripts/check-secrets.sh` | ✅ |
| `swiftlint` | ⚠️ 18 warnings |
| `swiftlint --strict` | ❌ (CI lint job) |
| Code coverage (app) | 16.5% (873/5295 lines) |
| Swift 6 compile fixes | ✅ (`.accent` → `Color.accentColor`, `ShareCardView` gradient, `AudioAnalyzer` type compare) |

**Simulator UI exercised:** onboarding skip/replay · manual song CRUD · category filter · sort · song detail + share card sheet · project create · add track · settings (haptics, delete-all, intro replay) · data persistence across relaunch · delete-all reset.

**Not exercised (needs audio fixtures / device):** file import · playback / now-playing · waveform scrub · BPM/key detect · project play queue · suggest order (3+ tracks) · energy chart.

**Minor UX notes from MCP pass:** category filter with no matches shows generic empty state; delete-all sheet has no explicit Cancel in AX tree (dismiss tap-outside).

## Top of the backlog (highest leverage)

1. **Fix SwiftLint strict (12)** — 18 violations block CI lint; rename short vars + line length.
2. **Integration test (6.6)** — seed song + project via launch args; relaunch asserts persistence.
3. **Localization (10)** — String Catalog; en source of truth.
4. **VoiceOver audit artifact (11)** — run prompt from checklist § Agent prompt library → `accessibility/audits/2026-06-16-voiceover-core.md`.
5. **Repository layer (4)** — `any …Repository` to isolate SwiftData before schema versioning.
6. **Audio fixture tests** — import + playback smoke with bundled `.wav` / `.m4a` in test target.

## Agent prompt library (quick picks for this repo)

| When | Prompt (from generic checklist) |
|------|-------------------------------|
| Now | **MCP UI pass** — flows: import → play → sequence → share |
| Phase 11 | **VoiceOver audit** — Library, Song detail, Project detail, Player, Settings |
| Phase 12 | **User scenario** → integration test for import-first happy path |
| Pre-ship | **Release-surface audit** — Release build without `-enable_full_product_surface` |
| Pre-ship | **What is left before ship?** — cross-check inventory + owner decisions |

## Progress log

| Date | Change | Commit / notes |
|------|--------|----------------|
| 2026-06-16 | Initial app: models, sequencing, library, projects, tests | `init` |
| 2026-06-16 | UX roadmap | (docs) |
| 2026-06-16 | Import-first flow + full-screen scrubbing player | |
| 2026-06-16 | Visual release cards + background audio/lock screen | |
| 2026-06-16 | Energy-flow chart + badge legend | |
| 2026-06-16 | Project play queue + harmonic (Camelot) mixing | |
| 2026-06-16 | Automatic BPM & key detection | |
| 2026-06-16 | Waveforms (cache + Canvas + scrubber) | |
| 2026-06-16 | Phase 0/1/2/8/11/13/15 scaffolding | `7dc9dfc` |
| 2026-06-16 | First-run onboarding (replayable from Settings) | `295fdf1` |
| 2026-06-16 | GitHub Pages deploy workflow | `0fa0d60` |
| 2026-06-16 | **First green build + 57 tests**; ProducerBuddy sim; MCP UI pass; Swift 6 fixes | uncommitted |

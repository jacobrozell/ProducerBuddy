# Agent Build Checklist — ProducerBuddy

Living status of this app against the 0→Ship engineering checklist. The full
generic template (all 18 phases, rules, query template) is the canonical
reference; this file tracks **where ProducerBuddy actually is**.

Legend: ✅ done · 🟡 partial · ⛔ not started · ⚪ N/A (pre-v1)

## Phase status

| Phase | Title | Status | Notes |
|-------|-------|--------|-------|
| 0 | Repo & agent infra | 🟡 | XcodeGen, .gitignore, SwiftLint, CONTRIBUTING, CI, secret hooks ✅. Layered `Domain/Data/Persistence` folders ⛔ (flat `Sources/`). `.cursor/mcp.json` ⛔. |
| 1 | Spec system | 🟡 | `specs/` (Architecture, Accessibility), `docs/feature-inventory.md`, ROADMAP backlog ✅. Full system-spec set (design tokens, test plan, governance) ⛔. |
| 2 | Design system & a11y foundations | 🟡 | Reduce Motion, theme picker, non-color cues ✅. Token layers, contrast tracking, `Tests/Accessibility/` ⛔. |
| 3 | Domain layer (test-first) | ✅ | `SequencingEngine`, `AudioAnalyzer`, `WaveformGenerator` pure + unit-tested. Typed errors / command pattern ⛔. |
| 4 | Persistence & repositories | 🟡 | SwiftData models + container ✅. Repository protocols, DI container, versioned schema/migration ⛔. |
| 5 | App shell & navigation | 🟡 | `@main`, TabView, now-playing chrome, release-surface gate ✅. Router/deep links, onboarding ⛔. |
| 6 | First vertical slice | ✅ | Import → library → detail → project → sequence → share works end-to-end. Integration/relaunch test ⛔. |
| 7 | Shared chrome & adaptive layout | 🟡 | Empty states, banners, badges ✅. Orientation/idiom logic, iPad layout ⛔. |
| 8 | Entity mgmt & settings | 🟡 | CRUD ✅. Settings + AppLinks + delete-all ✅. Tip jar wired (nil = hidden). |
| 9 | Lists, history & derived views | ✅ | Library/Projects lists, energy chart, search/filter. Pagination ⛔ (fine at scale). |
| 10 | Localization | ⛔ | All strings hard-coded (en). No catalog/parity test. |
| 11 | Accessibility hardening (gate) | 🟡 | Engineering pass done (labels, adjustable scrubber, Reduce Motion). Manual VoiceOver/large-text/contrast/orientation audits ⛔. |
| 12 | Test matrix & CI | 🟡 | Unit tests (Swift Testing) + GitHub Actions lint/build/test + secret scan ✅ (**unverified — never run**). UI test targets, nightly matrix ⛔. |
| 13 | Release surface / lean ship | 🟡 | `ReleaseSurface` gate + `-enable_full_product_surface` ✅. Branch model, lean v1 plan, QA matrix ⛔. |
| 14 | Telemetry/deep links/extensions | ⚪ | None by design (no analytics). Deferred. |
| 15 | Legal pages & store URLs | 🟡 | `docs/*.html` (privacy/support/accessibility/index) + `AppLinks` ✅. GitHub Pages enablement + store metadata ⛔. |
| 16 | Release QA & ship | ⛔ | Owner decisions open; no device matrix / RC sign-off. |
| 17 | Expand surface (post-v1) | ⚪ | Pre-v1. |
| 18 | Doc hygiene | 🟡 | README/ROADMAP/specs/inventory maintained. Drift script ⛔. |

## Top of the backlog (highest leverage)

1. **Verify Phase 0.11** — run `xcodegen generate && xcodebuild test`. Nothing is
   truly "done" until the build is green; CI added but unproven.
2. **Localization (10)** — extract strings to a String Catalog; en source of truth.
3. **Manual accessibility audit (11)** — VoiceOver pass on the 5 core screens;
   fill the screen tracker in `specs/Accessibility.md`.
4. **Repository layer (4)** — introduce `any …Repository` to isolate SwiftData.
5. **Onboarding + GitHub Pages enablement (5, 15)** — first-run + hosted URLs live.

## Progress log

| Date | Change | Commit |
|------|--------|--------|
| 2026-06-16 | Initial app: models, sequencing, library, projects, tests | `init` |
| 2026-06-16 | UX roadmap | (docs) |
| 2026-06-16 | Import-first flow + full-screen scrubbing player | |
| 2026-06-16 | Visual release cards + background audio/lock screen | |
| 2026-06-16 | Energy-flow chart + badge legend | |
| 2026-06-16 | Project play queue + harmonic (Camelot) mixing | |
| 2026-06-16 | Automatic BPM & key detection | |
| 2026-06-16 | Waveforms (cache + Canvas + scrubber) | |
| 2026-06-16 | Phase 0/1/2/8/11/13/15 scaffolding: infra, specs, legal pages, Settings, a11y pass | |

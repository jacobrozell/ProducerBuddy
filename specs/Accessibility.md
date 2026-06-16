# Accessibility Spec

Accessibility is a **release gate** — no launch with open critical failures on
core flows. Target: WCAG 2.1 AA.

## Requirements

| # | Requirement | Status |
|---|-------------|--------|
| A1 | Icon-only controls have `accessibilityLabel` | 🟡 core controls done |
| A2 | Interactive controls ≥ 44×44 pt | 🟡 star rating + transport use `minimumTapTarget()` |
| A3 | Dynamic Type via system text styles; no clipping at AXXXL | 🟡 empty states scroll at AXXXL |
| A4 | Reduce Motion respected for non-essential animation | ✅ `RootView`, onboarding |
| A5 | Status not conveyed by color alone (label/symbol pairing) | ✅ badges/legend |
| A6 | Decorative imagery hidden from VoiceOver | 🟡 player, song/project headers |
| A7 | Canvas waveform exposed as an adjustable element | ✅ `FullPlayerView` |
| A8 | Supported orientations documented | 🟡 landscape layouts in player, onboarding, chart |
| A9 | Accessibility statement linked from Settings | ✅ `AppLinks.accessibility` |
| A10 | Automated contrast/label tests on tokens & key controls | 🟡 contrast + identifier contract tests |

## Supported orientations

Portrait and landscape are enabled in `project.yml`. Landscape layouts on large
phones vs iPad are **not yet verified** (distinguish with device idiom, not
horizontal size class alone).

## Screen tracker

| Screen | VoiceOver | Dynamic Type | Contrast | Orientation |
|--------|-----------|--------------|----------|-------------|
| Library | 🟡 | 🟡 empty state scroll | ⛔ | 🟡 |
| Song detail | 🟡 | ⛔ | ⛔ | 🟡 |
| Full player | 🟡 | 🟡 scroll in landscape | ⛔ | 🟡 side-by-side landscape |
| Project detail | 🟡 | ⛔ | ⛔ | 🟡 chart height |
| Settings | 🟡 | ⛔ | ⛔ | 🟡 |
| Onboarding | 🟡 | 🟡 scroll + scaled hero | ⛔ | 🟡 compact layout |

(⛔ here = not yet manually audited, not necessarily failing.)

## Verification

- Target release: v1.0
- Last verified: 2026-06-16 (engineering pass + WCAG UI audits; physical
  VoiceOver pending — see `accessibility/audits/2026-06-16-voiceover-core-flows.md`)
- Primary code paths: `A11yID`, view modifiers across `Sources/Views` &
  `Sources/Components`, `RootView` (Reduce Motion / appearance).

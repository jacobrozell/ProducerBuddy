# Accessibility Spec

Accessibility is a **release gate** — no launch with open critical failures on
core flows. Target: WCAG 2.1 AA.

## Requirements

| # | Requirement | Status |
|---|-------------|--------|
| A1 | Icon-only controls have `accessibilityLabel` | 🟡 core controls done |
| A2 | Interactive controls ≥ 44×44 pt | 🟡 needs audit (star control is small) |
| A3 | Dynamic Type via system text styles; no clipping at AXXXL | 🟡 styles used, not verified |
| A4 | Reduce Motion respected for non-essential animation | ✅ `RootView` |
| A5 | Status not conveyed by color alone (label/symbol pairing) | ✅ badges/legend |
| A6 | Decorative imagery hidden from VoiceOver | 🟡 player/bar done |
| A7 | Canvas waveform exposed as an adjustable element | ✅ `FullPlayerView` |
| A8 | Supported orientations documented | ⛔ portrait + landscape enabled, untested |
| A9 | Accessibility statement linked from Settings | ✅ `AppLinks.accessibility` |
| A10 | Automated contrast/label tests on tokens & key controls | ⛔ not started |

## Supported orientations

Portrait and landscape are enabled in `project.yml`. Landscape layouts on large
phones vs iPad are **not yet verified** (distinguish with device idiom, not
horizontal size class alone).

## Screen tracker

| Screen | VoiceOver | Dynamic Type | Contrast | Orientation |
|--------|-----------|--------------|----------|-------------|
| Library | 🟡 | ⛔ | ⛔ | ⛔ |
| Song detail | 🟡 | ⛔ | ⛔ | ⛔ |
| Full player | 🟡 | ⛔ | ⛔ | ⛔ |
| Project detail | 🟡 | ⛔ | ⛔ | ⛔ |
| Settings | 🟡 | ⛔ | ⛔ | ⛔ |

(⛔ here = not yet manually audited, not necessarily failing.)

## Verification

- Target release: v1.0
- Last verified: 2026-06-16 (engineering pass only; **no manual VoiceOver audit
  or device run yet**)
- Primary code paths: `A11yID`, view modifiers across `Sources/Views` &
  `Sources/Components`, `RootView` (Reduce Motion / appearance).

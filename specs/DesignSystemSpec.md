# Design System Spec

MixStack visual identity: **studio archive** — warm parchment (light) and near-black
(dark) with violet accent. Matches the family feel of MiniMuster (material cards,
serif display) while keeping a distinct producer accent.

## Tokens

| Token | Light | Dark | Use |
|-------|-------|------|-----|
| `Brand.background` | warm parchment | `#0B0C0F` | Root background |
| `Brand.surface` | `#FFFDF8` | `#15171E` | Cards, tiles |
| `Brand.textPrimary` | near-black ink | warm white | Titles, body |
| `Brand.accent` | `#7C3AED` | same | Chrome, highlights |
| `Brand.destructive` | blood red | darker red | Delete actions |

Implementation: `Sources/DesignSystem/Tokens/BrandTheme.swift`

## Typography

- **Display / stats:** `.system(_, design: .serif)` via `DS.Typography`
- **Lists / forms:** system default (Dynamic Type)

## Chrome modifiers

| Modifier | Screens |
|----------|---------|
| `.brandTabChrome()` | `RootView` |
| `.brandHeroBackground()` | Onboarding, future splash |
| `.brandFormChrome()` | Settings |

## Components

| Component | Use |
|-----------|-----|
| `StatTile` | Library summary grid |
| `StateChip` | Tags, format badges |

## Separation from Brand Kit

App **theme** (light/dark) stays in `AppAppearance`. **Brand Kit** accent
(planned) affects share/export surfaces only — not tab chrome.

## Verification

- WCAG contrast tests: `Tests/Accessibility/WCAGContrastTests.swift`
- Last verified: 2026-06-16

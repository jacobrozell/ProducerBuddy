# MixStack Design System

Layered tokens matching the MiniMuster / Dart Buddy pattern: **Brand** for product chrome, **DS** for layout rhythm.

| Symbol | File | When to use |
|--------|------|-------------|
| `Brand.*` | `Tokens/BrandTheme.swift` | Backgrounds, text, accent, destructive |
| `DS.Spacing` / `DS.Radius` | `Tokens/DesignTokens.swift` | Padding, corner radius |
| `DS.Typography` | `Tokens/DesignTokens.swift` | Serif display + stat values |
| `.brandTabChrome()` | `Tokens/BrandChrome.swift` | Root tab shell |
| `.brandHeroBackground()` | `Tokens/BrandChrome.swift` | Onboarding, splash |
| `.brandFormChrome()` | `Tokens/BrandChrome.swift` | Settings forms |
| `AdaptiveLayout` | `AdaptiveLayout.swift` | Landscape + Dynamic Type helpers |
| `minimumTapTarget()` | `AdaptiveLayout.swift` | 44×44 pt controls |
| `StatTile` | `Components/StatTile.swift` | Library / project stat grids |
| `StateChip` | `Components/StateChip.swift` | Tags and filter pills |

**Rules**

- Use system semantic fonts for dense lists (song rows, forms).
- Use serif display for screen titles and stat values only.
- Brand accent (`#7C3AED`) is for chrome and highlights — share-card accent stays in Brand Kit (planned).
- Prefer material-backed cards over flat list rows for summary headers.

Spec: `specs/DesignSystemSpec.md`

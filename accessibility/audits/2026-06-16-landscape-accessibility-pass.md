# Landscape + accessibility pass — 2026-06-16

Engineering review (simulator + code audit). Not a full VoiceOver device sign-off.

## Landscape fixes

| Screen | Issue | Fix |
|--------|-------|-----|
| Full player | Artwork consumed vertical space; controls clipped | Side-by-side layout when `verticalSizeClass == .compact`; ScrollView |
| Onboarding | Hero + text clipped in landscape | ScrollView pages, smaller hero, hide page dots |
| Energy chart | Fixed 160pt height crowded toolbar | 120pt in compact height |
| Now playing bar | Cramped row in landscape | Tighter padding; track opens full player via button |

## Accessibility fixes

| Area | Issue | Fix |
|------|-------|-----|
| Star rating | ~22pt tap targets, no VoiceOver value | 44pt `Button` stars; combined label + value |
| Transport controls | Icon-only targets below 44pt | `minimumTapTarget()` on player + mini bar |
| Now playing bar | Relied on tap gesture; time hidden from VO | Button opens player; progress + time in label |
| Sort / new project | Missing labels | "Sort", "New project" |
| Energy chart | Chart invisible to VoiceOver | Summary accessibility label |
| Import progress | Progress not announced | Combined label with counts |
| Mix chips | Selected state not exposed | `.isSelected` trait |
| Loop toggle | No explicit value | Label + on/off value |
| Decorative art | Song/project headers read as empty groups | `accessibilityHidden` on artwork |

## Remaining gaps

- Manual VoiceOver walkthrough on device (Library filters sheet, drag reorder)
- AXXXL Dynamic Type on Song detail metadata rows
- iPad split-view library + projects ✅ (`MixStackUIPad` scheme)
- Contrast audit on category tint gradients

## Verification

- `swiftlint --strict` ✅
- 98 unit tests ✅ including `PersistenceIntegrationTests`, `AdaptiveLayoutTests`
- 10 UI tests ✅ (split schemes: smoke, landscape, accessibility, iPad)

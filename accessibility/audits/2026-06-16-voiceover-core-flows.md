# VoiceOver core flows — 2026-06-16

Engineering audit (simulator + automated WCAG UI tests + code review).
**Not a physical-device VoiceOver sign-off** — see manual checklist below.

## Scope

| Flow | Screens |
|------|---------|
| Library | Home list, stats header, filters sheet, import |
| Song | Detail, version stack, star rating, share |
| Player | Now playing bar, full player, waveform scrub |
| Projects | List, detail, running order |
| Settings | Appearance, links, done dismiss |

## Device matrix

| Device | iOS | Text size | Status |
|--------|-----|-----------|--------|
| iPhone 17 Simulator | 26.5 | Default | Automated WCAG audits ✅ |
| iPhone (physical) | — | Default + AXXXL | ⛔ Manual pending |
| iPad (A16) Simulator | 26.5 | Default | Split navigation smoke ✅ |

## Automated coverage

`MixStackUIAccessibility` scheme runs `performAccessibilityAudit` on:

- Library (name/role/value + hit regions)
- Song detail (after navigation)
- Projects tab
- Settings sheet

Unit tests cover token contrast (`WCAGContrastTests`) and stable identifiers
(`AccessibilityIdentifierContractTests`).

## Code-reviewed VoiceOver behaviors

| Control | Expected spoken output | Verified |
|---------|------------------------|----------|
| Star rating | "Rating, X of 5 stars" + adjustable | Code ✅ |
| Now playing bar | Track title, play/pause, progress | Code ✅ |
| Waveform scrub | Adjustable position | Code ✅ |
| Loop toggle | Label + on/off value | Code ✅ |
| Mix version chips | Selected trait when active | Code ✅ |
| Energy chart | Summary label (not raw bars) | Code ✅ |
| Settings gear | "Settings" | Audit ✅ |
| iPad sidebar tabs | Library / Projects buttons | UI test ✅ |

## Findings

### Blockers

None identified in automated or code review pass.

### Majors (manual follow-up)

| ID | Screen | Issue | Repro |
|----|--------|-------|-------|
| VO-M1 | Library filters | BPM slider + key chips not manually walked | Open filters sheet with VoiceOver |
| VO-M2 | Project detail | Drag reorder running order | Long-press reorder with VoiceOver |
| VO-M3 | Full player | Waveform scrub at AXXXL | Enable largest text size, open player |

### Minors

| ID | Screen | Issue |
|----|--------|-------|
| VO-m1 | Song detail | Category tint badges — confirm contrast + label at AXXXL |
| VO-m2 | Onboarding | Page dots hidden in landscape — verify page position is announced |
| VO-m3 | Import resolution | Multi-item sheet — confirm focus order |

## Pass / fail

| Gate | Decision |
|------|----------|
| Automated WCAG UI (core tabs) | **Pass** |
| Physical VoiceOver walkthrough | **Pending** — ship requires VO-M1–M3 on device |
| Dynamic Type AXXXL | **Pending** — manual |

## Next audit

After physical device pass, update this file with device model, iOS build,
tester name, and close VO-M* items or file fixes.

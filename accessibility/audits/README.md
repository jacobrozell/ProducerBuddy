# Accessibility audits

Dated VoiceOver and manual WCAG evidence for MixStack core flows.

## Template

Create `YYYY-MM-DD-voiceover-<scope>.md` with:

1. **Scope** — screens exercised (Library, Song detail, Player, Settings, …)
2. **Device** — simulator or physical device, iOS version, text size
3. **Findings** — blockers, majors, minors (with repro steps)
4. **Pass/fail** — ship gate decision

## Planned audits

| Date | Scope | Status |
|------|-------|--------|
| 2026-06-16 | Core flows (Library, Song, Player, Projects, Settings) | 🟡 automated + code review — [report](2026-06-16-voiceover-core-flows.md) |
| TBD | Physical device VoiceOver sign-off (VO-M1–M3) | ⛔ |
| TBD | Project detail drag reorder | ⛔ |

Spec: `specs/Accessibility.md`

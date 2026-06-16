# Specs

Authoritative descriptions of system behavior. Source-of-truth hierarchy:

```
governance (this file) → system specs → feature behavior
        → docs/feature-inventory.md (what ships today)
        → ROADMAP.md (maybe / future)
```

When a spec and the code disagree, the spec wins for *intended* behavior and the
inventory wins for *current* behavior — fix whichever is wrong and note it.

## System specs

- [Architecture](Architecture.md) — layers, dependency rules, module map.
- [Accessibility](Accessibility.md) — release-gate requirements and screen tracker.

## Conventions

- Each feature/system spec should end with a **Verification** block: target
  release, last-verified date, commit, and primary code paths.
- New user-visible strings land in every bundled locale at once (currently `en`
  only; see ROADMAP §Localization).

# Brand Kit Spec

Let producers set **accent color, display name, and optional logo** once so every
release card, share blurb header, and future audiogram inherits a consistent
look — the difference between a screenshot and a *brand*.

---

## Goals

| Goal | Success looks like |
|------|-------------------|
| Consistent social posts | Every Share Card uses my purple accent and artist name |
| Low setup cost | Defaults work out of the box; customization is optional |
| Portable identity | Brand settings survive backup/sync (see `CatalogSync.md`) |

## Non-goals

- Full design tool (layouts are app-defined templates).
- Multiple brand profiles / imprints (one kit per install in v1).
- Font picker beyond system semantic styles (custom fonts are licensing pain).

---

## User stories

1. **Instagram producer** — I set accent to match my FL project color (#9B59B6),
   upload a PNG logo, and every story-format card looks like my feed.
2. **Alias artist** — Display name "DJ NightShift" overrides song artist on cards
   when I want a unified credit line.
3. **Reset** — "Restore defaults" clears logo and accent without touching songs.

---

## Data model

### `BrandKit` (SwiftData `@Model` singleton or `AppSettings` embed)

| Field | Type | Notes |
|-------|------|-------|
| `accentColorHex` | `String` | `#RRGGBB`; default app accent |
| `displayName` | `String` | Shown on cards; default "" → use song/project title only |
| `tagline` | `String` | Optional footer, e.g. "New music every Friday" |
| `logoFilename` | `String?` | Relative path under Documents/Brand/ |
| `cardStyle` | `String` | `minimal` \| `gradient` \| `bold` (template enum) |

Logo: max 512×512 PNG/JPEG; stored via `BrandStorage` (mirror `AudioStorage`).

---

## UI surfaces

### Settings — **Brand Kit** section

- Color picker (sRGB hex)
- Text: Display name, Tagline
- Logo: pick image, preview, remove
- Style: segmented control with live mini preview
- Restore defaults

### Share Card flow

- `ShareCardView` / `ReleaseCardRenderer` read `BrandKit` for:
  - Gradient stops derived from accent
  - Logo top-left or centered watermark (style-dependent)
  - Footer tagline
- Song card: title + BPM/key; artist line uses `displayName` when set, else
  `song.artist`, else omit

### Onboarding (stretch)

- Optional "Set your artist name" step feeding `displayName`.

---

## Integration

| Location | Change |
|----------|--------|
| `BrandKit` model + `BrandStorage` | New |
| `SettingsView` | Brand Kit section |
| `ShareCardView`, `ReleaseCardRenderer` | Inject brand tokens |
| `AppAppearance` | Document relationship (theme vs brand accent) |

**Separation:** App **theme** (light/dark) stays in `AppAppearance`; **brand
accent** only affects exported/sharing surfaces, not tab bar chrome — avoids
jarring UI recolors.

---

## Accessibility

- Color picker has text label; contrast of card text verified against accent in
  each `cardStyle` (minimum 4.5:1 for body text).

---

## Verification

- Target release: with Share Card v2 polish (after basic card ships ✅)
- Last verified: 2026-06-16 (spec only; **not implemented**)
- Primary code paths: `SettingsView`, `ShareCardView`, `ReleaseCardRenderer`

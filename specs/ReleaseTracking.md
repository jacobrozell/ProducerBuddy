# Release Tracking Spec

Help hobbyist producers close the loop between **finished master** and **live on
streaming** — track release dates, distributor status, and links without
replacing DistroKid, TuneCore, or Spotify for Artists.

---

## Goals

| Goal | Success looks like |
|------|-------------------|
| Remember what's live | A beat marked **Released** has a date and at least one streaming link |
| Reduce "did I upload this?" anxiety | Project detail shows release readiness per track |
| Share with fans | Copy or open Spotify/Apple Music links from song detail |
| Stay lightweight | No API keys, no distributor login — manual fields the user controls |

## Non-goals

- **Submitting to distributors** or uploading audio from the app.
- **Royalty accounting**, split sheets, or contract management.
- **Scraping** Spotify/Apple for auto-link discovery (paste links manually).
- **Replacing** a spreadsheet for a label-scale catalog.

---

## User stories

1. **Weekend releaser** — I mastered three beats Sunday; I mark each **Ready to
   Mix → Mastered**, then after DistroKid goes through I set **Released**, paste
   the Spotify URL, and pick a release date.
2. **EP builder** — On my project screen I see which tracks are still WIP vs.
   released before I share the project card.
3. **Fan reply** — Someone asks for the link; I open song detail and tap **Copy
   Spotify link** without digging through email.
4. **Remix catalog** — I note "Remix of Artist X" in release notes and keep my
   original upload date separate from the remix drop.

---

## Data model

### `ReleaseInfo` (embedded on `Song`, not a separate entity)

| Field | Type | Notes |
|-------|------|-------|
| `releaseDate` | `Date?` | Calendar date the track went/will go live |
| `distributor` | `String` | Free text or picker preset: DistroKid, TuneCore, Amuse, CD Baby, Other, "" |
| `spotifyURL` | `String` | Validated `https://` URL when non-empty |
| `appleMusicURL` | `String` | Same |
| `soundcloudURL` | `String` | Optional; common for beatmakers |
| `releaseNotes` | `String` | Credits, featured artists, "type beat" lease terms, ISRC if user has it |

`Song.category == .released` should **nudge** (not force) filling `releaseDate`;
show a subtle "Add release info" banner when category is released but date is nil.

### `Project` extension (computed, no new stored fields)

- `releasedTrackCount` / `totalTrackCount`
- `isFullyReleased` — all tracks `.released` with `releaseDate != nil`
- Surface on project detail header: **"3/5 released"** with tap to filter running
  order by unreleased first (UI only).

### Validation

- URLs: trim whitespace; reject non-`http(s)` schemes on save.
- `releaseDate` in the future is allowed (scheduled drop).
- Clearing category from `.released` does **not** wipe release fields (user may
  demote for a re-release workflow).

---

## UI surfaces

### Song editor — **Release** section (below Musical)

- Date picker: **Release date** (optional)
- Picker: **Distributor** (presets + Other → text field)
- Text fields: Spotify, Apple Music, SoundCloud (with link icons)
- Multiline: **Release notes** (ISRC, credits, lease info)

### Song detail — **Release** card (when any release field set OR category `.released`)

- Formatted date, distributor badge
- Tappable link rows (open in Safari)
- **Copy link** swipe or context menu per URL
- Empty state CTA: *"Track is live? Add your streaming links."*

### Library

- Optional filter chip: **Released** (uses `category == .released`; future:
  "Has streaming link")
- Sort option: **Release date** (newest first; unreleased at bottom)

### Project detail

- Header pill: `3/5 released`
- Row subtitle on `TrackFlowRow` when track is unreleased in an otherwise
  "finished" project: small category badge

### Share card (stretch)

- When `releaseDate` set, show formatted date on project card.
- Single song card: optional "Out now" + Spotify QR (post-v1).

---

## Integration points

| Location | Change |
|----------|--------|
| `Song` | New release fields |
| `SongEditorView` | Release section |
| `SongDetailView` | Release card + copy actions |
| `LibraryView` | Sort by release date |
| `ProjectDetailView` | Released count header |
| `ShareCardView` | Optional date line |
| `A11yID` | `song.releaseLinks`, `project.releaseProgress` |

---

## Accessibility

| # | Requirement |
|---|-------------|
| R1 | Link rows: `accessibilityLabel` "Open on Spotify" + hint "Opens in browser" |
| R2 | Copy actions announce "Copied Spotify link" |
| R3 | Release progress "3 of 5 tracks released" as full phrase |

---

## Testing

- Unit: URL validation helper
- Model: `Project.releasedTrackCount` with mixed categories
- Manual: set released + links → share sheet text includes Spotify URL (existing
  blurb export)

---

## Verification

- Target release: shipped
- Last verified: 2026-06-17 (**implemented**)
- Primary code paths: `Song`, `SongEditorView`, `SongDetailView`, `ProjectDetailView`, `ReleaseInfoCard`
- Tests: `ReleaseTrackingTests.swift`

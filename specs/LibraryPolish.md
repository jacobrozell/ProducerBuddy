# Library Polish Spec

Bundle of **high-leverage UX fixes** on the Library and list rows — the screens
a producer opens ten times a day between FL Studio exports.

Most items are small; ship together as one polish release.

---

## Goals

| Goal | Success looks like |
|------|-------------------|
| Find tracks like a producer | Filter by BPM range, key, vocals — not just substring search |
| Faster common actions | Swipe to favorite or add to project |
| Safer catalog | Confirm before deleting songs and projects |
| Scannable lists | Section headers when sorted by BPM or rating |

## Non-goals

- Smart playlists or rule engine.
- Folder hierarchy mirroring FL project tree.
- Full-text search in notes (stretch).

---

## Features

### 1. BPM range filter

- UI: dual-thumb slider or min/max steppers in filter sheet
- Range: 60–200 BPM (clamp song values)
- Combine with existing category + vocal filters (AND logic)
- Persist last range in `@AppStorage` optional

### 2. Key filter

- Chip grid: Camelot codes or letter keys (user setting)
- Multi-select; empty = all keys
- "Compatible with current song" quick filter when navigating from detail (stretch)

### 3. Vocal filter

- Per `VocalDetection.md`: All · With vocals · Instrumental · Uncertain
- Ship in same PR as vocal detection or stub chips disabled until then

### 4. Section headers

When sort = **BPM** or **Rating**:

| Sort | Sections |
|------|----------|
| BPM | 60–90 · 90–110 · 110–128 · 128–150 · 150+ |
| Rating | 5★ · 4★ · … · Unrated |

Use `Section` in `List` with sticky headers.

### 5. Swipe actions

| Edge | Action | Behavior |
|------|--------|----------|
| Leading | Favorite | Toggle `isFavorite`; haptic |
| Trailing | Add to Project… | Sheet: pick project or create new |
| Trailing (destructive) | Delete | Confirmation dialog |

Project list: swipe delete with confirmation only.

### 6. Delete confirmation

**Song delete:**

> Delete "Track Name"? This removes N mix(es) and audio files from this device.
> This can't be undone.

**Project delete:**

> Delete "EP Name"? Songs stay in your library; only the project and order are
> removed.

### 7. Import progress

When batch importing (existing `SongImportService`):

- Inline banner: "Importing 3 of 7…" with cancel
- Per-file failure toast with filename

### 8. Search scope

Extend search to: title, artist, genre, notes (case-insensitive contains).

---

## UI layout

Filter bar evolution:

```
[Category chips …]  [Filters ▾]  [Sort ▾]
```

**Filters** sheet: BPM range, Key, Vocals, Favorites only toggle.

---

## Accessibility

- Swipe actions expose standard VoiceOver actions
- Filter sheet: each control labeled; state announced on apply
- Section headers are headings

---

## Integration

| Location | Change |
|----------|--------|
| `LibraryView` | Filters, sections, swipes, search |
| `SongRow` | Swipe actions |
| `ProjectListView` | Delete confirm |
| `SongImportService` | Progress callback |
| `VocalLibraryFilter` | Enum (may exist) |
| `A11yID` | Filter and swipe IDs |

---

## Testing

- Unit: filter predicate composes correctly (BPM + category + vocal)
- Unit: section bucket for BPM 124 → 110–128
- UI test (stretch): swipe favorite toggles state

---

## Verification

- Target release: next polish sprint (before release tracking)
- Last verified: 2026-06-17 (implemented)
- Primary code paths: `LibraryView`, `LibraryFiltersSheet`, `LibraryFilterLogic`,
  `AddToProjectSheet`, `ProjectListView`, `SongImportService`, `AudioImporter`

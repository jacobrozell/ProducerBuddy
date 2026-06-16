# Sharing (shipped)

Text blurbs and rendered PNG release cards.

## Text share

`ShareLink` in detail menus.

**Song** (`SongDetailView.shareText`):

```
🎵 {title} · by {artist} · {bpm} BPM · {genre}
Made with ProducerBuddy
```

**Project** (`ProjectDetailView.tracklistText`):

```
{title} — {kind}
1. Track…
Made with ProducerBuddy
```

## Visual share cards

Gated: `ReleaseSurface.shareCards`.

### Flow

```
ShareCardSheet → ShareCardView (preview)
              → ReleaseCardRenderer.renderPNG → temp .png
              → ShareLink
```

### CardFormat

| Format | Points | Pixels @3× |
|--------|--------|------------|
| square | 340×340 | 1020×1020 |
| story | 340×604 | 1020×1812 |

### ShareCardView (`Sources/Components/ShareCardView.swift`)

Fixed frame `format.size`. Gradient from `song.category.tint` or accent.

- **Song:** title, artist, BPM/key/genre pills
- **Project:** title, subtitle, tracklist (5 square / 12 story), "+ N more"

### ShareCardSheet

Segmented format picker. `.task(id: format)` re-renders PNG.

### ReleaseCardRenderer

`ImageRenderer` at scale 3 → `uiImage.pngData()` → temp dir atomic write.

## Verification

- Last verified: 2026-06-16
- Code: `ShareCardView`, `ShareCardSheet`, `ReleaseCardRenderer`
- Tests: `ShareCardTests.swift`

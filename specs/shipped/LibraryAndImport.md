# Library & Import (shipped)

Catalog list and audio ingestion.

## LibraryView (`Sources/Views/LibraryView.swift`)

`@Query` all songs → filter → sort → `List` of `SongRow` → `SongDetailView`.

### Filters (order matters)

1. **Category chip** — optional `SongCategory`; tap again clears
2. **Vocal filter** — `VocalLibraryFilter` menu chip (see [VocalDetection](../VocalDetection.md))
3. **Search** — substring on title, artist, genre

### Sort (`LibrarySort`)

| Mode | Comparator |
|------|------------|
| Recently Added | `dateAdded` desc |
| Title | case-insensitive asc |
| BPM | asc |
| Rating | desc |

### Toolbar

- **Import Audio…** — `songImporter` (multi-select)
- **New Song** — `SongEditorView(song: nil)` sheet

### Delete

`onDelete` → delete each mix's file via `AudioStorage.deleteFile`, then
`modelContext.delete(song)`.

### Import banner

`lastImportCount` shows green capsule 2s after import.

## Import-first flow (multi-file)

```
SongImporter → AudioStorage.importAudio (per file) → SongImportService.importSongs
```

### AudioStorage (`Sources/Services/AudioStorage.swift`)

- `audioDirectory` = `Documents/Audio/` (created lazily)
- `importFile(from:)` — copy with UUID filename; security-scoped access
- `importAudio(from:)` — copy + `AVURLAsset` duration + `commonMetadata`
  title/artist → `ImportedAudio`
- `suggestedTitle` = tag title → filename → "Untitled"

### SongImportService (`Sources/Services/SongImportService.swift`)

Per `ImportedAudio`:

1. Insert `Song(title: suggestedTitle, artist:)`
2. Insert primary `Mix(name: "Original", isPrimary: true)`
3. `context.save()`
4. `scheduleMetadataDetection` → `AudioAnalyzer.analyze` → song fields
5. `scheduleWaveformGeneration` → `WaveformGenerator.generate` → `mix.waveform`

Uses `PersistentIdentifier` for background tasks after save.

## Single-file import (add mix)

`AudioImporter` modifier — one file, returns `(fileName, duration)`. Used from
`SongDetailView` only. See [SongsAndMixes](SongsAndMixes.md).

## Manual create

`SongEditorView(song: nil)` — no audio until mix import on detail screen.

## UI components

- `SongRow` — play primary mix, vocal icon, rating, mix count
- `FilterChip` — category pills (private in LibraryView)

## Verification

- Last verified: 2026-06-16
- Code: `LibraryView`, `SongRow`, `AudioImporter`, `AudioStorage`, `SongImportService`, `VocalLibraryFilter`
- Tests: `SongImportServiceTests.swift`

# Catalog Sync & Backup Spec

Make the catalog **trustworthy long-term** — survive device loss, sync iPhone ↔
iPad, and export a portable bundle before iCloud lands or for manual backup.

---

## Goals

| Goal | Success looks like |
|------|-------------------|
| No catalog hostage | Export everything to a zip I can stash in iCloud Drive |
| Multi-device | Same library on phone and iPad without manual re-import |
| FL export safety | Audio files + metadata stay together |

## Non-goals

- Collaborative/shared libraries.
- Version history / time machine per song.
- Syncing with FL Studio project files (`.flp`).

---

## Phased delivery

### Phase 1: Portable export / import

**Export bundle** (`.producerbuddy` zip):

```
manifest.json          // schema version, export date, counts
songs.json             // SwiftData snapshot (songs, mixes metadata, projects)
audio/                 // all mix files keyed by relative filename
brand/                 // logo if Brand Kit shipped
```

- Settings → **Export Catalog…** → share sheet
- **Import Catalog…** → merge or replace dialog:
  - **Merge:** skip songs with same `id`; optional rename on title collision
  - **Replace:** wipe local store first (double confirm)

`SongImportService` patterns reused for audio copy.

### Phase 2: iCloud sync

- SwiftData + CloudKit container (`NSPersistentCloudKitContainer` pattern)
- Audio via **iCloud Documents** (`Documents/Audio` ubiquity)
- Conflict: last-writer-wins on metadata; audio conflict = keep both with suffix
  (rare)

### Phase 3: Files app awareness

- Document browser for `Documents/Inbox/` — files AirDropped or saved from Files
  appear as import candidates on Library
- Open-in-Place: accept `.mp3`, `.wav`, `.m4a`, `.aiff` via document types

---

## User stories

1. **New phone** — Export on old device, AirDrop zip, import on new — library
   restored with waveforms regenerated in background.
2. **iPad sequencing** — Edit project order on iPad; picks up on phone after sync.
3. **Backup habit** — Monthly export to Files / Dropbox folder.

---

## manifest.json schema

```json
{
  "schemaVersion": 1,
  "appVersion": "1.2.0",
  "exportedAt": "2026-06-16T12:00:00Z",
  "songCount": 42,
  "projectCount": 3
}
```

Version migrations documented in `Architecture.md` when schema versioning ships.

---

## Security & privacy

- No cloud account in app beyond user's iCloud
- Export zip unencrypted (user's responsibility); optional password zip stretch

---

## UI

### Settings — **Data**

- Export Catalog
- Import Catalog
- (Phase 2) iCloud Sync toggle + status: Synced / Uploading / Error
- Link to existing Delete All Data (destructive, separate)

---

## Testing

- Round-trip: export 3 songs → import on fresh container → counts match
- Merge: duplicate `id` skipped; new songs appended
- Large catalog: 50 tracks export without memory spike (stream zip)

---

## Verification

- Target release: Phase 1 shipped; Phase 2 (iCloud) planned
- Last verified: 2026-06-17 (**Phase 1 implemented** — ZIP export/import)
- Primary code paths: `CatalogExporter`, `CatalogImporter`, `SettingsCatalogSection`, `ZipArchive`
- Tests: `CatalogSyncTests.swift`

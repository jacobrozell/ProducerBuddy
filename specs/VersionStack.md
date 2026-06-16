# Version Stack Spec

**One song, many renders** — rough mix, master v3, tagged beat, stripped
arrangement — without turning every FL export into a duplicate library row.

Today `Song` + `Mix` already support multiple versions, but the UX treats them
as an afterthought (`Mix 2`, flat list, import always creates a new song). This
spec makes **version management** a first-class producer workflow and automates
the boring parts: naming, matching imports, and picking the best render.

---

## Goals

| Goal | Success looks like |
|------|-------------------|
| Stop duplicate songs | Re-exporting `NightDrive_v2_master.mp3` lands on the *same* song, not song #4 |
| Prefix-driven imports | Files matching a song's **export prefix** auto-attach as new versions — zero taps when naming is consistent |
| Readable version history | I see Rough → Demo → Master v2 in order, not "Original" and "Mix 3" |
| Fast A/B decisions | Compare two renders side-by-side; promote winner to primary in one tap |
| Arrangements stay organized | Slowed edit and full arrangement live under one idea *or* linked siblings — my choice |
| FL-native | Filename patterns (`Project_7`, `_final`, `_tagged`) drive labels without typing |

## Non-goals

- **DAW project files** (`.flp`) or stem lanes inside the app.
- **Automatic audio diffing** ("what changed between v2 and v3") — metadata + waveform shape only.
- **Git-style branching** with merge commits — linear version stack is enough for v1.
- **Cloud collaboration** on versions.

---

## Producer mental model

```
Song  = the beat / idea  (title, nominal BPM & key, workflow category)
Mix   = one exported render  (rough, master, tagged, arrangement, …)
```

| FL Studio habit | Maps to |
|-----------------|---------|
| Same project, new export | **New mix** on existing song |
| Renamed project / different idea | **New song** |
| Tagged + untagged pair | Two **mixes** with roles `tagged` / `instrumental` |
| Slowed & reverb "arrangement" | **Mix** with role `arrangement` *or* linked **sibling song** (user picks at import) |
| `Project_5.mp3` … `Project_5 master.wav` | Same song; matched by **export prefix** or normalized title |
| User sets prefix `NightDrive_` on a song | Any import `NightDrive_*.mp3` → new mix on that song |

**Primary mix** = the render the app uses for library play, project playback,
share cards, and metadata detection unless the user picks another.

---

## User stories

1. **Saturday export dump** — I drop 8 files from FL's render folder; the app
   groups 3 onto existing songs as new versions and creates 5 new songs. I confirm
   the 2 uncertain matches in one sheet.
2. **Master pick** — I A/B master v1 and v2 in the full player, tap **Set as
   Primary**, and my project queue uses v2 tonight.
3. **Tagged beat pack** — Instrumental and tagged versions sit under one song with
   clear role badges; Spotify upload uses the primary (tagged) mix.
4. **Arrangement fork** — My "slowed" export is related but different enough; I
   choose **New song (linked)** so it has its own BPM/key but stays connected in
   detail view.
5. **Cleanup** — I accidentally imported the same beat twice as two songs; **Merge
   into…** moves all mixes onto one song and deletes the empty duplicate.
6. **Prefix workflow** — I set export prefix `NightDrive_` on my beat once. Every
   Saturday I drop `NightDrive_rough.mp3`, `NightDrive_master_v3.wav` into the
   library; they stack on the same song without a confirmation sheet.
7. **Prefix override** — `NightDrive_slowed.mp3` matches prefix but I want a
   separate arrangement song; import sheet offers **New linked song** in one tap.

---

## Data model

### `MixRole` (new enum)

| Case | Display | Typical filename hints |
|------|---------|------------------------|
| `original` | Original | (first import), `original` |
| `rough` | Rough | `rough`, `demo`, `wip`, `bounce` |
| `arrangement` | Arrangement | `slowed`, `sped`, `reverb`, `acoustic`, `remix` |
| `instrumental` | Instrumental | `inst`, `instrumental`, `no tag` |
| `tagged` | Tagged | `tagged`, `tag`, `with tag` |
| `master` | Master | `master`, `final`, `mastered`, `mstr` |
| `reference` | Reference | `ref`, `reference` |
| `other` | Other | fallback |

Stored on `Mix` as `roleRaw: String` (default `original`).

### New `Mix` fields

| Field | Type | Notes |
|-------|------|-------|
| `roleRaw` | `String` | `MixRole` |
| `sourceFileName` | `String?` | Original picker filename, e.g. `NightDrive_v2_master.mp3` |
| `versionLabel` | `String?` | Parsed token: `v2`, `v3` — shown in stack UI |
| `sortOrder` | `Int` | User drag order in version stack; default `dateAdded` ordinal |

**Display name** (computed, not stored separately unless user overrides):

```
displayName = userName ?? "\(role.displayName)\(versionLabel.map { " \($0)" } ?? "")"
```

Keep existing `name` as user-editable override; when empty, use computed display.

### `Song` fields — matching & prefix

| Field | Type | Notes |
|-------|------|-------|
| `exportPrefix` | `String?` | User-defined; files whose **basename** matches attach here as mixes |
| `exportPrefixIsManual` | `Bool` | `true` after user edits prefix; blocks silent auto-overwrite |
| `normalizedTitle` | `String` | Lowercased, stripped of version suffixes — fallback matching |
| `linkedSongIDs` | `[UUID]` | Sibling arrangements (v1.1) |

`normalizedTitle` recomputed when `title` changes. `exportPrefix` suggested when
nil (see [Export prefix](#export-prefix)).

### Export prefix

The **highest-confidence** signal for "this file belongs to this song." Optional
per song; when set, imports matching the prefix are treated as **new iterations**
(mixes), not new catalog entries.

#### Semantics

| Rule | Detail |
|------|--------|
| **Match target** | Original picker filename **without extension** (basename) |
| **Match mode** | Case-insensitive **prefix** on basename: `NightDrive_master.mp3` matches prefix `NightDrive_` |
| **Delimiter** | Prefix should include trailing `_` or `-` when the beat name is a token: `NightDrive_` not `NightDrive` (see validation) |
| **Uniqueness** | At most one song may claim a given prefix (case-insensitive) in the library |
| **Empty / nil** | No prefix rule; fall back to fuzzy title matching only |

#### Auto-suggestion (`ExportPrefixSuggester`)

When a song is created and `exportPrefix` is nil:

1. Derive from `title`: remove spaces/punctuation → `Night Drive` → `NightDrive_`
2. If first import basename shares a clear stem, prefer that stem + `_`
3. Show suggestion in editor; user confirms or edits before relying on it

Do **not** auto-set `exportPrefix` silently on first import unless user has
**Auto-suggest export prefix** enabled (default **on**) **and** they accept or
save without clearing the field.

#### Validation (`ExportPrefixValidator`)

| Check | Behavior |
|-------|----------|
| Min length | ≥ 3 characters (after trim) |
| Charset | Letters, numbers, `_`, `-` only |
| Trailing delimiter | Warn if no `_` or `-` suffix — "Add `_` so `Night` doesn't match `Nightmare`" |
| Reserved / weak | Block `beat`, `project`, `track`, `mix`, `song` alone (case-insensitive) |
| Collision | Another song already uses prefix → save blocked with link to conflicting song |
| Global list (stretch) | Settings may list "ignored" prefixes that never auto-match |

#### Scoring integration

Prefix match is **necessary for auto-add without confirmation** when combined
with setting **Auto-add on prefix match** (default **on**). See scoring table
in [Import matcher](#2-match-candidates-importmatcher).

| Outcome | Condition |
|---------|-----------|
| **Silent add as mix** | Prefix match **and** `confidence >= 0.85` **and** auto-add on |
| **Resolution sheet** | Prefix match but confidence 0.55…0.84, or ambiguous multi-song, or user disabled auto-add |
| **New song** | No prefix match and fuzzy score `< 0.55` |

**Ambiguous prefix:** two songs share overlapping prefixes (should be blocked at
save) — if data predates validation, show resolution sheet listing both.

#### Prefix learning (iteration — post-v1)

When user corrects an import ("add to X" vs "new song"), optionally offer:

> **Remember:** files starting with `NightDrive_` → *Night Drive*

Sets `exportPrefix` on chosen song if unset. Gated behind explicit tap — no
silent learning in v1.

**Linked arrangements (v1.1):** `linkedSongIDs: [UUID]` — bidirectional sibling
links for forks chosen at import (**New linked song**).

### Import fingerprint (matching only, not shown)

```swift
struct ImportFingerprint: Sendable, Equatable {
    let sourceBasename: String       // "NightDrive_v2_master"
    let normalizedTitle: String
    let durationSeconds: Int         // rounded
    let bpmEstimate: Int?
}
```

---

## Automation — import intelligence

New service: `VersionImportService` in `Sources/Services/`.

### 1. Filename parsing (`MixNamingParser`)

Input: `NightDrive_v2_master.mp3`

| Output | Example |
|--------|---------|
| `baseTitle` | `NightDrive` |
| `versionLabel` | `v2` |
| `suggestedRole` | `.master` |
| `normalizedTitle` | `nightdrive` |

**Rules** (applied in order, case-insensitive):

1. Strip extension
2. Remove FL patterns: `^Project[_\s-]?(\d+)$` → title `Project 7`, no version label
3. Strip trailing version tokens: `_v\d+`, `-v\d+`, ` v\d+`, `_\d+$` (when not sole title)
4. Strip role tokens from suffix list: `master`, `final`, `mastered`, `rough`, `demo`,
   `wip`, `bounce`, `tagged`, `tag`, `inst`, `instrumental`, `slowed`, `sped`, …
5. Collapse `_`, `-`, multiple spaces
6. Remaining string → `baseTitle`; stripped tokens → role + version label

Unit-tested with a table of real producer filenames (see Testing).

### 2. Match candidates (`ImportMatcher`)

When each file finishes `AudioStorage.importAudio`, before creating a song:

```swift
struct ImportMatchCandidate: Identifiable {
    let song: Song
    let confidence: Double   // 0…1, capped at 1.0
    let reason: String       // "Export prefix", "Same title · same length"
    let matchKind: ImportMatchKind  // .exportPrefix, .title, .fuzzyTitle, …
}

enum ImportMatchKind: String {
    case exportPrefix
    case normalizedTitle
    case fuzzyTitle
    case durationBPM  // corroboration only, not sole signal
}

static func findMatches(
    fingerprint: ImportFingerprint,
    in songs: [Song]
) -> [ImportMatchCandidate]

static func prefixMatch(
    basename: String,
    prefix: String
) -> Bool  // case-insensitive hasPrefix
```

**Scoring** (additive, cap 1.0):

| Signal | Weight | Notes |
|--------|--------|-------|
| **Export prefix match** | **+0.70** | `song.exportPrefix` non-nil and basename matches |
| `normalizedTitle` exact (parser stem) | +0.40 | Stacks with prefix if both fire |
| `normalizedTitle` Levenshtein ≤ 2 | +0.25 | Never auto-add alone without prefix |
| Duration within ±2 s | +0.15 | Corroboration |
| BPM within ±3 (if known) | +0.10 | Corroboration |
| Same artist tag | +0.05 | Corroboration |

**Decision thresholds:**

| Confidence | Behavior (auto-match on) |
|------------|-------------------------|
| `≥ 0.85` | Add as mix silently; pre-fill role from parser |
| `0.55 … 0.84` | Show import resolution sheet; default to top candidate |
| `< 0.55` | New song; suggest export prefix from parser stem |

**Prefix-only auto-add:** basename matches exactly one song's `exportPrefix` →
confidence floor **0.85** even without duration/BPM (producer naming is the contract).

**Prefix + wrong duration (>30 s delta):** still show resolution sheet — might
be arrangement fork, not iteration.

**No prefix on any song:** fall back to title/fuzzy rules; max auto-add without
sheet is **0.85** requiring title exact + duration corroboration.

### 3. Import resolution flow

**Batch import** with matches:

```
┌─────────────────────────────────────────┐
│  Import 6 files                         │
│  ─────────────────────────────────────  │
│  ✓ NightDrive_master.mp3 → Night Drive  │
│    Matched: export prefix `NightDrive_` │
│    Add as: [Master ▾]                    │
│  ? NightDrive_slowed.mp3 → Night Drive  │
│    Prefix match · longer than other mixes│
│    ○ Add as version  ● New linked song  │
│  ✓ NewBeat.mp3 → New song               │
│    Suggested prefix: `NewBeat_`         │
│  ─────────────────────────────────────  │
│              [Import All]                 │
└─────────────────────────────────────────┘
```

- Per-file row: parsed title, **match reason** (prefix / title / fuzzy), role
  picker, target (existing song / new / new linked)
- Prefix matches show lock icon + prefix string; tap **Change song** to override
- **Apply to similar** — same matched song + same prefix in this batch
- New songs: optional **Set export prefix** field pre-filled from stem

**Single add-mix** (`SongDetailView`): skip resolution sheet; always attaches to
current song. Pre-fill role/name from parser.

### 4. Auto-primary rules (suggest only)

After adding a mix, non-blocking banner:

| Condition | Suggestion |
|-----------|------------|
| New role `.master` and no primary with role `.master` | "Set as primary?" |
| New mix & category ≥ `.mastered` | "Use this master for playback?" |
| User taps **Set as Primary** | existing `setPrimary` + dismiss |

Never auto-promote without explicit tap (producer trust).

### 5. Per-mix metadata (phase 2)

On mix import, optionally run **light analyze** (BPM/key/LUFS) stored on `Mix`:

| Field | Notes |
|-------|-------|
| `detectedBPM` | May differ from song nominal on arrangements |
| `detectedKey` | |
| `integratedLUFS` | When [LoudnessAnalysis](LoudnessAnalysis.md) ships |

Song-level BPM/key stay tied to **primary mix** unless user edits manually.

---

## UI / UX

### Library (`SongRow`)

| Element | Behavior |
|---------|----------|
| Mix count | `3 versions` instead of `3 mixes` when count > 1 |
| Primary role badge | Tiny pill: `Master` / `Tagged` when not `.original` |
| Filter (stretch) | **Has versions** — `mixes.count > 1` |

### Song detail — export prefix card

Section below **Details**, above **Versions**:

```
Export naming ─────────────────────────────
Prefix: NightDrive_          [Copy] [Edit]
Tip: Name FL exports NightDrive_master.mp3,
     NightDrive_rough.wav …
```

| Action | Behavior |
|--------|----------|
| **Copy** | Pasteboard: prefix + example suffix `_master.mp3` |
| **Edit** | Inline or editor field; runs `ExportPrefixValidator` |
| Empty state | "Set a prefix so future exports stack here automatically" + **Suggest** |

Show small badge on header when prefix is set: `NightDrive_` (truncated).

### Song editor

- Field: **Export prefix** (optional), with suggested value chip
- Validation errors inline (collision, too short, weak prefix)
- Toggle: **Use suggested prefix from title** on save (default on for new songs)

### Song detail — **Version stack** (replaces flat "Mixes" section)

```
Versions ──────────────────── [+ Add] [Compare]
┌────────────────────────────────────────────┐
│ ★ Master v2          3:24   −13 LUFS  ▶   │  ← primary
│   Rough              3:22                 │
│   Tagged             3:24                 │
│   Instrumental       3:24                 │
└────────────────────────────────────────────┘
```

| Interaction | Result |
|-------------|--------|
| Tap row | Play that mix |
| Tap ★ | Set primary (`Haptics.tap`) |
| Long-press / swipe | Edit, Delete (confirm), Duplicate notes |
| Drag handle | Reorder `sortOrder` |
| **+ Add** | File picker → attach with parsed name/role |
| **Compare** | Opens compare sheet (2 selected or primary vs latest) |

**Mix edit sheet** (`MixEditorView`):

- Name (optional override)
- Role picker
- Notes
- Read-only: source filename, date added, duration
- Detected BPM/key/LUFS when available

### Full player — version picker v2

Replace segmented control (max ~4 labels) with **menu or horizontal scroll chips**:

```
[★ Master v2] [Rough] [Tagged] [Inst]
```

- Primary mix chip shows ★
- Role color dot (reuse category-style tints per role)
- `switchMix` unchanged under the hood
- Subtitle: `Master v2 · 128 BPM` (mix-level BPM when differs)

### Compare sheet (`VersionCompareView`)

Two columns, pick any two mixes of the same song:

| Row | Mix A | Mix B |
|-----|-------|-------|
| Waveform | mini | mini |
| Duration | 3:22 | 3:24 |
| BPM | 128 | 128 |
| Key | Am | Am |
| LUFS | −14.1 | −11.2 |
| Role | Rough | Master |

- Linked playheads: play A, tap **Switch**, play B from same timestamp
- **Set left/right as primary** buttons
- Uses existing `AudioPlayer.switchMix` + seek

### Merge duplicates (`MergeSongsSheet`)

From song detail menu → **Merge another song into this…**

1. Pick source song from list
2. Preview: "Moves 2 versions from *Night Drive Demo*"
3. Confirm → all mixes reparented, source song deleted, primary resolved (keep
   destination primary unless source was only song with master role)

### Linked arrangements (v1.1)

Song detail footer: **Related** — chips linking sibling songs. Tap navigates.
Created when user chooses **New linked song** at import.

---

## Settings

| Setting | Default | Notes |
|---------|---------|-------|
| Auto-match versions on import | On | Master switch for import intelligence |
| **Auto-add on export prefix match** | **On** | Silent mix add when prefix matches one song |
| Auto-suggest export prefix | On | Pre-fill prefix on new songs / import |
| Ask when duration differs widely | On | Prefix match but Δduration > 30 s → sheet |
| Default role for unmatched imports | Original | |
| Ask before merge | On | |

Path: **Settings → Import & Versions**

---

## Integration points

| Location | Change |
|----------|--------|
| `Song` | `exportPrefix`, `exportPrefixIsManual`, `normalizedTitle` |
| `ExportPrefixSuggester`, `ExportPrefixValidator` | Services |
| `Mix`, `MixRole` | Model |
| `MixNamingParser`, `ImportMatcher`, `VersionImportService` | Services |
| `SongImportService` | Call matcher before insert; batch resolution |
| `LibraryView` | Import resolution sheet |
| `SongDetailView` | Version stack UI, compare entry |
| `MixEditorView` | New |
| `VersionCompareView` | New |
| `MergeSongsSheet` | New |
| `FullPlayerView` | Chip picker |
| `SongRow` | Version count + role badge |
| `ImportedAudio` | Add `sourceFileName` |
| `A11yID` | `song.versionStack`, `song.exportPrefix`, `song.compare`, `import.resolution` |
| [LibraryAndImport](shipped/LibraryAndImport.md) | Update when shipped |
| [SongsAndMixes](shipped/SongsAndMixes.md) | Update when shipped |

---

## Accessibility

| # | Requirement |
|---|-------------|
| V1 | Version row: "{role}, {duration}, primary" or "not primary" |
| V2 | Compare table columns labeled Mix A / Mix B |
| V3 | Import resolution: each row announces match confidence in plain language |
| V5 | Export prefix field: "Export prefix, Night Drive underscore, used to match imports" |

---

## Iteration plan (prefix feature)

Ship prefix matching in **thin slices**; tune weights from real imports.

| Iteration | Scope | Learn |
|-----------|-------|-------|
| **A** | Model + validator + manual prefix on song editor | Collision UX, delimiter warnings |
| **B** | Prefix-only silent import (no fuzzy) | False positive rate |
| **C** | Full scoring + resolution sheet | When to ask vs auto-add |
| **D** | Duration mismatch gate + linked song path | Arrangement forks |
| **E** | "Remember prefix" on correction | Reduce setup friction |
| **F** | Library filter "has prefix set" | Power-user catalog hygiene |

Instrument (local only, no analytics): debug log match kind + score per import
during beta; adjust weights in spec before widening auto-add.

---

## Testing

### Unit — `MixNamingParserTests`

| Filename | baseTitle | role | version |
|----------|-----------|------|---------|
| `NightDrive_v2_master.mp3` | NightDrive | master | v2 |
| `Project_7.mp3` | Project 7 | original | nil |
| `summer_bounce_rough.wav` | summer bounce | rough | nil |
| `beat_tagged_final.mp3` | beat | master | nil |
| `MY TRACK - slowed.mp3` | MY TRACK | arrangement | nil |

### Unit — `ExportPrefixValidatorTests`

- `NightDrive_` valid; `Night` warns missing delimiter; `beat` rejected
- Collision between two songs blocked on save

### Unit — `ImportMatcherTests` (prefix)

| Basename | Song prefix | Expected |
|----------|-------------|----------|
| `NightDrive_master` | `NightDrive_` | match, kind `.exportPrefix`, ≥ 0.85 |
| `NightDrive_master` | `Night_` | no match |
| `Nightmare_v1` | `Night_` | no match — validator should discourage weak prefix |
| `OtherBeat_master` | `NightDrive_` | no match |

### Unit — `ImportMatcherTests` (fuzzy fallback)

- Exact title + duration → confidence ≥ 0.85 without prefix
- Different title → no candidate
- Typos + same duration → candidate 0.55…0.84

### Integration

- Import 2 files same normalized title → one song, two mixes
- Merge moves mixes, deletes source
- Primary promotion updates `song.primaryMix` playback in library

### Manual acceptance

- [ ] Export prefix copy tip pastes sensible example
- [ ] Prefix collision blocked in editor
- [ ] `NightDrive_*` batch silently stacks when prefix set
- [ ] Duration outlier shows sheet despite prefix match
- [ ] Compare sheet switches mixes without losing position
- [ ] Full player chip picker works with 6+ versions
- [ ] Delete mix confirm; cannot delete last mix without deleting song
- [ ] VoiceOver reads version stack clearly

---

## Phased delivery

### Phase 1 — Labels & stack UI (highest leverage)

- `MixRole` + parser + auto-naming on import/add-mix
- Version stack UI in song detail (sort, role badges, primary star)
- `MixEditorView`
- SongRow "N versions"
- Full player chip picker

### Phase 2 — Export prefix & smart import

- `Song.exportPrefix` + `ExportPrefixValidator` + `ExportPrefixSuggester`
- Export prefix card + editor field + copy tip
- `ImportMatcher` prefix scoring + **Auto-add on prefix match** setting
- Import resolution sheet (prefix reason string, override)
- `sourceFileName` on mix
- Suggest primary banner

### Phase 3 — Compare & cleanup

- `VersionCompareView`
- `MergeSongsSheet`
- Per-mix BPM/key (and LUFS when loudness spec lands)
- Fuzzy title matching without prefix (full scoring table)

### Phase 4 — Linked arrangements & learning

- `linkedSongIDs`, related section, import choice **New linked song**
- "Remember prefix" on import correction
- Duration-mismatch gate tuning from beta

---

## Open questions

1. **Max mixes per song?** Cap at 20 with warning, or unlimited?
2. **Delete last mix** — force song delete or keep empty song shell? → **Spec: prompt to delete song.**
3. **Project playback when primary changes** — queue uses primary at play time (refresh) — document in [Playback](shipped/Playback.md).
4. **Renaming song** — recompute `normalizedTitle` and **offer** to update `exportPrefix` (don't auto-change if `exportPrefixIsManual`).
5. **Duplicate file hash** — skip import if byte-identical file already on a mix? (Phase 3 nice-to-have.)
6. **Multiple prefix aliases** — `NightDrive_` and `ND_` for one song? → defer; v1 one prefix per song.
7. **First import sets prefix?** → suggest only; set on save if user leaves field populated.
8. **Prefix on manual song (no audio yet)?** → allowed; show empty version stack + naming tip.

---

## Verification

- Target release: Phase 1 + Phase 2 iteration A/B (prefix import)
- Last verified: 2026-06-16 (implemented; **79 tests pass**; sim launch + library snapshot)
- Primary code paths: `MixRole`, `MixNamingParser`, `ExportPrefixValidator`,
  `ExportPrefixSuggester`, `ImportMatcher`, `SongImportService`, `SongDetailView`,
  `SongEditorView`, `MixEditorView`, `VersionStackRow`, `FullPlayerView`, `SongRow`,
  `VersionImportSettings`, `SettingsView`

# Audiogram Export Spec

Render a **short video** (15–30 s) with an animating waveform over a branded
card — the format beatmakers actually post to Instagram Stories, TikTok, and
Reels to tease a drop.

Depends on: waveforms (`Mix.waveformPeaks` ✅), Brand Kit (`BrandKit.md`).

---

## Goals

| Goal | Success looks like |
|------|-------------------|
| One-tap social teaser | Pick a snippet → export MP4 → share to Instagram |
| On-brand | Uses Brand Kit accent, logo, title, BPM/key |
| Fast enough | 30 s export completes in < 30 s on recent iPhone |

## Non-goals

- **Lyric kinetic typography** or complex motion graphics.
- **DAW-style timeline editing** — start/end handles only.
- **Direct post to Instagram API** — system share sheet only.
- **4K / 60 fps** — 1080×1920 @ 30 fps is enough for stories.

---

## User stories

1. **Drop teaser** — I loop the hook (0:45–1:15), export a 20 s audiogram, post
   to Stories with "out Friday" sticker.
2. **Beat preview** — 15 s instrumental snippet with waveform + "128 BPM · Am"
   for a type-beat channel.
3. **Project promo** — First track hook + project title on card for EP announce.

---

## Export pipeline

### Input

- Source: primary mix (or user-selected mix)
- Snippet: `startTime` … `endTime` (default: first 30 s or length if shorter)
- Format preset: **Story 9:16** (default), **Square 1:1** (reuse card layout)
- Duration cap: **15 / 20 / 30 s** picker

### Rendering (`AudiogramRenderer` service)

1. Load cached waveform peaks for snippet range
2. Compose frames:
   - Background: brand gradient or solid (`BrandKit`)
   - Title, artist, BPM/key overlay (`ShareCardView` layout subset)
   - Animated waveform bars synced to audio playback position
3. `AVAssetWriter` + `AVAssetReader` — mux H.264 video with AAC audio slice
4. Output: temp `.mp4` → `UIActivityViewController`

### Waveform animation

- 60 bars across bottom third; heights from peak buckets interpolated per frame
- Respect `Reduce Motion`: static waveform image, audio only

---

## UI surfaces

### Song detail & Full player

- Action: **Export Audiogram…**
- Sheet:
  - Waveform trim handles (reuse scrubber interaction)
  - Duration chips: 15 / 20 / 30 s
  - Format: Story / Square
  - Preview thumbnail (first frame)
  - **Export** → progress → share sheet

### Project detail (stretch)

- Audiogram of first track + project title overlay

---

## Performance & limits

- Max source snippet: 60 s analyzed (export still capped at 30 s output)
- Cancel in-flight export
- Disk: delete temp file after share sheet dismiss

---

## Testing

- Unit: peak slice for time range maps to correct bucket indices
- Integration: export 5 s synthetic tone → MP4 exists, duration ±0.5 s
- Manual: play exported file in Photos; audio/video in sync

---

## Verification

- Target release: post-v1 (after Brand Kit + section markers optional)
- Last verified: 2026-06-16 (spec only; **not implemented**)
- Primary code paths: `AudiogramRenderer`, `FullPlayerView`, `SongDetailView`,
  `ShareCardView`, `BrandKit`

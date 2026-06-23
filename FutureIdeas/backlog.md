# MixStack — future ideas

From [`../ROADMAP.md`](../ROADMAP.md). Shipped items live in `specs/shipped/`.

## Shared tempo package (BeatMic engine)

MixStack will **not** maintain its own BPM estimator long-term. After [`BeatMic`](../../BeatMic/FutureIdeas/backlog.md) ships TestFlight and extracts an SPM package, MixStack adopts it for import and on-demand analysis.

| Change | Notes |
|--------|-------|
| **Replace `AudioAnalyzer.estimateBPM`** | Call shared `BPMAnalyzer` / file loader from the package; one mono PCM load → tempo + existing key + vocal |
| **Keep in MixStack** | `estimateKey`, chromagram, `MusicalKey`, `estimateVocalPresence`, catalog write-back |
| **Confidence + alternatives** | Surface package `BPMEstimate` in song detail (optional half/double-time hints when confidence is ambiguous) |
| **Re-analyze migration** | New imports use package BPM immediately; existing songs unchanged unless user re-analyzes |
| **Later** | Live mic tempo (hold phone at monitor while A/B’ing) via package streaming API if BeatMic adds it |

MixStack’s role long-term: **producer toolkit** — catalog, sequencing, loudness, key/vocal, share cards — with tempo analysis delegated to the shared package.

---

## Other ideas

| Idea | Notes |
|------|-------|
| **Harmonic neighbour suggestions** | Beyond clash flags on import |
| **Multi-signal energy model** | Arc templates for arrangement hints |
| **Platform banner share preset** | 16:9 + link-in-bio page |
| **iCloud sync** | Schema versioning + migration |
| **Pitch/tempo preview** | Stem/section markers — `TimelineMarkers.md` |

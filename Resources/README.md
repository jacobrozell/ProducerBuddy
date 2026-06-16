# Demo audio (local only)

Place `.mp3` (or `.wav` / `.m4a` if you extend the seeder) files here for
**local demo and simulator testing**. They are copied into the app bundle at
build time and **not committed** (`Resources/*.mp3` is gitignored).

## Use

1. Add tracks to this folder.
2. `xcodegen generate` and rebuild.
3. Either:
   - Launch with `-seed_demo_tracks` (imports when library is empty), or
   - Settings → **Load Demo Tracks**.

Tracks are copied into the app's Documents `Audio/` folder on import, same as
the Files picker flow.

**Note:** MP3s are gitignored and copied into the app bundle at build time via
the `Copy Demo Audio` script in `project.yml`.

# ADR 0029 — Release builds (v0.1.0-alpha)

Date: 2026-10-01 · Status: accepted (the user asked for a release and chose the options below).

## Context
- Until now the game ran only from source (`godot --path game`). There was no `export_presets.cfg`.
- The user asked for a first release. User answers (2026-10-01): version `v0.1.0-alpha`, a GitHub pre-release,
  Windows and Linux. Android was also asked for, but the game has no touch controls (walking, menus and sleep
  are keys only), so the user chose to skip Android for this release.

## Decision
- `game/export_presets.cfg` has two presets: "Windows Desktop" and "Linux" (x86_64, release templates).
  - `include_filter="*.json"`: game data is plain JSON read with `FileAccess`, not a Godot resource, so it must be
    packed by name. Without it the build starts with no canon, maps or rules.
  - `exclude_filter`: `tests/*`, `test_support/*`, `addons/gut/*`, `_scratch/*`. GUT is an editor plugin only.
  - `embed_pck=true`: one file per platform (the `.pck` is inside the exe).
  - `application/modify_resources=false`: no rcedit needed; the exe keeps Godot's icon for now.
- The version lives in `project.godot` (`application/config/version`). The title screen shows it
  (`TitleMenu.version_text()`, test `unit_play_loop.test_title_shows_the_build_version`).
- `tools/release.ps1` builds both zips into `export/` (gitignored): export, smoke test, then zip with
  `README.txt` (player guide from `tools/release/README-PLAYERS.txt`), `CREDITS.md` and the asset licence files.
- Smoke test: `tools/release/smoke.gd`, run with the normal Godot exe and `--main-pack <exported binary>`. It loads all
  data from the pack, checks for no data errors, textures, no tests in the pack, plays 5 nights, and exits 1 on a
  problem. (A release template ignores `-s`, so the editor exe reads the pack instead.)
- Zips are made with `tar.exe` (Windows 10+): `Compress-Archive` in PowerShell 5 writes `\` in zip paths.
- Export templates are not in git. Install them once (Godot editor: Manage Export Templates, or unzip the Windows
  and Linux files of `Godot_v4.7.2-stable_export_templates.tpz` into `%APPDATA%\Godot\export_templates\4.7.2.stable`).

## Consequences
- A release: bump `config/version`, run `tools/release.ps1`, tag `v<version>` on main, upload the two zips.
- Linux: the zip loses the exec bit; `README.txt` tells players to `chmod +x`.
- Saves from an alpha may not load in a later build (save migrations exist, but are not promised to players).
- Android (and touch controls) is a future milestone. It needs an on-screen pad and menu buttons first.
- The M19 (Book 7) plan moves to ADR 0030.

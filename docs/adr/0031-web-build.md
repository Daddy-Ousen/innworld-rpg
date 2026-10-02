# ADR 0031 — Web build (play in the browser)

Date: 2026-10-01 · Status: accepted (the user asked for a browser version on itch.io and on GitHub Pages).

## Context
- v0.1.0-alpha ships Windows and Linux zips (ADR 0029). The user asked if the game can run in a browser.
- Checks: no shaders, no threads, no `OS.execute`. Saves and settings use `user://` (IndexedDB in a browser).
  `DirAccess` on `res://` already works from a pack (desktop smoke test).
- User answers (2026-10-01): host on itch.io and on GitHub Pages; start on the GitHub URL
  (`https://daddy-ousen.github.io/innworld-rpg/`) and add an own subdomain later. Full export templates downloaded.

## Decision
- A third preset "Web" in `game/export_presets.cfg`: same include and exclude filters as the desktop presets,
  `variant/thread_support=false` (single-threaded: no cross-origin isolation headers, so any static host works),
  `html/canvas_resize_policy=2` (the game fills the browser window), no PWA.
  Godot uses the Compatibility renderer on the web by itself; the game has no shaders, so the look stays the same.
- `tools/release.ps1` builds `export/InnworldRPG-v<version>-web.zip` with `index.html` at the zip root (itch.io and
  Pages need it there). The smoke test reads `index.pck` with `--main-pack`, like the desktop builds.
- Web only: `display/window/stretch/mode.web="canvas_items"` and `aspect.web="expand"` in `project.godot`. The game
  scales to the browser window like a 1152x648 window (the desktop size); without it the HUD text was cut off in small
  windows. The desktop builds do not change. Very small windows (640x480) make the text small.
- The title screen hides Quit in a browser (`TitleMenu.shows_quit`): a web page cannot close itself.
- GitHub Pages: `.github/workflows/pages.yml` does not build the game. On a published release (or by hand with a tag)
  it downloads the `*-web.zip` from the release and publishes it. GitHub needs no Godot and no templates.
- itch.io: the user uploads the same web zip by hand (an HTML project, "played in the browser"). Claude does not log in
  or handle the itch.io account or API key.

## Consequences
- A release now uploads three zips. Publishing the GitHub release also publishes the web build to Pages.
- Repo setting (once, by the user or with their yes): Settings → Pages → Source "GitHub Actions".
- The `github-pages` environment allows only `main` by default, so the run that a release (a tag) starts is rejected.
  Either add a tag rule `v*` to the environment, or run the workflow from `main` with the tag:
  `gh workflow run pages.yml --ref main -f tag=v<version>` (v0.1.1-alpha was deployed this way).
- An own subdomain later: a DNS CNAME record `play.<domain>` → `daddy-ousen.github.io`, then the domain in
  Settings → Pages → Custom domain, with "Enforce HTTPS". The workflow does not change.
- Browser saves live in the browser's site data. Clearing it deletes the saves. itch.io and Pages are two sites, so
  they keep separate saves.
- In fullscreen the browser takes Esc to leave fullscreen; the game menu then needs a second Esc.
- First load: `index.pck` 64 MB + `index.wasm` 40 MB (web zip 70 MB). Local start to the title screen about 10 s.
- Checked in Chrome (2026-10-01, local server): title, new game, walk, save, page reload keeps the save, Continue.
  A night (`sleep *`) takes about 0.3 s. Browsers start sound only after the first click (normal).
- Browser automation note: the in-app browser's `type` does not reach Godot; Playwright `keyboard.type` does.

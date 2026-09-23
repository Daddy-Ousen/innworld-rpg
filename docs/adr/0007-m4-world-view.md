# ADR 0007 — M4.3 2D world view

Date: 2026-09-23 · Status: accepted (M4 plan approved by the user 2026-09-23)

## Session autoload — `ui/session.gd` (`Session`)
- Holds `db` (`DataDb.load_dir()`) and `gs` (a new game, seed 1). Signal `state_changed`.
- Scenes send Commands on `Session.gs`, then call `Session.changed()`. A new or loaded game goes through `Session.set_state(gs)`.
- No `class_name` (it would clash with the autoload name).
- `project.godot`: `[autoload] Session`, main scene `res://world/main.tscn` (rule 11: approved in the plan).

## Debug console
- `ConsoleCommands` stays headless and unchanged. The console scene syncs: before a command `console.gs = Session.gs`; after it `Session.set_state(console.gs)`. So `new` and `load` also move the map.
- `ui/debug_console.tscn` still runs on its own (no Session → its own db and game).
- In the main scene it is an overlay on a `CanvasLayer`; the backtick key toggles it (caught in `_input`, before the text box).

## World view — `world/world_view.tscn` (`WorldView`)
- One `TileMapLayer`. The `TileSet` is made in code: one 16×16 atlas cell per `tiles.json` entry, filled with its `color`; tiles you cannot walk on get a darker edge. Nearest filter.
- Redraws only when the player's area changes. Exits get a pale overlay; objects are yellow squares with the first letter of their name.
- Player: a red square with a light "nose" on the facing side. `Camera2D` child, zoom ×3, limits = map size, smoothing on; it jumps (no glide) on an area change.

## Main scene — `world/main.tscn`
- WASD / arrow keys (physical keys, polled in `_process`): one step at once, then one step every 0.14 s while held.
- E: "use" menu (`ui/interact_menu.tscn`, an `ItemList` of `Interact.options`; Enter picks, Esc closes) → `Commands.interact`.
- Z: `Commands.sleep`. A refused step when collapse is due also sleeps (a collapse). Until M4.5 the night lines go to the HUD log.
- No walking while the menu or the console is open.

## HUD — `ui/hud.tscn` (`Hud`)
- Top: day, time, map name · place name (zone or map location, from canon). A warning when 6 h or less of awake time is left.
- Bottom: the last 4 log lines and a key hint.

## Tests
- `unit_world_view`: tile set, cell → tile mapping, player marker, area change redraw and camera limits, HUD text and warning, main scene step/use/sleep, console overlay → Session, held key repeat, use menu.
- Manual check: `godot --path game`. Frames via `--write-movie <file>.png --fixed-fps 5 --quit-after 3`.

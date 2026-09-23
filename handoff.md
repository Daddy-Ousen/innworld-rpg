# Handoff

## Just done (2026-09-23, branch `feat/m4.3-world-view`)
PR #6 merged; tag `m4.2-done` pushed. User chose float fix option 2 (exact text), to do in M4.4 with save v5.
M4.3 2D view is done and tested:
- `ui/session.gd` autoload `Session` (db + gs, `state_changed`). `project.godot`: autoload + main scene `res://world/main.tscn`.
- `world/world_view.tscn/.gd` (`WorldView`): TileMapLayer, TileSet made in code from `tiles.json` colors, objects as lettered squares, exits tinted, player square + facing nose, Camera2D ×3 with map limits.
- `world/main.tscn/.gd`: WASD/arrows (hold repeats every 0.14 s), E use menu, Z sleep, backtick console overlay; collapse on a refused step.
- `ui/hud.tscn/.gd` (`Hud`), `ui/interact_menu.tscn/.gd` (`InteractMenu`).
- `ui/debug_console.gd` syncs with `Session` when it exists.
- Tests: `unit_world_view` (10 tests). GUT 203/203. ADR 0007.
- Manual frames checked for gate, market, floodplains, inn hill, inn inside.

## Waiting on the user
- Review PR #7 (https://github.com/Daddy-Ousen/innworld-rpg/pull/7), merge, then tag `m4.3-done`.
- Play it: `godot --path game` (WASD, E, Z, backtick).
- Old game-data suggestions still open: `[Basic Crafting]`, `[Gatherer]` + `[Detect Poison]`, `[Detect Guilt]`, `[Dangersense]`, `[Spearmaster]`, `[Swordslayer]`, `[Bar Fighting]`, `[Unerring Throw]`, `[Iron Scales]`.

## Timeline (days)
Day 1 = Erin's arrival. 1.00–1.09 = days 1–7. 1.10 + interlude = day 7 / night 7. 1.11–1.12 = day 8 (player arrives). 1.13–1.14 = day 9.

## Next
- M4.4 NPC schedules + utility AI on branch `feat/m4.4-npc-ai` (plan file: `C:\Users\rhasa\.claude\plans\lets-start-m4-plan-lucky-treehouse.md`). Save v5 also stores floats as exact text (user decision, option 2); remove the float tolerance in `tests/sim_walk_day.gd` then. `Pathfind` already exists (M4.2). ADR number for M4.4 is 0008.
- M4.5: System dialog replaces the night lines in the HUD log; `sleep` on the inn bed.

## Gotchas
- Commits and PRs: author Daddy-Ousen only. NO `Co-Authored-By: Claude` trailer, no Claude footer.
- Use the Write tool for JSON and long text files; heredocs with JSON or `\U` paths break in Git Bash / Python.
- A sleep at 06:00 is a 4 h nap (same day). Loop on `gs.world.last_day`, not on sleep count.
- `const X := SomeClassName` does not parse in Godot 4.7 test scripts. Use the class name directly.
- New `.gd` files get `.gd.uid` files. Commit them.
- Godot class cache goes stale after checkout/merge or new class_name: run `godot --headless --path game --import`, then the tests.
- Python 3.14; use `python -X utf8` in Git Bash when printing book text.
- Python tests: `python -m unittest discover -s tools/tests` (no `-t .`).
- GUT `.import` files show as modified: line endings only. Do not commit them.
- Godot JSON reads back ~1 in 3 long floats with a 1-bit error (fix planned in M4.4).
- New game starts on day 8. Tests that need day 1 use `ToyData` (its rules set `start_minute` 360).
- A GUT run with a broken script can hang. Use `timeout 500 godot ...` in Git Bash.
- `bool("yes")` is a script error in Godot 4.7; check `x is bool` first.
- The `Session` autoload exists in GUT runs. Tests that use it call `Session.set_state(GameState.new_game(...))` first.
- Screenshots: `godot --path game --write-movie <scratch>/x.png --fixed-fps 5 --quit-after 3` (a real window opens briefly). To show another place, a scratch scene can call `Session.gs.player.place(...)` before adding `main.tscn`; delete scratch files before committing.
- Maps were made by a scratch script (not in git). Edit `game/data/maps/*.json` by hand; `unit_map_db` checks widths, exits and reachability.

## Active files
`game/ui/{session,hud,interact_menu,debug_console}.gd`, `game/ui/{hud,interact_menu}.tscn`, `game/world/{main,world_view}.{gd,tscn}`, `game/project.godot`, `game/tests/unit_world_view.gd`, `docs/adr/0007-m4-world-view.md`.

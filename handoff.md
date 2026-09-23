# Handoff

## Just done (2026-09-23, branch `feat/m4.2-world-grid`)
PR #5 merged; tag `m4.1-done` pushed.
M4.2 world grid core is done and tested:
- Data: `game/data/tiles.json`, `game/data/maps/{liscor_gate,liscor_market,floodplains_south,inn_hill,inn_interior}.json`, `rules.json` `world` + `clock.start_minute` 10440 (day 8, 06:00).
- Core: `map_db.gd`, `player_state.gd`, `movement.gd`, `interact.gd`, `pathfind.gd`; `GameState` v4 (`player`), migration 3→4, `Actions.perform` `minutes` opt, `Commands.move/interact`, `DataDb.maps`.
- `new_game` runs the director for days 1–7 first; the player starts at `liscor_gate` 3,12.
- `actions.json`: context `location` "inn" → "wandering_inn".
- Console: `where`, `look`, `go <dir> [xN]`, `use <object> <action>`.
- Tests: `unit_map_db`, `unit_movement`, `unit_interact`, `sim_walk_day`, + migration/console tests. GUT 193/193, Python 26/26, validator 0 errors.
- ADR 0006.

## Waiting on the user
- Review PR for M4.2, merge, then tag `m4.2-done`.
- Float save round trip (ADR 0006 "Known issue"). Options: (1) keep the test tolerance (now), (2) save floats as exact strings (save format change), (3) round XP values so they survive JSON.
- Old game-data suggestions still open: `[Basic Crafting]`, `[Gatherer]` + `[Detect Poison]`, `[Detect Guilt]`, `[Dangersense]`, `[Spearmaster]`, `[Swordslayer]`, `[Bar Fighting]`, `[Unerring Throw]`, `[Iron Scales]`.

## Timeline (days)
Day 1 = Erin's arrival. 1.00–1.09 = days 1–7. 1.10 + interlude = day 7 / night 7. 1.11–1.12 = day 8 (player arrives). 1.13–1.14 = day 9.

## Next
- M4.3 2D view on branch `feat/m4.3-world-view` (plan file: `C:\Users\rhasa\.claude\plans\lets-start-m4-plan-lucky-treehouse.md`): `Session` autoload, `world_view` TileMapLayer from `tiles.json` colors, input, HUD, console overlay.
- M4.5: a `sleep` action on the inn bed (now the bed only has `clean_room`).

## Gotchas
- Commits: author Daddy-Ousen only. NO `Co-Authored-By: Claude` trailer.
- Heredocs with long JSON in Git Bash failed once (quote parse error). Use the Write tool for JSON files.
- A sleep at 06:00 is a 4 h nap (same day). Loop on `gs.world.last_day`, not on sleep count.
- `const X := SomeClassName` does not parse in Godot 4.7 test scripts. Use the class name directly.
- New `.gd` files get `.gd.uid` files. Commit them.
- Godot class cache goes stale after checkout/merge: run `godot --headless --path game --import`, then the tests.
- Python 3.14; use `python -X utf8` in Git Bash when printing book text.
- Python tests: `python -m unittest discover -s tools/tests` (no `-t .`).
- GUT `.import` files show as modified: line endings only. Do not commit them.
- Godot JSON reads back ~1 in 3 long floats with a 1-bit error. Do not compare saved/loaded floats exactly (see `_diff` in `tests/sim_walk_day.gd`).
- New game starts on day 8. Tests that need day 1 use `ToyData` (its rules set `start_minute` 360).
- A GUT run with a broken script can hang. Use `timeout 500 godot ...` in Git Bash.
- `bool("yes")` is a script error in Godot 4.7; check `x is bool` first.
- Maps were made by a scratch script (not in git). Edit `game/data/maps/*.json` by hand; `unit_map_db` checks widths, exits and reachability.

## Active files
`game/core/{map_db,player_state,movement,interact,pathfind,game_state,save_migrations,actions,commands,data_db}.gd`, `game/data/{tiles.json,maps/,rules.json,actions.json}`, `game/ui/console_commands.gd`, `game/test_support/toy_maps.gd`, `game/tests/{unit_map_db,unit_movement,unit_interact,sim_walk_day}.gd`, `docs/adr/0006-m4-world-grid.md`.

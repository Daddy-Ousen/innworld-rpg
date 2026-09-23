# ADR 0006 — M4.2 world grid core

Date: 2026-09-23 · Status: accepted (M4 plan approved by the user 2026-09-23)

## Start: day 8, outside the Liscor east gate (user choice)
- The player is one of the Earthers of the Great Ritual (night 7). `rules.json` `clock.start_minute` = 10440 (day 8, 06:00).
- `GameState.new_game` runs `Director.run` through day 7 first, so canon history exists. Its rumor lines are dropped: the player was not there.
- Erin walks through the same gate on day 8 (`b1.erin_walks_to_liscor`).
- `ToyData` sets `start_minute` back to 360: toy games still start on day 1.
- Later (M7+): a Celum start. There is no Celum canon yet (first seen 1.19R), and the M6 slice events are all near Liscor.

## Data (new schemas, rule 11: approved)
- `data/tiles.json`: `{"tiles": {id: {"name", "walk": bool, "color": "#rrggbb"}}}`. `color` is for placeholder tiles (M4.3).
- `data/maps/<area>.json`: `id` (= file name), `name`, `location` (canon location id), `confidence`, `note`, `legend` (one char → tile id), `rows` (ASCII grid, equal widths), `zones` (canon location id → `[[x, y, w, h], ...]`), `exits`, `objects`.
  - exit: `{"at": [x, y] | [x, y, w, h], "to": area, "arrive": [x, y], "minutes": int}`. A wide exit keeps the offset: arrive + (tile − rect origin).
  - object: `{"id", "at": [x, y], "name", "actions": [action ids], "solid"?: bool, "context"?: {}}`.
- 5 maps, all `confidence: "guess"` (layout is design, the places are canon): `liscor_gate` (start 3,12), `liscor_market` (Krshia's and Lism's stalls as zones), `floodplains_south` (stream, blue fruit trees), `inn_hill`, `inn_interior` (stove, basin, broom, tables, bed).
- Route: market ⇄ gate 10 min, gate ⇄ floodplains 20 min, floodplains ⇄ inn hill 20 min, inn hill ⇄ inside 0 min (a door).
- `rules.json` `world`: `{"start": {"area", "pos"}, "step_seconds": 6}`.
- `actions.json`: context `location` values use canon ids. `"inn"` → `"wandering_inn"` (cook_stew, clean_room, talk_with_guest).

## Validation — `core/map_db.gd` (`MapDb`, `db.maps`)
- `DataDb.load_dir()` loads and validates maps; errors join `db.errors`. Toy dbs set `db.maps` and call `validate(db)`.
- Checks: tile fields; map fields; row widths; legend chars and tiles; `location` and zone ids exist in canon; zone and exit rects inside the map; exit tiles walkable; exit targets exist; every arrive tile walkable and not an exit; exits with minutes > 0 need the `travel` action; object ids unique, inside the map, actions exist; `rules.world.start` is walkable.

## State — `core/player_state.gd` (`PlayerState`, `gs.player`)
- `area`, `x`, `y`, `facing`, `sub_seconds`. An empty area = not placed.
- `SAVE_VERSION` 4. Migration 3 → 4 adds `"player": {}`. `Movement.ensure_placed` puts an unplaced player at the start on first use (the migration has no db).

## Movement — `core/movement.gd`
- `Movement.step(gs, db, dir)` → `{moved, blocked, refused, exit_to, minutes}`. Refused when collapse is due (same as `Actions.perform`), for an unknown direction, or with no maps.
- Blocked by a non-walk tile, a solid object or the map edge. The player still turns; no time passes.
- A step adds `step_seconds` to `sub_seconds`; whole minutes go to the clock (`Clock` stays an int minute counter).
- An exit with minutes > 0 runs `Actions.perform("travel", {minutes, intensity: minutes / travel.minutes, context: {from, to}})`. Intensity scales travel XP to the trip (clamped by `xp.intensity_min`). A 0-minute exit (door) costs one step and logs nothing.
- `Actions.perform` has a new optional `minutes` opt.
- `Movement.location_at` → zone id, else the map's location.

## Interact — `core/interact.gd`
- `Interact.options` → objects on or next to the player (8 neighbours), nearest first, then by id.
- `Interact.perform(object, action, opts)` → `{record, error}`. Context = `{location: map location, zone?}` + object context + caller context (last wins). So `buy_supplies` at a stall gets `location = liscor_market`.

## Also
- `core/pathfind.gd` (`Pathfind.path`): BFS in one map, fixed direction order, never steps on an exit that is not a goal. Pulled forward from M4.4 because the tests need it to walk.
- `Commands.move`, `Commands.interact`. Console: `where`, `look` (ASCII window: `@` you, `o` object, `>` exit), `go <n|s|e|w> [xN]`, `use <object> <action>`.
- A `sleep` action on the bed waits for M4.5 (the bed has `clean_room` for now).

## Known issue: float save round trip is not exact
Godot 4.7's JSON parser reads back about 1 in 3 floats written at 17 digits with a 1-bit error (ADR 0002 assumed exact). `sim_walk_day` compares save/load with a 1e-9 relative tolerance on floats. Everything else is exact. A real fix needs a save format change (user decision, see handoff).

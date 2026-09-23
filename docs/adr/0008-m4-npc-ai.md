# ADR 0008 — M4.4 NPC schedules, utility AI, save v5

Date: 2026-09-23 · Status: accepted (M4 plan approved by the user 2026-09-23; float fix = user option 2)

## Data — `data/npc_behaviour.json` (new schema, approved in the plan)
- Design data next to the canon NPCs. The canon NPC schema does not change.
- `entries`: off-map place → `{map: [x, y]}`. A place is the world beyond the maps: `liscor` (the city: gate 1,11 and market 2,4) and `wilds` (Floodplains 0,23 and inn hill 31,0). NPCs from that place come in and go out at these tiles.
- `npcs`: canon NPC id → `{"confidence", "notes"?, "goals": [...]}`. 14 NPCs. The Dragon is not in the file (it never leaves its lair).
- Goal: `goal` (one of `sleep, work, guard_post, patrol, trade, eat, visit_inn, forage, travel, off_map`), `base` > 0, optional `hours` `[[from, to, mult], ...]` (whole hours; from > to wraps past midnight; no match = 0), optional `days` `[first, last]`, `when_flags`, `unless_flags`, and a `target`:
  - `{"off_map": place}`, `{"area", "pos": [x, y]}`, or `{"area", "route": [[x, y], ...]}` (a patrol loop, 2+ points).
- Target and entry tiles must be walkable and not an exit (`BehaviourDb.validate`, errors join `DataDb.errors`).
- Most schedules are `guess`. Goals tied to canon say so in `notes`: Erin's day-8 trip to Liscor (1.11–1.12), Relc at the inn at dawn on day 9 (1.13), Pisces hiding after day 7, Rags watching the inn after she is spared.
- Why `days`: the director runs a day's canon events at that night, so the day's own flags are not set yet while it happens. Canon errands on a known day need a day range.

## Rules — `rules.json` `npc` (approved in the plan)
`step_seconds` 8 (the player: 6), `jump_seconds` 300, `talk_actions` [`talk_with_guest`, `persuade`, `comfort_someone`], `talk_relationship` 1. The plan's "LOD radius" became "the player's area"; the "re-plan interval" is every command.

## Utility AI — `core/utility_ai.gd`
- score = base × hour mult; 0 if outside `days`, a `when_flags` flag is unset or an `unless_flags` flag is set.
- Best score wins; ties go to the goal listed first. Nothing above 0 → `IDLE` (stay where you are). No RNG.

## Runtime state — `core/npc_roster.gd` (`GameState.npcs`, save v5)
- `sec`: world second the NPCs were last moved to (−1 = not placed yet).
- Per NPC: `area` (map id, `"@" + place` off-map, or `""` not yet), `x`, `y`, `facing`, `goal`, `route_i`, `carry` (step seconds not yet spent), `talked_day`.
- World seconds = clock minutes × 60 + the player's `sub_seconds`. It only goes up.

## Simulation — `core/npc_sim.gd`
- `Commands` call `NpcSim.sync` after every command that moves the clock (`perform`, `move`, `wait`, `interact`, `sleep`, `knock_out`, `kill_npc`). Core `Actions`/`Movement` do not know NPCs exist.
- Level of detail:
  - In the player's area: one tile per `step_seconds` along a BFS path (`Pathfind`). NPCs go around the player; if the player blocks every way, or stands on the goal, they wait next to them. NPCs pass through each other (no deadlocks; placeholder art hides it).
  - Leaving the area: walk to the exit (or the place's entry tile) and step through.
  - Other areas: jump to the goal's spot. If the way there passes through the player's area, appear at that area's way in and walk (so Erin walks past the gate on her way into Liscor).
  - A gap over `jump_seconds` (an action, a travel, a night): everyone jumps to their goal's spot.
  - No path at all: jump.
- An NPC placed on the player's tile moves to the nearest free tile.
- Dead NPCs (`WorldState.is_alive`) are removed from the roster.
- `Pathfind.path` gets an `avoid` set. `Pathfind.route` finds the chain of maps between two areas; off-map places link to their entry maps.

## Night step 6
`Night.run` runs `NpcSim.advance_to(wake time)` after the director (step 5), before the clock moves (step 8). NPCs wake where their goals put them; NPCs the director killed are gone.

## Player and NPCs
- NPCs block the player's steps. `Movement.step` returns `npc` (who is in the way).
- `Interact.options` lists NPCs on or next to the player after the objects, with the talk actions. Talking adds `context.npc`, puts the NPC first in `witnesses`, and gives +1 relationship (NPC → `"player"`) once per NPC per day.
- `Commands.wait(seconds)`: stand still (the Space key waits one step; console `wait <minutes>`). Refused when collapse is due.
- `Commands.settle`: places a migrated player and NPCs without moving time (console `load` calls it).

## Save v5
- `npcs` added; `_migrate_4_to_5` sets `{}` (placed on the next command).
- Floats are exact (user option 2): Godot's text-to-float is not exact (measured: about 1 in 3 floats at 17 digits, by any route: JSON, `to_float`, `str_to_var`). So `SaveCodec` writes every float as its 64 bits: `"f64:" + 16 hex digits`, big-endian (`0.5` → `"f64:3fe0000000000000"`). It is text and exact, but not readable as a number. Ints and strings do not change. Old saves with plain numbers still load. `sim_walk_day` now compares saves exactly (the ADR 0006 tolerance is gone).

## View
- `WorldView` draws a blue square per NPC in the area with its name above (drawn at 3× size and scaled down, so it stays sharp). `setup(maps, names)`.
- Main scene: Space waits; bumping an NPC says "X is in the way." once.
- Console: `npcs` (where everyone is, their goal and relationship), `wait <minutes>`, `look` marks people with `&`.

## Tests
`unit_utility_ai`, `unit_pathfind`, `unit_behaviour_db`, `unit_npc_sim` (walk speed, waiting, going around, entry and door, leaving, jumps, arrival tile, death, talk once a day, night, save/load), `unit_game_state` (exact floats, codec, 4→5), view and console tests, and `sim_npc_day` (real day 8: gate, market at noon, the inn in the evening, day 9 dawn, the Chieftain gone after night 9; same twice; save/load mid-day the same).

## Later
- Relationship decay (night step 7), NPC classes and levels at low detail, NPC-to-NPC talk.
- A NPC's own travel time between areas (now they jump).

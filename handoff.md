# Handoff

## Just done (2026-09-23, branch `feat/m5.2-monsters`)
M5.1 was merged (PR #10) and tagged `m5.1-done`.
M5.2 Monsters on the map is done and tested (GUT 348/348, Python 26/26, validator 0 errors):
- **`core/monster_sim.gd`** (`MonsterSim`), called by `Combat.sync` after the area check:
  - turns per `act_seconds` (`carry`), round by round in id order; none on entering; none over `jump_seconds` unless a monster is hostile (then capped by `max_turns_per_sync`); stop when the player is down;
  - spawns on entering and every `spawn.check_minutes` (`spawn_open`, `spawn_tiles`, `spawn_check`);
  - spot roll once within `spot_radius`; ambush when next to the player or bumped (`MonsterSim.ambush`, used by `Commands.move`);
  - pack aggro together; pack morale (half gone → flee); hurt → flee; give up (crab hides, others go home); territorial leash measured from home; flee to the edge / an exit and vanish;
  - `fight.routed` counts when a monster starts to flee (also a scare in `Combat._strike`).
- **Data:** 4 spawns in `enemies.json`; Razorbeak `aggro_radius` 3; map `item` fields (seed cores, stones, rolling pin, chairs); zone `razorbeak_nests` and object `razorbeak_nest`; 3 `loose_stones` objects.
- **Core:** `Combat.take` / `Commands.take`; `Interact.TAKE` and `item` in options; `MapDb` checks `item` and allows objects with no actions; `DataDb` loads combat before it validates maps; `CombatDb` validates spawns; monsters have `pack` (defaults to 1 on load).
- **Tests:** new `unit_monster_sim` (31), `sim_combat` (6); additions in `unit_combat_db`, `unit_interact`, `unit_map_db`. `unit_combat` now calls `ToyCombat.freeze` (monsters never act). `ToyCombat` has an `arena` map (`to_arena`) and a `bird`.
- ADR 0010 has the M5.2 section. ROADMAP M5.2 ticked.

## Waiting on the user
- Review the M5.2 PR, merge, then tag `m5.2-done`.
- Old game-data suggestions still open: `[Basic Crafting]`, `[Gatherer]` + `[Detect Poison]`, `[Detect Guilt]`, `[Dangersense]`, `[Spearmaster]`, `[Swordslayer]`, `[Bar Fighting]`, `[Unerring Throw]`, `[Iron Scales]`.

## Next: M5.3 Combat UI (branch `feat/m5.3-combat-ui`, from `main` after the merge)
- Until M5.3, monsters are invisible in the running game (no markers, no HP in the HUD).
- `world/world_view.gd`: monster markers in the enemy colour, label "Goblin 5/8"; a hidden crab looks like a rock tile, no label.
- `ui/hud.gd`: `HP 14/20 · Held: Chair` (warning colour at ≤25%); combat lines (`gs.combat.lines`) into the log.
- `world/main.gd`: bump to attack, one attack per key press (no auto-repeat attacks); `B` block, `T` throw at the nearest hostile, `X` drop; `E` menu gets "Take <item>" entries (options with `item` != ""; `Commands.take`); after any command, if `Combat.is_down`, call `Commands.knock_out` and open the dialog.
- `ui/interact_menu.gd`: take entries (metadata `[id, Interact.TAKE]`).
- `ui/system_messages.gd`: `KNOCKOUT` page ("Knocked Out … You wake at <place> with N HP.") replaces the collapse page (night result key `knocked_out`).
- `ui/character_sheet.gd`: HP and stats (`Stats.of`).
- `ui/console_commands.gd`: `attack <dir>`, `block`, `throw [id]`, `drop`, `use <obj> take`; debug `monsters`, `spawn <enemy> [dx dy]`, `knockout`; HP in `status`.
- `sim_m5_done` (ROADMAP "Done when"); ADR 0010 M5.3 section; tag `m5.3-done` and `m5-done` after merge.

## Gotchas
- Commits and PRs: author Daddy-Ousen only. NO `Co-Authored-By: Claude` trailer, no Claude footer.
- **Line endings:** most `.gd`, `.json` and `.md` files are CRLF in the working copy (`core.autocrlf=true`). Check with `tr -cd '\r' < file | wc -c` vs `wc -l` (grep `$'\r'` does not work in this Git Bash). The Edit tool keeps CRLF. `cat >>` or a Python write adds LF lines: then normalise the whole file. Never mix endings in one `.gd` file: GUT skips a script with a parse error and still exits 0. Always grep the GUT output for `Parse Error`.
- Bash heredocs can turn tabs into spaces. For edits with tabs, use the Edit tool or a scratch `.py` file.
- **Monster tests:** `ToyCombat.db()` gives a new db per test. `ToyCombat.freeze(db)` stops monster turns. `to_arena(gs, db, pos)` places the player in the open 14×9 arena (wall at x 6, y 3–5; no border walls, so fleeing monsters reach the edge). Set the goblin `ranged.chance` to 0 unless a test wants stones. Pack members must be within `lose_radius` of the player or they give up at once.
- `Combat.in_danger` = fight on + a hostile monster. A fleeing monster keeps the fight on, but it is no danger.
- A sleep at 06:00 is a 4 h nap (same day). Tests that sleep right after a new game advance the clock first (`gs.clock.advance(14 * 60)`).
- Class names in data already have brackets (`[Innkeeper]`). Do not add more.
- `const X := SomeClassName` does not parse in Godot 4.7 test scripts. Use the class name directly.
- New `.gd` files get `.gd.uid` files. Commit them.
- Godot class cache goes stale after checkout/merge or new class_name: run `godot --headless --path game --import`, then the tests.
- Python 3.14; use `python -X utf8` in Git Bash when printing book text.
- Python tests: `python -m unittest discover -s tools/tests` (no `-t .`). The "ERROR chapters/9.00.json" line in its output is an expected fixture.
- GUT `.import` files show as modified: line endings only. Do not commit them.
- New game starts on day 8 at 06:00. Tests that need day 1 use `ToyData` (its rules set `start_minute` 360). NPC toy world: `ToyNpcs` (guard, baker, farmer). Toy shop has a `cot` (sleep, no actions) at 0,1.
- A GUT run with a broken script can hang. Use `timeout 500 godot ...` in Git Bash.
- `bool("yes")` is a script error in Godot 4.7; check `x is bool` first.
- The `Session` autoload exists in GUT runs. Tests that use it call `Session.set_state(GameState.new_game(...))` first.
- NPCs stand next to the start and in the inn. Tests that need an empty spot clear `gs.npcs.npcs` or place the player elsewhere. Test walks use `ToyMaps.walk_to` (goes around NPCs, not monsters: a bump attacks).
- Godot text → float is never exact. Keep all save floats going through `SaveCodec`.
- Screenshots: a scratch scene in `game/` (set `Session` state, add `world/main.tscn`), then `godot --path game --write-movie <scratch>/x.png --fixed-fps 5 --quit-after 3 res://<scene>.tscn`. Delete scratch files before committing.
- `SystemDialog` buttons connect deferred; tests call `dialog.choose(...)` directly.

## Active files
`game/core/{monster_sim,combat,combat_state,combat_db,commands,interact,map_db,data_db}.gd`, `game/data/{enemies.json,maps/floodplains_south.json,maps/inn_hill.json,maps/inn_interior.json}`, `game/test_support/toy_combat.gd`, `game/tests/{unit_monster_sim,sim_combat,unit_combat_db,unit_interact}.gd`, `docs/adr/0010-m5-combat.md`.

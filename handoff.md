# Handoff

## Just done (2026-09-23, branch `feat/m5.1-combat-core`)
M4 closed: PR #9 merged; tags `m4.5-done` and `m4-done` pushed (on merge commit 0e2f19a).
M5 plan approved (3 parts; plan file `C:\Users\rhasa\.claude\plans\lets-start-m5-plan-buzzing-possum.md`; decisions in `progress.md` and ADR 0010).
M5.1 Combat core is done and tested:
- **Data:**
  - `data/enemies.json`: goblin_grunt, rock_crab, razorbeak; `spawns: []`.
  - `data/items.json`: chair, rolling_pin, stone, seed_core (tag `repels_crab`).
  - `rules.json` `combat`.
- **Core:**
  - `CombatDb` (in `DataDb.combat`) and `Stats` (base stats + stat_mod skills; max HP 20).
  - `CombatState` (`gs.combat`) and `Combat`.
  - `PlayerState.hp` (−1 = full, 0 = down) and `held`. Save v6 (`_migrate_5_to_6`).
- **Commands:**
  - `attack(dir)`, `block`, `throw(id)`, `drop`, debug `spawn_monster`.
  - `move` into a monster = attack.
  - `_after` = `Combat.sync` + `NpcSim.sync`.
  - Danger refuses `perform`, `interact` and `sleep` (`sleep` returns `{}`; main scene and console handle it).
  - `knock_out` = `end_fight(knocked_out)` + `Night.run(gs, db, true, true)`.
- **Night:** a knock-out wakes at 06:00 (not the 12 h collapse sleep). Step 6 `Combat.night` clears monsters, heals, and moves a knocked-out player to the safe place.
- **Tests:** GUT 302/302 (new: `unit_combat`, `unit_combat_db`, `unit_stats`, plus additions to `unit_night`, `unit_game_state`, `unit_data_db`). Python 26/26. Validator 0 errors.

## Waiting on the user
- Review PR #10 (https://github.com/Daddy-Ousen/innworld-rpg/pull/10), merge, then tag `m5.1-done`.
- Old game-data suggestions still open: `[Basic Crafting]`, `[Gatherer]` + `[Detect Poison]`, `[Detect Guilt]`, `[Dangersense]`, `[Spearmaster]`, `[Swordslayer]`, `[Bar Fighting]`, `[Unerring Throw]`, `[Iron Scales]`.

## Next: M5.2 Monsters on the map (branch `feat/m5.2-monsters`, from `main` after the merge)
- **`core/monster_sim.gd`**, called from `Combat.sync` before the fight check:
  - Area change: despawn, then a spawn check.
  - A gap over `combat.jump_seconds`: no turns, only spawn checks.
  - Turns: once per `act_seconds` (a `carry` budget), in id order. Stop when the player is down. Cap: `max_turns_per_sync`.
  - AI by state:
    - `hidden`: spot roll `0.2 + 0.1 × PER`, once, within `spot_radius`; ambush with `hit_bonus` when next to the player or bumped.
    - `idle`: aggro radius. A pack aggroes together; a territorial monster aggroes only near `home`.
    - `hostile`: flee when scared, below `flee_below`, or when half its pack is gone. Give up past `lose_radius` or `chase_turns` minus the speed bonus: a crab hides again, a Razorbeak goes home, a goblin flees. Otherwise attack when adjacent, or ranged throw (chance), or step along `Pathfind.path` (avoid monsters, NPCs, the player).
    - `flee`: step away. Despawn at the edge or an exit (`routed += 1`).
    - `home`: walk back, then `idle`.
  - Call `Combat.join` when a monster turns hostile.
- **Spawns** (`enemies.json` `spawns`; validate in `CombatDb`):
  - `crab_valley`, `goblins_orchard`, `goblins_hill` (`unless_flags: ["goblin_tribe.leaderless"]`), `razorbeak_nest` (home 21,16).
  - Checked on entering the area and every `spawn.check_minutes`.
  - Cooldown per spawn in `spawn_last`; `min_distance` from the player; cap `max_monsters`.
- **Maps:**
  - `floodplains_south`: zone `razorbeak_nests` [19, 14, 4, 5], object `razorbeak_nest`, `"item": "seed_core"` on the blue fruit trees, 2 `loose_stones` (`item: stone`).
  - `inn_interior`: rolling_pin on the stove, chair on `table` and `chess_table`.
  - `inn_hill`: 1 `loose_stones`.
  - Check every rect and tile against the rows.
- **Interact:** `TAKE` pseudo-action (like `SLEEP`), options get `item`, `Commands.take(object_id)`. `MapDb` validates the object field `item`.
- **Tests:** `unit_monster_sim`, `unit_movement`, `unit_interact`, `unit_map_db`, `sim_combat` (real data; same seed gives the same result; save/load mid-fight gives the same result).
- **Then M5.3:** monster markers in `WorldView` (a hidden crab shows as rock), HP + held item in the HUD, combat lines to the HUD log, keys B / T / X plus a take entry in the E menu, no auto-repeat attacks, knock-out → dialog (`KNOCKOUT` page), character sheet stats, console commands (`attack`, `block`, `throw`, `drop`, `monsters`, `spawn`, `knockout`), `sim_m5_done`, ADR 0010 M5.2/M5.3 sections.

## Gotchas
- Commits and PRs: author Daddy-Ousen only. NO `Co-Authored-By: Claude` trailer, no Claude footer.
- **Line endings:** most `.gd` files are CRLF. When a Python script edits them, read with `newline=''` and write back with the same ending. Never add `\n` text to a CRLF file: a stray `\r` is a GDScript parse error. GUT then SKIPS that script, and the exit code is still 0. Always grep the GUT output for `Parse Error`.
- Use the Write tool (or a scratch .py file) for JSON and long edits; bash heredocs with `'''`, JSON or `\U` paths break in Git Bash. In a Python heredoc, a `\\` + newline becomes a joined line.
- A sleep at 06:00 is a 4 h nap (same day). Tests that sleep right after a new game advance the clock first (`gs.clock.advance(14 * 60)`).
- **Combat tests:** `ToyCombat.db()` (a new db per test; `always_hit` / `never_hit` change its rules). The player is at town 1,2; 2,2 (east) and 1,1 (north) are free. `ToyMaps.walk_to` does not avoid monsters (a bump attacks), so place monsters off the path.
- `Combat.in_danger` = fight on + a hostile monster. A fight only ends when no monster is hostile or fleeing. In M5.1 a fleeing monster never leaves (no AI yet).
- Class names in data already have brackets (`[Innkeeper]`). Do not add more.
- `const X := SomeClassName` does not parse in Godot 4.7 test scripts. Use the class name directly.
- New `.gd` files get `.gd.uid` files. Commit them.
- Godot class cache goes stale after checkout/merge or new class_name: run `godot --headless --path game --import`, then the tests.
- Python 3.14; use `python -X utf8` in Git Bash when printing book text.
- Python tests: `python -m unittest discover -s tools/tests` (no `-t .`). The "ERROR chapters/9.00.json" line in its output is an expected fixture.
- GUT `.import` files show as modified: line endings only. Do not commit them.
- New game starts on day 8. Tests that need day 1 use `ToyData` (its rules set `start_minute` 360). NPC toy world: `ToyNpcs` (guard, baker, farmer). Toy shop has a `cot` (sleep, no actions) at 0,1.
- A GUT run with a broken script can hang. Use `timeout 500 godot ...` in Git Bash.
- `bool("yes")` is a script error in Godot 4.7; check `x is bool` first.
- The `Session` autoload exists in GUT runs. Tests that use it call `Session.set_state(GameState.new_game(...))` first.
- NPCs stand next to the start and in the inn. Tests that need an empty spot clear `gs.npcs.npcs` or place the player elsewhere. Test walks use `ToyMaps.walk_to` (goes around NPCs).
- Godot text → float is never exact. Keep all save floats going through `SaveCodec`.
- Screenshots: a scratch scene in `game/` (set `Session` state, add `world/main.tscn`), then `godot --path game --write-movie <scratch>/x.png --fixed-fps 5 --quit-after 3 res://<scene>.tscn`. Delete scratch files before committing.
- `SystemDialog` buttons connect deferred; tests call `dialog.choose(...)` directly.

## Active files
`game/core/{combat,combat_state,combat_db,stats,commands,night,movement,actions,player_state,game_state,save_migrations,data_db,skill_system}.gd`, `game/data/{enemies,items,rules}.json`, `game/test_support/toy_combat.gd`, `game/tests/{unit_combat,unit_combat_db,unit_stats}.gd`, `docs/adr/0010-m5-combat.md`.

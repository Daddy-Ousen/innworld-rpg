# Handoff

## Just done (2026-09-24, branch `feat/m7b-battles`, M7.B big battles)
M7.1 is closed. The user approved it. PR #18 was merged early, so the review fixes and the "reviewed" marks came in a follow-up, PR #19. Tag `m7.1-done` is on fa01971.
The user picked the full battle upgrade (option 1) and decided that an NPC at 0 HP is down, not dead.
Commits on the branch:
- `17672ac` feat(core): NPC HP, monster targets, helpers, stage waves, save v9.
- `5e572e1` feat(tools): the validator checks waves.
- `e14466f` feat(ui): HP bars, fewer labels, the helper edge, fallen NPCs, "Foes left".
- `5c74748` fix(core): fighters pick a foe they can reach; new `sim_big_battle`.
- `2bc271f` data(book1): the raid as 40 Goblins in 4 waves.
- `b163c5f` feat(ui): label de-overlap.
- Docs: ADR 0013, ROADMAP, progress.

Tests: GUT 468/468 (49 scripts), Python 39, validator 0 errors. `sim_big_battle`: about 5 ms per command.
Screenshots (scratch scene, deleted): at 12:00 on day 21, wave 0 of 8 Goblins at the door with Erin; "Foes left: 40"; the labels no longer overlap.

## Waiting on the user
- Review the M7.B PR. Balance point: a player who only waits is knocked out about a minute into the raid, so the raid is hard to win at 20 HP. Options: Klbkch comes earlier, fewer foes per wave, or leave it to play-testing.
- After review: merge, and tag `m7b-done`.
- Old game-data suggestions still open: `[Basic Crafting]`, `[Gatherer]` + `[Detect Poison]`, `[Detect Guilt]`, `[Dangersense]`, `[Spearmaster]`, `[Swordslayer]`, `[Bar Fighting]`, `[Unerring Throw]`, `[Iron Scales]`, `[Alcohol Brewing]`.

## Next
- M7.2: canon 1.35R–1.44R. Read the batch first (3 Explore readers for a first pass, then read every chapter yourself). 1.34 ends with Erin about to go exploring. Big fights can now use `stage.waves`, `helpers` and `allies` (allies need an `npc_behaviour` entry). Ask before any schema change.
- Known limits: NPCs never leave the area when they flee; Klbkch ignores `klbkch.spares_goblins`; a stage is tied to one map area; the raid balance.

## Gotchas
- Commits and PRs: author Daddy-Ousen only. NO `Co-Authored-By: Claude` trailer, no Claude footer.
- **Line endings:** most `.gd`, `.json` and `.md` files are CRLF in the working copy (`core.autocrlf=true`). New files written by the Write tool are LF: fine, but never mix endings in one file. Patch CRLF files with a Python script that converts to LF, edits, and converts back.
- **GUT exits 0 even when a script has a parse error** (it skips the script). Always grep the output for `Parse Error` and check the script/test count (now 49 / 468).
- Write GUT output to `$TMP` or the scratchpad, not next to the repo.
- A test that makes `push_error` on purpose must call `assert_push_error("text")` once per error.
- Tests that build `world/main.tscn` or the title set `switch_scene = false`. Saves in tests go to `Session.save_dir` (= `user://test_saves` via the pre-run hook); clear slots in `before_each`.
- Bash heredocs can turn tabs into spaces. For edits with tabs, use the Edit tool or a scratch `.py` file.
- **Monster tests:** `ToyCombat.db()` gives a new db per test. `ToyCombat.freeze(db)` stops monster turns. `to_arena(gs, db, pos)` places the player in the open 14×9 arena. Set the goblin `ranged.chance` to 0 unless a test wants stones. Pack members must be within `lose_radius` of the player or they give up at once.
- `Combat.in_danger` = fight on + a hostile monster.
- A sleep at 06:00 is a 4 h nap (same day). Tests that sleep right after a new game advance the clock first (`gs.clock.advance(14 * 60)`).
- Class names in data already have brackets (`[Innkeeper]`). Do not add more.
- `const X := SomeClassName` does not parse in Godot 4.7 test scripts. Use the class name directly.
- New `.gd` files get `.gd.uid` files. Commit them.
- Godot class cache goes stale after checkout/merge or new class_name: run `godot --headless --path game --import`, then the tests.
- Python 3.14; use `python -X utf8` in Git Bash when printing book text.
- Python tests: `python -m unittest discover -s tools/tests` (no `-t .`). The "ERROR chapters/9.00.json" line in its output is an expected fixture.
- GUT `.import` files show as modified: line endings only. Do not commit them.
- New game starts on day 8 at 06:00. Tests that need day 1 use `ToyData`. NPC toy world: `ToyNpcs`. Toy shop has a `cot` (sleep, no actions) at 0,1.
- A GUT run with a broken script can hang. Use `timeout 500 godot ...` in Git Bash.
- `bool("yes")` is a script error in Godot 4.7; check `x is bool` first.
- The `Session` autoload exists in GUT runs. Tests that use it call `Session.set_state(GameState.new_game(...))` first.
- NPCs stand next to the start and in the inn. Tests that need an empty spot clear `gs.npcs.npcs` or place the player elsewhere. Test walks use `ToyMaps.walk_to`.
- Godot text → float is never exact. Keep all save floats going through `SaveCodec`.
- Screenshots: a scratch scene in `game/` (script picks a mode from an env var, adds `world/main.tscn` or the title), then `godot --path game --write-movie <scratchpad>/x.png --fixed-fps 5 --quit-after 3 res://<scene>.tscn`. Delete scratch files (and their `.uid`) before committing.
- **Python file writes:** always pass `encoding='utf-8'` to `open()`.
- `sim_m5_done` depends on the seed (2). If spawn data or monster AI change, it may need a new seed.
- On day 8 the inn's canon location name is "The abandoned inn on the hill". From day 13 the flag `wandering_inn.named` is set; the name field does not change.
- Canon JSON files are LF. Director: an anonymous role (`prefer: []`) always fills; a dead NPC in `requires.alive` is a hard fail (no substitute), so leave an NPC out of `alive` if a stand-in may take the role.
- Canon review flow: write events as `candidate`, run the validator (it also checks 7-word copies against `canon/raw`), user reviews, then flip to `reviewed`.
- `SystemDialog` buttons connect deferred; tests call `dialog.choose(...)` directly.

- **M6.4 hooks:** action records keep `context`; hooks match on it (`Director.did`). The log keeps 7 days only, so hook `days` span ≤ 7 (validator error).
- A new game clears `world.news` after the day 1–7 director run (the player was not there).
- Day 8 now has local news, so the first night's System dialog starts with a Local News page.
- `sed -i` in Git Bash turns a CRLF file into LF. Fine (git stores LF), but do not mix endings in one file.
- `git status` may list LF-converted files with no real diff; `git add` clears them.

- **M6.5 stages:** a canon event `stage` puts its foes on the map (Stage.check after every command). Tests that play the inn on day 9 from 09:00 meet the Chieftain; tests about something else set `gs.world.staged["b1.erin_kills_chieftain"] = 9` first (see `sim_m4_done`).
- NPCs near a hostile monster react (NpcReact) instead of walking their goals. Toy NPC + monster tests: `ToyNpcs.combat_db(events)`.
- Fight record context now has `killed` (bool). Hooks can match it.
- The Python heredoc trick breaks on `\` line continuations (they get joined). For GDScript edits with `\`, use the Edit tool or a scratch `.py` file.
- One GUT script only: `-gdir=res://tests -gselect=<script name>` (plain `-gtest` still ran everything here).

- **M7.1:** check that an event id is free before you use it (the validator flags duplicates across files). `Commands.wait(gs, db, s)` takes seconds. A day-21 test at the inn at noon meets the raid; tests about something else set `gs.world.staged["b1.klbkch_dies_defending_erin"] = 21`. The fight record's `enemy` is the most dangerous foe type in the fight.
- New chapter JSON files written by the Write tool are LF; `npcs.json`, `locations.json`, `enemies.json` and `npc_behaviour.json` are CRLF in the working copy. Patch those with a Python script that keeps CRLF.

- **M7.B:**
  - Roster NPC entries have `hp` (-1 = full) and `down`. Read `down` with `n.get("down", false)`, because tests build NPC dicts by hand.
  - Monsters now attack fighting NPCs and helpers (`Combat.monster_target`), so seeded fight sims can change when NPC fight stats change. Erin's damage is kept low so the player still takes part in the Chieftain fight (`sim_m6_done`).
  - A stage with `waves` keeps the fight going until all waves came (`Stage.waves_left`).
  - Wave allies must have an `npc_behaviour` entry.
  - The bash heredoc broke on a long Python script with `\` line continuations: write the script with the Write tool into the scratchpad, then run it.

## Active files
`game/core/{combat,combat_state,monster_sim,npc_react,npc_sim,npc_roster,stage,canon_db,combat_db,behaviour_db,save_migrations,game_state,data_db}.gd`, `game/world/{world_view,main}.gd`, `game/ui/hud.gd`, `game/data/{rules,npc_behaviour}.json`, `game/data/canon/book1/chapters/1.29.json`, `game/tests/{unit_battle,sim_big_battle,sim_goblin_raid,unit_world_view,unit_game_state}.gd`, `tools/validate_data.py`, `docs/adr/0013-m7b-big-battles.md`.

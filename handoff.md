# Handoff

## Just done (2026-09-24, branch `data/book1-1.55-1.63`)
M7.4, the last Book 1 batch, is written and waiting for the user's review (PR open).
- `feat(director)`: new `effects.revive` (user choice). Director, CanonDb, validator + tests.
- `fix(npc)`: a stage ally brought in during a long step (jump) stays in the fight if its goal is in another area.
- `data(book1)`: 21 `candidate` events in `1.55R.json` … `1.63.json` (days 38–41). New NPCs `bird`, `tekshia`, `hawk`; updated `klbkch`, `toren`, `olesm`, `sostrom`, `selys` and location `liscor_dungeon` (all `candidate`). 7 new enemy types. Two stages with `change` hooks on day 39: east gate (`player_held_the_gate`) and inn hill (`player_fought_skinner`).
- Docs: ADR 0012 M7.4 section, ROADMAP, progress.
- GUT 499/499 (52 scripts), Python 40, validator 0 errors, `sim_canon_book1` to day 41 with drift 0. Checked on screen (inn hill fight).

## Waiting on the user
- Review the M7.4 events (timeline guesses, likely links, the Tekshia name conflict, balance). Then flip every `candidate` in M7.4 files and changed NPC/location entries to `reviewed`, accept ADR 0012 M7.4, tick ROADMAP M7.4 and M7, merge, tag `m7.4-done` and `m7-done`.
- After the merge: update the README status table and counts (Book 1 done: 1.00–1.63, days 1–41, 151 events, 50 NPCs, 44 locations).
- 1.16.json still has one old `candidate` event from M6.4 (left as is).
- Old game-data suggestions still open: `[Basic Crafting]`, `[Gatherer]` + `[Detect Poison]`, `[Detect Guilt]`, `[Dangersense]`, `[Spearmaster]`, `[Swordslayer]`, `[Bar Fighting]`, `[Unerring Throw]`, `[Iron Scales]`, `[Alcohol Brewing]`, `[Loud Voice]`.

## Next
- After review: M8 (see `docs/ROADMAP.md`).
- Known limits: no fear aura or poison; fights only on the hill and at the east gate; allies rush in and go down fast (balance); Gazi, Tkrn, Ksmvr, the thief, Tekshia and Hawk have no map schedule.

## Gotchas
- Commits and PRs: author Daddy-Ousen only. NO `Co-Authored-By: Claude` trailer, no Claude footer.
- **Line endings:** most `.gd`, `.json` and `.md` files are CRLF in the working copy (`core.autocrlf=true`). New files written by the Write tool are LF: fine, but never mix endings in one file. Patch CRLF files with a Python script that converts to LF, edits, and converts back (see the scratch `patch_*.py` pattern).
- **GUT exits 0 even when a script has a parse error** (it skips the script). Always grep the output for `Parse Error` and check the script/test count (now 51 / 486).
- Write GUT output to `$TMP` or the scratchpad, not next to the repo.
- A test that makes `push_error` on purpose must call `assert_push_error("text")` once per error.
- Tests that build `world/main.tscn` or the title set `switch_scene = false`. Saves in tests go to `Session.save_dir` (= `user://test_saves` via the pre-run hook); clear slots in `before_each`.
- Bash heredocs can turn tabs into spaces. For edits with tabs, use the Edit tool or a scratch `.py` file.
- **Monster tests:** `ToyCombat.db()` gives a new db per test. `ToyCombat.freeze(db)` stops monster turns. `to_arena(gs, db, pos)` places the player in the open 14×9 arena. Set the goblin `ranged.chance` to 0 unless a test wants stones. Pack members must be within `lose_radius` of the player or they give up at once.
- A monster added with `ToyCombat.spawn` gets many turns on the first `Commands.wait` unless you call `Commands.settle` first (the combat clock catches up).
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
- Screenshots: a scratch scene in `game/` (script builds the state, calls `Session.set_state`, then adds `world/main.tscn`), then `godot --path game --write-movie <scratchpad>/x.png --fixed-fps 5 --quit-after 3 res://<scene>.tscn`. Delete scratch files (and their `.uid`) before committing.
- **Python file writes:** always pass `encoding='utf-8'` to `open()`.
- `sim_m5_done` depends on the seed (2). If spawn data or monster AI change, it may need a new seed.
- On day 8 the inn's canon location name is "The abandoned inn on the hill". From day 13 the flag `wandering_inn.named` is set; the name field does not change.
- Canon JSON files are LF. Director: an event fires on the first day of its window when its conditions hold; an anonymous role (`prefer: []`) always fills; a dead NPC in `requires.alive` is a hard fail (no substitute), so leave an NPC out of `alive` if a stand-in may take the role.
- Never link two canon entities (e.g. the 1.00 Dragon and Teriarch) unless the text says so (user rule).
- Canon review flow: write events as `candidate`, run the validator (it also checks 7-word copies against `canon/raw`), user reviews, then flip to `reviewed`. Summaries and stage notes are at most 300 characters.
- `SystemDialog` buttons connect deferred; tests call `dialog.choose(...)` directly.
- **M6.4 hooks:** action records keep `context`; hooks match on it (`Director.did`). The log keeps 7 days only, so hook `days` span ≤ 7 (validator error).
- A new game clears `world.news` after the day 1–7 director run (the player was not there).
- `sed -i` in Git Bash turns a CRLF file into LF. Fine (git stores LF), but do not mix endings in one file.
- **M6.5 stages:** a canon event `stage` puts its foes on the map (Stage.check after every command). Tests that play the inn on day 9 from 09:00 meet the Chieftain; tests about something else set `gs.world.staged["b1.erin_kills_chieftain"] = 9` first (see `sim_m4_done`). The same goes for day 21 (`b1.klbkch_dies_defending_erin`) and now day 28 at 19–21 in the inn (`b1.adventurers_attack_goblins_at_inn`).
- NPCs near a hostile monster react (NpcReact) instead of walking their goals. Only `guard` NPCs and stage allies fight.
- Fight record context has `killed` (bool). Hooks can match it. The record's `enemy` is the most dangerous foe type in the fight.
- **M7.B:** roster NPC entries have `hp` (-1 = full) and `down`; read `down` with `n.get("down", false)`. Monsters attack the nearest of player / fighting NPC / helper, so a player who stands back is not hit. A stage with `waves` keeps the fight going until all waves came. Wave allies must have an `npc_behaviour` entry; a wave with `after_seconds` 0 comes at once.
- Check that an event id is free before you use it (the validator flags duplicates across files). `Commands.wait(gs, db, s)` takes seconds.
- `npcs.json`, `locations.json`, `enemies.json` and `npc_behaviour.json` are CRLF in the working copy. Patch them with a Python script that keeps CRLF.
- To test one commit alone: stage its files, `git stash push --keep-index --include-untracked`, run the suite, commit, `git stash pop`.
- **M7.3:** the Goblin battle stage is on `floodplains_south`, day 35, 08–11 (`b1.rags_kills_the_feathered_chieftain`). Tests that play the Floodplains that morning meet it; mark it staged if a test is about something else. The Horns (`calruz`, `ceria_springwalker`, `gerial`, `sostrom`) stand in the inn 06–09 and 18–23 from day 36.
- Screenshot trick still works (scratch `game/shot_*.gd/.tscn`, `main.switch_scene = false`); delete the files after.
- **M7.4:** on day 39 two stages open: `liscor_gate` 18–23 and `inn_hill` 20–24. A test that stands at the east gate (the new-game start) on the evening of day 39 starts a fight, and then `ToyCanon.sleep_through` loops forever (sleep is refused in danger). Put the player in the inn first, or mark the events staged (`b1.skinner_leads_the_dead_into_liscor`, `b1.rags_kills_skinner`).
- **Revive:** `effects.revive` sets an NPC alive again (after `kill`). Klbkch is dead on days 21–39 and alive from night 39. Calruz, Ceria and Olesm are alive in the data but off the map (`*.missing` flags).
- GUT `-gtest=` does not limit the run here; use `-gdir=res://tests -gselect=<script name>` to run one script.
- Scratch screenshot scene for M7.4 was `game/shot_skinner.gd/.tscn` (deleted): sleep to day 38, advance 14 h, place on `inn_hill`, wait.

## Active files
`game/data/canon/book1/chapters/1.55R.json` … `1.63.json`, `game/data/canon/book1/{npcs,locations}.json`, `game/data/{enemies,npc_behaviour}.json`, `game/core/{director,canon_db,npc_sim}.gd`, `tools/validate_data.py`, `game/tests/{sim_skinner_night,sim_canon_book1,unit_director,unit_battle,unit_combat_db,sim_player_hooks}.gd`, `docs/adr/0012-m7-rest-of-book1.md`, `docs/ROADMAP.md`, `README.md` (after the merge).

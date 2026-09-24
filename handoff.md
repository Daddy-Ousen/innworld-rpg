# Handoff

## Just done (2026-09-24, branch `data/book1-1.35-1.44`, M7.2 canon 1.35R–1.44R)
PR #20 (M7.B) was merged by the user; tag `m7b-done` is on 1376815 and pushed.
M7.2 is done and reviewed by the user (2026-09-24). The PR is open (see progress.md / `gh pr list`).
Review answers: timeline, Relc (no evening visits yet) and the brawl hook as proposed. Teriarch is NOT confirmed to be the 1.00 Dragon, so `teriarch` and `teriarch_cave` are separate entries; `cave_dragon` and `dragon_backup_lair` are unchanged.

Commits on the branch:
- `ea32938` fix(core): indoors, a fleeing monster walks to the nearest exit (the inn corners trapped them; the day-21 raid too).
- `3cc1f83` data(book1): 24 events in 10 chapter files (days 24–33), NPCs, locations, 2 stage-only enemies, `toren` behaviour, the inn brawl stage + hook, tests.
- Docs commit, then the review commit (Teriarch split, all M7.2 entries `reviewed`, docs).

Tests: GUT 478/478 (50 scripts), Python 39, validator 0 errors. `sim_canon_book1` LAST_DAY 33, drift 0.

## Waiting on the user
- Review and merge the M7.2 PR, then tag `m7.2-done`.
- Old game-data suggestions still open: `[Basic Crafting]`, `[Gatherer]` + `[Detect Poison]`, `[Detect Guilt]`, `[Dangersense]`, `[Spearmaster]`, `[Swordslayer]`, `[Bar Fighting]`, `[Unerring Throw]`, `[Iron Scales]`, `[Alcohol Brewing]`, `[Loud Voice]`.
- Note: 1.16.json still has one old `candidate` event from M6.4 (not part of M7.2; left as is).

## Next
- M7.3: canon 1.45–1.54. Read every chapter first. Toren is named in 1.46. Winter comes (`liscor.winter_coming`). Ryoka heads to Esthelm; the Horns go for the Liscor ruins (`liscor_dungeon`).
- Known limits: a player can still kill a fleeing adventurer; NPC name labels overlap when NPCs stand close; the thief and Ksmvr have no map schedule; the raid balance (M7.B).

## Gotchas
- Commits and PRs: author Daddy-Ousen only. NO `Co-Authored-By: Claude` trailer, no Claude footer.
- **Line endings:** most `.gd`, `.json` and `.md` files are CRLF in the working copy (`core.autocrlf=true`). New files written by the Write tool are LF: fine, but never mix endings in one file. Patch CRLF files with a Python script that converts to LF, edits, and converts back (see the scratch `patch_*.py` pattern).
- **GUT exits 0 even when a script has a parse error** (it skips the script). Always grep the output for `Parse Error` and check the script/test count (now 50 / 478).
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

## Active files
`game/data/canon/book1/chapters/1.35R.json` … `1.44R.json`, `game/data/canon/book1/{npcs,locations}.json`, `game/data/{enemies,npc_behaviour}.json`, `game/core/monster_sim.gd`, `game/tests/{sim_inn_brawl,sim_canon_book1,unit_monster_sim,unit_combat_db,sim_player_hooks}.gd`, `docs/adr/0012-m7-rest-of-book1.md`, `docs/ROADMAP.md`.

# Handoff

## Just done (2026-09-24, branch `data/book1-1.26-1.34`, M7.1)
M6 is merged (PR #17; tags `m6.5-done`, `m6-done`). The user approved the M7 plan: 4 canon batches (ADR 0012). For the day-21 raid the user chose a `change` hook (Klbkch still dies).
- Canon 1.26R–1.34: 9 new chapter files (19 events, days 19–23, all `candidate`), 11 new NPCs, 7 new locations. `pawn` is named, `beilmark` is a Gnoll, `klbkch` has the tag `prognugator` (these 3 are back to `candidate`).
- The raid is `b1.klbkch_dies_defending_erin` (1.29). `b1.goblin_raid_on_inn` already exists in 1.02. Its stage is in `inn_interior` 12–14, with the raid leader + 5 Goblins at the door and Erin as ally. Hook `player_fought_raid` → change.
- `enemies.json`: `goblin_raid_leader` (stage only) and spawn `crab_hill_unpatrolled` (when `liscor_watch.no_inn_patrols`).
- `npc_behaviour.json`: `pawn` visits the inn 18–22 after `pawn.named`; `relc` has `unless_flags` `relc.blames_erin`.
- Tests: `sim_canon_book1` LAST_DAY 23 + 2 tests; new `sim_goblin_raid` (5 tests); `sim_m6_done` pre-stages the raid; counts updated in `sim_player_hooks`, `unit_combat_db`, `sim_canon_fights`. GUT 447/447 (47 scripts), Python 36, validator 0 errors.
- Checked on screen: at 12:00 on day 21, 6 Goblins at the inn door, with Erin next to them.
- Docs: ROADMAP M7 section, ADR 0012, progress.

## Waiting on the user
- Review the M7.1 events in PR #18 (https://github.com/Daddy-Ousen/innworld-rpg/pull/18). Flagged conflicts:
  - Ryoka's Guild is in Remendia (1.20R), Wales (1.26R) and Celum (1.33R).
  - 1.32R says "a week ago" but also "three days".
  - The Goblin grave is "several hundred feet" away (1.30) or "a mile" (1.31).
  - The new spawn is a Rock Crab stand-in.
- After review: flip the events to `reviewed`, merge, and tag `m7.1-done`.
- Old game-data suggestions still open: `[Basic Crafting]`, `[Gatherer]` + `[Detect Poison]`, `[Detect Guilt]`, `[Dangersense]`, `[Spearmaster]`, `[Swordslayer]`, `[Bar Fighting]`, `[Unerring Throw]`, `[Iron Scales]`, `[Alcohol Brewing]`.

## Next
- M7.2: canon 1.35R–1.44R. Read the batch first (3 Explore readers worked well for the first pass; then read every chapter yourself). 1.34 ends with Erin about to go exploring, so expect a fight away from the inn. Ask before any schema change.
- Known limits: name labels overlap; Klbkch ignores `klbkch.spares_goblins`; NPCs never leave the area when they flee; monsters attack only the player; the raid stage is inside the inn only; Rags's band is not on the map.

## Gotchas
- Commits and PRs: author Daddy-Ousen only. NO `Co-Authored-By: Claude` trailer, no Claude footer.
- **Line endings:** most `.gd`, `.json` and `.md` files are CRLF in the working copy (`core.autocrlf=true`). New files written by the Write tool are LF: fine, but never mix endings in one file. Patch CRLF files with a Python script that converts to LF, edits, and converts back.
- **GUT exits 0 even when a script has a parse error** (it skips the script). Always grep the output for `Parse Error` and check the script/test count (now 47 / 447).
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

## Active files
`game/data/canon/book1/chapters/{1.26R,1.27R,1.28A,1.29,1.30,1.31,1.32R,1.33R,1.34}.json`, `game/data/canon/book1/{npcs,locations}.json`, `game/data/{enemies,npc_behaviour}.json`, `game/tests/{sim_goblin_raid,sim_canon_book1,sim_m6_done,sim_canon_fights,sim_player_hooks,unit_combat_db}.gd`, `docs/adr/0012-m7-rest-of-book1.md`, `docs/ROADMAP.md`.

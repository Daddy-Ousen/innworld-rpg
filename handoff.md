# Handoff

## Just done (2026-09-24, branch `feat/m6.5-canon-fights`)
M6.5 canon fights + the M6 slice check. User picks (2026-09-24, all my recommendations): Chieftain fight = `change`; sparing record + Rags hook needs a kill; NPCs have no HP; tune levels. `stage` schema and save v8 approved.
- Commits: `cdc54fa` feat(core) stages, NpcReact, sparing, save v8; `c5c9c0e` feat(tools) validator stage checks; `a9fd5b4` data(book1) Chieftain stage + hook, `goblin_chieftain`, Rags hook `killed: true`, `sim_canon_fights`; `acef921` data(rules) levels 40 / 1.25; `8fba05e` test(sim) `sim_m6_done`; `db22be9` fix(core) stage allies join from anywhere in the area; then docs.
- New core: `game/core/stage.gd`, `game/core/npc_react.gd`. Changed: `canon_db`, `combat_db`, `combat` (`settle_if_over`, `killed`, `spare_foe`), `combat_state` (monster `stage`), `monster_sim` (`in_hours`, `taken`), `npc_sim`, `commands`, `world_state` (`staged`), `save_migrations` (7 → 8), `data_db` (rules keys `npc.react`, `combat.spare_tags`).
- Tests: GUT 440/440 (46 scripts), Python 36, validator 0 errors. `sim_m6_done` (seed 1): [Cook] level 6 by day 22, Chieftain won on day 9, event changed.
- Checked on screen (screenshots): the Chieftain marker "Goblin Chieftain 20/20" at the inn door at 09:00; Erin walks over and fights next to the player.

## Waiting on the user
- Review PR #17 (https://github.com/Daddy-Ousen/innworld-rpg/pull/17): the stage line, the hook news line, the Chieftain stats (guesses), the new level curve. Then merge and tag `m6.5-done` and `m6-done` on the merge commit.
- Old game-data suggestions still open: `[Basic Crafting]`, `[Gatherer]` + `[Detect Poison]`, `[Detect Guilt]`, `[Dangersense]`, `[Spearmaster]`, `[Swordslayer]`, `[Bar Fighting]`, `[Unerring Throw]`, `[Iron Scales]`, `[Alcohol Brewing]`.

## Next
- M7: rest of Book 1 (ROADMAP "Later"). Plan it first; ask about chapter split and schema needs.
- Known limits to consider (ADR 0011 M6.5): name labels overlap when markers stand side by side; Klbkch ignores `klbkch.spares_goblins`; NPCs never leave the area when they flee; monsters attack only the player.

## Gotchas
- Commits and PRs: author Daddy-Ousen only. NO `Co-Authored-By: Claude` trailer, no Claude footer.
- **Line endings:** most `.gd`, `.json` and `.md` files are CRLF in the working copy (`core.autocrlf=true`). New files written by the Write tool are LF: fine, but never mix endings in one file. Patch CRLF files with a Python script that converts to LF, edits, and converts back.
- **GUT exits 0 even when a script has a parse error** (it skips the script). Always grep the output for `Parse Error` and check the script/test count (now 46 / 440).
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

## Active files
`game/core/{stage,npc_react,combat,combat_db,combat_state,monster_sim,npc_sim,commands,canon_db,world_state,save_migrations,data_db}.gd`, `game/data/{enemies,actions,rules}.json`, `game/data/canon/book1/chapters/{1.14,1.25}.json`, `game/tests/{unit_stage,unit_npc_react,unit_combat,sim_canon_fights,sim_m6_done,sim_m4_done}.gd`, `game/test_support/{toy_npcs,toy_combat}.gd`, `tools/validate_data.py`, `docs/adr/0011-m6-vertical-slice.md`.

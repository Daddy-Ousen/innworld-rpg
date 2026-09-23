# Handoff

## Just done (2026-09-24, branch `feat/m6.4-hooks-news`, PR #16)
M6.4 Player hooks + news. Schema approved by the user 2026-09-24 (my picks: `changed` outcome, 3 cases below, all local news heard).
- Commits: `22858d6` feat(director) core + UI + validator, `368cc80` data(book1), `a665603` docs.
- Core: `Director` hooks (`_player_hook` for cancel/mutate before `requires`; `change` in `_fire`), `happened()`, outcome `changed`; `WorldState.news` + `add_news` / `news_since`; `Night` result `news`; records keep `context`; save v7 (`_migrate_6_to_7`); `ActionLog.from_dict` turns whole-number context floats back to ints; `GameState.new_game` clears news of days 1–7.
- UI: `SystemMessages.NEWS` page "Local News"; journal: your mark on the story, drift line, 7 days of news, scroll (PgUp/PgDn); console `news`.
- Data: 13 `news` lines (days 8–19); hooks on `b1.erin_screams_off_rock_crab` (mutate → new `b1.player_beat_rock_crab_first`, candidate), `b1.inn_first_regulars` (change), `b1.rags_brings_goblins_to_eat` (cancel).
- Validator: news/hooks checks, `--actions` (auto: `game/data/actions.json`), copy check on news. Python 32 OK.
- Tests: `unit_player_hooks`, `sim_player_hooks` (real fights by bump attack with frozen monsters + always hit; real cooking at the stove at inn_interior 20,2). GUT 408/408 (42 scripts). Validator 0 errors.
- Journal and News page checked on screen (screenshots).

## Waiting on the user
- Review PR #16 (https://github.com/Daddy-Ousen/innworld-rpg/pull/16): the 13 news lines, the 3 hook news lines, the new node `b1.player_beat_rock_crab_first` (candidate). Then merge and tag `m6.4-done` on the merge commit.
- Old game-data suggestions still open: `[Basic Crafting]`, `[Gatherer]` + `[Detect Poison]`, `[Detect Guilt]`, `[Dangersense]`, `[Spearmaster]`, `[Swordslayer]`, `[Bar Fighting]`, `[Unerring Throw]`, `[Iron Scales]`, `[Alcohol Brewing]`.

## Next
- M6.5 Canon fights (the Chieftain at the inn), sparing Goblins, NPCs flee monsters, guards fight; `sim_m6_done`. Needs a schema OK for `stage` (ask first). A canon fight can end in a hook result (the player's fight record).
- Open balance note: levels after the first class are slow (check in M6.5).

## Gotchas
- Commits and PRs: author Daddy-Ousen only. NO `Co-Authored-By: Claude` trailer, no Claude footer.
- **Line endings:** most `.gd`, `.json` and `.md` files are CRLF in the working copy (`core.autocrlf=true`). New files written by the Write tool are LF: fine, but never mix endings in one file. Patch CRLF files with a Python script that converts to LF, edits, and converts back.
- **GUT exits 0 even when a script has a parse error** (it skips the script). Always grep the output for `Parse Error` and check the script/test count (now 42 / 408).
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

## Active files
`game/core/{director,world_state,canon_db,night,actions,action_log,game_state,save_migrations}.gd`, `game/ui/{journal.gd,journal.tscn,system_messages.gd,console_commands.gd}`, `game/data/canon/book1/chapters/{1.12,1.14–1.18,1.21,1.24,1.25}.json`, `game/tests/{unit_player_hooks,sim_player_hooks,sim_canon_book1,unit_system_messages,unit_journal}.gd`, `tools/validate_data.py`, `docs/adr/0011-m6-vertical-slice.md`.

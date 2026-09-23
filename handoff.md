# Handoff

## Just done (2026-09-23, branch `feat/m6.1-play-loop`)
M6 plan approved (5 sub-modules, see `docs/ROADMAP.md` M6 and ADR 0011). M6.1 Play loop is done and tested (GUT 382/382, 40 scripts). No schema or save change.
- `core/save_slots.gd`: 3 manual slots + autosave, `info`, `label`, `latest`, `load_game` (runs `Commands.settle`).
- `ui/session.gd`: `save_dir`, `fresh`, `start_new_game`, `save_slot`, `load_slot`, `autosave`.
- `ui/title_menu.tscn` is the main scene (`project.godot`). `ui/pause_menu.tscn` (Esc), `ui/slot_list.tscn` (shared), `ui/journal.tscn` (J).
- `world/main.gd`: Esc / J keys, welcome page for a fresh game, autosave when the System dialog closes, `quit_to_title`, autosave on window close. `switch_scene = false` in tests.
- `ui/system_messages.gd`: `WELCOME`, `HINTS`, `welcome_page()`. Character sheet shows the focus name (`Journal.focus_name`).
- `data/classes.json`: all `offer_threshold` ÷ 3 (rounded to 5). First offer on night 3 (day 11). `sim_m4_done` MAX_DAYS 3.
- `test_support/gut_pre_run.gd` + `.gutconfig.json` `pre_run_script`: tests save to `user://test_saves`.
- Tests: `unit_save_slots`, `unit_journal`, `unit_play_loop`.

## Waiting on the user
- Review PR #13 (https://github.com/Daddy-Ousen/innworld-rpg/pull/13), merge, then tag `m6.1-done` on the merge commit.
- Old game-data suggestions still open: `[Basic Crafting]`, `[Gatherer]` + `[Detect Poison]`, `[Detect Guilt]`, `[Dangersense]`, `[Spearmaster]`, `[Swordslayer]`, `[Bar Fighting]`, `[Unerring Throw]`, `[Iron Scales]`.

## Next: M6.2 Canon 1.15–1.20R (branch `data/book1-1.15-1.20`)
- Same flow as M4.1: read one chapter at a time from `canon/raw/book1/` (017_1-15.txt … 022_1-20R.txt), propose events / NPCs / locations in own words, the user reviews.
- Rough day cues found in planning: 1.15 ≈ day 9–10, 1.16 next day, 1.17 wakes (≈ day 12), 1.18, 1.19R / 1.20R are Ryoka in Celum (tier 1 + rumor). Confirm while reading.
- Extend `sim_canon_book1` to the new last day, drift 0. Validator 0 errors.
- Then M6.3 (1.21, 1.22, 1.23A, 1.24, Interlude – King Edition, 1.25). 1.22 has Erin's [Innkeeper Level 10] (chapter `system` log).
- M6.4 needs a schema OK first: `hooks` and `news` on canon events (ADR 0011 plan). M6.5 needs a schema OK for `stage` (monster on a map in an event window).

## Gotchas
- Commits and PRs: author Daddy-Ousen only. NO `Co-Authored-By: Claude` trailer, no Claude footer.
- **Line endings:** most `.gd`, `.json` and `.md` files are CRLF in the working copy (`core.autocrlf=true`). New files written by the Write tool are LF: fine, but never mix endings in one file. Patch CRLF files with a Python script that converts to LF, edits, and converts back.
- **GUT exits 0 even when a script has a parse error** (it skips the script). Always grep the output for `Parse Error` and check the script/test count (now 40 / 382).
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
- On day 8 the inn's canon location name is "The abandoned inn on the hill".
- `SystemDialog` buttons connect deferred; tests call `dialog.choose(...)` directly.

## Active files
`game/core/save_slots.gd`, `game/ui/{session,title_menu,pause_menu,slot_list,journal,system_messages,character_sheet}.gd`, `game/world/main.gd`, `game/world/main.tscn`, `game/data/classes.json`, `game/tests/{unit_save_slots,unit_journal,unit_play_loop,sim_m4_done}.gd`, `docs/adr/0011-m6-vertical-slice.md`.

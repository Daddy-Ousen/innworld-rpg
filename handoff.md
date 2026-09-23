# Handoff

## Just done (2026-09-24, branch `data/book1-1.21-1.25`, not pushed)
M6.2 merged (PR #14), tag `m6.2-done`. M6.3 data drafted, one chapter at a time. New entries are `status: "candidate"`.
- `1.21.json`: inn_first_regulars d15, selys_sews_pads d16.
- `1.22.json`: erin_traps_acid_flies d16, erin_beats_pisces_at_chess d16, pisces_saves_erin_from_flies d17; system: Erin [Innkeeper] 10, [Alcohol Brewing], [Dangersense].
- `1.23A.json`: antinium_uncover_ruin_door d14 (secret dig by Klbkch).
- `1.24.json`: liscor_ruins_discovered (tier 1 + rumor, window 17–18 guess), goblins_hunt_rock_crab d18, erin_serves_acid_flies d18.
- `interlude_king_edition.json`: king_of_destruction_wakes d18 (tier 1 + rumor).
- `1.25.json`: queen_allows_workers_visit d19, rags_brings_goblins_to_eat d19, workers_learn_chess d19; system: Olesm level (number unknown), Rags and pawn [Tactician].
- New NPCs: terbore, free_queen, pawn (id is a guess), flos_reimarch, orthenon. New locations: liscor_dungeon, chandrar, reim.
- Updated (were `reviewed`): rags name "Littlest Goblin" → "Rags"; olesm name → "Olesm Swifttail"; klbkch note (Klbkchhezeim, Prognugator); selys note ([Fast Stitching]); 1.11 `bully` role now prefers `terbore`.
- `sim_canon_book1`: LAST_DAY 19, counts 62 / 27 / 30, new test `test_killing_the_free_queen_keeps_workers_home`. GUT 384/384 (40 scripts), validator 0 errors, Python 26 OK.

## Waiting on the user (M6.3 review)
1. Dungeon discovery as tier 1 + rumor (so the player hears it now) or tier 2 with no rumor until M6.4 news. My pick: tier 1 + rumor.
2. King of Destruction rumor reaches Liscor on day 18. My pick: keep.
3. Worker id `pawn` (a guess, like `rags` was). My pick: keep.
4. Canon ends on day 19, not "about day 22" as the roadmap says. 1.26R and later are next (M7). My pick: accept day 19.
After OK: `candidate` → `reviewed`, tick M6.3 in `docs/ROADMAP.md` and `progress.md`, push, PR, then tag `m6.3-done` on the merge commit.
Old game-data suggestions still open: `[Basic Crafting]`, `[Gatherer]` + `[Detect Poison]`, `[Detect Guilt]`, `[Dangersense]`, `[Spearmaster]`, `[Swordslayer]`, `[Bar Fighting]`, `[Unerring Throw]`, `[Iron Scales]`, and now `[Alcohol Brewing]`.

## Next after M6.3
- M6.4 Player hooks + news (save v7). Ask for a schema OK first: `hooks` and `news` on canon events (ADR 0011 plan).
- M6.5 Canon fights + `sim_m6_done`. Needs a schema OK for `stage`.

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
- On day 8 the inn's canon location name is "The abandoned inn on the hill". From day 13 the flag `wandering_inn.named` is set; the name field does not change.
- Canon JSON files are LF. Director: an anonymous role (`prefer: []`) always fills; a dead NPC in `requires.alive` is a hard fail (no substitute), so leave an NPC out of `alive` if a stand-in may take the role.
- Canon review flow: write events as `candidate`, run the validator (it also checks 7-word copies against `canon/raw`), user reviews, then flip to `reviewed`.
- `SystemDialog` buttons connect deferred; tests call `dialog.choose(...)` directly.

## Active files
`game/data/canon/book1/{npcs,locations}.json`, `game/data/canon/book1/chapters/1.15–1.20R.json`, `game/tests/sim_canon_book1.gd`. Older: `game/core/save_slots.gd`, `game/ui/{session,title_menu,pause_menu,slot_list,journal,system_messages,character_sheet}.gd`, `game/world/main.gd`, `game/world/main.tscn`, `game/data/classes.json`, `game/tests/{unit_save_slots,unit_journal,unit_play_loop,sim_m4_done}.gd`, `docs/adr/0011-m6-vertical-slice.md`.

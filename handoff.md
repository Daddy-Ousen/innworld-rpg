# Handoff

## Just done (2026-09-25)
- M8.3 canon batch written, tested green, committed, pushed, and opened as [PR #30](https://github.com/Daddy-Ousen/innworld-rpg/pull/30) on branch `data/book2-2.19G-2.26` (off `main`, which already has M8.2 merged plus a docs housekeeping commit — progress.md archive split, context-discipline notes in CLAUDE.md). Chapters: 2.19G, 2.20, 2.21, 2.22K, 2.23, 2.24T, 2.25, 2.26, 1.00C, 1.01C.
- New book2 NPCs (21): Rockgaw, Lyonette, Brunkr, Halrac, Typhenous, Revi, Ulrien, Jelaqua, Seborn, Moore, Dreshhi, Mars, Takhatres, Trey, Teresa, Drevish, Tom, Richard, Emily, Wilen. (Dropped a duplicate "Orthenon" NPC draft — he already exists in book1.)
- New locations (5): `goblin_mountain_lair`, `jawbreaker_camp`, `empire_of_sands`, `rhir`, `blighted_lands`.
- New enemy `silverfang_gnoll_warrior` in `game/data/enemies.json`.
- Two new stages: `b2.frost_faeries_accept_the_banquet` (2.21, `kind: "scene"` at inn_hill) and `b2.battle_at_the_wandering_inn` (2.26, combat stage, foes vs. Erin/Toren/Ceria/Pisces then Relc/Klbkch/Zevara reinforcements) plus a `player_fought_gnoll_warband` hook on the battle.
- `sim_canon_book2.gd` `LAST_DAY` bumped 47 -> 55. Bumped two hardcoded baseline counts that needed +1 from this batch: `unit_combat_db.gd` enemies 18->19, `sim_player_hooks.gd` hooks 10->11.
- Validator 0 errors (`--all`). GUT 533/533 (56 scripts), Python 51/51.
- Not yet committed or pushed. `docs/ROADMAP.md` and `progress.md` updated with the M8.3 summary; this file is the snapshot for the commit/PR step.

## Waiting on the user
- None right now. M8.3 data is written, tested, green — ready to commit and open a PR, same pattern as M8.1/M8.2 (data commit, then a `docs:` commit noting the PR).

## Next
1. Wait for user review of [PR #30](https://github.com/Daddy-Ousen/innworld-rpg/pull/30).
2. After review/merge: `data(book2): mark canon 2.19G-2.26 reviewed` commit, ADR entry if any design call needs recording, tag `m8.3-done` on the merge commit, sync local `main`.
3. Then start M8.4 (canon 2.27G-2.38) on a fresh branch off `main`.

## Gotchas
- Commits and PRs: author Daddy-Ousen only. NO `Co-Authored-By: Claude` trailer, no Claude footer.
- **Rhir is real** (user correction this session): the 1.00C/1.01C interlude (Tom, the Blighted Lands) is on a real continent, Rhir, that matters in later books - not a throwaway separate-world aside. Model it as normal canon data, not flavor-only. See memory `lore-rhir-real-continent`. The book text itself never uses the word "Rhir" (that's later-canon knowledge), so the `rhir` location entry is `confidence: "guess"` with a note; `blighted_lands` (the region within it) is `confidence: "confirmed"` since the text does name it.
- **"Aunt" is a Gnoll honorific, not a family line**: both Tkrn (existing NPC) and Brunkr (new, M8.3) call Krshia "aunt" - the book never says they're blood kin to each other or to her. Don't record them as related. Same spirit as the existing "never merge two canon entities unless the book says so" rule.
- **Book 2 starts on day 41.** `sim_canon_book1` counts `b1.` events only; its rumor count covers all books. `sim_canon_book2` sleeps to day 40 once in `before_all` and copies the save per test. `LAST_DAY` is now 55 (M8.3); bump it again for M8.4.
- **Stage `kind: "scene"`** (M8.2): a stage with no `foes`, instead `"npcs": [{"npc", "pos"}]` moved onto the map with no fight; every npc needs an `npc_behaviour` entry or it silently does nothing, and `Stage.scene_npcs_here` holds them in place for the stage's hours.
- **Toren's snow wall overlay** (`inn_hill`, active once `wandering_inn.snow_wall` is set, from day 44): blocks `y=13, x=10-14` and `x=17-25` (gap at the door, `x=15-16`). Any new stage foe/ally/npc position on `inn_hill` from day 44 on must dodge those tiles, or `sim_winter`'s `test_winter_data_is_sound` catches it. M8.3's inn-battle foes ended up at `y=15-16` instead.
- **Enemy `escape`:** `Combat.damage_monster` removes the monster when its hp drops below `escape.below` x hp (routed, not killed; returns false). Callers must not touch the monster after a false return without `c.monsters.has(id)`. (Not used in M8.3 - Brunkr and the Silverfang warband have no `escape`; the fight's canon resolution is carried entirely in event effects, not required kills.)
- **A stage only supports two mechanical sides** (foes vs. allies+helpers). M8.3's inn battle has three real factions in the book (Silverfang Gnolls, Griffon Hunt briefly mistaking the brawl for a monster fight, the Watch/Horns defending) plus the Halfseekers de-escalating it - only the Gnolls-vs-defenders split is on the map; Griffon Hunt and the Halfseekers are narrated only (effects/news/summary), following the same precedent as Zevara being off-map in the M8.1 Gazi stage.
- **Line endings are mixed and file-by-file.** Checked directly again this session: all book2 chapter files (including the new M8.3 ones), `npcs.json`, `locations.json` and `enemies.json` are CRLF. Patch a CRLF file with a Python script that converts to LF, edits, converts back; watch tab vs. space depth carefully (id keys and field keys are NOT at the depth you'd guess from `Read` tool output - check real byte offsets with a small python snippet before writing a replace, don't eyeball it).
- **GUT exits 0 even when a script has a parse error** (it skips the script). Grep the output for `Parse Error` and check the script/test count (56 scripts / 533 tests as of M8.3).
- Write GUT output to the scratchpad, not next to the repo. `-gselect=<script name>` runs one script. Re-run `godot --headless --path game --import` after adding new `class_name`s (not needed this session - data only, no new GDScript classes).
- A test that makes `push_error` on purpose must call `assert_push_error("text")` once per error.
- Tests that build `world/main.tscn` or the title set `switch_scene = false`. Saves in tests go to `Session.save_dir`.
- **Monster tests:** `ToyCombat.db()` gives a new db per test. `ToyCombat.freeze(db)` stops monster (and helper) turns; NPC allies still act. `ToyCombat.always_hit(db)`.
- Python 3.14; use `python -X utf8` when printing book text. Python tests: `python -m unittest discover -s tools/tests` (51).
- Validator: `python tools/validate_data.py game/data/canon/book2` (earlier books load by default) or `--all game/data/canon`. Summaries <= 300, news <= 200, rumor <= 200 chars; no 7-word copies of the book. It checks depends_on/role/location ids against known data (catches typos) but does NOT check enemy ids exist or map positions are walkable/off-overlay - only the game/GUT tests catch those.
- New game starts on day 8 at 06:00. A sleep at 06:00 is a 4 h nap.
- Never link two canon entities unless the text says so (user rule). Calruz stays missing.

## Active files
None open right now - M8.3 data is written and tested; ready to commit.

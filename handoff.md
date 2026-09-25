# Handoff

## Just done (2026-09-25)
- PR #29 (M8.2) merged to `main` at c229bf7. Tagged `m8.2-done`, tag pushed.
- Local `main` synced. Working branch `data/book2-2.10T-2.18` still checked out (now behind `main` by the merge commit only — merge, not rebase, needed if continuing on it, but M8.3 should start a fresh branch off `main`).

## Waiting on the user
- None right now.

## Next
1. Start M8.3 canon 2.19G–2.26 + 1.00C/1.01C (same per-batch ask pattern: timeline, stage/hook, new NPCs) — branch off `main` (which now has M8.2).
2. Delete local branch `data/book2-2.10T-2.18` once confirmed merged and no longer needed (currently still checked out, working tree clean).

## Gotchas
- Commits and PRs: author Daddy-Ousen only. NO `Co-Authored-By: Claude` trailer, no Claude footer.
- **Book 2 starts on day 41** (the call, 2.00, 2.01 are day 41). `sim_canon_book1` counts `b1.` events only; its rumor count covers all books. `sim_canon_book2` sleeps to day 40 once in `before_all` and copies the save per test. `LAST_DAY` is now 47 (M8.2); bump it again for M8.3.
- **Stage `kind: "scene"` (new, M8.2):** a stage with no `foes`, instead `"npcs": [{"npc", "pos"}]` moved onto the map with no fight. Every npc in the list needs an `npc_behaviour` entry (same rule as fight allies) or it silently does nothing. `NpcSim.advance_to` holds scene npcs in place for the stage's hours (`Stage.scene_npcs_here`) — without that fix an npc placed by a scene walks off again on the very next tick, back toward its normal schedule goal.
- **Gazi stage:** day 42, 13–17 on `ruins_entrance`. Tests that stand there that afternoon meet it. The allies drive her off in about a minute; a test that needs the player's attack record puts the player next to her first (`sim_gazi_attack._next_to_gazi`).
- **Enemy `escape`:** `Combat.damage_monster` removes the monster when its hp drops below `escape.below` × hp (routed, not killed; returns false). Callers must not touch the monster after a false return without `c.monsters.has(id)`.
- **Line endings are mixed and file-by-file, not a clean per-book rule** — check with `open(path,'rb').read()[:200]` before trusting an old note (this one included). Checked directly this session: `game/data/canon/book2/{npcs,locations}.json` and all book2 chapter files are CRLF; `game/data/canon/book1/npcs.json` is CRLF but `game/data/canon/book1/chapters/*.json` is LF. Patch a CRLF file with a Python script that converts to LF, edits, converts back; watch for tabs, since Bash heredocs can turn them into spaces (use the Edit tool or a scratch `.py` file instead).
- `enemies.json` uses a compact style (several fields per line); the book2 canon files use a similar hand-built "short things inline, long things multi-line" JSON style (no formatter script exists for it — `pretty_json.py` in this session's scratchpad approximates it if you need to regenerate).
- **GUT exits 0 even when a script has a parse error** (it skips the script). Grep the output for `Parse Error` and check the script/test count (60 scripts / 533 tests as of M8.2).
- Write GUT output to the scratchpad, not next to the repo. `-gselect=<script name>` runs one script. Re-run `godot --headless --path game --import` after adding new `class_name`s or the class cache goes stale.
- A test that makes `push_error` on purpose must call `assert_push_error("text")` once per error.
- Tests that build `world/main.tscn` or the title set `switch_scene = false`. Saves in tests go to `Session.save_dir`.
- **Monster tests:** `ToyCombat.db()` gives a new db per test. `ToyCombat.freeze(db)` stops monster (and helper) turns; NPC allies still act. `ToyCombat.always_hit(db)`.
- Python 3.14; use `python -X utf8` when printing book text. Python tests: `python -m unittest discover -s tools/tests` (51).
- Validator: `python tools/validate_data.py game/data/canon/book2` (earlier books load by default) or `--all game/data/canon`. Summaries ≤ 300, news ≤ 200, rumor ≤ 200 chars; no 7-word copies of the book.
- New game starts on day 8 at 06:00. A sleep at 06:00 is a 4 h nap.
- Never link two canon entities unless the text says so (user rule). Calruz stays missing. The `liscor_dungeon` ↔ `death_beyond_death` link (M8.2) is the one exception the user explicitly confirmed — it's recorded, but the game does not let the player walk between them yet.
- **Winter (M8.W):** from the morning of day 43 the player loses 1 HP per 30 min outdoors (floor 1). Fairies spawn with `gs.rng` on entering outdoor maps in winter. Toren's snow wall overlay on `inn_hill` (from day 44) blocks part of the map — any new stage or npc position there must avoid its rects, or `sim_winter`'s `test_winter_data_is_sound` catches it.
- **Overlays are a cache on MapDb** (`overlay_key`), shared by every game on the same db. Call `db.maps.sync_flags(gs.flags)` before walkability checks on a game that did not just run a command.
- Check that an event id is free before you use it (the validator flags duplicates across books too).

## Active files
None open right now — ready for a fresh M8.3 branch.

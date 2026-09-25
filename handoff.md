# Handoff

## Just done (2026-09-25)
- M8.1 merged (PR #26). The user reviewed the 21 events (timeline, Invrisil, Gazi balance as proposed).
- Branch `data/book2-m8.1-reviewed`: book2 events, NPCs and places flipped to `reviewed`; ADR 0014 M8.1 accepted; ROADMAP M8.1 ticked.

## Waiting on the user
- Merge the review PR; then tag `m8.1-done` on the merge commit.
- M8.W Winter details: cold rules (how much HP, what counts as warm, firewood?) and Frost Fairies on the map (what they do). Ask before building. Save change expected.

## Next
1. M8.W Winter (branch `feat/m8w-winter`): snow look from flag `izril.winter` (set day 42), cold rules, fairies.
2. M8.2 canon 2.10T–2.18 (starts with Toren's POV; Relc said the inn "exploded" at the end of 2.09).

## Gotchas
- Commits and PRs: author Daddy-Ousen only. NO `Co-Authored-By: Claude` trailer, no Claude footer.
- **Book 2 starts on day 41** (the call, 2.00, 2.01 are day 41). `sim_canon_book1` counts `b1.` events only; its rumor count covers all books. `sim_canon_book2` sleeps to day 40 once in `before_all` and copies the save per test.
- **Gazi stage:** day 42, 13–17 on `ruins_entrance`. Tests that stand there that afternoon meet it. The allies drive her off in about a minute; a test that needs the player's attack record puts the player next to her first (`sim_gazi_attack._next_to_gazi`).
- **Enemy `escape`:** `Combat.damage_monster` removes the monster when its hp drops below `escape.below` × hp (routed, not killed; returns false). Callers must not touch the monster after a false return without `c.monsters.has(id)`.
- **Line endings:** most `.gd`, `.json` and `.md` files are CRLF in the working copy. Canon JSON (book1 and book2) is LF. Patch CRLF files with a Python script that converts to LF, edits, converts back. Watch backslash-newline in Python heredocs: they turned into a literal `\r` once in `combat.gd` (parse error). Use the Edit tool for lines with a trailing `\`.
- `enemies.json` uses a compact style (several fields per line). `npcs.json`, `locations.json` (book1), `enemies.json`, `npc_behaviour.json`, `rules.json` are CRLF.
- **GUT exits 0 even when a script has a parse error** (it skips the script). Grep the output for `Parse Error` and check the script/test count (now 54 / 508).
- Write GUT output to the scratchpad, not next to the repo. `-gselect=<script name>` runs one script.
- A test that makes `push_error` on purpose must call `assert_push_error("text")` once per error.
- Tests that build `world/main.tscn` or the title set `switch_scene = false`. Saves in tests go to `Session.save_dir`.
- Bash heredocs can turn tabs into spaces. For edits with tabs, use the Edit tool or a scratch `.py` file.
- **Monster tests:** `ToyCombat.db()` gives a new db per test. `ToyCombat.freeze(db)` stops monster (and helper) turns; NPC allies still act. `ToyCombat.always_hit(db)`.
- Godot class cache goes stale after checkout/merge or new class_name: run `godot --headless --path game --import`, then the tests.
- Python 3.14; use `python -X utf8` when printing book text. Python tests: `python -m unittest discover -s tools/tests` (47).
- Validator: `python tools/validate_data.py game/data/canon/book2` (earlier books load by default) or `--all game/data/canon`. Summaries ≤ 300, news ≤ 200, rumor ≤ 200 chars; no 7-word copies of the book.
- New game starts on day 8 at 06:00. A sleep at 06:00 is a 4 h nap.
- Never link two canon entities unless the text says so (user rule). Calruz stays missing (M8.1 user choice).
- Screenshots: scratch `game/shot_*.gd` + `.tscn` (script builds the state, `Session.set_state`, adds `world/main.tscn` with `switch_scene = false`), then `godot --path game --write-movie <scratchpad>/x.png --fixed-fps 5 --quit-after 3 res://shot_x.tscn`. Delete the files (and `.uid`) after.
- **M7.4:** on day 39 two stages open (`liscor_gate` 18–23, `inn_hill` 20–24). A test at the east gate that evening starts a fight.
- NPCs near a hostile monster react (NpcReact). Only `guard` NPCs and stage allies fight. Wave allies need an `npc_behaviour` entry with a `combat` block.
- Check that an event id is free before you use it (the validator flags duplicates across books too).

## Active files
`game/data/canon/book2/**`, `game/data/maps/{ruins_entrance,floodplains_south}.json`, `game/data/{enemies,npc_behaviour,rules}.json`, `game/core/{combat,combat_db}.gd`, `game/tests/{sim_canon_book2,sim_gazi_attack,sim_canon_book1,sim_player_hooks,unit_combat_db}.gd`, `tools/validate_data.py`, `docs/adr/0014-m8-book2-and-celum.md`, `docs/ROADMAP.md`.

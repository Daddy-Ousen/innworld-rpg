# Handoff

## Just done (2026-09-23, branch `feat/m3-world-director`)
M3 world director is done and tested (not pushed yet):
- Canon data moved: `canon/events/` → `game/data/canon/` (user choice). CLAUDE.md, validator help, DESIGN §6, ADR 0004 note updated.
- `game/core/canon_db.gd` — loads every `data/canon/book*`, run order, dependents, alt-only events. `DataDb.load_dir()` sets `db.canon`.
- `game/core/world_state.gd` — `gs.world`: NPC fates, relationships, event status, history, drift, `last_day`. Save v3 + migration.
- `game/core/director.gd` — night step 5. Rules in ADR 0005.
- `Clock.sleep_length` / `wake_day` (director runs up to the day before the wake day).
- `Commands.kill_npc`, `Commands.set_flag`; console `kill`, `flag`, `history`, `drift`.
- `rules.json` new `director` section.
- Tests: GUT 156/156 (19 scripts), exit 0. Python 26/26. Validator 0 errors on `game/data/canon/book1`.
- ADR 0005 written; ROADMAP M3 ticked.

## Waiting on the user
- Push branch and open PR. After merge: `git tag m3-done`.
- Game-data suggestions from M2 still open: `[Basic Crafting]`, `[Gatherer]` + `[Detect Poison]`, `[Detect Guilt]`, `[Dangersense]`, `[Spearmaster]`, `[Swordslayer]`.

## Next (M4, 2D world)
- Tilemap (inn, Floodplains part, Liscor gate + market), grid movement, NPC schedules + utility AI, System message UI.
- Player interactions should call `Commands.set_flag` / `Commands.kill_npc` to bend canon.
- Open canon questions: id `rags` (guess), id `high_passes` (guess), Pisces = 1.04 bone thief (`likely`).
- Continue event extraction from 1.10 onward into `game/data/canon/book1/chapters/`.

## Gotchas
- Commits: author Daddy-Ousen only. NO `Co-Authored-By: Claude` trailer.
- A sleep at 06:00 is a 4 h nap (same day). Loop on `gs.world.last_day`, not on sleep count (`ToyCanon.sleep_through`).
- `const X := SomeClassName` does not parse in Godot 4.7 test scripts. Use the class name directly.
- New `.gd` files get `.gd.uid` files. Commit them.
- Godot class cache goes stale after checkout/merge: run `godot --headless --path game --import`, then the tests.
- Python 3.14; use `python -X utf8` in Git Bash when printing book text.
- Python tests: `python -m unittest discover -s tools/tests` (no `-t .`).
- Day 1 = Erin's arrival. 1.00–1.09 = days 1–7.
- GUT `.import` files show as modified: line endings only. Do not commit them.

## Active files
`game/core/{canon_db,world_state,director}.gd`, `game/test_support/toy_canon.gd`, `game/tests/{unit_director,sim_divergence,sim_canon_book1}.gd`, `docs/adr/0005-m3-world-director.md`.

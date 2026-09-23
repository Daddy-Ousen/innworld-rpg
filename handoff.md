# Handoff

## Just done (2026-09-23, branch `data/book1-1.10-1.14`)
M4 plan approved (5 sub-modules). Plan file: `C:\Users\rhasa\.claude\plans\lets-start-m4-plan-lucky-treehouse.md`.
M4.1 done: canon 1.10, Great Ritual interlude, 1.11–1.14 — 12 events, NPCs `selys krshia lism belsc drassi`, 8 locations, all reviewed by the user. `sim_canon_book1` runs to day 9 (`LAST_DAY`), drift 0. PR #5 open: https://github.com/Daddy-Ousen/innworld-rpg/pull/5
Checks: validator 0 errors, GUT 156/156, Python 26/26.

## Decision (user, 2026-09-23): player arrives on day 8
The player is one of the Earthers of the Great Ritual (night 7). New game starts on day 8 outside the Liscor east gate.
M4.2 must: set the start in `rules.json` (`world.start` area/pos + a day-8 start minute), and run the director for days 1–7 at new game so canon history exists. Erin walks through the same gate on day 8 (`b1.erin_walks_to_liscor`). Check tests that assume a day-1 start (`sim_30_days`, `sim_canon_book1`, `unit_night`); toy dbs keep their own rules.

## Waiting on the user
- Merge PR #5. Then tag `m4.1-done`.
- Old game-data suggestions still open: `[Basic Crafting]`, `[Gatherer]` + `[Detect Poison]`, `[Detect Guilt]`, `[Dangersense]`, `[Spearmaster]`, `[Swordslayer]`, `[Bar Fighting]`, `[Unerring Throw]`, `[Iron Scales]`.

## Timeline (days)
Day 1 = Erin's arrival. 1.00–1.09 = days 1–7. 1.10 + interlude = day 7 / night 7. 1.11–1.12 = day 8. 1.13–1.14 = day 9.

## Next
- M4.2 world grid core on branch `feat/m4.2-world-grid` (see plan): `tiles.json`, `maps/*.json`, `MapDb`, `PlayerState`, `Movement`, `Interact`, save v4, console `where/look/go/use`, ADR 0006.

## Gotchas
- Commits: author Daddy-Ousen only. NO `Co-Authored-By: Claude` trailer.
- Heredocs with long JSON in Git Bash failed once (quote parse error). Use the Write tool for JSON files.
- A sleep at 06:00 is a 4 h nap (same day). Loop on `gs.world.last_day`, not on sleep count.
- `const X := SomeClassName` does not parse in Godot 4.7 test scripts. Use the class name directly.
- New `.gd` files get `.gd.uid` files. Commit them.
- Godot class cache goes stale after checkout/merge: run `godot --headless --path game --import`, then the tests.
- Python 3.14; use `python -X utf8` in Git Bash when printing book text.
- Python tests: `python -m unittest discover -s tools/tests` (no `-t .`).
- GUT `.import` files show as modified: line endings only. Do not commit them.

## Active files
`game/data/canon/book1/{npcs,locations}.json`, `game/data/canon/book1/chapters/1.1*.json`, `game/data/canon/book1/chapters/interlude_the_great_ritual.json`, `game/tests/sim_canon_book1.gd`, `docs/ROADMAP.md`.

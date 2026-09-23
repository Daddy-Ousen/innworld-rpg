# Handoff

## Just done (2026-09-23, branch `data/book1-1.10-1.14`, not committed)
M4 plan approved (5 sub-modules). Plan file: `C:\Users\rhasa\.claude\plans\lets-start-m4-plan-lucky-treehouse.md`.
M4.1 canon extraction for 1.10, Interlude – The Great Ritual, 1.11–1.14:
- New chapter files: `game/data/canon/book1/chapters/{1.10,interlude_the_great_ritual,1.11,1.12,1.13,1.14}.json` — 12 events, all `status: "candidate"`.
- `npcs.json`: new `selys`, `krshia`, `lism`, `belsc`, `drassi` (candidate). Updated notes on `relc` (+[Sergeant]), `rags`, `pisces`.
- `locations.json`: new `liscor_east_gate`, `liscor_adventurers_guild`, `liscor_mages_guild`, `liscor_plaza`, `krshia_stall`, `lism_stall`, `goblin_grave`, `blighted_kingdom` (candidate).
- `game/tests/sim_canon_book1.gd`: `LAST_DAY := 9`; counts raised.
- ROADMAP M4 split into M4.1–M4.5 + "Done when". progress.md updated.
- Checks: validator 0 errors, GUT 156/156, Python 26/26.

## Waiting on the user
- Review the M4.1 candidate data. After OK: set `status` → `reviewed` in the new records, run validator + tests, commit `data(book1): events, NPCs and locations for 1.10-1.14` and `docs: split M4 into sub-modules`, push, open PR.
- Design question raised: the Great Ritual (night 7) brings many Earthers to the world. Should the player arrive then (day 8) instead of day 1?
- Old M2 game-data suggestions still open: `[Basic Crafting]`, `[Gatherer]` + `[Detect Poison]`, `[Detect Guilt]`, `[Dangersense]`, `[Spearmaster]`, `[Swordslayer]`. New: `[Bar Fighting]`, `[Unerring Throw]`, `[Iron Scales]`.

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

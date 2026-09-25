# Handoff

## Just done (2026-09-25)
- M8.6 (economy + travel) is built on branch `feat/m8.6-economy-travel`. Full detail: `docs/adr/0015-m8.6-economy-travel.md`.
- User choices this session: no sleep outdoors except at a camp; indoors/camp floor = half heal, a bed = full heal; hunger lowers max HP (-10% per hungry night, floor 50%); road 2 x 10 h through `road_camp`.
- GUT 580/580 (61 scripts), validator 0 errors (`--all`), Python 51/51. Checked on screen (shop menu, coins on HUD, Hungry, bag menu, sleep refused outdoors).

## Waiting on the user
- Review and merge the M8.6 PR. Then tag `m8.6-done` on the merge commit.

## Next
1. After merge: update `progress.md` (PR number, merge commit, tag).
2. M8.7: final canon batches (3 interludes + 2.39-2.48, Erin in Celum, Octavia). `sim_canon_book2` `LAST_DAY` bumps then.

## Gotchas
- Commits and PRs: author Daddy-Ousen only. NO `Co-Authored-By: Claude` trailer, no Claude footer.
- **Never use `sed -i` in Git Bash on repo files** - it strips CRLF. Patch with Python on bytes, or the Edit tool. All repo text files are CRLF. A Python helper that keeps line endings: write `patch(path, [(old, new)])` that detects `\r\n` first. Do NOT normalise whole folders: book1 chapter JSON files are LF on disk.
- New `class_name` scripts need `godot --headless --path game --import` once, or other scripts fail to parse them.
- `-gtest=` is ignored by this GUT setup; use `-gselect=<script name> -gdir=res://tests` to run one script.
- Sleep: `Commands.sleep(gs, db, bed := "")`. Outdoors (not a `camp` map) it is refused and returns {}. A loop that sleeps "until day N" never ends if the sleep is refused: tests and `ToyCanon.sleep_through` use `Rest.ANYWHERE` ("*"). Console: `sleep *`.
- Toy dbs (`ToyData`, `unit_data_db`) erase `rules.economy`: no hunger, sleep anywhere. Real-db tests have hunger on: long sims get lower max HP unless fed.
- Hunger only counts a sleep into a new day (a 06:00 sleep is a nap). Tests that check hunger wait to 22:00 first.
- Screenshots: a throwaway scene in `game/_scratch/` run with `godot --path game res://_scratch/shot.tscn`. Delete `game/_scratch` before committing.
- GUT API: `assert_signal_not_emitted`. GUT exits 0 even on a parse error - grep for `Parse Error` and check the script count (61 / 580 now).
- **Rhir is real** - see memory `lore-rhir-real-continent`. "Aunt" is a Gnoll honorific. Calruz stays missing. Never link two canon entities unless the text says so.
- Book 2 starts on day 41. `sim_canon_book2` `LAST_DAY` is 67; no bump until M8.7.
- Stage `kind: "scene"`: every npc placed needs an `npc_behaviour` entry. Halrac has none yet.
- Validator: `python tools/validate_data.py --all game/data/canon`. It does not check maps, economy or walkable positions - only GUT does.

## Active files
- `game/core/economy.gd`, `game/core/rest.gd`, `game/data/economy.json`, `game/data/maps/road_camp.json`.

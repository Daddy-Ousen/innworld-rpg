# Handoff

## Just done (2026-09-23, branch `feat/m4.4-npc-ai`)
PR #7 merged; tag `m4.3-done` pushed. M4.4 NPC schedules + utility AI is done and tested (ADR 0008):
- Data: `game/data/npc_behaviour.json` (14 NPCs; off-map places `liscor` and `wilds` with entry tiles), rules `npc`.
- Core: `behaviour_db.gd` (load + validate), `utility_ai.gd`, `npc_roster.gd` (`GameState.npcs`), `npc_sim.gd`, `save_codec.gd`. `Pathfind.path` has `avoid`; `Pathfind.route` links maps and off-map places.
- `Commands` sync NPCs after every clock move. New `Commands.wait(seconds)` and `Commands.settle`. Night step 6 in `Night.run`.
- NPCs block the player (`Movement.step` returns `npc`). Talk via `Interact` (NPC options after objects), +1 relationship once a day.
- Save v5: `npcs`, migration 4→5, floats as `"f64:<16 hex>"` (exact). `sim_walk_day` tolerance removed.
- View: blue NPC squares with sharp names; Space waits; "X is in the way." Console: `npcs`, `wait <min>`, `look` shows `&`.
- Tests: GUT 243/243 (new: `unit_utility_ai`, `unit_pathfind`, `unit_behaviour_db`, `unit_npc_sim`, `sim_npc_day`). Python 26/26. Validator 0 errors.
- Manual frames checked: gate 08:03 (Erin walks to Liscor, guards), market 12:06 (Krshia, Lism, Erin, Selys), inn 18:10 (Relc, Klbkch at the table).

## Waiting on the user
- Review PR #8 (https://github.com/Daddy-Ousen/innworld-rpg/pull/8), merge, then tag `m4.4-done`.
- Play it: `godot --path game` (WASD, Space wait, E use/talk, Z sleep, backtick console).
- Old game-data suggestions still open: `[Basic Crafting]`, `[Gatherer]` + `[Detect Poison]`, `[Detect Guilt]`, `[Dangersense]`, `[Spearmaster]`, `[Swordslayer]`, `[Bar Fighting]`, `[Unerring Throw]`, `[Iron Scales]`.

## Timeline (days)
Day 1 = Erin's arrival. 1.00–1.09 = days 1–7. 1.10 + interlude = day 7 / night 7. 1.11–1.12 = day 8 (player arrives). 1.13–1.14 = day 9.

## Next
- M4.5 System message UI on branch `feat/m4.5-system-ui` (plan file: `C:\Users\rhasa\.claude\plans\lets-start-m4-plan-lucky-treehouse.md`): `ui/system_messages.gd` (headless pages), `ui/system_dialog.tscn` (offers with Accept/Decline + confirm), sleep on the inn bed, character sheet (C). ADR number 0009. Then the M4 "Done when" check.

## Gotchas
- Commits and PRs: author Daddy-Ousen only. NO `Co-Authored-By: Claude` trailer, no Claude footer.
- Use the Write tool (or a scratch .py file) for JSON and long edits; bash heredocs with `'''`, JSON or `\U` paths break in Git Bash.
- A sleep at 06:00 is a 4 h nap (same day). Loop on `gs.world.last_day`, not on sleep count.
- `const X := SomeClassName` does not parse in Godot 4.7 test scripts. Use the class name directly.
- New `.gd` files get `.gd.uid` files. Commit them.
- Godot class cache goes stale after checkout/merge or new class_name: run `godot --headless --path game --import`, then the tests.
- Python 3.14; use `python -X utf8` in Git Bash when printing book text.
- Python tests: `python -m unittest discover -s tools/tests` (no `-t .`). The "ERROR chapters/9.00.json" line in its output is an expected fixture.
- GUT `.import` files show as modified: line endings only. Do not commit them.
- New game starts on day 8. Tests that need day 1 use `ToyData` (its rules set `start_minute` 360). NPC toy world: `ToyNpcs` (guard, baker, farmer).
- A GUT run with a broken script can hang. Use `timeout 500 godot ...` in Git Bash.
- `bool("yes")` is a script error in Godot 4.7; check `x is bool` first.
- The `Session` autoload exists in GUT runs. Tests that use it call `Session.set_state(GameState.new_game(...))` first.
- NPCs now stand next to the start (Beilmark at gate 2,13) and in the inn (Erin at 20,2 at 06:00). Tests that need an empty spot clear `gs.npcs.npcs` or place the player elsewhere. Test walks use `ToyMaps.walk_to` (goes around NPCs).
- Godot text → float is never exact. Keep all save floats going through `SaveCodec` (`GameState.to_json` / `from_json` do this).
- Screenshots: `godot --path game --write-movie <scratch>/x.png --fixed-fps 5 --quit-after 3` (a real window opens briefly). A scratch scene can set `Session` state first; delete scratch files before committing.
- Maps were made by a scratch script (not in git). Edit `game/data/maps/*.json` by hand; `unit_map_db` checks widths, exits and reachability.

## Active files
`game/core/{npc_sim,npc_roster,utility_ai,behaviour_db,save_codec,pathfind,commands,movement,interact,night,game_state}.gd`, `game/data/npc_behaviour.json`, `game/world/{main,world_view}.gd`, `game/ui/console_commands.gd`, `game/tests/{sim_npc_day,unit_npc_sim}.gd`, `docs/adr/0008-m4-npc-ai.md`.

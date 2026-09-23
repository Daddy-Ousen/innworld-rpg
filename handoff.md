# Handoff

## Just done (2026-09-23, branch `feat/m4.5-system-ui`)
PR #8 merged; tag `m4.4-done` pushed (annotated, on merge commit 760d4d5). M4.5 System message UI is done and tested (ADR 0009):
- `Night.run` result has `collapsed`, `progress`, `world` sections; `Night.COLLAPSE_LINE`.
- `ui/system_messages.gd` `SystemMessages` (headless): pages in order collapse → levels/skills → rumors → drift → offers (from `gs.progression.offers`) → morning. Confirm page for decline, result page, `is_open` skips withdrawn offers.
- `ui/system_dialog.tscn/.gd` `SystemDialog`: canvas layer 4. Accept / Decline → confirm (Yes / Back). No skip. Console (backtick) blocked while it is open.
- Sleep: Z, or the inn bed (map object `"sleep": true`, user choice). `Interact.SLEEP` + `Interact.can_sleep`; use menu "Sleep (end the day)"; console `use bed sleep`. Collapse on a refused step/wait/use opens the dialog too.
- `ui/character_sheet.tscn/.gd` `CharacterSheet`: C opens, C/Esc closes. HUD hint shows C.
- Tests: GUT 258/258 (new: `unit_system_messages`, `sim_m4_done`). Python 26/26. Validator 0 errors.
- Frames checked: offer dialog in the inn, character sheet after accept.

## Waiting on the user
- Review the M4.5 PR, merge, then tag `m4.5-done` and `m4-done` (M4 is complete after this merge).
- Play it: `godot --path game` (WASD, Space wait, E use/talk/sleep in bed, Z sleep, C character, backtick console).
- Balance note: first offer on day 22 with a plain inn workday (canon: Erin's first night). Tune later (M6).
- Old game-data suggestions still open: `[Basic Crafting]`, `[Gatherer]` + `[Detect Poison]`, `[Detect Guilt]`, `[Dangersense]`, `[Spearmaster]`, `[Swordslayer]`, `[Bar Fighting]`, `[Unerring Throw]`, `[Iron Scales]`.

## Timeline (days)
Day 1 = Erin's arrival. 1.00–1.09 = days 1–7. 1.10 + interlude = day 7 / night 7. 1.11–1.12 = day 8 (player arrives). 1.13–1.14 = day 9.

## Next
- After merge: M5 Combat (see `docs/ROADMAP.md`). Plan it first (plan mode); it will need new schemas (enemies), so ask the user.

## Gotchas
- Commits and PRs: author Daddy-Ousen only. NO `Co-Authored-By: Claude` trailer, no Claude footer.
- Use the Write tool (or a scratch .py file) for JSON and long edits; bash heredocs with `'''`, JSON or `\U` paths break in Git Bash.
- A sleep at 06:00 is a 4 h nap (same day). Tests that sleep right after a new game advance the clock first (`gs.clock.advance(14 * 60)`).
- Class names in data already have brackets (`[Innkeeper]`). Do not add more.
- `const X := SomeClassName` does not parse in Godot 4.7 test scripts. Use the class name directly.
- New `.gd` files get `.gd.uid` files. Commit them.
- Godot class cache goes stale after checkout/merge or new class_name: run `godot --headless --path game --import`, then the tests.
- Python 3.14; use `python -X utf8` in Git Bash when printing book text.
- Python tests: `python -m unittest discover -s tools/tests` (no `-t .`). The "ERROR chapters/9.00.json" line in its output is an expected fixture.
- GUT `.import` files show as modified: line endings only. Do not commit them.
- New game starts on day 8. Tests that need day 1 use `ToyData` (its rules set `start_minute` 360). NPC toy world: `ToyNpcs` (guard, baker, farmer). Toy shop has a `cot` (sleep, no actions) at 0,1.
- A GUT run with a broken script can hang. Use `timeout 500 godot ...` in Git Bash.
- `bool("yes")` is a script error in Godot 4.7; check `x is bool` first.
- The `Session` autoload exists in GUT runs. Tests that use it call `Session.set_state(GameState.new_game(...))` first.
- NPCs stand next to the start and in the inn. Tests that need an empty spot clear `gs.npcs.npcs` or place the player elsewhere. Test walks use `ToyMaps.walk_to` (goes around NPCs).
- Godot text → float is never exact. Keep all save floats going through `SaveCodec`.
- Screenshots: a scratch scene in `game/` (set `Session` state, add `world/main.tscn`), then `godot --path game --write-movie <scratch>/x.png --fixed-fps 5 --quit-after 3 res://<scene>.tscn`. Delete scratch files before committing.
- `SystemDialog` buttons connect deferred; tests call `dialog.choose(...)` directly.

## Active files
`game/ui/{system_messages,system_dialog,character_sheet,interact_menu,console_commands}.gd`, `game/world/main.{gd,tscn}`, `game/core/{night,interact,map_db}.gd`, `game/data/maps/inn_interior.json`, `game/tests/{unit_system_messages,sim_m4_done}.gd`, `docs/adr/0009-m4-system-ui.md`.

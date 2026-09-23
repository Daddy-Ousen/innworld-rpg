# Handoff

## Just done (2026-09-23, branch `feat/m5.3-combat-ui`)
M5.2 was merged (PR #11) and tagged `m5.2-done`.
M5.3 Combat UI is done and tested (GUT 358/358, Python 26/26, validator 0 errors). Presentation only; no schema or save change.
- `world/world_view.gd`: monster markers (edge by state: red hostile, yellow flee, dark calm; a dark ring; body in the enemy colour; label "Goblin 5/8"). A hidden crab is drawn as the `rock` tile, no label. `setup(maps, names, enemies)`.
- `ui/hud.gd` + `hud.tscn`: `%Health` line `HP 14/20 · Held: Chair` (`Hud.health`, `Hud.is_low` at ≤ 25%). Log keeps 6 lines. New key hint.
- `world/main.gd`: bump attack once per key press (`_attack_dir` lock per direction); `B` block, `T` throw at `Combat.nearest_foe`, `X` drop; `use(obj, Interact.TAKE)`; `_finish()` after every command (combat text to the log; if down: `Commands.knock_out` + dialog, log "Everything goes dark.").
- `ui/interact_menu.gd`: "Take <item>" entries. `ui/system_messages.gd`: `KNOCKOUT` page. `ui/character_sheet.gd`: HP + stats.
- `ui/console_commands.gd`: `attack`, `block`, `throw [id]`, `drop`, `use <obj> take`, debug `monsters`, `spawn <enemy> [dx dy]`, `knockout`; HP in `status`; `M` in `look`.
- Core: `Combat.nearest_foe(gs)` only.
- Tests: new `sim_m5_done` (seed 2; plays the M5 "Done when" through the main scene); additions in `unit_world_view`, `unit_system_messages`, `unit_console`, `unit_combat`.
- ADR 0010 M5.3 section. ROADMAP M5.3 ticked.

## Waiting on the user
- Review PR #12 (https://github.com/Daddy-Ousen/innworld-rpg/pull/12), merge, then tag `m5.3-done` and `m5-done` on the merge commit.
- Old game-data suggestions still open: `[Basic Crafting]`, `[Gatherer]` + `[Detect Poison]`, `[Detect Guilt]`, `[Dangersense]`, `[Spearmaster]`, `[Swordslayer]`, `[Bar Fighting]`, `[Unerring Throw]`, `[Iron Scales]`.

## Next: M6 Vertical slice (read `docs/ROADMAP.md` M6 first; plan mode; ask the user)
- The first ~14 in-game days of Book 1 playable end to end; save/load at any point; 3 divergence cases in play.
- Open M6 items from ADR 0010: NPCs react to monsters, guards fight, the Chieftain fight, sparing Goblins, XP tuning (first class offer on day 22 is late; canon Erin gets [Innkeeper] on night 1).
- Known M5 limits: NPCs walk through monsters; monsters do not use exits; fleeing is greedy; throw has no line of sight.
- Save/load from the game screen is only in the debug console (`save` / `load`). M6 needs a real save/load UI.

## Gotchas
- Commits and PRs: author Daddy-Ousen only. NO `Co-Authored-By: Claude` trailer, no Claude footer.
- **Line endings:** most `.gd`, `.json` and `.md` files are CRLF in the working copy (`core.autocrlf=true`). Check with `tr -cd '\r' < file | wc -c` vs `wc -l` (grep `$'\r'` does not work in this Git Bash). The Edit tool keeps CRLF. `cat >>` or a Python write adds LF lines: then normalise the whole file. Never mix endings in one `.gd` file: GUT skips a script with a parse error and still exits 0. Always grep the GUT output for `Parse Error`.
- Bash heredocs can turn tabs into spaces. For edits with tabs, use the Edit tool or a scratch `.py` file.
- **Monster tests:** `ToyCombat.db()` gives a new db per test. `ToyCombat.freeze(db)` stops monster turns. `to_arena(gs, db, pos)` places the player in the open 14×9 arena (wall at x 6, y 3–5; no border walls, so fleeing monsters reach the edge). Set the goblin `ranged.chance` to 0 unless a test wants stones. Pack members must be within `lose_radius` of the player or they give up at once.
- `Combat.in_danger` = fight on + a hostile monster. A fleeing monster keeps the fight on, but it is no danger.
- A sleep at 06:00 is a 4 h nap (same day). Tests that sleep right after a new game advance the clock first (`gs.clock.advance(14 * 60)`).
- Class names in data already have brackets (`[Innkeeper]`). Do not add more.
- `const X := SomeClassName` does not parse in Godot 4.7 test scripts. Use the class name directly.
- New `.gd` files get `.gd.uid` files. Commit them.
- Godot class cache goes stale after checkout/merge or new class_name: run `godot --headless --path game --import`, then the tests.
- Python 3.14; use `python -X utf8` in Git Bash when printing book text.
- Python tests: `python -m unittest discover -s tools/tests` (no `-t .`). The "ERROR chapters/9.00.json" line in its output is an expected fixture.
- GUT `.import` files show as modified: line endings only. Do not commit them.
- New game starts on day 8 at 06:00. Tests that need day 1 use `ToyData` (its rules set `start_minute` 360). NPC toy world: `ToyNpcs` (guard, baker, farmer). Toy shop has a `cot` (sleep, no actions) at 0,1.
- A GUT run with a broken script can hang. Use `timeout 500 godot ...` in Git Bash.
- `bool("yes")` is a script error in Godot 4.7; check `x is bool` first.
- The `Session` autoload exists in GUT runs. Tests that use it call `Session.set_state(GameState.new_game(...))` first.
- NPCs stand next to the start and in the inn. Tests that need an empty spot clear `gs.npcs.npcs` or place the player elsewhere. Test walks use `ToyMaps.walk_to` (goes around NPCs, not monsters: a bump attacks).
- Godot text → float is never exact. Keep all save floats going through `SaveCodec`.
- Screenshots: a scratch scene in `game/` (set `Session` state, add `world/main.tscn`), then `godot --path game --write-movie <scratch>/x.png --fixed-fps 5 --quit-after 3 res://<scene>.tscn`. Delete scratch files before committing.
- **Python file writes:** always pass `encoding='utf-8'` to `open()`. The Windows default (cp1252) writes `·` and `—` as bad bytes; Godot then skips the whole script ("invalid unicode") and GUT still exits 0. Check the test count after each run.
- A knock-out at 06:00 on day 8 is a nap: the player wakes the same day. Tests that want day 9 advance the clock first.
- `sim_m5_done` depends on the seed (2). If spawn data or monster AI change, it may need a new seed: loop seeds with `_play(s)` and pick one that returns "".
- On day 8 the inn's canon location name is "The abandoned inn on the hill".
- `SystemDialog` buttons connect deferred; tests call `dialog.choose(...)` directly.

## Active files
`game/world/{main,world_view}.gd`, `game/world/world_view.tscn`, `game/ui/{hud,interact_menu,system_messages,character_sheet,console_commands}.gd`, `game/ui/hud.tscn`, `game/core/combat.gd`, `game/tests/{sim_m5_done,unit_world_view,unit_system_messages,unit_console,unit_combat}.gd`, `docs/adr/0010-m5-combat.md`.

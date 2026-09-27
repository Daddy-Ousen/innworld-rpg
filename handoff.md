# Handoff

## Just done (2026-09-27)
- PR #45 (M10.5) merged. Tags `m10.5-done` and `m10-done` on merge commit 25b8d94 (pushed). M10 moved to `docs/PROGRESS_ARCHIVE.md`.
- User paused new books. M11 (graphics) planned: ADR 0018, ROADMAP M11. Plan docs committed on branch `feat/m11.0-art-spike` (not pushed yet).
- User choices: 2D top-down pixel art, 32 px cells; free LPC packs (characters + tiles) plus our own edits, with `CREDITS.md`; standard animation first (smooth steps, walk cycle, facing, attack swing, hit flash, damage numbers, knock-out fall).

## Next steps
1. M11.0 Art spike on `feat/m11.0-art-spike`:
   - Find the LPC parts: human body, lizard head + tail (Drake), wolf head + tail (Gnoll), goblin, skeleton. Check each licence. Source: the Universal LPC Spritesheet Generator repo and OpenGameArt. Downloading needs the user's OK (name, source, size).
   - Make `game/assets/{tiles,objects,characters,fx}/` and `CREDITS.md` (author, licence, link per file).
   - `WorldView.TILE` 16 -> 32; camera zoom to match. Tests in `unit_world_view` that use pixel sizes must follow.
   - `liscor_gate` drawn with LPC tiles; the player as a layered LPC character that walks.
   - Screenshot with the `_scratch` scene; the user approves the look.
   - Before M11.1/M11.2: show the user the schema for `tiles.json` `sprite`, object sprites and `appearance.json` (rule 11).
2. Book 5 threads (for later, from M10): Ryoka heading home, Rags heading south, Brunkr's arm, Octavia's penicillin, Toren in the dungeon, Tyrion Veltras has no NPC record, Erin's white coin, Lyonette's oath. Detail in ADR 0017.

## Waiting on the user
- Approve the M11 plan (ADR 0018). Then M11.0 starts.
- Delete old remote branches `data/book4-*` (optional).

## Gotchas
- Commits and PRs: author Daddy-Ousen only. NO `Co-Authored-By: Claude` trailer, no Claude footer.
- **Never use `sed -i` in Git Bash on repo files** - it strips CRLF. All working-copy text files are CRLF (autocrlf=true). Patch with Python on bytes (keep CRLF) or with the Edit tool. Do NOT normalise whole folders.
- `Commands.wait(gs, db, seconds)` takes SECONDS. The clock does pass midnight while awake, but the director only runs on sleep (`Commands.sleep(gs, db, Rest.ANYWHERE)`). Wake time is 6:00, so a stage before 6 is only reachable by staying up.
- A GUT test helper named `_set` clashes with `Object._set` (parse error).
- A stage starts only while its event is pending, the player is on the stage area, inside its hours and its `when_flags` hold (`Stage.is_open`).
- Scene stages place NPCs even off their schedule, but every placed NPC needs an `npc_behaviour` entry.
- Clearing an old "away" flag can wake an old schedule: 3.24 clears `horns_of_hammerad.gone_to_albez`, which put Pisces back on the Floodplains at night; fixed with `unless_flags` in_celum / left_celum.
- Talking to an NPC next to you gives `talk_with_guest` / `persuade` / `comfort_someone` (rules.npc.talk_actions) with the map's location as context; talking adds +1 relationship.
- Screenshots: a throwaway scene in `game/_scratch/` that adds `world/main.tscn` as a child (`add_child.call_deferred`), run with `godot --path game res://_scratch/shot.tscn`. Delete `game/_scratch` before committing.
- New `class_name` scripts need `godot --headless --path game --import` once.
- `-gtest=` is ignored; use `-gselect=<script name> -gdir=res://tests`.
- GUT exits 0 even on a parse error - grep for `Parse Error` and check the script count (73 now).
- Validator: `python tools/validate_data.py game/data/canon --all` (the folder with book<N> in it, not a book folder).
- Toy dbs erase `rules.economy`; real-db tests have hunger on.
- Rhir is real; Calruz stays missing; never link two canon entities unless the text says so (Ylawes is Yvlon's brother: 3.24 says so).
- Book 3 "E" chapters are Laken, not Erin. Laken, Geneva, Niers (3.22L) and Venitra use placeholder days.
- Save is v13 (M10.0 portal trips). `MapDb` holds maps in `areas`; use `objects_on(area)` or `objects_near`, not `areas[a]['objects']`, so flag-hidden objects stay hidden. Enemy `danger` must be 0.0–1.0.
- Same-day canon order: chain with `depends_on`. Siblings that share one dependency run in id order, so a sibling can clear a flag another still `requires` (M10.1: the rescue cleared `mrsha.fell_into_the_dungeon` before Toren's event). Debug with a throwaway `extends SceneTree` script that prints `gs.world.history` reasons. Helper-only waves come at once when no foe is left; put helper waves before the last foe wave.

- Octavia matters to Book 3: killing her before day 87 cancels 3.25's goodbye and the wagon leaving, which cascades. Kill tests for her must run after day 87.
- Scene stages: `Stage.place_npc` skips an NPC who is already in the stage area, so that NPC stays at their own post (M10.3: Lyonette, Mrsha in the inn). Only NPCs brought in from elsewhere take the stage tile. Hooks that need an NPC next to the player must name NPCs that really are placed.
- Scene `when_flags` are read during the day, before the night's events run: use a flag that is set by an earlier night.
- Python patching: converting line ends twice (LF to CRLF on a string that already has CRLF) leaves a stray CR, and git then shows the file as `-text` and changed in full. Check `git ls-files --eol` after patching.
- Never write a bash `cat > "$UNSET_VAR/..."` line without a heredoc: it waits on stdin and hangs the shell.

- Director dependencies are hard: an event whose `depends_on` was cancelled is cancelled too. Chain events only to events that always happen, or one dead NPC cancels a whole day (M10.4 cut the chains this way). Siblings run in id order, so name ids to sort in story order.
- Effects and scene flags: a flag set by an event on day N is visible on day N+1. An event set and cleared in the same night never shows in a schedule (`erin.at_esthelm`).
- Fight-stage tests: a helper that walks to `Pathfind.around(at)` can stop on a diagonal square and never attack. Walk to the four side squares instead (`sim_book4_christmas._fight_turn`). Strong allies that arrive at once can kill weak foes before the player strikes; delay the ally wave.
- A throwaway `extends SceneTree` script that errors before `quit()` hangs Godot headless forever. Use `_initialize()`, and run with `timeout 300`.

## Graphics notes (M11)
- Core must not change for art. The view compares old and new state after each command and plays tweens; tweens never block input.
- Missing art must fall back to today's squares, so headless tests and new data never break.
- `.import` files for new PNGs are kept in git (ADR 0001). Run `godot --headless --path game --import` after adding art.

## Active files
- `docs/adr/0018-m11-graphics.md`, `docs/ROADMAP.md` (M11), `game/world/world_view.gd` (TILE, drawing), `game/world/main.gd` (input, refresh), `game/data/tiles.json`, `game/tests/unit_world_view.gd`.

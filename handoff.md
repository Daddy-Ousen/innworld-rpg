# Handoff

## Just done (2026-09-27)
- PR #44 (M10.4) merged. Tag `m10.4-done` on 2696cfe (pushed).
- M10.5 (3.40-3.42 + Interlude - Winter Solstice) built on branch `data/book4-3.40-solstice`. Detail: ADR 0017 "M10.5". This ends Book 4 and M10's canon.
  - User choices: two scenes with hooks (Santa thieves in `liscor_market`, day 94 18-22, allies Relc + Klbkch arrive after 30 s; Erin in the snow on `inn_hill`, day 95 19-23, hook `comfort_someone` with Erin); Ryoka rests at Riverfarm on day 95 (guess); about 32 events.
  - 32 events: `3.40.json` (7), `3.41.json` (9), `3.42.json` (11), `interlude_winter_solstice.json` (5). New NPCs `anabelle`, `tamaroth`; locations `crag_pig`, `invrisil_runners_guild`, `riverfarm_road`; enemy `liscor_house_thief`.
  - GUT 689/689 (74 scripts). Python 51 OK. Validator 0 errors. Scenes NOT checked on screen.

## Next steps
1. Commit, push, open the M10.5 PR (if not yet done). User merges. Then tag `m10.5-done` and `m10-done` on the merge commit, tick M10 in `progress.md`, move M10 detail to `docs/PROGRESS_ARCHIVE.md`.
2. Plan M11 (Book 5) with the user. Open threads carried into Book 5:
   - Ryoka: `ryoka.heading_home_to_liscor` is set again on day 96 (via Invrisil; Reynold drives her). Clear it when she arrives. Hedault is making the Horns' gear (`hedault.makes_gear_for_the_horns`, pickup not shown); `hedault.owes_the_horns_a_debt`. She still holds `ryoka.holds_magnolias_seal`.
   - Rags: `rags.heading_south`, `rags.wants_to_see_erin`, `rags.tribe_turns_north` still set. Clear the last when she arrives.
   - Brunkr: `brunkr.hand_infected` + treated flags still set (at the party, bandaged; no result shown).
   - Octavia: `octavia.researches_penicillin` still set. Matches are done.
   - Toren alive in the dungeon (`toren.in_liscor_dungeon`). Hawk asked about him (`hawk.asked_about_the_skeleton`).
   - Tyrion Veltras knows of Erin (`tyrion_veltras.hears_of_erin`); no NPC record yet. Sserys and Wrymvr are named only.
   - Erin has the white coin (`erin.has_the_white_coin`). Lyonette swore an oath (`lyonette.swore_an_oath_to_the_stars`).
3. Halrac, Jelaqua, Xrn, Typhenous, Revi, Moore, Ulrien, Seborn, Olesm, Belgrade, Octavia and Hedault have no `npc_behaviour` entries. Add them if a later scene must place them.

## Waiting on the user
- Merge the M10.5 PR.
- Delete old remote branches `data/book4-3.26-3.29` ... `data/book4-3.36-3.39` (optional).

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

## Active files
- M10.5: `game/data/canon/book4/chapters/3.40.json`, `3.41.json`, `3.42.json`, `interlude_winter_solstice.json`, `npcs.json`, `locations.json`, `game/data/enemies.json`, `game/tests/sim_book4_christmas.gd` (new), `sim_canon_book4.gd` (LAST_DAY 96), `sim_book4_relief_home.gd`, `sim_player_hooks.gd` (30 hooks), `unit_combat_db.gd` (36 enemies), `docs/adr/0017-m10-book4.md`. Generator script was a throwaway (not in repo).
- M10.4: `chapters/3.36.json` to `3.39.json`, `sim_book4_relief_home.gd`.
- M10.0 door: `game/core/portal.gd`, `game/data/maps/celum_stitchworks.json`.

# Handoff

## Just done (2026-09-27)
- PR #42 (M10.2) merged. Tag `m10.2-done` on ccf8743 (pushed).
- M10.3 (3.32-3.35) built on branch `data/book4-3.32-3.35`. Detail: ADR 0017 "M10.3".
  - User choices: two scenes with hooks (Zel scolds Erin, day 91; Erin pitches the Esthelm relief, day 92); add class `magical_innkeeper` + Erin's two Skills; 3.35 on day 93; clear `ivolethe.banished_from_magnolias_land`.
  - 22 events: `chapters/3.32.json` (5 more), new `3.33.json` (5), `3.34.json` (7), `3.35.json` (5). New NPC `umbral`.
  - Erin comes home on day 91 (`erin.home_at_the_inn`; the wagon, Celum and stranded flags cleared). Level 30 that night: `erin.magical_grounds`, `erin.class_magical_innkeeper`. The inn door shows from day 92 and runs. Second door `albez_door.second_door_in_stitchworks` (day 92).
  - Erin is at Esthelm from day 92 (`erin.at_esthelm`, a new off_map goal in `npc_behaviour.json`).
  - GUT 670/670 (72 scripts). Python 51 OK. Validator 0 errors. Zel scene checked on screen.
- The branch is committed and PR #43 is open for the user to merge.

## Next steps
1. The user merges the M10.3 PR. Then tag `m10.3-done` on the merge commit.
2. M10.4 (3.36-3.39): read with a subagent, then ask the user for stage and hook choices. Start `chapters/3.36.json`.
   - Clear `erin.at_esthelm` when the text brings Erin home (or keep her at Esthelm if it does not).
   - Esthelm relief flags to build on: `esthelm_relief.planned`, `esthelm.receives_aid_from_liscor_and_celum`, `antinium.expedition_to_esthelm`, `esthelm.sings_erins_carol`.
   - The Horns, Pawn, Zel and Klbkch were at Esthelm on day 92 in the text but have no Esthelm schedule. Add `off_map` goals if a later scene must place them.
3. Toren is in the Liscor dungeon (`toren.in_liscor_dungeon`), alive. The town of Esthelm believes he died (`esthelm.believes_the_purple_eyed_skeleton_died`). Keep him alive unless the text says he died.
4. Rags heads south (`rags.heading_south`, `rags.wants_to_see_erin`). `rags.tribe_turns_north` still blocks her foraging near Liscor; clear it when she arrives.
5. Halrac, Jelaqua, Xrn, Typhenous, Revi, Moore, Ulrien, Seborn and Octavia have no `npc_behaviour` entries. Add them if a later scene must place them.
6. Laken has only Durene in 3.35; our flags say Gamel goes with him and he has Frostwing. Reconcile if a later chapter shows them.

## Waiting on the user
- Merge the M10.3 PR.
- Delete the old remote branches `data/book4-3.26-3.29` and `data/book4-3.30-3.31` (optional).

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
- GUT exits 0 even on a parse error - grep for `Parse Error` and check the script count (72 now).
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

## Active files
- M10.3: `game/data/canon/book4/chapters/3.32.json`, `3.33.json`, `3.34.json`, `3.35.json`, `game/data/canon/book4/npcs.json`, `game/data/classes.json`, `game/data/skills.json`, `game/data/npc_behaviour.json` (Erin), `game/tests/sim_book4_homecoming.gd`, `game/tests/sim_canon_book4.gd`, `docs/adr/0017-m10-book4.md`.
- M10.2: `game/tests/sim_book4_wistram.gd`, `chapters/3.30.json`, `3.31G.json`.
- M10.0 door: `game/core/portal.gd`, `game/data/maps/celum_stitchworks.json`.

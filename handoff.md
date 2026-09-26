# Handoff

## Just done (2026-09-27)
- PR #41 (M10.1) merged. Tag `m10.1-done` on ce7d682 (pushed).
- The old branch `data/book4-3.26-3.29` still exists on GitHub. The auto-mode check blocked its delete; the user can delete it.
- M10.2 (3.30-3.31G + the 3.32 frame + Wistram Days as history) built on branch `data/book4-3.30-3.31`. Detail: ADR 0017 "M10.2".
  - User choices: 3.30 is day 89; one scene, the Wistram story at the Frenzied Hare (night 89, 20-24); 8 key Wistram NPCs only.
  - New files: `chapters/3.30.json` (4 events), `3.31G.json` (7 events, days 91-92), `3.32.json` (1 event: the story frame, with stage + hook `player_heard_the_wistram_story`).
  - NPCs: termin, poisonbite, cognita, illphres (dead), calvaron (dead), montressa_du_valeross, beatrice, charles_de_trevalier, amerys, feor. Locations: celum_liscor_road, village_of_the_dead.
  - Door: 3.30 sets `albez_door.anchor_at_stitchworks`, clears `albez_door.linked_to_frenzied_hare`.
  - GUT 659/659 (71 scripts). Python 51 OK. Validator 0 errors. Scene checked on screen.
- The PR for this branch is open for the user to merge.

## Next steps
1. The user merges the M10.2 PR. Then tag `m10.2-done` on the merge commit.
2. M10.3 (3.32-3.35): read with a subagent, then ask the user for stage and hook choices. Add the rest of 3.32 to the existing `chapters/3.32.json`.
   - Timeline from the reader: day 90 the wagon reaches Esthelm (Erin cooks at the Esthelm inn, no door use there); day 91 it reaches Liscor just before sunset.
   - Set `albez_door.at_wandering_inn`, then `erin.magical_grounds` on Erin's Level 30 (3.33).
   - Erin's goals: `erin.stranded_north` still holds her off the map; `erin.on_wagon_south` is set. Book 4 must bring her home to the inn (clear or replace these). Check her goals in `npc_behaviour.json`.
   - Toren's four bones of "the [Archmage]" (3.32): do not link to Nekhret unless the text says so.
3. Toren is in the Liscor dungeon (`toren.in_liscor_dungeon`), alive. Keep him alive unless the text says he died.
4. Rags heads south (`rags.heading_south`, `rags.wants_to_see_erin`). `rags.tribe_turns_north` still blocks her foraging near Liscor; clear it when she arrives.
5. Halrac, Jelaqua and Xrn have no `npc_behaviour` entries yet. Add them if a later scene must place them.

## Waiting on the user
- Merge the M10.2 PR.
- Delete the old remote branch `data/book4-3.26-3.29` (optional).

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
- GUT exits 0 even on a parse error - grep for `Parse Error` and check the script count (71 now).
- Validator: `python tools/validate_data.py game/data/canon --all` (the folder with book<N> in it, not a book folder).
- Toy dbs erase `rules.economy`; real-db tests have hunger on.
- Rhir is real; Calruz stays missing; never link two canon entities unless the text says so (Ylawes is Yvlon's brother: 3.24 says so).
- Book 3 "E" chapters are Laken, not Erin. Laken, Geneva, Niers (3.22L) and Venitra use placeholder days.
- Save is v13 (M10.0 portal trips). `MapDb` holds maps in `areas`; use `objects_on(area)` or `objects_near`, not `areas[a]['objects']`, so flag-hidden objects stay hidden. Enemy `danger` must be 0.0–1.0.
- Same-day canon order: chain with `depends_on`. Siblings that share one dependency run in id order, so a sibling can clear a flag another still `requires` (M10.1: the rescue cleared `mrsha.fell_into_the_dungeon` before Toren's event). Debug with a throwaway `extends SceneTree` script that prints `gs.world.history` reasons. Helper-only waves come at once when no foe is left; put helper waves before the last foe wave.

- Octavia matters to Book 3: killing her before day 87 cancels 3.25's goodbye and the wagon leaving, which cascades. Kill tests for her must run after day 87.
- Never write a bash `cat > "$UNSET_VAR/..."` line without a heredoc: it waits on stdin and hangs the shell.

## Active files
- M10.2: `game/data/canon/book4/chapters/3.30.json`, `3.31G.json`, `3.32.json`, `game/data/canon/book4/npcs.json`, `locations.json`, `game/tests/sim_book4_wistram.gd`, `game/tests/sim_canon_book4.gd`, `docs/adr/0017-m10-book4.md`.
- M10.0 door: `game/core/portal.gd`, `game/data/maps/celum_stitchworks.json`.

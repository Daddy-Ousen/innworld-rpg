# Handoff

## Just done (2026-09-26)
- PR #40 (M10.0 Albez door) merged. Tag `m10.0-done` on 3284dea.
- M10.1 (3.26G-3.29G) built on branch `data/book4-3.26-3.29`. Detail: ADR 0017 "M10.1".
  - `game/data/canon/book4/`: 17 events, days 85-90. NPCs tremborag, ulvama, noears, pyrite, redscar, greybeard. Locations north_izril, tremborags_mountain, liscor_dungeon_rift.
  - New map `dungeon_rift` (south exit of floodplains_south, 60 min), tile `chasm`, knock-out wake.
  - Two scenes with hooks on day 85: Lyonette searches the snow (floodplains_south 11-16); rescuers at the rift (dungeon_rift 14-20, rope anchor offers keep_watch).
  - Fix: Rags stops foraging on the floodplains after `rags.tribe_turns_north`.
  - GUT 651/651 (70 scripts). Python 51 OK. Validator 0 errors. Rift scene checked on screen.
- The PR for this branch is open for the user to merge.

## Next steps
1. The user merges the M10.1 PR. Then tag `m10.1-done` on the merge commit.
2. M10.2 (3.30-3.31G + Wistram Days 1-7 as history only): read with a subagent, then ask the user for stage and hook choices.
3. Door flags the later batches must set:
   - M10.2 (3.30): set `albez_door.anchor_at_stitchworks` and clear `albez_door.linked_to_frenzied_hare`.
   - M10.3 (3.32-3.33): set `albez_door.at_wandering_inn`, then `erin.magical_grounds` on Erin's Level 30.
   - Erin is home: her Liscor goals stop on `erin.left_liscor`, and her off-map goal holds while `erin.stranded_north` is set. Book 4 must clear or replace these. Check her goals.
4. Toren is in the Liscor dungeon (`toren.in_liscor_dungeon`), alive. Keep him alive unless the text says he died (3.32 is not clear).
5. Rags: `rags.leads_her_own_tribe`, `tremborag.hunts_rags`, `garen.stays_with_tremborag`. 3.31G continues her thread.
6. Halrac, Jelaqua and Xrn have no `npc_behaviour` entries yet. Add them if a later scene must place them. The Halfseekers may move to the inn (`halfseekers.eye_the_wandering_inn`).

## Waiting on the user
- Merge the M10.1 PR.

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
- GUT exits 0 even on a parse error - grep for `Parse Error` and check the script count (70 now).
- Validator: `python tools/validate_data.py game/data/canon --all` (the folder with book<N> in it, not a book folder).
- Toy dbs erase `rules.economy`; real-db tests have hunger on.
- Rhir is real; Calruz stays missing; never link two canon entities unless the text says so (Ylawes is Yvlon's brother: 3.24 says so).
- Book 3 "E" chapters are Laken, not Erin. Laken, Geneva, Niers (3.22L) and Venitra use placeholder days.
- Save is v13 (M10.0 portal trips). `MapDb` holds maps in `areas`; use `objects_on(area)` or `objects_near`, not `areas[a]['objects']`, so flag-hidden objects stay hidden. Enemy `danger` must be 0.0–1.0.
- Same-day canon order: chain with `depends_on`. Siblings that share one dependency run in id order, so a sibling can clear a flag another still `requires` (M10.1: the rescue cleared `mrsha.fell_into_the_dungeon` before Toren's event). Debug with a throwaway `extends SceneTree` script that prints `gs.world.history` reasons. Helper-only waves come at once when no foe is left; put helper waves before the last foe wave.

## Active files
- M10.1: `game/data/canon/book4/**`, `game/data/maps/dungeon_rift.json`, `game/tests/sim_canon_book4.gd`, `game/tests/sim_book4_mrsha.gd`, `docs/adr/0017-m10-book4.md`.
- M10.0: `game/core/portal.gd`, `game/core/map_db.gd`, `game/data/maps/celum_stitchworks.json`, `game/tests/unit_portal.gd`.

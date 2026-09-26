# Handoff

## Just done (2026-09-26)
- M9 is done: PR #39 merged, tags `m9.4-done` and `m9-done` on 9e8f179. M9 detail is in `docs/PROGRESS_ARCHIVE.md`.
- M10 planned with the user (ADR 0017, ROADMAP M10): the door first, then 5 canon batches (3.26G-3.29G, 3.30-3.31G + Wistram Days as history only, 3.32-3.35, 3.36-3.39, 3.40-3.42 + Winter Solstice).
- Book 4 extracted to `canon/raw/book4` (25 chapters).
- M10.0 built on branch `plan/m10-book4`: the Albez door.
  - The Celum end is the new map `celum_stitchworks` (Octavia's shop).
  - 0 trips before `erin.magical_grounds`, then 4 a day.
  - Save v13.
  - GUT 640/640 (68 scripts). Checked on screen.
- The PR for this branch is open for the user to merge. It also holds the M9 archive docs.

## Next steps
1. The user merges the M10.0 PR. Then tag `m10.0-done` on the merge commit.
2. M10.1 (3.26G-3.29G): read the chapters with a subagent (the G chapters are Rags and the Goblin Lord; 3.27M is Mrsha). Then ask the user for stage and hook choices.
3. Door flags the canon batches must set:
   - M10.2 (3.30): set `albez_door.anchor_at_stitchworks` and clear `albez_door.linked_to_frenzied_hare`.
   - M10.3 (3.32-3.33): set `albez_door.at_wandering_inn`, then `erin.magical_grounds` on Erin's Level 30.
   - Erin is home: her Liscor goals stop on `erin.left_liscor`, and her off-map goal holds while `erin.stranded_north` is set. Book 4 must clear or replace these. Check her goals.
4. Toren: keep him alive unless the text says he died (3.32 is not clear).

## Waiting on the user
- Merge the M10.0 PR.

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
- GUT exits 0 even on a parse error - grep for `Parse Error` and check the script count (68 now).
- Validator: `python tools/validate_data.py game/data/canon --all` (the folder with book<N> in it, not a book folder).
- Toy dbs erase `rules.economy`; real-db tests have hunger on.
- Rhir is real; Calruz stays missing; never link two canon entities unless the text says so (Ylawes is Yvlon's brother: 3.24 says so).
- Book 3 "E" chapters are Laken, not Erin. Laken, Geneva, Niers (3.22L) and Venitra use placeholder days.
- Save is v13 (M10.0 portal trips). `MapDb` holds maps in `areas`; use `objects_on(area)` or `objects_near`, not `areas[a]['objects']`, so flag-hidden objects stay hidden. Enemy `danger` must be 0.0–1.0.
- Same-day canon order: chain with `depends_on`. Helper-only waves come at once when no foe is left; put helper waves before the last foe wave.

## Active files
- M10.0: `game/core/portal.gd`, `game/core/map_db.gd`, `game/data/maps/celum_stitchworks.json`, `game/tests/unit_portal.gd`, `docs/adr/0017-m10-book4.md`.
- `game/data/canon/book3/**`, `game/data/maps/bee_cave.json`, `game/data/enemies.json`, `game/data/npc_behaviour.json`, `game/tests/sim_book3_finale.gd`, `game/tests/sim_canon_book3.gd`, `docs/adr/0016-m9-book3.md`.

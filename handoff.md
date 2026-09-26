# Handoff

## Just done (2026-09-26)
- PR #38 (M9.3) merged; tagged `m9.3-done` on 5cced62 and pushed.
- M9.4 (3.21L–3.25, the end of Book 3) built on branch `data/book3-3.21-3.25`; PR opened for the user to review and merge.
  - User choices: the dawn bee raid as a fight stage (Lyonette as ally); four scenes with hooks (painted Soldiers day 82, Zel at the inn day 84, Frozen day 86, Erin leaves Celum day 87); the Albez door as flags only.
  - World: tile `cave_floor`, map `bee_cave` (from the inn hill east edge, 45 min, indoor), enemy `ashfire_bee` (stage only), schedules `zel_shivertail`, `jasi`, `yvlon_byres`, Horns' Celum evenings at the Hare. Knock-out wake for the cave is the inn.
  - Canon: 38 events, 6 new NPCs (xrn, tersk, pivr, ijvani, adelynn, robert). Book 3 ends day 87. Detail in ADR 0016 M9.4.
  - GUT 629/629 (67 scripts), validator 0 errors (`--all`), Python 51/51. Not checked on screen.

## Next steps
1. User merges the M9.4 PR; tag `m9.4-done` and `m9-done` on the merge commit; mark M9 done in `progress.md` and move M9 detail to `docs/PROGRESS_ARCHIVE.md`.
2. Plan M10 (Book 4) with the user: the Albez door as a working portal (engine + save change), Erin back at the inn, Toren (`toren.heading_to_liscor`, `toren.link_severed`, not dead), Venitra/Ijvani hunting Ryoka, the Antinium delegation, Zel and Ilvriss in Liscor.
3. Optional: check the bee raid and the scenes on screen.

## Waiting on the user
- Review and merge the M9.4 PR.

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
- GUT exits 0 even on a parse error - grep for `Parse Error` and check the script count (67 now).
- Validator: `python tools/validate_data.py game/data/canon --all` (the folder with book<N> in it, not a book folder).
- Toy dbs erase `rules.economy`; real-db tests have hunger on.
- Rhir is real; Calruz stays missing; never link two canon entities unless the text says so (Ylawes is Yvlon's brother: 3.24 says so).
- Book 3 "E" chapters are Laken, not Erin. Laken, Geneva, Niers (3.22L) and Venitra use placeholder days.
- Save is v12. `MapDb` holds maps in `areas`. Enemy `danger` must be 0.0–1.0.
- Same-day canon order: chain with `depends_on`. Helper-only waves come at once when no foe is left; put helper waves before the last foe wave.

## Active files
- `game/data/canon/book3/**`, `game/data/maps/bee_cave.json`, `game/data/enemies.json`, `game/data/npc_behaviour.json`, `game/tests/sim_book3_finale.gd`, `game/tests/sim_canon_book3.gd`, `docs/adr/0016-m9-book3.md`.

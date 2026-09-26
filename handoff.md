# Handoff

## Just done (2026-09-26)
- PR #39 (M9.4) merged. Tags `m9.4-done` and `m9-done` on 9e8f179, pushed. M9 (Book 3) is done.
- M9 detail moved to `docs/PROGRESS_ARCHIVE.md`; `progress.md` now shows M9 done and M10 not planned.
- Book 4 (Winter Solstice) extracted to `canon/raw/book4` (gitignored): 25 chapters, 282,404 words. Chapters 3.26G–3.42, seven "Wistram Days" interludes (Ceria and Pisces at Wistram in the past, with Calvaron), and "Interlude – Winter Solstice".
- Branch `plan/m10-book4` holds the docs commit (not merged yet).

## Next steps
1. Plan M10 (Book 4) with the user: batches, the Albez door as a real portal (engine + save change), how to treat Wistram Days (past events: history only, like the Antinium Wars interludes?). Then ADR 0017 and a ROADMAP M10 section.
2. Toren: `toren.heading_to_liscor`, `toren.link_severed`, not dead. Check what Book 4 does with him.
3. Same flow per batch: ask stage/hook choices, world data by hand, canon JSON by a subagent, re-verify class names, tests, commits, PR.

## Waiting on the user
- M10 plan choices.

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

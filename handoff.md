# Handoff

## Just done (2026-09-26)
- PR #37 (M9.2) merged; tagged `m9.2-done` on a07b7fc and pushed.
- M9.3 built on branch `data/book3-3.15-3.20` (4 commits); PR opened for the user to review and merge.
  - User choices: the Esthelm siege as a wave stage with the Redfang band as late helpers; Erin's play (3.16) as a scene + hook.
  - World: new map `esthelm_ruins` (east edge of the road camp, 180 min), 9 stage-only enemies, `ylawes_byres` schedule (guard post from `ylawes.at_esthelm`), off-map place `esthelm`, knock-out wake in the ruins.
  - Canon: 37 events (3.15–3.20T, days 77–80), 19 new NPCs (Jasi, Hess, Ylawes, the Florist, the vanguard commander and head Shaman, the Redfang band), 5 locations. Detail in ADR 0016 M9.3.
  - Stages: `b3.erin_stages_romeo_and_juliet` (scene, day 78, 19–23; hook `player_watched_erins_play`); `b3.the_last_battle_of_esthelm` (fight, day 80, 8–18; 22 foes in 6 waves; hook `player_held_the_esthelm_barricade`).
  - GUT 615/615 (66 scripts), validator 0 errors (`--all`), Python 51/51. Not checked on screen.

## Next steps
1. User merges the M9.3 PR; tag `m9.3-done` on the merge commit.
2. M9.4 (3.21 L – 3.25, days ~81–90): Lyonette's bees and classes; painted Soldiers; the Antinium delegation; Scalelings and Zel (Zel gets `npc_behaviour`); the Horns in Celum (clear `horns_of_hammerad.gone_to_albez` in 3.24); the Albez door; Erin leaves Celum on the wagon (3.25). Ask stage/hook details first.
3. Toren heads to Liscor (`toren.heading_to_liscor`); check what Book 3 end does with him.
4. Same flow: world data by hand, canon JSON by a subagent, re-verify, commits, PR.

## Waiting on the user
- Review and merge the M9.3 PR.

## Gotchas
- Commits and PRs: author Daddy-Ousen only. NO `Co-Authored-By: Claude` trailer, no Claude footer.
- **Never use `sed -i` in Git Bash on repo files** - it strips CRLF. All working-copy text files are CRLF (autocrlf=true). Patch with Python on bytes, keeping `
`, or with the Edit tool. Do NOT normalise whole folders.
- `Commands.wait(gs, db, seconds)` takes SECONDS. It does not pass midnight; sleep (`Commands.sleep(gs, db, Rest.ANYWHERE)`) to reach the next day.
- A GUT test helper named `_set` clashes with `Object._set` (parse error).
- A stage starts only while its event is pending, the player is on the stage area, inside its hours and its `when_flags` hold (`Stage.is_open`).
- Screenshots: a throwaway scene in `game/_scratch/` that adds `world/main.tscn` as a child (`add_child.call_deferred`, not `change_scene_to_file` in `_ready`), run with `godot --path game res://_scratch/shot.tscn`. Delete `game/_scratch` before committing.
- New `class_name` scripts or tests need `godot --headless --path game --import` once (it also makes the `.uid` files).
- `-gtest=` is ignored; use `-gselect=<script name> -gdir=res://tests`.
- GUT exits 0 even on a parse error - grep for `Parse Error` and check the script count (66 now).
- Toy dbs erase `rules.economy`; real-db tests have hunger on.
- Rhir is real; Calruz stays missing; never link two canon entities unless the text says so.
- Stage `kind: "scene"`: every npc placed needs an `npc_behaviour` entry. Ryoka, Garia, Halrac, Lyonette have none.
- The Book 2 epub has web-serial author's notes (Mating Rituals interlude, 2.48). Ignore them.
- Erin lives in Celum from day 71 (`erin.in_celum`) for ALL of Book 3. She leaves on the wagon in 3.25 (M9.4); she is home only in Book 4.
- Book 3 "E" chapters (3.00, 3.01, 3.11, 3.12) are Laken (Emperor), not Erin. Laken and Geneva (1.00D/1.01D) use placeholder days from day 71 on.
- Id clashes: maid Teresa (3.13) is not `teresa`; old Horn Marian (3.08) is not `marian`. The Hob in 3.10 is unnamed (not `garen`).
- `ryoka.left_celum` is still set from Book 1; `ryoka.gone_to_magnolia` (set in 3.10, day 76) ends her Celum schedule.
- NPC schedules can block stage fights: Fals at the Celum guild 7–10 broke the day-75 guild-fight test, so his hours are 6–9. Check new schedules against stage areas and hours.
- Save is v12 (M9.2): `WinterState.warm_until`. Goods may have `warm_minutes` and `from_flag` (economy.json).
- New files written by agents are LF; git warns and converts. That is fine.
- Same-day canon order: an event that kills an NPC can run before other same-day events that need that NPC. Chain them with `depends_on` (M9.3: the Esthelm battle waits for the Florist's last event).
- Stage waves with only helpers come at once when no foe is left. A strong ally (Ylawes) can clear a wave early, so helpers that come after the last foe arrive to an empty fight and leave at once. Put helper waves before the last foe wave.
- Enemy `danger` must be 0.0–1.0.
- `MapDb` holds maps in `areas` (not `maps`).

## Active files
- `game/data/canon/book3/**`, `game/data/maps/esthelm_ruins.json`, `game/data/enemies.json`, `game/data/npc_behaviour.json`, `game/tests/sim_esthelm_siege.gd`, `game/tests/sim_canon_book3.gd`, `docs/adr/0016-m9-book3.md`.

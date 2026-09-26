# Handoff

## Just done (2026-09-26)
- PR #36 (M9.1) was merged; tagged `m9.1-done` on 4b31284 and pushed.
- M9.2 built on branch `data/book3-3.06-3.14` (5 commits); PR opened for the user to review and merge.
  - User choices: scene stage Ryoka and Fals at the Frenzied Hare (day 76, 9–12) with hook `player_sat_with_ryoka_and_fals`; Corusdeer soup as a real item.
  - Engine: `warm_minutes` / `from_flag` goods, `WinterState.warm_until`, `Winter.warm_for`, `EconomyDb.on_sale`, SAVE_VERSION 12 + migration 11→12. Soup sold at Stitchworks from `erin.makes_corusdeer_soup` (8c, 240 min).
  - 41 canon events (3.06L–3.14), NPCs `nemor` (dies), `frostwing`, `gamel`; locations `ocre`, `first_landing`, `road_to_invrisil`. Detail in ADR 0016 M9.2.
  - GUT 609/609 (65 scripts), validator 0 errors (`--all`), Python 51/51. Not checked on screen.

## Next steps
1. User merges the M9.2 PR; tag `m9.2-done` on the merge commit.
2. M9.3 (3.15 – 3.20 T): new `esthelm_ruins` map (from the road camp) and the Esthelm siege as a wave stage. Ask stage/hook details first. Erin's plays in Celum (3.15/3.16) could be a scene at the Hare.
3. Same flow: world data by hand, canon JSON by a subagent, re-verify, commits, PR.

## Waiting on the user
- Review and merge the M9.2 PR.

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
- GUT exits 0 even on a parse error - grep for `Parse Error` and check the script count (65 now).
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

## Active files
- `game/data/canon/book3/**`, `game/data/npc_behaviour.json`, `game/data/economy.json`, `game/core/winter.gd`, `game/core/economy.gd`, `game/tests/sim_canon_book3.gd`, `game/tests/sim_book3_stages.gd`, `docs/adr/0016-m9-book3.md`.

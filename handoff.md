# Handoff

## Just done (2026-09-26)
- PR #35 (Ryoka never levels) merged. M9 = Book 3 planned and approved: `docs/adr/0016-m9-book3.md`, ROADMAP M9 section.
- Book 3 extracted to `canon/raw/book3` (28 chapters, 305,675 words).
- M9.1 built on branch `data/book3-3.00-3.05`, 4 commits, [PR #36](https://github.com/Daddy-Ousen/innworld-rpg/pull/36) open for the user to review and merge.
  - 39 events (3.00E–3.05L, 1.00D, 1.01D); stages `b3.ryoka_beats_persua_in_the_runners_guild` (day 75) and `b3.lyonette_reopens_the_inn` (scene, day 76), both with hooks.
  - Schedules for Lyonette, Mrsha, Ryoka; enemies `persua_courier`, `celum_runner`; inn counter shop.
  - GUT 602/602 (65 scripts), validator 0 errors (`--all`), Python 51/51. Checked on screen (guild fight, day 75 10:00).

## Next steps
1. User merges PR #36; tag `m9.1-done` on the merge commit.
2. M9.2 (3.06 L – 3.14, days ~76–82): ask the stage/hook choices first. Most of it is far from any map (Hive, Albez, Ocre, Magnolia's estate, Riverfarm). Ideas: a Corusdeer soup item that keeps you warm (needs an engine hook, ask), a Liscor-side scene at the inn, or a `change` hook only. Set `ryoka.gone_to_magnolia` in 3.09/3.10.
3. Same flow: world data by hand, canon JSON by a subagent, re-verify, commits, PR.

## Waiting on the user
- Review and merge PR #36.

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
- GUT exits 0 even on a parse error - grep for `Parse Error` and check the script count (63 now).
- Toy dbs erase `rules.economy`; real-db tests have hunger on.
- Rhir is real; Calruz stays missing; never link two canon entities unless the text says so.
- Stage `kind: "scene"`: every npc placed needs an `npc_behaviour` entry. Ryoka, Garia, Halrac, Lyonette have none.
- The Book 2 epub has web-serial author's notes (Mating Rituals interlude, 2.48). Ignore them.
- Erin lives in Celum from day 71 (`erin.in_celum`) for ALL of Book 3. She leaves on the wagon in 3.25 (M9.4); she is home only in Book 4.
- Book 3 "E" chapters (3.00, 3.01, 3.11, 3.12) are Laken (Emperor), not Erin. Laken and Geneva (1.00D/1.01D) use placeholder days from day 71 on.
- Id clashes: maid Teresa (3.13) is not `teresa`; old Horn Marian (3.08) is not `marian`. The Hob in 3.10 is unnamed (not `garen`).
- `ryoka.left_celum` is still set from Book 1; use `ryoka.gone_to_magnolia` (M9.2) to end her Celum schedule.

## Active files
- `game/data/canon/book3/**`, `game/data/npc_behaviour.json`, `game/data/enemies.json`, `game/data/economy.json`, `game/data/maps/inn_interior.json`, `game/tests/sim_canon_book3.gd`, `game/tests/sim_book3_stages.gd`, `docs/adr/0016-m9-book3.md`.

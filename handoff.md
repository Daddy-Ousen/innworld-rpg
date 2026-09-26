# Handoff

## Just done (2026-09-26)
- PR #34 merged; tags `m8.7-done` and `m8-done` pushed on merge commit ad436eb.
- Ryoka never gains a level (user). Branch `fix/book2-ryoka-no-level`: 2.35 sets `ryoka.class_offer_cancelled` instead of `ryoka.gained_first_class` / `ryoka.class_barefoot_runner` (event id kept for old saves); [Barefoot Runner] system records in 1.20R and 2.35 are now kind `other` (offered, refused). Docs fixed. GUT 591/591, validator 0 errors, Python 51/51. PR open.
- M8.7 is built on branch `data/book2-2.39-2.48` (4 commits: world data, canon data, stage test, docs). [PR #34](https://github.com/Daddy-Ousen/innworld-rpg/pull/34) is open for the user to review and merge.
- Detail: `docs/adr/0014-m8-book2-and-celum.md`, section "M8.7".
- GUT 591/591 (63 scripts), validator 0 errors (`--all`), Python 51/51. Checked on screen: the bar fight in the Frenzied Hare on day 71.
- With M8.7, all of M8 is done. The M8 detail moved to `docs/PROGRESS_ARCHIVE.md`.

## Waiting on the user
- Review and merge the Ryoka fix PR.
- What the next milestone is. ROADMAP has no M9; "Later" = audio, polish, LLM flavour layer. Book 3 would be a new M9.

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
- Erin lives in Celum from day 71 (`erin.in_celum`). A Book 3 event must clear or override that to bring her home.

## Active files
- `game/data/canon/book2/chapters/2.39.json`–`2.48.json`, `interlude_quiet_discussions.json`, `game/data/maps/celum_frenzied_hare.json`, `game/data/npc_behaviour.json`, `game/tests/sim_erin_in_celum.gd`, `game/tests/sim_book2_end_stages.gd`, `game/tests/sim_canon_book2.gd`.

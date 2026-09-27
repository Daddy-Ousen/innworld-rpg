# Progress

M0–M10 detail (roadmap bullets, decisions, ADR 0001–0017) lives in
`docs/PROGRESS_ARCHIVE.md`. Read the archive only when you need that old detail.

## Context discipline (all sessions)
- Redirect GUT / validator runs to a file (scratchpad). Read only the pass/fail summary line and any FAIL/Error/Parse Error lines — never the full run.
- Delegate chapter-text reading (for canon extraction) and full test-suite runs to a subagent. Only its short summary should land in the main session's context, not raw book text or raw test logs.
- Don't re-read a file right after Edit/Write — the tool already confirms the change.
- See `handoff.md` "Gotchas" for the GUT-exits-0-on-parse-error trap and other run-output pitfalls.

## Roadmap status
- [x] M0–M7 — Book 1 and the engine. Tags `m0-done` … `m7-done`, `m7.4-done`, `m7b-done`.
- [x] M8 — Book 2 (Fae and Fare) + Celum. M8.0–M8.6 merged and tagged; M8.7 merged ([PR #34](https://github.com/Daddy-Ousen/innworld-rpg/pull/34), tags `m8.7-done` and `m8-done` on merge commit ad436eb). Detail in the archive and ADR 0014 / 0015.
- [x] M9 — Book 3 (Flowers of Esthelm). M9.1–M9.4 merged; tags `m9.1-done` … `m9.4-done` and `m9-done` on merge commit 9e8f179 ([PR #39](https://github.com/Daddy-Ousen/innworld-rpg/pull/39)). Detail in the archive and ADR 0016.
- [x] M10 — Book 4 (Winter Solstice). M10.0–M10.5 merged; tags `m10.0-done` … `m10.5-done` and `m10-done` on merge commit 25b8d94 ([PR #45](https://github.com/Daddy-Ousen/innworld-rpg/pull/45)). Detail in the archive and ADR 0017.
- [ ] M11 — Graphics, characters and animation. Plan accepted 2026-09-27 (ADR 0018, ROADMAP M11). New books paused. User choices: 2D pixel art, 32 px cells; free LPC packs + our edits (credits file); standard animation first.
  - [x] M11.0 Art spike: merged ([PR #46](https://github.com/Daddy-Ousen/innworld-rpg/pull/46)), tag `m11.0-done` on ea93b99. 32 px cells, LPC tiles, baked character sheets, player step glide.
  - [x] M11.1 Tiles and objects: merged ([PR #47](https://github.com/Daddy-Ousen/innworld-rpg/pull/47)), tag `m11.1-done` on 84eab06. All 16 tiles and 67 map objects have art.
  - [x] M11.2 Characters: merged ([PR #48](https://github.com/Daddy-Ousen/innworld-rpg/pull/48)), tag `m11.2-done` on d000380. 43 looks, Antinium edits.
  - [x] M11.3 Animation: merged ([PR #49](https://github.com/Daddy-Ousen/innworld-rpg/pull/49)), tag `m11.3-done` on ebdcbf0. Sheet layout v2 (128 px attack block), `world/anim_diff.gd`, glides, hit flash, damage numbers, falls, swings.
  - [x] M11.4 Monsters: merged ([PR #50](https://github.com/Daddy-Ousen/innworld-rpg/pull/50)), tag `m11.4-done` on b76ff4a. All 36 enemies have a sheet: 30 LPC people looks, 6 creatures from `tools/build_creatures.py` (LPC golem, bee, big worm, eagle recoloured; Rock Crab and snowman Snow Golem drawn). Monsters with a sheet are sprites with a state ring; gone ones fall and fade; a hidden crab is the rock prop. GUT 726/726 (78 scripts), Python 73/73, validator 0 errors.
  - [ ] M11.5 Atmosphere (branch `feat/m11.5-atmosphere`): built, [PR #51](https://github.com/Daddy-Ousen/innworld-rpg/pull/51) open, waiting for the user to check it. New `world/atmosphere.gd`: sky tint by the clock (room light indoors), fire light from `"light"` in `objects.json` (campfire, brazier, hearth, stove; user OK for the schema change), snow outdoors in winter. GUT 736/736 (79 scripts), Python 73/73, validator 0 errors.
  - [ ] M11 done: the user checks the game on screen, then tag `m11-done`.

## After M8
- [x] Ryoka never gains a level (user, 2026-09-26): merged ([PR #35](https://github.com/Daddy-Ousen/innworld-rpg/pull/35)).

## Completed (current engine state)
- Canon: Book 1 (1.00–1.63, days 1–41), Book 2 (Interlude – The Call to 2.48, days 41–71) are complete event data. Book 3 (3.00E–3.25 + 1.00D/1.01D, days 71–87) is complete event data. Book 4 (3.26G–Interlude – Winter Solstice, days 85–96) is complete event data.
- Godot 4.7.2 project in `game/`, GUT 9.7.1 in `game/addons/gut`.
- Core: `economy`, `economy_state`, `economy_db`, `rest` (M8.6), `portal` (M10.0), `stage` (waves, M7.B), `npc_react`, `save_slots`, `rng`, `game_state` (SAVE_VERSION=13), `save_migrations` (1→…→13), `combat_db`, `stats`, `combat_state`, `combat`, `monster_sim`, `save_codec`, `behaviour_db`, `utility_ai`, `npc_roster`, `npc_sim`, `map_db`, `player_state`, `movement`, `interact`, `pathfind`, `canon_db`, `world_state`, `director`, `clock`, `tags`, `data_db`, `action_log`, `xp`, `actions`, `progression`, `levels`, `skill_system`, `class_system`, `night`, `commands`.
- UI: `ui/title_menu.tscn` (main scene), `ui/pause_menu.tscn`, `ui/slot_list.tscn`, `ui/journal.tscn`, `ui/session.gd` (autoload), `ui/hud.tscn` (HP line), `ui/interact_menu.tscn`, `ui/system_messages.gd`, `ui/system_dialog.tscn`, `ui/character_sheet.tscn`, `ui/console_commands.gd`, `ui/debug_console.tscn` (also the overlay). World: `world/main.tscn` (main scene), `world/world_view.tscn`.
- Data: `tiles.json`, `maps/` (liscor_gate, liscor_market, floodplains_south, inn_hill, inn_interior, ruins_entrance, celum_gate, celum_square, celum_runners_guild, road_camp, celum_frenzied_hare, esthelm_ruins, bee_cave, celum_stitchworks, dungeon_rift), `npc_behaviour.json`, `enemies.json`, `items.json`, `economy.json`; rules `npc`, `combat`, `winter`, `economy`, `portal`.
- Tests: 79 GUT scripts, 736 tests, all pass, headless exit 0. Python tool tests: 73 pass (`python -m unittest discover -s tools/tests`).
- Tools: `tools/extract_epub.py`, `tools/validate_data.py`, `tools/build_sprites.py`, `tools/build_objects.py`, `tools/build_creatures.py` (all need Pillow: `pip install -r tools/requirements.txt`).

## Blockers
- None.

## Balance note
- M6.5: levels cost less (base_xp 40, growth 1.25). A hard inn worker: first class on night 1–3, level 5 by about day 18–21 (`sim_m6_done`: [Cook] level 6 by day 22). Canon Erin is level 9 by day 9; the player is not meant to match her.

## Repo
- Public: https://github.com/Daddy-Ousen/innworld-rpg, branch `main`.

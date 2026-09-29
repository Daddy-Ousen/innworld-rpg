# Progress

M0–M13 detail (roadmap bullets, decisions, ADR 0001–0020) lives in
`docs/PROGRESS_ARCHIVE.md`. Read the archive only when you need that old detail.

## Context discipline (all sessions)
- Redirect GUT / validator runs to a file (scratchpad). Read only the pass/fail summary line and any FAIL/Error/Parse Error lines — never the full run.
- Delegate chapter-text reading (for canon extraction) and full test-suite runs to a subagent. Only its short summary should land in the main session's context, not raw book text or raw test logs.
- Don't re-read a file right after Edit/Write — the tool already confirms the change.
- Test scope (user, 2026-09-28): data-only sub-milestones run targeted tests only; the full suite runs only for `game/core/` code, save/schema changes, and at a milestone's end. Detail in `CLAUDE.md` "Test scope".
- See `handoff.md` "Gotchas" for the GUT-exits-0-on-parse-error trap and other run-output pitfalls.

## Roadmap status
- [x] M0–M7 — Book 1 and the engine. Tags `m0-done` … `m7-done`, `m7.4-done`, `m7b-done`.
- [x] M8 — Book 2 (Fae and Fare) + Celum. M8.0–M8.6 merged and tagged; M8.7 merged ([PR #34](https://github.com/Daddy-Ousen/innworld-rpg/pull/34), tags `m8.7-done` and `m8-done` on merge commit ad436eb). Detail in the archive and ADR 0014 / 0015.
- [x] M9 — Book 3 (Flowers of Esthelm). M9.1–M9.4 merged; tags `m9.1-done` … `m9.4-done` and `m9-done` on merge commit 9e8f179 ([PR #39](https://github.com/Daddy-Ousen/innworld-rpg/pull/39)). Detail in the archive and ADR 0016.
- [x] M10 — Book 4 (Winter Solstice). M10.0–M10.5 merged; tags `m10.0-done` … `m10.5-done` and `m10-done` on merge commit 25b8d94 ([PR #45](https://github.com/Daddy-Ousen/innworld-rpg/pull/45)). Detail in the archive and ADR 0017.
- [x] M11 — Graphics, characters and animation. M11.0–M11.5 merged; tags `m11.0-done` … `m11.5-done` and `m11-done` on merge commit 7bb4656 ([PR #51](https://github.com/Daddy-Ousen/innworld-rpg/pull/51)). Detail in the archive and ADR 0018.
- [x] M12 — Audio: music, sound effects, ambience. M12.0–M12.5 merged; tags `m12.0-done` … `m12.5-done` and `m12-done` on merge commit 95fb6c4 ([PR #57](https://github.com/Daddy-Ousen/innworld-rpg/pull/57)). Detail in the archive and ADR 0019.
- [x] M13 — Book 5 (The Last Light). M13.0, M13.T, M13.1–M13.7 merged; tags `m13.0-done` … `m13.7-done` and `m13-done` on merge commit 17b6bab ([PR #66](https://github.com/Daddy-Ousen/innworld-rpg/pull/66)). Detail in the archive and ADR 0020.
- [ ] M14 — Engine works (plan accepted 2026-09-28, ADR 0021; plan file `C:\Users\rhasa\.claude\plans\start-engine-works-plan-bright-patterson.md`).
  User choices: all four areas (inn play, living world, UI skin + portraits, balance); attack NPCs with a fate
  warning; guests = patrons + canon NPCs; free pixel font (ask before the download).
  - [x] M14.0 Bag screen — merged ([PR #67](https://github.com/Daddy-Ousen/innworld-rpg/pull/67)), tag `m14.0-done` on merge commit 801e382.
  - [x] M14.1 Cooking recipes — merged ([PR #68](https://github.com/Daddy-Ousen/innworld-rpg/pull/68)), tag `m14.1-done` on merge commit 7c31db7.
  - [x] M14.2 Guests and serving (save v15) — merged ([PR #69](https://github.com/Daddy-Ousen/innworld-rpg/pull/69)), tag `m14.2-done` on merge commit 12c4ddd.
  - [ ] M14.3 Standing (save v16) — branch `feat/m14.3-standing`: `core/standing.gd`, `rules.standing`,
    `WorldState.reputation` + `contact`, night step 7 decay, greeting bands, price shift by town, friends fight,
    inn guest bonus, character sheet lines. `unit_standing` (21 tests) green. Full suite: 103 scripts, 978 tests, all pass (after one `unit_npc_sim` fix); Python 78 OK; validator 0 errors. PR open; tick after merge.
  - [ ] M14.4 NPC schedules · M14.5 Attack NPCs ·
    M14.6 UI skin · M14.7 Portraits · M14.8 Balance

## After M8
- [x] Ryoka never gains a level (user, 2026-09-26): merged ([PR #35](https://github.com/Daddy-Ousen/innworld-rpg/pull/35)).

## Completed (current engine state)
- Canon: Book 1 (1.00–1.63, days 1–41), Book 2 (Interlude – The Call to 2.48, days 41–71) are complete event data. Book 3 (3.00E–3.25 + 1.00D/1.01D, days 71–87) is complete event data. Book 4 (3.26G–Interlude – Winter Solstice, days 85–96) is complete event data.
- Godot 4.7.2 project in `game/`, GUT 9.7.1 in `game/addons/gut`.
- Core: `economy`, `economy_state`, `economy_db`, `rest` (M8.6), `portal` (M10.0), `stage` (waves, M7.B), `npc_react`, `save_slots`, `rng`, `game_state` (SAVE_VERSION=16), `save_migrations` (1→…→16), `inn_state`, `guests`, `standing`, `cooking`, `traps`, `combat_db`, `stats`, `combat_state`, `combat`, `monster_sim`, `save_codec`, `behaviour_db`, `utility_ai`, `npc_roster`, `npc_sim`, `map_db`, `player_state`, `movement`, `interact`, `pathfind`, `canon_db`, `world_state`, `director`, `clock`, `tags`, `data_db`, `action_log`, `xp`, `actions`, `progression`, `levels`, `skill_system`, `class_system`, `night`, `commands`.
- Audio (M12.0-M12.5): `world/music_pick.gd`, `world/ambience_pick.gd`, autoload `Audio` (`ui/audio.gd`), `ui/audio_db.gd`, `ui/audio_settings.gd`, `ui/options_menu.tscn`, `data/audio.json`, `world/sound_cues.gd`, `game/default_bus_layout.tres`, `game/assets/audio/`.
- UI: `ui/title_menu.tscn` (main scene), `ui/pause_menu.tscn`, `ui/slot_list.tscn`, `ui/journal.tscn`, `ui/session.gd` (autoload), `ui/hud.tscn` (HP line), `ui/interact_menu.tscn`, `ui/system_messages.gd`, `ui/system_dialog.tscn`, `ui/character_sheet.tscn`, `ui/console_commands.gd`, `ui/debug_console.tscn` (also the overlay). World: `world/main.tscn` (main scene), `world/world_view.tscn`.
- Data: `tiles.json`, `maps/` (liscor_gate, liscor_market, floodplains_south, inn_hill, inn_interior, ruins_entrance, celum_gate, celum_square, celum_runners_guild, road_camp, celum_frenzied_hare, esthelm_ruins, bee_cave, celum_stitchworks, dungeon_rift), `npc_behaviour.json`, `enemies.json`, `items.json`, `economy.json`; rules `npc`, `combat`, `winter`, `economy`, `portal`.
- Tests: 86 GUT scripts, 800 tests, all pass, headless exit 0 (main after M12.5). Python tool tests: 77 pass (`python -m unittest discover -s tools/tests`).
- Canon: Book 5 has days 97–111 (4.06 M – 4.17) and Geneva's 1.02 D – 1.06 D (days 77–90, off-map) on main; and 4.18 – 4.23 E (days 106–118); the M13.6 branch adds 4.24 – 4.27 H (days 110–113). 4.00 K – 4.06 K are history notes in ADR 0020.
- Main after M13.T: 90 GUT scripts, 836 tests; save v14; `core/traps.gd`. Main after M13.1: 92 GUT scripts, 849 tests. Main after M13.2: 93 GUT scripts, 861 tests. Main after M13.3: 94 GUT scripts, 871 tests. Main after M13.4: 95 GUT scripts, 876 tests. Main after M13.5: 96 GUT scripts, 888 tests. Main after M13.6: 97 GUT scripts, 902 tests. M13.7 branch: 98 GUT scripts, 914 tests, all pass; Python 78 OK; validator 0 errors; 44 enemies. Maps now 20 (+ esthelm_creler_cave in M13.6), 19 (+ inn_upper_floor, inn_watchtower, liscor_depths, liscor_crypt). Enemies 43 (M13.6: creler_hatchling, creler_juvenile).
- Tools: `tools/extract_epub.py`, `tools/validate_data.py`, `tools/build_sprites.py`, `tools/build_objects.py`, `tools/build_creatures.py` (all need Pillow: `pip install -r tools/requirements.txt`), `tools/build_sfx.py` (standard library only).

## Blockers
- None.

## Balance note
- M6.5: levels cost less (base_xp 40, growth 1.25). A hard inn worker: first class on night 1–3, level 5 by about day 18–21 (`sim_m6_done`: [Cook] level 6 by day 22). Canon Erin is level 9 by day 9; the player is not meant to match her.

## Repo
- Public: https://github.com/Daddy-Ousen/innworld-rpg, branch `main`.

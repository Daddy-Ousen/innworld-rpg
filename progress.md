# Progress

M0–M8 detail (roadmap bullets, decisions, ADR 0001–0015) lives in
`docs/PROGRESS_ARCHIVE.md`. Read the archive only when you need that old detail.

## Context discipline (all sessions)
- Redirect GUT / validator runs to a file (scratchpad). Read only the pass/fail summary line and any FAIL/Error/Parse Error lines — never the full run.
- Delegate chapter-text reading (for canon extraction) and full test-suite runs to a subagent. Only its short summary should land in the main session's context, not raw book text or raw test logs.
- Don't re-read a file right after Edit/Write — the tool already confirms the change.
- See `handoff.md` "Gotchas" for the GUT-exits-0-on-parse-error trap and other run-output pitfalls.

## Roadmap status
- [x] M0–M7 — Book 1 and the engine. Tags `m0-done` … `m7-done`, `m7.4-done`, `m7b-done`.
- [x] M8 — Book 2 (Fae and Fare) + Celum. M8.0–M8.6 merged and tagged; M8.7 merged ([PR #34](https://github.com/Daddy-Ousen/innworld-rpg/pull/34), tags `m8.7-done` and `m8-done` on merge commit ad436eb). Detail in the archive and ADR 0014 / 0015.
- [ ] M9 — Book 3 (Flowers of Esthelm). Plan approved 2026-09-26 (ADR 0016, ROADMAP M9). 4 batches:
  - [x] M9.1 3.00 E – 3.05 L + 1.00 D / 1.01 D — merged ([PR #36](https://github.com/Daddy-Ousen/innworld-rpg/pull/36)), tag `m9.1-done` (4b31284). 39 events, Persua guild fight (stage) + Lyonette reopening (scene), both with hooks.
  - [x] M9.2 3.06 L – 3.14 — built on branch `data/book3-3.06-3.14` (PR pending merge). 41 events; Ryoka and Fals at the Hare (scene + hook); Corusdeer soup keeps the cold off (save v12). GUT 609/609 (65 scripts), validator 0 errors (`--all`), Python 51/51.
  - [ ] M9.3 3.15 – 3.20 T (Esthelm map + siege stage)
  - [ ] M9.4 3.21 L – 3.25

## After M8
- [x] Ryoka never gains a level (user, 2026-09-26): merged ([PR #35](https://github.com/Daddy-Ousen/innworld-rpg/pull/35)).

## Completed (current engine state)
- Canon: Book 1 (1.00–1.63, days 1–41) and Book 2 (Interlude – The Call to 2.48, days 41–71) are complete event data. Book 3: 3.00E–3.14 + 1.00D/1.01D (days 71–80, M9.1–M9.2).
- Godot 4.7.2 project in `game/`, GUT 9.7.1 in `game/addons/gut`.
- Core: `economy`, `economy_state`, `economy_db`, `rest` (M8.6), `stage` (waves, M7.B), `npc_react`, `save_slots`, `rng`, `game_state` (SAVE_VERSION=12), `save_migrations` (1→…→12), `combat_db`, `stats`, `combat_state`, `combat`, `monster_sim`, `save_codec`, `behaviour_db`, `utility_ai`, `npc_roster`, `npc_sim`, `map_db`, `player_state`, `movement`, `interact`, `pathfind`, `canon_db`, `world_state`, `director`, `clock`, `tags`, `data_db`, `action_log`, `xp`, `actions`, `progression`, `levels`, `skill_system`, `class_system`, `night`, `commands`.
- UI: `ui/title_menu.tscn` (main scene), `ui/pause_menu.tscn`, `ui/slot_list.tscn`, `ui/journal.tscn`, `ui/session.gd` (autoload), `ui/hud.tscn` (HP line), `ui/interact_menu.tscn`, `ui/system_messages.gd`, `ui/system_dialog.tscn`, `ui/character_sheet.tscn`, `ui/console_commands.gd`, `ui/debug_console.tscn` (also the overlay). World: `world/main.tscn` (main scene), `world/world_view.tscn`.
- Data: `tiles.json`, `maps/` (liscor_gate, liscor_market, floodplains_south, inn_hill, inn_interior, ruins_entrance, celum_gate, celum_square, celum_runners_guild, road_camp, celum_frenzied_hare), `npc_behaviour.json`, `enemies.json`, `items.json`, `economy.json`; rules `npc`, `combat`, `winter`, `economy`.
- Tests: 65 GUT scripts, 609 tests, all pass, headless exit 0. Python tool tests: 51 pass (`python -m unittest discover -s tools/tests`).
- Tools: `tools/extract_epub.py`, `tools/validate_data.py`.

## Blockers
- None.

## Balance note
- M6.5: levels cost less (base_xp 40, growth 1.25). A hard inn worker: first class on night 1–3, level 5 by about day 18–21 (`sim_m6_done`: [Cook] level 6 by day 22). Canon Erin is level 9 by day 9; the player is not meant to match her.

## Repo
- Public: https://github.com/Daddy-Ousen/innworld-rpg, branch `main`.

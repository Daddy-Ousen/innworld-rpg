# Progress

## Roadmap status
- [x] M0 — Setup (done 2026-09-23, tag `m0-done`)
- [x] M1 — Sim core (done 2026-09-23, PR #2 merged, tag `m1-done`)
  - [x] Schemas: ADR 0002 accepted (outcome_mult yes, tags.json registry yes)
  - [x] Clock, tags, data loader, action log, XP, `Actions.perform` (part 1, PR #1 merged)
  - [x] Part 2: classes (17), skills (47), pools, offers, decline blacklist, levels, dilution, capstones, class loss, consolidation, night pipeline 1–4 + 8, `Commands` facade, debug console, `sim_30_days`, `sim_decline`
- [x] M2 — Canon pipeline (done 2026-09-23, PR #3 merged, tag `m2-done`)
  - [x] `tools/extract_epub.py` + tests. Book 1: 66 chapters, ~448k words, 6 images skipped.
  - [x] Schemas (ADR 0004 accepted) + `tools/validate_data.py` + tests (26 Python tests pass).
  - [x] Events 1.00–1.09 (now in `game/data/canon/book1/`): 26 events, 10 NPCs, 15 locations, all `reviewed`; validator 0 errors.
- [x] M3 — World director (done 2026-09-23 on branch `feat/m3-world-director`; PR to open; tag `m3-done` after merge)
  - [x] Canon data moved to `game/data/canon/` (user choice).
  - [x] `CanonDb` loader, `WorldState` (save v3), `Director` (night step 5), rules `director` section.
  - [x] `Commands.kill_npc` / `set_flag`; console `kill`, `flag`, `history`, `drift`.
  - [x] Tests: `unit_canon_db`, `unit_director`, `sim_divergence` (3 scenarios), `sim_canon_book1` (real week 1, drift 0).
- [ ] M4 … M6 — see `docs/ROADMAP.md`

## Completed
- Godot 4.7.2 project in `game/`, GUT 9.7.1 in `game/addons/gut`.
- Core: `rng`, `game_state` (SAVE_VERSION=3), `save_migrations` (1→2→3), `canon_db`, `world_state`, `director`, `clock`, `tags`, `data_db`, `action_log`, `xp`, `actions`, `progression`, `levels`, `skill_system`, `class_system`, `night`, `commands`.
- UI: `ui/console_commands.gd`, `ui/debug_console.tscn` (main scene).
- Tests: 19 GUT scripts, 156 tests, all pass, headless exit 0. Python tool tests: 26 pass (`python -m unittest discover -s tools/tests`).
- Tools: `tools/extract_epub.py`, `tools/validate_data.py`.

## Blockers
- None.

## Repo
- Public: https://github.com/Daddy-Ousen/innworld-rpg, branch `main`.

## Architectural decisions
- ADR 0001: GUT version, RNG state as strings in JSON, `.import` files committed, save load path.
- ADR 0002: data schemas (tags, actions, rules, classes, skills), XP formula, clock as one absolute minute counter, saves use full float precision and keep key order.
- ADR 0003: non-zero-sum class pools, decline freezes the pool, offer order and cap, dilution formula, capstone breakthroughs, skill pick weights, xp_mult applied in XP, class loss, night pipeline, `Commands` facade.
- ADR 0004 (accepted): extractor rules; canon data layout (`npcs.json`, `locations.json`, `chapters/<ch>.json`), event schema changes vs DESIGN §4.3 (window.confidence, optional roles, tag-only roles, on_fail ends in cancel, delay_limit, clear_flags, rumor, tier 1–2), chapter `system` log, validator with 7-word copy check.
- ADR 0005 (accepted): canon data in `game/data/canon/`, `CanonDb`, `WorldState` stores only changes (save v3), director rules (strict `requires.alive`, anonymous monster roles, wait/role/hard failures, propagation after cancel or mutate, effect remap to substitutes), drift weights in `rules.json` `director`.

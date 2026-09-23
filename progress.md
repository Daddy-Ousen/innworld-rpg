# Progress

## Roadmap status
- [x] M0 — Setup (done 2026-09-23, tag `m0-done`)
- [x] M1 — Sim core (code done 2026-09-23; PR #2 open; tag `m1-done` after merge)
  - [x] Schemas: ADR 0002 accepted (outcome_mult yes, tags.json registry yes)
  - [x] Clock, tags, data loader, action log, XP, `Actions.perform` (part 1, PR #1 merged)
  - [x] Part 2: classes (17), skills (47), pools, offers, decline blacklist, levels, dilution, capstones, class loss, consolidation, night pipeline 1–4 + 8, `Commands` facade, debug console, `sim_30_days`, `sim_decline`
- [ ] M2 — Canon pipeline (next)
- [ ] M3 … M6 — see `docs/ROADMAP.md`

## Completed
- Godot 4.7.2 project in `game/`, GUT 9.7.1 in `game/addons/gut`.
- Core: `rng`, `game_state` (SAVE_VERSION=2), `save_migrations` (1→2), `clock`, `tags`, `data_db`, `action_log`, `xp`, `actions`, `progression`, `levels`, `skill_system`, `class_system`, `night`, `commands`.
- UI: `ui/console_commands.gd`, `ui/debug_console.tscn` (main scene).
- Tests: 15 scripts, 115 tests, all pass, headless exit 0.

## Blockers
- None. ADR 0003 accepted 2026-09-23.

## Repo
- Public: https://github.com/Daddy-Ousen/innworld-rpg, branch `main`.

## Architectural decisions
- ADR 0001: GUT version, RNG state as strings in JSON, `.import` files committed, save load path.
- ADR 0002: data schemas (tags, actions, rules, classes, skills), XP formula, clock as one absolute minute counter, saves use full float precision and keep key order.
- ADR 0003: non-zero-sum class pools, decline freezes the pool, offer order and cap, dilution formula, capstone breakthroughs, skill pick weights, xp_mult applied in XP, class loss, night pipeline, `Commands` facade.

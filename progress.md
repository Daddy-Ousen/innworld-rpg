# Progress

## Roadmap status
- [x] M0 — Setup (done 2026-09-23, tag `m0-done`)
- [ ] M1 — Sim core (in progress)
  - [x] Schemas: ADR 0002 accepted (outcome_mult yes, tags.json registry yes)
  - [x] Clock (`core/clock.gd`)
  - [x] Tag system + data loader (`core/tags.gd`, `core/data_db.gd`, `data/tags.json`, `data/actions.json` 32 actions, `data/rules.json`)
  - [x] Action log + XP formula + perform command (`core/action_log.gd`, `core/xp.gd`, `core/actions.gd`)
  - [ ] Classes, offers, decline blacklist, levels, dilution, skills, night pipeline, debug console, `sim_30_days` (M1 part 2)
- [ ] M2 … M6 — see `docs/ROADMAP.md`

## Completed
- Godot 4.7.2 project in `game/`, GUT 9.7.1 in `game/addons/gut`.
- `core/rng.gd`, `core/game_state.gd` (SAVE_VERSION=1), `core/save_migrations.gd`.
- M1 part 1: clock, tags, data loader, action log, XP, `Actions.perform`. GameState now has `clock`, `action_log`, `focus_tags` (placeholder `data` removed).
- Tests: 8 scripts, 55 tests, all pass, headless exit 0.

## Blockers
- None.

## Repo
- Public: https://github.com/Daddy-Ousen/innworld-rpg, branch `main`.

## Architectural decisions
- ADR 0001: GUT version, RNG state as strings in JSON, `.import` files committed, save load path.
- ADR 0002: data schemas (tags, actions, rules, classes, skills), XP formula, clock as one absolute minute counter, saves use full float precision and keep key order.

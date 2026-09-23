# Progress

## Roadmap status
- [x] M0 — Setup (done 2026-09-23, tag `m0-done`)
- [ ] M1 — Sim core (next)
- [ ] M2 … M6 — see `docs/ROADMAP.md`

## Completed
- Godot 4.7.2 project in `game/`, GUT 9.7.1 in `game/addons/gut`.
- `core/rng.gd` (Rng), `core/game_state.gd` (GameState, SAVE_VERSION=1), `core/save_migrations.gd`.
- Tests: `tests/unit_rng.gd`, `tests/unit_game_state.gd` — 8/8 pass, headless exit 0.

## Blockers
- None.

## Architectural decisions
- ADR 0001 (`docs/adr/0001-m0-setup.md`): GUT version, RNG state as strings in JSON, `.import` files committed, save load path.

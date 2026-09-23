# Handoff

## Just done
M0 finished, tagged `m0-done`. Branch `main` is pushed to https://github.com/Daddy-Ousen/innworld-rpg (public). Git author for this repo (local config): Daddy-Ousen, GitHub noreply email.

## Next
Start M1 (see `docs/KICKOFF.md` Session 2 prompt): plan data schemas for actions, classes, skills; show them to the user before code.

## Gotchas
- Fresh clone: run `godot --headless --path game --import` once before tests (builds the class cache in `game/.godot/`).
- GUT file prefix is empty in `game/.gutconfig.json`; test files are named `unit_*.gd` / `sim_*.gd`.
- Use `JSON.new().parse()`, not `JSON.parse_string()` (the static one logs engine errors that GUT counts as failures).
- 64-bit ints in JSON must be strings (see `Rng.to_dict`).
- `GameState.data` is a placeholder dict; replace with typed fields in M1 and bump SAVE_VERSION only after a save format exists in use.
- Rng methods shadow global `randi()`/`randf()` names on purpose; always call them on an Rng instance.

## Active files
`game/core/rng.gd`, `game/core/game_state.gd`, `game/core/save_migrations.gd`, `game/tests/`, `docs/ROADMAP.md`.

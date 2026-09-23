# ADR 0001 — M0 setup choices

Date: 2026-09-23 · Status: accepted

## GUT version
Godot is 4.7.2. GUT 9.7.1 is used. GUT 9.7.0 added Godot 4.7 compatibility. The addon is vendored in `game/addons/gut`.
`.gutconfig.json` sets an empty file prefix, so GUT finds `unit_*.gd` and `sim_*.gd` (its default prefix is `test_`).

## RNG state in JSON
`Rng` stores `seed` and `state` as **strings**. Godot parses JSON numbers as floats, and a 64-bit value loses precision. Strings keep the RNG exact across save/load.

## `*.import` files are committed
ROADMAP M0 listed `*.import` for `.gitignore`. Godot 4 docs say to commit `.import` files (they hold import settings) and ignore only `.godot/`. We follow the Godot docs.

## Save loading
`GameState.load_from_file` → `from_json` → `SaveMigrations.migrate` → `from_dict`. A save with a newer `save_version`, or invalid JSON, returns `null` with a `push_error`.
We parse with `JSON.new().parse()`, not `JSON.parse_string()`, because the static call also logs an engine error on bad input.

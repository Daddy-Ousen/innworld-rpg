# Handoff

## Just done
M1 part 1 is done. It is on branch `feat/m1-sim-core-part1`, PR https://github.com/Daddy-Ousen/innworld-rpg/pull/1 (not merged yet). Local `main` = `origin/main`. ADR 0002 accepted. Built: `core/clock.gd`, `core/tags.gd`, `core/data_db.gd`, `core/action_log.gd`, `core/xp.gd`, `core/actions.gd`; data `tags.json`, `actions.json` (32), `rules.json`. GameState has typed fields. 55/55 tests pass.

## Next (M1 part 2, see docs/KICKOFF.md Session 3)
1. `data/classes.json` (~15) and `data/skills.json` (~40) per ADR 0002. Extend `DataDb` to load + validate them (tags must exist in `tags.json`).
2. Class candidate pools fed from action records (xp × `Tags.match_weight(class.tag_weights, tag)`), offers (max 2/night), accept/decline, permanent blacklist.
3. Levels: `rules.levels` (base_xp 100, growth 1.35, capstones 10/20/30), multi-class dilution.
4. Skills from weighted pools (`tag_affinity` × `action_log.tag_totals`), picked with `gs.rng`.
5. Night pipeline steps 1–4 and 8. Use `Clock.sleep(rules, collapsed)`; it returns calendar days passed.
6. Debug text console scene. Then `sim_30_days` test + decline test.

## Gotchas
- Commits: author Daddy-Ousen only. NO `Co-Authored-By: Claude` trailer (user request).
- After adding a new `class_name` script, run `godot --headless --path game --import` once, or tests cannot find the class.
- GUT file prefix is empty in `game/.gutconfig.json`; test files are named `unit_*.gd` / `sim_*.gd`.
- Use `JSON.new().parse()` for untrusted text (the static `parse_string` logs engine errors on bad input).
- JSON numbers load as floats. `from_dict` must cast int fields (see `ActionLog.from_dict`, `Clock.from_dict`). Dictionary `==` treats 1 and 1.0 as different.
- `GameState.to_json` uses `sort_keys=false, full_precision=true`. Keep it: it makes a loaded game continue exactly the same (tested in `unit_actions.gd`).
- Day = calendar day from `clock.total_minutes`. It is NOT "number of sleeps".
- `Actions.perform` returns `{}` while a collapse is due. The night pipeline must then call `clock.sleep(rules, true)`.
- GUT `.import` files show as modified in git: line endings only (CRLF). Do not commit them.

## Active files
`game/core/*.gd`, `game/data/*.json`, `game/tests/unit_*.gd`, `docs/adr/0002-m1-data-schemas.md`, `docs/ROADMAP.md`.

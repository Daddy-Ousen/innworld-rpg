# Handoff

## Just done
M1 part 2 is done on branch `feat/m1-sim-core-part2` (4 commits on top of `main`). PR #1 (part 1) was merged before this work.
Built: `core/progression.gd`, `levels.gd`, `skill_system.gd`, `class_system.gd`, `night.gd`, `commands.gd`; `data/classes.json` (17), `data/skills.json` (47), `rules.skills`; save version 2 + migration; `ui/console_commands.gd` + `ui/debug_console.tscn` (main scene); tests `sim_30_days`, `sim_decline` and unit tests. 115/115 tests pass, headless exit 0. All design choices are in `docs/adr/0003-m1-class-system.md`.

## Waiting on the user
- ADR 0003 accepted (all 3 items approved 2026-09-23).
- Branch pushed, PR open (see progress.md). After merge: `git tag m1-done`.

## Next (M2, see docs/KICKOFF.md Session 4)
1. `tools/extract_epub.py` → `canon/raw/book1/` + `index.json`.
2. Event/NPC/location schemas + `tools/validate_data.py`.
3. Event candidates from the first ~10 chapters; stop for human review.
4. While reading chapters: check class/skill `canon_ref` in `classes.json` / `skills.json` (most are `likely`/`guess`, chapter `null`).

## Gotchas
- Commits: author Daddy-Ousen only. NO `Co-Authored-By: Claude` trailer (user request).
- After adding a new `class_name` script, run `godot --headless --path game --import` once, or tests cannot find the class.
- Test helper `ToyData` lives in `game/test_support/` (not `tests/`: GUT warns on non-test scripts there).
- GUT file prefix is empty in `game/.gutconfig.json`; test files are `unit_*.gd` / `sim_*.gd`.
- Pools and class XP change only at night (`Night.run`), not during the day.
- `sim_30_days` trace is printed with `gut.p`. If you change tuning numbers, the trace changes; the tests check determinism and minimums, not exact values.
- Console text uses `RichTextLabel` with BBCode off: class names contain `[` `]`.
- Presentation must call `Commands.*` only (rule 1). `ConsoleCommands` follows this.
- JSON numbers load as floats. `from_dict` casts int fields (`Progression.from_dict` too).
- In Git Bash, never run `cat > file` without a heredoc: it waits on stdin and hangs.
- GUT `.import` files show as modified in git: line endings only (CRLF). Do not commit them.

## Active files
`game/core/{progression,levels,skill_system,class_system,night,commands}.gd`, `game/data/{classes,skills,rules}.json`, `game/ui/*`, `game/tests/{sim_*,unit_*}.gd`, `docs/adr/0003-m1-class-system.md`.

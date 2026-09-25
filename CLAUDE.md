# Innworld RPG — rules for AI agents

Fan-made, non-commercial RPG set in *The Wandering Inn* (pirateaba).
The player is an unnamed Earther who arrives at the start of Book 1.
Read `docs/DESIGN.md` before any system work. Read `docs/ROADMAP.md` to see the current milestone.

## Stack
- Engine: Godot 4.x, GDScript only. No C#, no GDExtension.
- Tests: GUT (Godot Unit Test) in `game/addons/gut`.
- Tools: Python 3.12+ in `tools/` (content extraction only; never shipped with the game).
- Data: JSON in `game/data/`. No YAML (Godot has no native parser).
- Platform: Windows first. Use PowerShell commands in docs and scripts.

## Layout
```
CLAUDE.md
docs/                 design, roadmap, decisions (ADRs)
game/                 Godot project root (project.godot lives here)
  core/               pure simulation logic — NO Node, NO scene, NO rendering
  data/               classes, skills, actions, rules (JSON)
    canon/book<N>/    reviewed canon: npcs.json, locations.json, chapters/<ch>.json
  world/              scenes, maps, tilesets (presentation)
  ui/                 UI scenes and scripts (presentation)
  tests/              GUT tests (unit_*.gd, sim_*.gd)
tools/                python: epub → chapters, event extraction helpers
canon/
  raw/                extracted chapter text  (gitignored — copyrighted)
The Wandering Inn Books 1-17 Pirateaba/   source epubs (read-only, gitignored)
```

## Hard rules
1. **Core is headless.** Everything in `game/core/` extends `RefCounted` or `Resource`. It must run in `godot --headless` with no scene tree. Presentation reads state and sends commands; it never changes state directly.
2. **One source of truth.** All game state lives in one `GameState` object. It serialises to JSON for save/load. Anything not in `GameState` does not exist after a load.
3. **Deterministic.** All randomness goes through `core/rng.gd` (seeded). Never call `randi()`/`randf()` directly. Same seed + same commands = same result.
4. **Content is data.** Classes, skills, action tags, NPCs, events: JSON in `game/data/`. Do not hard-code content in scripts. New books add data, not engine code.
5. **Canon is data, not script.** Canon events are nodes with roles, preconditions, fallbacks and effects (see DESIGN §4). Never write `if day == 12: kill(x)`.
6. **Tests before done.** Every core feature gets GUT tests. Run the full suite before each commit. A task is not done if tests fail.
7. **Small commits.** One feature per commit. Conventional message: `feat(core): …`, `fix(director): …`, `data(book1): …`.
8. **Save format is versioned.** `GameState.save_version`. Any schema change adds a migration in `core/save_migrations.gd`.
9. **Lore accuracy.** Canon source is the **Book 1 ebook (rewrite)**, not the web serial. The wikis follow the web serial — use them for background only and flag conflicts. Do not invent canon facts; mark guesses with `"confidence": "guess"` in data.
10. **No copyrighted text in git.** Never commit book text. Event JSON holds short summaries in your own words plus chapter references.
11. **Ask before** adding a dependency/addon, changing a JSON schema, or changing a rule in this file.

## Commands (from repo root; work in Git Bash and PowerShell)
Note: your shell tool on Windows is Git Bash. Use forward slashes and quote paths with spaces. Write user-facing docs and scripts for PowerShell.
```powershell
# run all tests headless
godot --headless --path game -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit

# run the game
godot --path game

# extract epub chapters (M2)
python tools/extract_epub.py "The Wandering Inn Books 1-17 Pirateaba/Book 1 - The Wandering Inn.epub" canon/raw/book1

# validate canon data
python tools/validate_data.py game/data/canon/book1
```
If `godot` is not on PATH, use the full path to the Godot exe or set `$env:GODOT`.

## Workflow per task
1. Read the milestone in `docs/ROADMAP.md`.
2. Plan first (plan mode). List files you will touch.
3. Write tests, then code.
4. Run tests. Fix until green.
5. Update `docs/ROADMAP.md` checkboxes and add an ADR in `docs/adr/` for any design decision.
6. Commit.

## Context discipline (agreed 2026-09-25, see `progress.md`)
Canon batches and full test runs blow up context fast. To keep quality without the bloat:
- Redirect GUT / validator runs to a scratchpad file. Read back only the summary line and any FAIL/Error/Parse Error lines, never the full run.
- Delegate chapter-text reading (for canon extraction) and full test-suite runs to a subagent (Agent tool). Only its short summary should return to the main session — not raw book text or raw test logs.
- Don't re-read a file right after Edit/Write.
- Keep `progress.md` to current-milestone status only; finished milestones live in `docs/PROGRESS_ARCHIVE.md`.

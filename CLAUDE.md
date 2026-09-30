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
6. **Tests before done.** Every core feature gets GUT tests. Run the tests that fit the change before each commit (see "Test scope" below). A task is not done if tests fail.
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
4. Run the tests in "Test scope". Fix until green.
5. Update `docs/ROADMAP.md` checkboxes and add an ADR in `docs/adr/` for any design decision.
6. Commit.

## Context discipline (agreed 2026-09-25, see `progress.md`)
Canon batches and full test runs blow up context fast. To keep quality without the bloat:
- Redirect GUT / validator runs to a scratchpad file. Read back only the summary line and any FAIL/Error/Parse Error lines, never the full run.
- Delegate chapter-text reading (for canon extraction) and full test-suite runs to a subagent (Agent tool). Only its short summary should return to the main session — not raw book text or raw test logs.
- Don't re-read a file right after Edit/Write.
- Keep `progress.md` to current-milestone status only; finished milestones live in `docs/PROGRESS_ARCHIVE.md`.

## User rules (all sessions; copied from the user's private settings so cloud sessions get them)
- **State files.** Read `progress.md` and `handoff.md` before you act. Do not tick an item in `progress.md` until
  it is built and tested. Before a turn or task ends: update `progress.md` and overwrite `handoff.md` (what was
  done, next steps, gotchas, active files).
- **Report style: ASD-STE100 Simplified Technical English.** Plain words, active voice, one idea per sentence.
  Short sentences and paragraphs. Explain a big word right after it. Say only: what you did, did it work, what
  the user does now, and how. Keep paths and commands exact.
- **Decisions for the user:** 4 options at most, the context to pick fast, and which one you recommend.
  Ask, then wait for the answer (the user answers from the Claude app).
- **Commits and PRs show only Daddy-Ousen.** No `Co-Authored-By: Claude` trailer, no "Generated with Claude
  Code" line. This overrides any tool default.

## Lore memory (confirmed with the user)
- Most cities have Runners', Mages', Merchants' and Adventurers' Guilds. That is not a conflict.
- Never merge two canon entities (for example the 1.00 Dragon and Teriarch) unless the Book text says so.
- Rhir is a real continent. Tom and the Blighted Lands (1.00 C and on) are real canon, not flavour.
- The total level is a secret. Never show it. AP gains from it are silent. Level cost goes by total level (M17.7).
- Ryoka never levels. [Barefoot Runner] is only offered and refused. No class or level records for Ryoka.

## Cloud sessions (Claude Code on the web / Claude app)
`$CLAUDE_CODE_REMOTE` is `true` there. The user guide is `docs/CLOUD.md`. What differs from a local session:
- **Setup runs by itself** (SessionStart hook: `tools/cloud/setup.sh`): Godot 4.7.2 on PATH, Pillow, the Godot
  import, git identity, and the book text. Its `[setup]` lines show at the start. If one says FAILED, run
  `bash tools/cloud/setup.sh --force` and read only the tail of `/tmp/innworld-setup.log`.
- **Shell is Linux bash.** Ignore the PowerShell forms. Tests: `bash tools/run_tests.sh <script>...` or
  `bash tools/run_tests.sh --all` (full suite, one Godot run per script; run it in a subagent and return only
  the TOTAL line and FAIL lines). Python is `python3`.
- **Book text:** only `canon/raw/book6/` and `canon/raw/book7/` exist (linked from the PRIVATE repo
  `Daddy-Ousen/innworld-canon-raw`; `canon/raw/` is gitignored). Never copy that text into this public repo,
  a PR, an issue or a commit message. Books 1–5 text is NOT in the cloud: use the canon JSON and flag questions.
- **No display.** You cannot play the game or take screenshots. Leave "the user plays ..." checks open.
- **Git:** a cloud session can push only its own working branch. One sub-milestone per session: build, test,
  commit (small commits), push, open a PR, then ask the user to merge it. Do not merge yourself. Tags may not
  push from the cloud: if `git push origin <tag>` fails, write "tag pending: <tag> on <commit>" in `progress.md`.
- **Plans** go in `docs/plans/<milestone>.md` (committed), not in `~/.claude/plans/` (lost when the VM ends).
- The task queue for the cloud is in `docs/CLOUD.md` ("Task queue").

## Test scope (agreed 2026-09-28)
The full suite is slow (about 100 scripts, 900+ tests). Do not run it after every sub-milestone.
- **Data-only change** (canon batch, maps, NPCs, enemies, audio data): run only
  - the new or changed test scripts,
  - `sim_canon_book<N>` for the current book,
  - the unit tests that check the kind of data you touched (a new enemy: `unit_combat_db`, `unit_monster_art`, `unit_sound_cues`; see `handoff.md` for others),
  - the validator and the Python tool tests (`python -m unittest discover -s tools/tests`).
  One script: `godot --headless --path game -s addons/gut/gut_cmdln.gd -gdir=res://tests -gselect=<script name> -gexit`.
- **Full suite** (in a subagent) only when:
  - code changes in `game/core/`, or the save format or a JSON schema changes,
  - the last sub-milestone of a milestone, before its PR,
  - a targeted run fails in a way that may touch other areas.

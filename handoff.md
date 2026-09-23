# Handoff

## Just done (2026-09-23, branch `feat/m2-canon-pipeline`)
M2 is done and committed locally (not pushed):
- `tools/extract_epub.py` + tests → `canon/raw/book1/` (66 chapters + `index.json`, gitignored).
- `tools/validate_data.py` + tests (ADR 0004 accepted).
- `canon/events/book1/`: `npcs.json` (10), `locations.json` (15), `chapters/1.00.json` … `1.09.json` (26 events, `system` logs). All records `status: "reviewed"`. Validator: 0 errors.
- User chose to keep relationship deltas (design values, marked in `canon_ref.note`).
- ROADMAP M2 ticked. GUT 115/115, Python 26/26.

## Waiting on the user
- Push branch + open PR? After merge: `git tag m2-done`.
- Game-data suggestions (not applied): `[Guardsman]` canon_ref → 1.06 confirmed. Missing from data: skill `[Basic Crafting]` (Innkeeper Lv5), class `[Gatherer]` + skill `[Detect Poison]`, skill `[Detect Guilt]`, skill `[Dangersense]`, classes `[Spearmaster]`, `[Swordslayer]`.

## Next (M3, world director)
- Needs a loader for `canon/events/` (outside `game/`). Decide: copy/export step, or move canon data into `game/data/canon/`. Ask the user (rule 11 if it changes layout).
- Open canon questions to confirm while reading on: id `rags` (guess), id `high_passes` (guess), Pisces = 1.04 bone thief (`likely`).
- Continue event extraction from 1.10 / interlude onward, one chapter per file.

## Gotchas
- Commits: author Daddy-Ousen only. NO `Co-Authored-By: Claude` trailer.
- Godot class cache goes stale after checkout/merge: `unit_console.gd` fails to parse and GUT shows 107/14 instead of 115/15. Fix: `godot --headless --path game --import`, then re-run.
- Python 3.14; use `python -X utf8` in Git Bash when printing book text.
- Python tests: `python -m unittest discover -s tools/tests` (no `-t .`).
- Validator auto-finds `canon/raw/book<N>`; `--no-raw` skips chapter-id + copy checks (CI has no raw text).
- Day 1 = Erin's arrival. 1.00–1.09 = days 1–7.
- In Git Bash, never run `cat > file` without a heredoc.
- GUT `.import` files show as modified: line endings only. Do not commit them.

## Active files
`tools/*.py`, `tools/tests/*`, `canon/events/book1/**`, `docs/adr/0004-m2-canon-schemas.md`.

# ADR 0004 — M2 canon pipeline: extractor and canon data schemas

Date: 2026-09-23 · Status: accepted (user approved 2026-09-23; relationship deltas kept as design values)

## Extractor — `tools/extract_epub.py`
- Stdlib only (`zipfile`, `xml.etree`, `html.parser`). No new dependency.
- Reads `META-INF/container.xml` → OPF → spine order. Titles come from the NCX table of contents.
- Skips: `<svg>`, `<image>`, `<img>`, `<head>`, and the centred art-credit paragraph right after an image. Skips spine items with no text (the cover).
- Output: `canon/raw/book1/NNN_<id>.txt` (paragraphs split by a blank line) and `index.json` (`order, id, title, file, source, word_count, images_skipped`).
- Chapter ids: `1.00`, `1.19R` (POV suffix kept), `interlude_the_great_ritual`.
- Book 1 result: 66 chapters, ~448k words, 6 images skipped.
- `canon/raw/` stays gitignored (copyrighted text).

## Canon data layout — `canon/events/book<N>/`
```
npcs.json                {"schema_version": 1, "npcs": {id: npc}}
locations.json           {"schema_version": 1, "locations": {id: location}}
chapters/<chapter>.json  {"schema_version": 1, "book": 1, "chapter": "1.00", "events": {id: event}, "system": [...]}
```
- One chapter file per chapter: an agent reads one chapter and writes one file. Easy to review.
- NPCs and locations are one registry per book (they recur across chapters). `canon_ref` = first appearance.
- Same conventions as ADR 0002: `schema_version: 1`, maps keyed by id, snake_case ids, `[Brackets]` in display names.

### Common fields
- `canon_ref`: `{"book", "chapter", "confidence", "note"?}`. `confidence` ∈ `confirmed | likely | guess`.
- `status`: `candidate | reviewed`. The agent writes `candidate`. A human sets `reviewed`.
- `summary`: own words, max 300 chars.

### Event (DESIGN §4.3 plus these changes)
```json
"b1.watch_spots_smoke": {
  "tier": 2,
  "window": {"earliest": 5, "latest": 5, "confidence": "confirmed"},
  "location": "liscor_walls",
  "roles": {"spotter": {"prefer": ["beilmark"], "fallback_tags": ["guard"], "optional": false}},
  "requires": {"alive": [], "flags": ["wandering_inn.chimney_smoke"], "not_flags": []},
  "depends_on": ["b1.erin_lights_kitchen_fire"],
  "on_fail": ["substitute", "delay", "cancel"],
  "delay_limit": 3,
  "effects": {"set_flags": [], "clear_flags": [], "kill": [], "relationship": [{"from": "a", "to": "b", "delta": 1}]},
  "rumor": "T1 only, optional: what the player hears.",
  "status": "candidate",
  "canon_ref": {"book": 1, "chapter": "1.05", "confidence": "confirmed"},
  "summary": "..."
}
```
Changes to the DESIGN sketch:
1. `window.confidence` — the book gives few dates; the day window is often a guess even when the event is confirmed.
2. `roles.<r>.optional` — a role the director may leave empty (e.g. a watcher).
3. A role may have only `fallback_tags` (no named NPC). Monsters are roles by tag (`rock_crab`, `goblin`).
4. `on_fail` must end in `cancel`, so the director always terminates.
5. `delay_limit` (days), optional. `delay` without it gets a warning; M3 sets the default.
6. `effects.clear_flags` added; `relationship` entries are `{from, to, delta}`.
7. `rumor` (optional) for T1 news.
8. `tier` is 1 or 2 only. T3 is emergent and has no data.
9. Day 1 = the day Erin arrives (1.00).

### NPC
`name, race, tags[], faction|null, home (location id)|null, classes[{name, level|null}], alive_at_start, status, canon_ref, summary`.
`tags` feed role `fallback_tags`. `classes` = what is known at the start of the book.

### Location
`name, kind (region|settlement|district|building|landmark|wild), parent (location id)|null, tags[], status, canon_ref, summary`.

### Chapter `system` log
`[{who (npc id), kind (class|level|skill|other), name, level|null, confidence, note?}]` — System messages and class facts seen in the chapter. Used to tune `data/classes.json` / `skills.json`.

## Validator — `tools/validate_data.py`
- Stdlib only. Exit 0 = valid, 1 = errors.
- Checks: required/unknown keys, enums, id formats, windows, cross-references (NPCs, locations, events, mutate targets), `depends_on` cycles, a dependency that cannot start before the event's window ends, event id unique per book, event `canon_ref.chapter` = file chapter, location parent cycles.
- With `canon/raw/book<N>/` present (auto-detected, or `--raw`): chapter ids must exist in `index.json`, and no summary/rumor/note may share a 7-word run with that chapter's text (rule 10 guard).
- Tests: `python -m unittest discover -s tools/tests` (26 tests, synthetic data only).

## Decisions
- Schema accepted (rule 11).
- `status` is per record, so a chapter can be partly reviewed.
- Relationship deltas in events are design values (not canon); kept, and marked in `canon_ref.note`.

# Roadmap

Rule: finish a milestone's acceptance tests before starting the next. Tick boxes as you go.

## M0 — Setup
- [x] `git init`, `.gitignore` (books folder, `canon/raw/`, `.godot/`) — `*.import` is kept in git, see ADR 0001
- [x] Godot 4 project in `game/`, GUT installed in `game/addons/gut`
- [x] Folder layout from CLAUDE.md
- [x] `core/rng.gd` (seeded), `core/game_state.gd` (empty, save/load JSON, `save_version`)
- [x] One passing GUT test run from the headless command
**Done when:** the headless test command exits 0.

## M1 — Sim core (text only)
- [x] Clock: minutes, day counter, forced collapse
- [x] Action log + tag system (`data/actions.json`, 32 actions, `data/tags.json`)
- [x] XP formula with novelty/risk/conviction multipliers (+ outcome, ADR 0002)
- [x] Class candidates, offers, accept/decline, permanent blacklist (`data/classes.json`, ~15 classes)
- [x] Levels, exponential curve, multi-class dilution
- [x] Skills from weighted pools (`data/skills.json`, ~40 skills)
- [x] Night resolution pipeline (DESIGN §2), steps 1–4 and 8
- [x] Debug text console scene: type actions, sleep, see System messages
**Done when:** `sim_30_days` test drives 30 days of scripted actions with a fixed seed, and gets the same offers/levels every run; a decline test shows the class never returns.
  Done: `tests/sim_30_days.gd`, `tests/sim_decline.gd` (ADR 0003).

## M2 — Canon pipeline
- [x] `tools/extract_epub.py` → chapter text files + `index.json` (chapter id, title, word count)
- [x] Event/NPC/location JSON schemas + a validator (`tools/validate_data.py`) — ADR 0004
- [x] Extract the first ~10 chapters of Book 1 into event candidates; human review — 1.00–1.09, 26 events, reviewed
**Done when:** validator passes on `canon/events/book1/`.
  Done: `python tools/validate_data.py canon/events/book1` → 0 errors (ADR 0004).

## M3 — World director
- [ ] Event nodes, windows, roles, requires, `on_fail`, effects
- [ ] Substitute / delay / mutate / cancel + dependency propagation
- [ ] Drift value; T1 rumors in the morning summary
- [ ] Tests with toy data: "save a doomed NPC", "kill a future-important NPC", "prevent an event"
**Done when:** the three toy scenarios give the expected history and drift.

## M4 — 2D world
- [ ] Tilemap: the inn on the hill, a part of the Floodplains, Liscor gate + market
- [ ] Player movement on grid, interact, time cost per action
- [ ] NPC schedules + utility AI for ~10 NPCs
- [ ] System message UI (level-up / offer dialog)

## M5 — Combat
- [ ] Turn-based grid combat on the world map
- [ ] Book 1 enemies (start small: 3 types)
- [ ] Combat actions emit tags (attack, block, flee, improvise)

## M6 — Vertical slice
- [ ] The first ~14 in-game days of Book 1 playable end to end
- [ ] Save/load at any point; 3 divergence cases work in play
**Done when:** a new player can play two weeks, get a class, and change one canon event.

## Later
- M7: rest of Book 1 · M8: Book 2 data · optional LLM flavour layer · audio · polish

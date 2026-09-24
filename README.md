# Innworld RPG

A fan-made, non-commercial RPG set in *The Wandering Inn* by pirateaba.
You play an unnamed Earther. The Great Ritual pulls you into the world at the start of Book 1.

> The books define how the world begins. The player decides what happens next.

This repo holds no book text. The books and the world belong to pirateaba.

## What the game is
- **You level by living.** Every action gives XP to hidden class pools. At night the System can offer you a class. A declined class never comes back.
- **Nights move the world.** Sleep ends the day: levels, skills, class offers, canon events, then the next morning.
- **Canon is the default, not a rail.** If you do nothing, Book 1 happens as written. Your actions can change, delay or stop canon events, and the world reacts.
- **Simulation first.** A headless simulation with a top-down 2D view on top. Combat is turn-based on the same map grid.

## Status
Work in progress. Placeholder graphics, no audio.

| Milestone | What | State |
|---|---|---|
| M0–M3 | Setup, sim core (classes, skills, levels), canon pipeline, world director | Done |
| M4 | 2D world: Liscor gate and market, the Floodplains, the inn; NPC schedules; System dialog | Done |
| M5 | Combat: Goblins, Rock Crabs, Razorbeaks; improvised weapons; knock-out, no death | Done |
| M6 | Vertical slice: save slots, journal, player hooks on canon events, canon fights | Done |
| M7 | Rest of Book 1 as canon data; big battles | 7.1, 7.B, 7.2, 7.3 done · 7.4 next |
| M8 | Book 2 data, audio, polish | Later |

Book 1 canon so far: chapters 1.00–1.54 (days 1–37), 130 events, 47 NPCs, 44 locations.
Details: [docs/ROADMAP.md](docs/ROADMAP.md).

## Play
Needs [Godot 4.7](https://godotengine.org/) on your PATH (or use the full path to the Godot exe).

```powershell
godot --headless --path game --import   # once, after a fresh clone
godot --path game
```

A new game starts on day 8, outside the east gate of Liscor.

| Key | Action |
|---|---|
| WASD / arrows | Walk (walk into a foe to attack) |
| E | Use what is next to you (talk, work, take items) |
| Space | Wait |
| Z | Sleep (in a bed) |
| B / T / X | Block / throw / drop your held item |
| C | Character sheet |
| J | Journal (choose a focus, see news and your changes to canon) |
| Esc | Menu (save, load, quit) |
| `` ` `` (backquote) | Debug console |

The game saves itself each morning. There are 3 save slots.

## Run the tests (PowerShell)
```powershell
godot --headless --path game -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
python -m unittest discover -s tools/tests
python tools/validate_data.py game/data/canon/book1
```
GUT: 486 tests in 51 scripts. Python: 39 tests.

## Layout
```
docs/          design, roadmap, decisions (ADRs in docs/adr/)
game/          Godot project
  core/        headless simulation (no nodes, no scenes)
  data/        classes, skills, actions, enemies, maps (JSON)
    canon/     Book 1 events, NPCs and locations (JSON)
  world/ ui/   scenes and presentation
  tests/       GUT tests
tools/         Python: epub extraction and data validator (not shipped)
```

## Canon and copyright
- The canon source is the Book 1 ebook (rewrite), not the web serial.
- Canon events are short summaries in our own words, with chapter references. No book text is in git.
- Guesses are marked `"confidence": "guess"` in the data.

## Stack
Godot 4.7, GDScript, GUT 9.7. Python 3.12+ for tools.
Design: [docs/DESIGN.md](docs/DESIGN.md) · Roadmap: [docs/ROADMAP.md](docs/ROADMAP.md) · Rules for AI agents: [CLAUDE.md](CLAUDE.md)

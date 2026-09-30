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
Work in progress. Pixel art, music and sound are in. Books 1–5 are playable as canon data.

| Milestone | What | State |
|---|---|---|
| M0–M3 | Setup, sim core (classes, skills, levels), canon pipeline, world director | Done |
| M4–M6 | 2D world, NPC schedules, System dialog, combat, save slots, journal, player hooks | Done |
| M7 | Rest of Book 1 as canon data; big battles | Done |
| M8 | Book 2 (Fae and Fare) + Celum; economy, hunger, travel, winter | Done |
| M9 | Book 3 (Flowers of Esthelm) | Done |
| M10 | Book 4 (Winter Solstice) | Done |
| M11–M12 | Graphics, characters and animation; music, sound effects, ambience | Done |
| M13 | Book 5 (The Last Light); the dungeon depths, traps | Done |
| M14–M16 | Bag, cooking, guests, standing, UI skin, portraits; readability; maps, art and cities | Done |
| M17 | Tactical combat (XCOM-style): AP, turn order, combat Skills, mana and spells (M17.0–M17.7 done); hidden XP (M17.8, next) | In progress |
| Next | Book 6 (The General of Izril), Book 7 (The Rains of Liscor) | Planned |

Canon data today: 766 events, 223 NPC records and 99 locations over Books 1–5.

| Book | Chapters | Events |
|---|---|---|
| 1 The Wandering Inn | 1.00–1.63 | 151 |
| 2 Fae and Fare | Interlude – The Call to 2.48 | 207 |
| 3 Flowers of Esthelm | 3.00–3.25 | 157 |
| 4 Winter Solstice | 3.26–3.40 | 111 |
| 5 The Last Light | 4.00 K–4.31 | 140 |

Details: [docs/ROADMAP.md](docs/ROADMAP.md) and [progress.md](progress.md).

## Play
Needs [Godot 4.7](https://godotengine.org/) on your PATH (or use the full path to the Godot exe).

```powershell
godot --headless --path game --import   # once, after a fresh clone
godot --path game
```

You can start outside the east gate of Liscor or in Celum.

| Key | Action |
|---|---|
| WASD / arrows | Walk (walk into a foe to attack) |
| Mouse (in a fight) | Click a blue tile to walk, a foe to attack |
| 1–9 (in a fight) | Use a Skill or spell, then click a target (Esc: cancel) |
| Space | Wait (in a fight: end your turn) |
| E | Use or take what is next to you (talk, work, trade) |
| B / T / X | Block / throw / drop your held item |
| F / I | Eat / bag |
| Z | Sleep (in a bed) |
| C / J / L | Character sheet / journal / message history |
| H | Help |
| Esc | Menu (save, load, quit) |
| `` ` `` (backquote) | Debug console |

The game saves itself each morning. There are 3 save slots.

## Run the tests
PowerShell or Git Bash, from the repo root:
```powershell
bash tools/run_tests.sh unit_rng unit_spells      # some scripts (one Godot run each)
bash tools/run_tests.sh --all                     # the full suite (slow)
python -m unittest discover -s tools/tests
python tools/validate_data.py game/data/canon/book5
```
GUT: 128 scripts, about 1,340 tests. Python: 95 tests.

## Work on it with Claude Code in the cloud
The repo is set up for Claude Code cloud sessions (claude.ai/code or the Claude app).
A session start hook installs Godot and imports the project. See [docs/CLOUD.md](docs/CLOUD.md).

## Layout
```
docs/          design, roadmap, decisions (ADRs in docs/adr/), cloud guide
game/          Godot project
  core/        headless simulation (no nodes, no scenes)
  data/        classes, skills, spells, actions, enemies, maps (JSON)
    canon/     Books 1–5: events, NPCs and locations (JSON)
  world/ ui/   scenes and presentation
  tests/       GUT tests
tools/         Python: epub extraction, art builders, data validator (not shipped)
  cloud/       cloud session setup (Godot install, import)
```

## Canon and copyright
- The canon source is the ebooks (Book 1 is the rewrite), not the web serial.
- Canon events are short summaries in our own words, with chapter references. No book text is in git.
- Guesses are marked `"confidence": "guess"` in the data.

## Stack
Godot 4.7, GDScript, GUT 9.7. Python 3.12+ for tools. Credits: [CREDITS.md](CREDITS.md).
Design: [docs/DESIGN.md](docs/DESIGN.md) · Roadmap: [docs/ROADMAP.md](docs/ROADMAP.md) · Rules for AI agents: [CLAUDE.md](CLAUDE.md)

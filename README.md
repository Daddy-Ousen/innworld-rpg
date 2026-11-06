# Innworld RPG

**A free, fan-made RPG set in pirateaba's Innworld.**

You are an unnamed Earther. The Great Ritual pulls you into Innworld at the start of Book 1.
The story of the books goes on around you, day by day. What you do with your days is up to you.

> The books define how the world begins. The player decides what happens next.

[**Get it on the Microsoft Store**](https://apps.microsoft.com/detail/9NSJKRJRTP5J) ·
[**Play on itch.io**](https://rhasasn229.itch.io/innworld-rpg) ·
[**Play in your browser**](https://daddy-ousen.github.io/innworld-rpg/) ·
[**Download v0.2.1-alpha**](https://github.com/Daddy-Ousen/innworld-rpg/releases/tag/v0.2.1-alpha) (Windows, Linux, Android) · free

*Non-commercial fan work. The books and the world belong to pirateaba. This repo holds no book text.*

---

## What kind of game is it?

- **You level by living.** Cook, fight, run, trade, talk. Every action feeds hidden class pools.
  At night the System can offer you a class. Say no, and that offer never comes back.
- **Nights move the world.** When you sleep, the day ends. You gain levels and Skills, and the canon events of the night happen.
- **Canon is the default, not a rail.** Do nothing, and the books happen as written.
  Step in, and you can change, delay or stop events. The world reacts to what you did.
- **Fights are tactical.** Turn-based on the map grid, XCOM-style: action points, cover, combat Skills, mana and spells.
- **A real place to live in.** Liscor, Celum, the Floodplains, the inn on the hill, the dungeon below.
  NPCs keep their own schedules. You can work at the inn, cook, take guests, go hungry, and get through the winter.

## What is in the alpha

| | |
|---|---|
| Story | Books 1–9 as canon data: 1,614 events, 335 characters, 130 places |
| World | 53 maps, day and night, winter snow, NPC schedules |
| Systems | Classes, levels, Skills, spells, tactical combat, traps, cooking, money, hunger, travel |
| Art and sound | Pixel art, character animation, music, sound effects, ambience |
| Saves | 3 slots, plus an autosave each morning |

This is an **alpha**. Expect bugs and rough edges. Saves from this build may not load in a later build.

| Book | Chapters | Events |
|---|---|---|
| 1 The Wandering Inn | 1.00 – 1.63 | 151 |
| 2 Fae and Fare | Interlude – The Call to 2.48 | 210 |
| 3 Flowers of Esthelm | 3.00 – 3.25 | 166 |
| 4 Winter Solstice | 3.26 – 3.40 | 116 |
| 5 The Last Light | 4.00 K – 4.31 | 149 |
| 6 The General of Izril | 4.32 G – 4.49 | 145 |
| 7 The Rains of Liscor | 5.00 – 5.20 G | 202 |
| 8 Blood of Liscor | 5.21 – 5.44 | 269 |
| 9 Tears of Liscor | 5.45 – 5.62 | 206 |

Next: Book 10. See the [roadmap](docs/ROADMAP.md).

## Play it

### Microsoft Store (Windows)

Get **[Innworld RPG on the Microsoft Store](https://apps.microsoft.com/detail/9NSJKRJRTP5J)**. It is free.
The Store installs it and keeps it up to date. It is the same alpha as the download below.

### In your browser

Open the game on **[itch.io](https://rhasasn229.itch.io/innworld-rpg)** and press **Run game**,
or open **https://daddy-ousen.github.io/innworld-rpg/**. Both run the same build. Use a computer with a keyboard.
The first load is about 100 MB, so give it a moment. Click once into the game to start the sound.
Your saves stay in this browser. If you clear the site data of your browser, the saves are gone.
For the best play, use the download below.

### Download

1. Go to the [Releases page](https://github.com/Daddy-Ousen/innworld-rpg/releases).
2. Download the zip for your system, or the `.apk` for Android.
3. Unzip it and start the game:
   - **Windows:** double-click `InnworldRPG.exe`.
     Windows SmartScreen can warn you, because the file has no signature. Click **More info**, then **Run anyway**.
   - **Android:** open the `.apk` on your phone and allow installs from this source.
   - **Linux:** run `chmod +x InnworldRPG.x86_64`, then `./InnworldRPG.x86_64`.

The game has touch controls (an on-screen pad and buttons); see "Touch" below. A keyboard works too.
You can start outside the east gate of Liscor or in Celum.

### Keys

| Key | Action |
|---|---|
| WASD / arrows | Walk (walk into a foe to attack) |
| E | Use or take what is next to you (talk, work, trade) |
| Space | Wait (in a fight: end your turn) |
| Mouse (in a fight) | Click a blue tile to walk, a foe to attack |
| 1–9 (in a fight) | Use a Skill or spell, then click a target (Esc: cancel) |
| B / T / X | Block / throw / drop your held item |
| F / I | Eat / bag |
| Z | Sleep in a bed (the night moves the world) |
| C / J / L | Character sheet / journal / message history |
| H | Help (all keys) |
| Esc | Menu (save, load, options, quit) |


### Touch

On a touch screen the game shows on-screen controls. **Options → Touch controls** sets Auto (on a touch screen), On or Off.

- The pad (bottom left) walks. Hold an arrow to keep walking. **Wait** is in the middle.
- On the right: **Use**, **Bag**, **More** (eat, sleep, character, journal, log, help, block, throw, drop) and **Menu**.
- **Back** closes a panel. One tap picks an item in a list. Drag a page to scroll it.
- In a fight: tap a tile to see the path and hit chance, then tap it again to act. **Cancel** stops a walk or a Skill.
- **Options → Menu size** makes menus and text bigger (Auto, 100%, 150%, 200%). Auto picks 200% on a phone.
  The map and the touch pad keep their size.

### Bugs and ideas

[Open an issue](https://github.com/Daddy-Ousen/innworld-rpg/issues). Give the version from the title screen.

---

## For developers

### Run from source

Needs [Godot 4.7](https://godotengine.org/) on your PATH (or the full path to the Godot exe).

```powershell
godot --headless --path game --import   # once, after a fresh clone
godot --path game
```

### Run the tests

From the repo root, in PowerShell or Git Bash:

```powershell
bash tools/run_tests.sh unit_rng unit_spells      # some GUT scripts (one Godot run each)
bash tools/run_tests.sh --all                     # the full GUT suite (slow)
python -m unittest discover -s tools/tests        # Python tool tests
python tools/validate_data.py game/data/canon --all
```

GUT: 227 scripts. Python: 105 tests.

### Build the release zips

Windows, with the Godot 4.7.2 export templates installed. This makes the Windows, Linux and Web zips.
A published GitHub release with the Web zip also updates the browser version ([ADR 0031](docs/DECISIONS.md)).

```powershell
$env:GODOT = "<path to Godot_v4.7.2-stable_win64_console.exe>"
powershell -ExecutionPolicy Bypass -File tools/release.ps1   # zips land in export/
```

Details: [ADR 0029](docs/DECISIONS.md).

### How it is built

- **Headless core.** All game rules live in `game/core/` with no nodes and no scenes. The view only reads state and sends commands.
- **One game state.** Everything is in one `GameState` object. It saves to versioned JSON with migrations.
- **Deterministic.** All randomness goes through one seeded RNG. The same seed and the same commands give the same game.
- **Content is data.** Classes, Skills, spells, enemies, maps, NPCs and canon events are JSON in `game/data/`.
  A new book adds data, not engine code.
- **Canon events are nodes,** not scripts. Each has roles, preconditions, fallbacks and effects, so the player can change them.

Read more: [design](docs/DESIGN.md) · [roadmap](docs/ROADMAP.md) · [decisions](docs/DECISIONS.md) · [progress](progress.md)

### Layout

```
docs/          design, roadmap, decisions, store guides
game/          Godot project
  core/        headless simulation (no nodes, no scenes)
  data/        classes, skills, spells, actions, enemies, maps (JSON)
    canon/     Books 1–9: events, NPCs and locations (JSON)
  world/ ui/   scenes and presentation
  tests/       GUT tests
tools/         Python: epub extraction, art and sound builders, data validator (not shipped)
  release/     release smoke test and player readme
  cloud/       cloud session setup (Godot install, import)
```

### Contributing

Project rules (architecture, data format, tests, commits) are in [CLAUDE.md](CLAUDE.md).
A setup script for remote dev environments is in `tools/cloud/`.

## Canon and copyright

- The canon source is the ebooks (Book 1 is the rewrite), not the web serial.
- Canon events are short summaries in our own words, with chapter references. No book text is in git.
- Guesses are marked `"confidence": "guess"` in the data.
- The game is free and non-commercial. *The Wandering Inn* and its world belong to pirateaba.
- [Terms of service](TERMS.md) and [privacy policy](PRIVACY.md).

## Credits

Built with Godot 4.7, GDScript and GUT 9.7. Tools in Python 3.12+.
Art comes from the Liberated Pixel Cup (LPC) packs; music and sounds come from free packs. Authors and licenses: [CREDITS.md](CREDITS.md).

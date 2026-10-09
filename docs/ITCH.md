# itch.io page

The text and settings for the itch.io page. Images are local (not in git): `export/itch/`.
Remake the screenshots with `export/itch/capture_shots.gd` (copy it to `game/_capture.gd`, run
`godot --path game -s res://_capture.gd -- <out dir> [shot ...]`, then delete the copy).

## Images

| File | Use |
|---|---|
| `cover_inn.png` (630 × 500) | Cover image (recommended) |
| `cover_winter.png` (630 × 500) | Spare cover (winter) |
| `screenshot_1_inn.png` | The inn full of guests (Book 1, evening) |
| `screenshot_2_fight.png` | A tactical fight: move range, turn order, Skill bar |
| `screenshot_3_offer.png` | The System offers a class |
| `screenshot_4_market.png` | Liscor market at noon |
| `screenshot_5_winter.png` | The inn in winter snow |
| `screenshot_6_liscor_gate.png` | Day 1 outside the east gate of Liscor |

The images use LPC art (CC-BY-SA), so the page must keep the credits link.

## Short description or tagline

> Live in the world of The Wandering Inn. The books happen around you, unless you change them.

## Description

Paste the text below into the itch.io editor. `export/itch/description.html` is the same text with formatting:
open it in a browser, select all, copy, and paste into the editor.

---

**Innworld RPG** is a free, fan-made RPG set in *The Wandering Inn* by pirateaba.

You are an unnamed Earther. You arrive in Innworld at the start of Book 1. The story of the books goes on
around you, day by day. What you do with your days is up to you.

*The books define how the world begins. You decide what happens next.*

### What kind of game is it?

- **You level by living.** Cook, fight, run, trade, talk. Every action feeds hidden class pools.
  At night the System can offer you a class. Say no, and that offer never comes back.
- **Nights move the world.** When you sleep, the day ends. You gain levels and Skills, and the canon events of the night happen.
- **Canon is the default, not a rail.** Do nothing, and the books happen as written.
  Step in, and you can change, delay or stop events. The world reacts to what you did.
- **Fights are tactical.** Turn-based on the map grid: action points, cover, combat Skills, mana and spells.
- **A real place to live in.** Liscor, Celum, the Floodplains, the inn on the hill, the dungeon below.
  NPCs keep their own schedules. Work at the inn, cook, take guests, go hungry, and get through the winter.

### What is in the alpha (v0.1.2)

- Books 1–6 as canon data: 898 events, 261 characters, 103 places
- 38 maps, day and night, winter snow, NPC schedules
- Classes, levels, Skills, spells, tactical combat, traps, cooking, money, hunger, travel
- Pixel art, character animation, music, sound effects, ambience
- 3 save slots, plus an autosave each morning

This is an **alpha**. Expect bugs and rough edges. Saves from this build may not load in a later build.
Next: Book 7 (The Rains of Liscor).

### How to play

- **In the browser:** press Run game above. You need a keyboard (no touch controls yet).
  The first load is about 100 MB. Click once into the game to start the sound.
  Your saves stay in this browser. If you clear the site data, the saves are gone.
- **Download (Windows, Linux):** [GitHub Releases](https://github.com/Daddy-Ousen/innworld-rpg/releases).
  Windows SmartScreen can warn you, because the file has no signature: click More info, then Run anyway.

### Keys

- **WASD / arrows:** walk (walk into a foe to attack)
- **E:** use or take what is next to you (talk, work, trade)
- **Space:** wait (in a fight: end your turn)
- **Mouse (in a fight):** click a blue tile to walk, a foe to attack
- **1–9 (in a fight):** use a Skill or spell, then click a target
- **Z:** sleep in a bed (the night moves the world)
- **C / J / I:** character sheet / journal / bag
- **H:** help (all keys) · **Esc:** menu (save, load, options)

### Policy check (2026-10-09)

Source: https://wanderinginn.com/fanworks-permissions/ . The policy does not name games; when in doubt it says to assume "not allowed".
We follow: no book text or art, credit given, free, no crowdfunding. Open: it forbids the book titles in marketing material.
The page text above names the book to say what the work is about. Decide with the author. See `docs/DESIGN.md` §7.

### Fan work

A free, non-commercial fan work. *The Wandering Inn* and its world belong to pirateaba.
The game holds no book text: the events are short summaries in our own words.
Read the story at [wanderinginn.com](https://wanderinginn.com) and support the author.

### Credits

Art from the Liberated Pixel Cup (LPC) family on OpenGameArt (CC-BY-SA), plus our own edits.
Music by RandomMind and cynicmusic, sounds by Kenney (CC0). Font: Pixel Operator by Jayvee Enaguas (CC0).
Made with Godot 4. Full list: [CREDITS.md](https://github.com/Daddy-Ousen/innworld-rpg/blob/main/CREDITS.md).
Source code: [github.com/Daddy-Ousen/innworld-rpg](https://github.com/Daddy-Ousen/innworld-rpg).

### Bugs and ideas

Write a comment below, or [open an issue](https://github.com/Daddy-Ousen/innworld-rpg/issues).
Give the version from the title screen.

---

## Settings

| Field | Value |
|---|---|
| Kind of project | HTML |
| Release status | In development |
| Pricing | No payments |
| Uploads | `InnworldRPG-v0.1.2-alpha-web.zip`, tick "This file will be played in the browser" |
| Embed options | 1152 × 648, Fullscreen button on, Mobile friendly off, Automatically start on page load off |
| Genre | Role Playing |
| Tags (10 at most) | rpg, pixel-art, fangame, turn-based, tactical, litrpg, fantasy, singleplayer, godot, life-simulation |
| Community | Comments |
| Visibility | Draft first; Public after a check of the page |

Pick tags from the list that itch.io suggests as you type; the exact names can differ a little.

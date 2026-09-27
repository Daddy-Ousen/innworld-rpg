# ADR 0018 — M11 graphics, character sprites and animation

Date: 2026-09-27 · Status: plan accepted by the user 2026-09-27 (sub-steps get their own sections)

## Context
- M0–M10 built the sim and Books 1–4 as data. The map is drawn with coloured squares (ADR 0007).
- The user pauses new books after M10 and asks for graphics, character models and animation.

## User choices (2026-09-27)
1. **Look:** 2D top-down pixel art, 32×32 px tiles. Characters are about 32×48 px (LPC frame 64×64).
   Not 16 px (races hard to tell apart), not 3D (a new view and rigging; against pillar 4).
2. **Art source:** free licensed packs plus our own edits. Characters and tiles from the LPC
   (Liberated Pixel Cup) family so the style matches. Gaps (for example the four-armed Antinium)
   are small pixel edits of LPC parts. No AI art (DESIGN §7).
3. **Animation first:** standard set. Smooth steps, walk cycle, facing, attack swing, hit flash,
   damage numbers, knock-out fall. Day/night light, snow and fire light come later (M11.5).

## Decisions
- **Core does not change.** All art is presentation (`world/`, `ui/`, `game/assets/`). The sim, the
  saves and the determinism stay as they are. No save version change is expected in M11.
- **The grid does not change.** Only the pixel size of a cell in the view goes from 16 to 32
  (`WorldView.TILE`). Camera zoom drops to match.
- **Content is data (rule 4).** Which art a tile, an object or a character uses lives in JSON:
  - `tiles.json`: each tile gets an optional `sprite` (sheet + cell, and a winter cell).
  - Map objects get an optional `sprite` key, or a `kind` that maps to a sprite.
  - New `data/appearance.json`: one entry per NPC, enemy and player look: race body, parts
    (head, hair, clothes, tail, weapon) and colours. Generic looks per race for NPCs without an entry.
  - The exact schemas are shown to the user before M11.1 and M11.2 (rule 11).
- **Fallback always works.** A tile, object or character with no art still draws as today (square
  and colour). New canon batches and headless tests never break on missing art.
- **Characters are layered at run time.** One node stacks the LPC layer sheets (body, head, clothes,
  hair, tail, weapon) in a fixed order. No baked sheets in git. A tool may bake later if speed needs it.
- **Animation reads state changes.** After each command the view compares the old and new state
  (positions, facing, HP, `down`) and plays tweens. It never changes state and never blocks input:
  a new command finishes the running tweens at once.
- **Licences.** LPC art is CC-BY-SA 3.0 / GPL 3.0 / OGA-BY (it differs per part). Every file we add
  gets a line in `CREDITS.md` (author, licence, source link). Our edits of CC-BY-SA art are
  CC-BY-SA too. The game stays free and non-commercial.
- **Assets live in** `game/assets/tiles/`, `game/assets/objects/`, `game/assets/characters/<layer>/`,
  `game/assets/fx/`. `*.import` files are kept in git (ADR 0001).

## Plan (one branch + PR each)
- **M11.0 Art spike.** Check the LPC parts we need (lizard head and tail for Drakes, wolf head and tail
  for Gnolls, goblin, skeleton) and their licences. `game/assets/` layout, `CREDITS.md`, cell size 32.
  One map (`liscor_gate`) with LPC tiles; the player as an LPC character who walks. The user checks a
  screenshot and approves the look before M11.1.
- **M11.1 Tiles and objects.** All 16 tile types with art, winter variants, edges between terrains
  (Godot terrain sets). All map objects (about 66 on 15 maps) get a sprite by kind.
- **M11.2 Characters.** `appearance.json`, the layered character node, 4 directions. The player and the
  33 NPCs with a schedule. Race parts: Human, Drake, Gnoll, Antinium Worker and Soldier, Goblin and Hob,
  half-Elf, Garuda, skeleton (Toren).
- **M11.3 Animation.** Smooth step (one tween per cell, same speed as the key repeat), walk cycle,
  facing for NPCs and monsters (from their last move), attack swing, hit flash, damage numbers,
  knock-out fall and down pose, Frost Fairies float.
- **M11.4 Monsters.** All 36 enemies with art (Goblin set, Rock Crab, Razorbeak, undead, Antinium,
  Gnolls, Ashfire Bees, Snow Golem, human foes).
- **M11.5 Atmosphere (later).** Day/night tint from the clock, falling snow, fire and lamp light.
- Later: UI skin and font, portraits for the main cast, emotes.

## Tests
- GUT: appearance data loads and falls back; tile and object sprite lookup (and fallback); the character
  node picks the right frame for facing and state; a step tween ends on the cell centre; the state diff
  gives the right animation events (move, hit, down). All run headless.
- `tools/validate_data.py`: every sprite and part file named in data exists; every NPC with a schedule
  and every enemy has an appearance (a warning until M11.4, then an error).
- Manual: screenshots with the `game/_scratch/` scene (see `handoff.md`), checked by the user.

## Done when (M11)
Every map, every NPC with a schedule and every enemy draws with art. Walking and combat animate. The
full GUT suite and the validator pass. The user has checked the game on screen.

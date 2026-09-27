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
- **Characters are baked by a tool** (changed in M11.0; the plan said layered at run time). LPC parts
  are one file per animation in a base palette plus colour palettes; recolouring them in Godot needs a
  shader per layer. `tools/build_sprites.py` (Pillow, user OK 2026-09-27) recolours and stacks the parts
  and writes one sheet per look to `game/assets/characters/<id>.png`. The LPC generator clone stays
  outside the repo; CREDITS.md records its commit.
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

## M11.0 Art spike (2026-09-27)
- Sources downloaded (user OK): "[LPC] Terrains" (`terrain-v7.png` → `game/assets/tiles/lpc_terrains.png`),
  "LPC Tile Atlas" (`terrain_atlas.png` → `lpc_atlas.png`), and a part clone of the Universal LPC
  Spritesheet Character Generator (data files and the part folders we use; kept in the scratchpad).
  The credit files of both tile packs are copied next to the sheets. `CREDITS.md` lists every source.
- LPC has the parts we hoped for: lizard heads and tails (Drakes), wolf heads, ears and tails (Gnolls),
  goblin heads (adult, child), skeleton body and head. Each part lists authors and licences in its
  sheet definition; the tool copies them into CREDITS.md.
- **`tiles.json` (schema, shown to the user with the screenshots):** optional per tile
  `"sprite": {"sheet": s, "cells": [[x, y], ...]}` (32 px cells of `game/assets/tiles/<s>.png`; one is
  picked per map cell by a fixed hash of its position, no RNG), `"prop": {"sheet": s, "region": [x, y, w, h]}`
  (in cells; drawn over the ground, bottom-centred on the cell, y-sorted with characters), and
  `winter_sprite` / `winter_prop`. A missing sheet or field = the colour square.
- **`appearance.json` (new file):** `{"schema_version": 1, "looks": {id: {"body", "skin", "base"?,
  "parts": [{"part", "color"?}], "confidence", "note"}}}`. Id = NPC id, enemy type or `player`.
  Colours not in the Book text are `"confidence": "guess"` (rule 9).
- Sheet layout: 64×64 frames, 9 columns, 13 rows (walk 0-3, slash 4-7, hurt 8, idle 9-12).
- View: `WorldView.TILE` 32, camera zoom 2 (was 3 at 16 px). World nodes are y-sorted; new `Props` layer.
  `CharacterSprite` (new) draws a sheet; the player's sprite glides one cell in 0.14 s with half a walk
  cycle; the marker itself moves at once, so logic and tests see the exact cell. NPCs with a sheet are
  sprites (a down NPC lies down); others and all monsters stay squares until M11.2 / M11.4.
- Art in this step: ground for `liscor_gate` tiles (grass, tall grass, dirt road, cobble, city wall,
  tree and rock props) and snow versions; looks for the player, Relc, Krshia and the Goblin grunt
  (the Goblin sheet is not drawn yet: monsters are M11.4).
- Tests: `unit_art.gd` (8), `tools/tests/test_build_sprites.py` (6). GUT 697/697 (75 scripts), Python 57/57.

## M11.1 Tiles and objects (2026-09-27)
- **User OKs (2026-09-27):** download five free LPC files (LPC Base Assets, [LPC] Tavern, LPC House Interior
  and Decorations, LPC Style Well, a campfire animation) and the two schema changes below. The campfire file
  was not needed in the end (the Tavern pack has a 32 px campfire) and is not in the repo.
- **Terrain edges are done in code, not with Godot terrain sets.** `world/ground_art.gd` (`GroundArt.plan`)
  is pure and headless-tested. `tiles.json` sprites get optional `"edges": [x, y]` (top-left cell of the
  3×6 LPC terrain block: rows 0-1 inner corners, rows 2-4 the edge ring, row 5 fills) and `"z"`. A cell draws
  the edge piece where a side or corner neighbour has another terrain with a lower z; the neighbour's ground
  goes in the `Tiles` layer under it, the piece in the new `Edges` layer. Tiles with no z (walls, buildings)
  keep hard edges. A strip one cell wide between two lower cells keeps a hard edge (LPC has no piece).
  z order: chasm 8, snow wall 7, water 6, shallows 5, tall grass 4, grass / snow 3, dirt / cave floor 2, cobble 1.
- **Props borrow ground.** `tree` and `rock` lost their grass sprite: a tile with a prop and no sprite takes the
  ground of its first neighbour with art, so a rock in the bee cave stands on cave floor and trees in winter on snow.
- **Object art (schema, user OK):** a map object gets `"kind"`; the new `data/objects.json` holds
  `{"kinds": {kind: {"sheet", "region": [x, y, w, h] (pixels), "frames"?: n, "winter_region"?}}}`. The
  sheet is looked up in `assets/tiles/` then `assets/objects/`. Drawn bottom-centred on the object's cell in
  the y-sorted `Props` layer; `frames` animate at 6 fps (fires, braziers). No kind or no art = the yellow square.
  MapDb checks that `kind` is a string. All 67 objects on the 15 maps have a kind (33 kinds).
- **Our edits:** `tools/build_objects.py` makes `assets/objects/edits.png` (wagon, chess table, market stall,
  notice board, broom, horseshoe, honeycomb, bee nest, blue fruit tree, dead tree, bedroll, mat, rope anchor,
  4-frame brazier, stone doors). `--check` compares objects.json with its layout.
- **Tile art:** grass, tall grass, dirt road, cobble, water, shallows, cave floor, chasm, snow wall from
  `lpc_terrains`; city wall from `lpc_atlas`; building (brick) from `lpc_house`; wood floor and door (a floor
  gap) from `lpc_inside`; wood wall from `lpc_interior`. Winter: snow and frozen dirt.
- Known limits: buildings are flat brick (no roofs yet); a two-cell stream draws as a row of small ponds.
- Tests: `unit_ground_art.gd` (8), `tools/tests/test_build_objects.py` (4). GUT 705/705 (76 scripts),
  Python 61/61, validator 0 errors.

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

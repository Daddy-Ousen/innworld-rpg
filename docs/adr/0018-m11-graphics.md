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

## M11.2 Characters (2026-09-27)
- **Looks for all 33 NPCs with a schedule**, the player and 8 generic race looks (43 sheets with the Goblin grunt).
  The canon facts come from a check of the Books 1-4 text (chapter refs in each look's `note`). Colours or gear the
  text does not state are `"confidence": "guess"`. Known conflicts are noted, not solved (Zevara's eyes, Krshia's fur,
  Sostrom's hair). One look per character for the whole game: Klbkch keeps four arms after 1.63, Mrsha is white,
  Pawn and Ksmvr keep all their limbs.
- **`appearance.json` keeps its shape; three new kinds of value** (shown to the user with the screenshots):
  - look id `race_<race>`: the generic look of an NPC with no own look. The race is canon `npcs.json` `race`, in lower
    case with `-` and ` ` as `_` (`race_half_elf`). `CharacterSprite.look_for(id, race)` picks own look, then race
    look, then none (a square). Generic looks: Human, Drake, Gnoll, Antinium, Goblin, Undead, Minotaur, half-Elf.
  - colour `all.lpcr.<name>`: any LPC colour on any material (the LPC generator's "all" palettes). Drake scales need
    it (lemon, garnet, azure, apple...).
  - part `innworld_extra_arms`, `innworld_antennae`, `innworld_mandibles`: our Antinium edits. `build_sprites.py`
    draws them per frame from the look's body and `heads_*` layers (the LPC alien head is the base): a second,
    darker pair of arms (the body's sides moved down 6 px and out 2 px, behind the body; front and back views),
    two feelers on the head, two pincers at the jaw (one from the side). Credited in CREDITS.md as CC-BY-SA edits.
- **The view** gets NPC races from `main.gd` (`WorldView.setup(..., races)`). The ADR plan's "layered node" stays a
  baked sheet (M11.0 decision); 4 directions come from the sheet rows. NPC facing from their moves is M11.3.
- **Weapons:** LPC weapons are drawn where the part has walk frames (Relc's spear, swords, axes, Sostrom's staff).
  Many have no slash frames, so they vanish during an attack swing; M11.3 must handle this. No bow walk frames
  (Bird), no club for the male body (Beilmark), no weapons for child bodies (Rags).
- Not drawn yet: shells on Antinium backs, Toren's eye-flames and armour, Ceria's bone hand, scars.
- Tests: `unit_art.gd` +3 (race fallback, every NPC with a schedule has its own look, the view uses the race look),
  `test_build_sprites.py` +3 (all palette, edits, edit needs a head). GUT 708/708 (76 scripts), Python 64/64.

## M11.3 Animation (2026-09-27)
- **Sheet layout v2** (`tools/build_sprites.py`, 768×1088 px): the 64 px rows are walk 0-3, hurt 4, idle 5-8 (the old
  64 px slash rows are gone). Under them (y 576) an **attack block** of 128×128 frames, 4 rows × 6 frames, with the
  character in the middle of each frame. The tool picks the attack from the weapon part: the LPC oversize sword slash
  (`slash_128`), the oversize axe slash (`slash_oversize`, 192 px frames, the middle 128 px kept), a thrust for a
  weapon with thrust and no slash (spear, staff; 6 of the 8 frames), else a plain slash (unarmed, dagger, wand). A
  layer with no frames for the attack keeps its standing walk frame, so no part vanishes in a swing. The Antinium
  edits are drawn on the attack frames too. No data schema change.
- **`CharacterSprite`** now uses sheet regions (`region_of(anim, dir, i)`; `shown` = the frame on show):
  `walk` (glide + half a walk cycle), `attack(dir)`, `fall()` (the hurt frames, then lying down), `finish()`.
- **`AnimDiff`** (`world/anim_diff.gd`, pure, headless-tested) compares two snapshots of the player's area (player,
  NPCs, visible monsters: cell, hp, down, side) and gives events: move (one cell, also diagonal), hit (hp dropped;
  the player's full hp is known from `Stats.max_hp` when `refresh` gets the db), fall, gone (a monster was removed),
  swing. The sim keeps no record of who hit whom and core must not change, so swings are read from state: the
  player swings when the fight's attacks + throws count grows (or when there is no fight left and the monster in
  front of the unmoved player was hit or is gone); a monster swings at a hit or gone unit of the other side next to it
  (king move) if it did not move. NPCs never swing (helpers in a fight are monsters). A miss by a monster shows no swing.
- **`WorldView.refresh(gs, db)`** keeps the last snapshot and plays the events: NPC sprites walk one cell (their
  names and bars slide too; the walk-cycle half is kept per NPC), monster squares slide; a hit tints the unit red for
  0.25 s and shows a rising damage number in the new `Fx` layer (red when you are hurt); a fallen NPC plays the fall;
  a gone monster leaves a shrinking, fading square; a swing plays the sprite attack or a square lunge (6 px). Frost
  Fairies bob 3 px. `monster_facing` keeps each monster's facing from its last step or swing, for M11.4 sprites.
  Nothing blocks input: markers are made anew on each refresh, which ends their tweens; numbers finish on their own; a
  new map clears the `Fx` layer.
- Not in this step: the player's own knock-out fall (a knock-out ends the day at once), throw projectiles, monster
  sprites (M11.4).
- Tests: `unit_anim.gd` (13), `unit_art.gd` updated (regions), `test_build_sprites.py` +2 (attack kind, weapons stay
  in the swing). GUT 721/721 (77 scripts), Python 66/66, validator 0 errors.

## M11.4 Monsters (2026-09-27)
- **User OKs (2026-09-27):** download three free LPC creature files ([LPC] Monsters, [LPC] Golem, [LPC] Birds)
  plus our own edits, and a new creature look kind in `appearance.json`.
- **People (30 enemies)** are LPC looks like the NPCs (`build_sprites.py`). Canon facts come from a check of the
  Books 1-4 text (chapter refs in each look's `note`); what the text does not say is a guess. Known limits: sizes are
  not drawn (Hobs, Soldiers, the Crypt Lord are the size of a person); LPC child bodies have no weapons (Goblin
  grunt); LPC bows sit behind the back; the Goblin commander's Shield Spider is not drawn; the LPC mask hides a
  whole Drake head, so the Drake thieves wear a bandana.
- **Creatures (6 enemies).** The creature look is a different shape from the one shown to the user
  (`{"sheet", "frame", "rows", "frames"}`): the new `tools/build_creatures.py` bakes each creature into the
  character sheet layout, so the game draws it as a `CharacterSprite` and needs no new code or schema for it.
  A creature look is `{"creature": source, "ramp"?: [colours dark → light], "hue"?, "sat"?, "val"?,
  "light"?: colour for white pixels, "die"?: "melt" | "crumble", "confidence", "note"}`. Sources: `golem`,
  `bee`, `big_worm`, `eagle` (art files in `tools/art/creatures/`, not shipped), `rock_crab` and `snowman`
  (drawn by the tool). A source with no fall frames gets a made one (it sinks and fades). `build_sprites.py`
  skips creature looks. Rock Crab: a boulder with dark-brown pincers and eye stalks (1.01). Razorbeak: the
  LPC eagle, green with a red head, twice the size (1.05; its leathery wings and teeth are not drawn). Ashfire
  Bee: black and yellow (2.42). Snow Golem: a snowman with stick teeth (2.42). Crypt Lord: the LPC golem in
  rotten-flesh colours (guess). Skinner: the LPC big worm in yellowed-skin colours (guess).
- **The view.** A monster whose type has a sheet is a `CharacterSprite` (it stands the way of
  `monster_facing`, walks, swings), a flat ring under its feet in its state colour (hostile red, fleeing
  yellow, ally blue, calm dark), its label above the head and its HP bar. A gone monster plays the fall and
  fades. A hidden monster is the `rock` tile's prop. Types with no sheet (toy tests, future data) stay squares.
- The validator does not check looks; the GUT test `unit_monster_art` checks that all 36 enemies have a sheet.
- Tests: `unit_monster_art.gd` (5), `tools/tests/test_build_creatures.py` (7). GUT 726/726 (78 scripts),
  Python 73/73, validator 0 errors.

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

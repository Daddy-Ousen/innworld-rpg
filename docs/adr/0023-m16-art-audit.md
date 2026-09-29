# ADR 0023 — M16.0 art audit

Date: 2026-09-29 · Status: list written; M16.1 done 2026-09-29 (result at the end)

## Context
M16 fixes maps and art (ADR 0022 items 3–6). M16.0 only looks and lists. No map, art or code changes.
Method: a throwaway scene rendered each of the 20 maps whole (no player, no day/night tint) once in summer and once
in winter, then one person read every image. Screenshots are not in git. `tiles.json`, `objects.json` and the
map rows were scanned for tile counts and doors.

## Root causes (why many things look bad)
- **One `rock` tile does three jobs.** It is a 1x1 slab prop (`lpc_atlas` 28,26) on a neighbour's ground. Scattered
  singles read as "stones"; 100–540 of them in a block read as a wall of slabs (bee cave, creler cave, depths,
  crypt, road camp, ruins entrance). There is no cliff top, cliff face or corner art.
- **One `building` tile** is a single brick cell (`lpc_house` 1,1) repeated. A 4x3 block is a flat red
  rectangle: no roof, wall, window or door. Esthelm ruins reuse it for ruined walls (it has no ruin look).
- **The inn** on `inn_hill` is a block of `wood_wall` cells (plank pattern): a flat slab with one bare `door` cell.
- **Doors and exits are bare floor cells** (tan square). Nothing tells a house from a shop from a guild.
- **Water has one tile.** Two ponds joined by a strip draw square blue blocks; a river end and a bridge gap draw a
  flat blue square. Water never freezes in winter. Pines carry no snow in winter.
- **Each city is 2–3 yard maps** (liscor_gate, liscor_market; celum_gate, celum_square + 3 indoor rooms). Edges are
  walls or grass, so nothing suggests a big city. No crowd.

## Audit list
Cell numbers are (x, y) from the top left, read from the images (±1). Fix = the sub-milestone that owns it.

### Nature and rocks — M16.1
1. `bee_cave`, `esthelm_creler_cave`, `liscor_depths`, `liscor_crypt`: cave walls are 380–540 identical slabs.
   Need a cave-wall / cliff look with top, face and corners.
2. `road_camp` (left and right edges, 122 cells) and `ruins_entrance` (top edge, 106): cliff of slabs with grass
   showing between them. Need cliff top + face tiles.
3. Scattered `rock` props (`liscor_gate`, `celum_gate`, `floodplains_south`, `inn_hill`, `road_camp`, `dungeon_rift`):
   flat grey slabs. Need boulder props (1x1 and 2x2). The tall standing stone on `liscor_gate` / `celum_gate` stays.
4. `road_camp` ponds at about (23–25, 4–10): two ponds joined by a square blue strip; thin water breaks.
   `floodplains_south` stream: rounded end at (24–25, 16) and a square blue block at (24–25, 17–18) where it
   continues (a bridge or ford is missing). Need water edges that work for 1–2 wide water, and a bridge or
   stepping-stones object.
5. `floodplains_south` (5–7, 5–8) and `road_camp` (9–11, 8–11): the dead tree draws as a brown blob with a green tree
   behind it (road_camp). Needs a real dead-tree prop.
6. `dungeon_rift`: the rift (`chasm`) has hard square corners at its left and right tips and no rim.
7. Tall-grass squares that do not blend: `celum_gate` (7,5) dark square at the end of a bush; `dungeon_rift` long strip
   at (5–10, 3); `esthelm_ruins` green square at (26,16).
8. Trees drawn over walls or roofs: `celum_gate` (1–2,0) and (28–29,0) stand on the city wall; `celum_square`
   (4,1) and (27,1) stand on roofs, (27,12) covers a table. Trees need a placement rule (grass only) or the maps move.
9. Winter: water stays blue (not frozen); pines stay green (no snow). Cliff art needs a winter look too.

### Buildings — M16.2
10. `liscor_market` (246 `building` cells), `celum_square` (177), `esthelm_ruins` (105): flat red slabs. Need roof,
    front wall with windows, and a door on the bottom row; Drake stone for Liscor, timber and brick for Celum.
11. `esthelm_ruins`: ruined walls use the red house tile. Need a ruin wall look (broken stone), not a roof.
12. `inn_hill`: the inn is a plank slab. Needs a real building (the inn has two floors and a tower in canon use).
13. Interior walls (`inn_interior`, `inn_upper_floor`, `celum_*` rooms): thin plank strips; no windows. Low
    priority; add window pieces in M16.2 if cheap.

### Doors and signs — M16.3
14. `celum_square`: two iron doors (24,2), (1,13) and two bare tan cells (6,3), (14,3) with no door art, no name.
15. Room exits on `celum_runners_guild`, `celum_frenzied_hare`, `celum_stitchworks`, `inn_interior`,
    `inn_upper_floor`: a bare tan cell in the bottom wall. Outside, `liscor_gate` / `celum_gate` gates are the
    same tan square. Every enterable door needs a marker and a sign.
16. `liscor_market`: both stalls use the same art; Krshia's stall and Lism's stall cannot be told apart. Need a
    sign each (name shows when the player is near).
17. Buildings with no door at all read as walls; M16.3 gives them "A private home" or "Closed".

### Cities — M16.4 / M16.5
18. `liscor_market`: almost empty (2 stalls, 2 braziers, a well, 2 buildings in a cobble box). No crowd, no
    shops, no street feel.
19. `liscor_gate`, `celum_gate`: open meadow with a road, not a city gate. No towers, no guards' post, no gatehouse.
20. `celum_square`: a plain cobble rectangle in red slabs. No guild street, no shop rows.
21. Map edges are walls or grass: no roofs or streets that "go on".

### Other maps — M16.6
22. `esthelm_ruins`: grey cobble floor with red blocks and a dirt path with a soft brown edge; the green square (see 7).
23. `inn_hill`: bare meadow around the inn; add a fence, a well, a sign, a stable if canon says so (check Book 1 text).
24. `ruins_entrance`: the plank fence pieces (wall with a gap) and the iron gate are the best art here; keep them.
25. Underground maps have little light or decoration (webs and bones only in the depths). Optional.

## What is fine
- Trees (pine, round), ground edges for grass, path and cobble, bushes, campfire, brazier, well, wagon, bed,
  cupboard, tables, board, stairs and ladders, the stone gate, plank fence pieces, honeycomb props.
- Interior floors and furniture read well.

## Decisions
- M16.1 first (rocks, cliffs, water); it touches most maps. M16.2 then M16.3 build on it. Cities (M16.4/5) come
  after the art so the new districts use final tiles.
- Fix by art in `tiles.json` / `objects.json` and by map edits. No core change; no save change.
- Screenshot helper: a scratch scene (not in git), see `handoff.md`.

## Open points for the user
- Is the list complete? Anything you saw that is not here?
- Is item 12 (a real inn building on `inn_hill`) in scope now, or only the door and sign?
- Art source for cliffs, boulders and houses: the LPC packs we already use (`lpc_terrains`, `lpc_atlas`) hold
  cliff and house pieces; a new pack needs your OK (rule 11: dependency).

## M16.1 result (2026-09-29)
Art source: the LPC sheets already in the repo (no new dependency); the user did not answer the open points, so the
inn building (item 12) stays in M16.2. Schema change (rule 11, approved with the M16.1 plan): tile field `cliff` /
`winter_cliff` = `{sheet, block [x, y]}` in `tiles.json`.

| Audit item | What changed |
|---|---|
| 1, 2 cliffs | New tiles `cliff` (earth, road camp, ruins entrance) and `stone_cliff` (bee cave, creler cave, depths, crypt). `GroundArt.cliff_piece` picks the rim, top, upper face, front face or side piece from the cell's place in the wall mass; the map edge counts as mass. Art: `game/assets/tiles/cliffs.png`, built by `tools/build_cliffs.py` from the atlas plateau (earth, stone, and both under snow). Map legends `^` changed; isolated `^` cells became `R` (rock). |
| 3 boulders | `rock` prop = one grey rock (atlas 26,25). New tile `boulder` (atlas 27,26, 3x2: a boulder and a standing slab) placed on road camp, ruins entrance, floodplains, inn hill (`O`). |
| 4 thin water | `shallows` now uses the water ground (same terrain, no square) plus a stepping-stones prop, so a ford reads as a crossing; the road camp ponds are one pond with a ford. `water` and `shallows` get an ice look in winter (`lpc_terrains` 27,14 block). |
| 5 dead tree | `dead_tree` (objects) is a bare tree drawn by `tools/build_objects.py`, not a recoloured leafy tree. |
| 6, 7 rift tips, tall-grass tails | `GroundArt.edge_pieces` returns one piece per corner or side when lower ground touches opposite sides or 3-4 sides; `GroundArt.mix` merges them (see-through where any piece is, bank where any piece has one) and `WorldView` draws the result as a sprite over the Edges layer. |
| 9 winter | Water freezes (ice look), cliffs get snow tops. Pines still carry no snow (no LPC art for it). |

Left for later: item 8 (trees on walls or roofs) waits for the M16.2 roofs; the winter pond is a plain
rectangle (the ice block has no soft bank); a one-cell rock wall inside a cave draws a thin sliver (use `rock`).
Tests: `unit_ground_art` (pieces, mix, cliff pieces, art check for `cliff`), `tools/tests/test_build_cliffs.py`.

# ADR 0024 — M16.4 Liscor districts

Date: 2026-09-29 · Status: M16.4.0 (crowd) and M16.4.1 (streets) done; rooms follow (M16.4.2–M16.4.4)

## Context
Liscor was two yard maps. ROADMAP M16.4 asks for 5–7 district maps joined by streets, streets that go on at the map
edge, a crowd of passers-by (view only) and canon places from Books 1–5 with guesses marked. User answers (2026-09-29):
6 street maps; interiors for the main rooms (guilds, Watch barracks, taverns).

## Decisions
- Keep the ids `liscor_gate` and `liscor_market` (canon events, schedules and about 25 tests use them). New maps join
  through exits: `liscor_market` → `liscor_plaza` → `liscor_guild_street`, `liscor_watch`, `liscor_homes`.
- Streets go on by running to the map edge: the edge stops the player, so no invisible wall is needed. Edges of the
  plaza and Watch maps are roofs and walls; the plaza's four edges and the guild street and homes ends are open cobble.
- Doors face south only (a house draws its south face), so buildings with doors sit on the north side of an east–west
  street. Each map lists its houses in a generator script (scratchpad, not in git); the JSON is the source.
- Crowd = view only (`crowd` map field, `game/world/crowd.gd`); walkers never enter `GameState`.

## Schema change (rule 11, approved with the M16.4 plan)
Optional map field `crowd`: `{"lanes": [{"path": [[x, y], ...], "walkers": n, "looks": ["race_drake", ...], "hours"?: [from, to]}]}`.
Not read by `game/core/`. `unit_crowd` checks that every lane cell is walkable and free of solid objects, every look has a
sheet, and a map shows at most `Crowd.MAX_WALKERS` (12) walkers.

## Canon basis (research from the extracted chapters; paraphrased, chapter numbers as in the raw files)
| Place | What the text says | Used as |
|---|---|---|
| Adventurers' Guild | two storeys, plain sign, one big hall with a counter, a job board, tables; stairs to a small upper floor (1.11, 1.62, 1.63) | room in M16.4.2 |
| Mages' Guild | crystal-ball-and-wand sign (1.11); front counter with a Drake clerk, messages carried upstairs (3.38) | room in M16.4.2 |
| Watch House | main street beside a Hive entrance (1.62); big ground room with tables, a desk near the door, stairs to Zevara's office (1.07, 1.15, 1.28) | room in M16.4.3 |
| Tailless Thief | north side of town, the costly Drake inn, counter with kegs, kitchen, lamps (2.09) | door on the guild street, room in M16.4.4 |
| Gnoll tavern | Gnoll customers and staff, one central table (2.17); street and name not stated | door on the homes street, room in M16.4.4 |
| Plaza and park | open plaza with benches, trees, a pillared public building with the city sigil (1.11); round cobbled park with a wooden playground (2.41) | `liscor_plaza` (no playground art) |
| Gates | east (1.11), north and south gates exist (1.60, 2.09); no west gate stated | not drawn: streets run to the edge |
| Merchants' and Runners' Guilds | not placed in Liscor by the text; most cities have them (memory note) | signed and closed on the guild street |
| Olesm | works for the Council, not at the Guild (1.25) | no schedule change |
| Terbore, Tekshia | Guild regulars; no look sheet, so no NPC yet | stay unplaced |

## M16.4.0 result (crowd)
`Crowd` (pure): `cells`, `chain` (ping-pong), `walker(lane, i, n, t)` (cell, prev, dir, step), `active(lane, hour)`
(default hours 6–22). `WorldView._show_crowd` / `_move_crowd` put a marker with a `CharacterSprite` per walker in the
Props layer, moved by real time (one cell per 0.7 s, `CharacterSprite.walk` glide), hidden outside the lane's hours,
no label. Applied to `liscor_market`. Tests: `unit_crowd` (9).

## M16.4.1 result (streets)
New maps: `liscor_plaza` (park, benches, notice board, Council Hall plaque), `liscor_guild_street` (Adventurers', Mages',
Merchants', Runners' Guilds and the Tailless Thief as signed buildings), `liscor_watch` (Watch House, quarters, Hive
entrance, city wall), `liscor_homes` (Selys's, Krshia's, the Gnoll tavern, homes). `liscor_market` gets a west exit to
the plaza. Doors of the enterable buildings are `stone_door` cells with a sign plaque beside them until their rooms exist
(M16.4.2–4 turn them into exits). New sign icons: sword, star, shield, scroll (`tools/build_signs.py`, `objects.json`
`signs`; `plaque` now points at the moved empty cell). Music mood `liscor`, ambience `market` for all four maps.
Tests: `unit_liscor_map` (reach, two-way exits, signed doors, moods).

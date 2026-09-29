# ADR 0025 — M16.5 Celum districts

Date: 2026-09-29 · Status: M16.5.0 (streets) and M16.5.1-3 (rooms) done: M16.5 complete

## Context
Celum was two yard maps (`celum_gate`, `celum_square`) and three bare rooms. ROADMAP M16.5 asks for the same treatment as Liscor
(ADR 0024). User answer (2026-09-29): 4 new streets, furnish the 3 existing rooms; the Mage's, Adventurers' and Merchants' Guilds stay
signed and closed.

## Decisions
- Keep every `celum_*` id (canon events, schedules and about 15 tests use them). `celum_square` stays the hub; its Rat's Tail door,
  well, stall, braziers, the muggers ground (2-4, 9-11), Hess's stall spot (26, 13), Erin's and Grev's spots are unchanged.
- The Runners' Guild, Frenzied Hare and Stitchworks doors moved off the square onto streets. The old door cells of the square
  are plain brick; three new exits leave the square: north gap (15-16, 0), west edge (0, 9-10), east edge (31, 10). The off-map
  arrival cell (31, 9) stays free.
- An exit rectangle wider than one cell shifts `arrive` by the cell's offset: `arrive` must be free floor for every cell of the exit.
- `stitchworks_door` (the shop) moved to Springbottom Street as a `plaque` object with `sign: {icon: none}` (an empty sign) so the
  door does not draw twice; the exit carries the potion sign.
- No schema change, no `game/core/` change: the `crowd`, `sign` and `plaque` features from M16.3 and M16.4 are enough.
- Test lesson: `ToyMaps.walk_to_area` is one hop. A test that goes from the square to a room now walks square, street, room.

## Canon basis (chapter numbers as in the raw files; paraphrased)
| Place | What the text says | Used as |
|---|---|---|
| Gate and wall | grey walls, a winch, gatehouse with a fee stand, at least two gates (1.19R, 2.44) | `celum_gate` (unchanged) |
| Main street | from the gate; the Adventurers' Guild is on it (2.44); the Mage's Guild is on the Runners' Guild street (2.47) | `celum_main_street`: Runners' Guild door, Mage's and Adventurers' Guild plaques (closed) |
| Runners' Guild | iron-bound door, counter, request board, tables (1.33R, 2.08); no floors given | door on the main street; room in M16.5.1 |
| Merchants' Guild | no building in the text | closed plaque |
| Reinhart mansion | marble front, iron gate, richer part of town (1.19R, 1.27R) | one closed plaque "grand house behind an iron gate" |
| Frenzied Hare | run-down, shutters, no glass, big common room with a fire, kitchen door (2.47, 3.15) | `celum_hare_street` door; room in M16.5.2 |
| Poor streets | wooden houses, no glass, mud lanes, food stalls; Jasi and Grev's hut by the wall (3.15) | `celum_hare_street` (stalls, mud), `celum_poor_quarter` (wall, hut plaque) |
| Stitchworks | small side street of nicer shops, between two shops (2.08, 2.44) | `celum_stitchworks_street`: door with a closed shop each side; room in M16.5.3 |
| Hess's bakery | Springbottom Street (3.16) | plaque on Springbottom Street (he still sells at the square stall in the morning) |
| Square | not described | guess (kept) |
| Council, church, docks | absent from the text | not drawn |

## M16.5.0 result (streets)
New maps: `celum_main_street` (32x24), `celum_stitchworks_street` (32x22), `celum_hare_street` (32x24), `celum_poor_quarter`
(32x24, city wall on the west and south). Crowd lanes (view only, mostly humans, a few Drakes and Gnolls) on the square and every
street. Music mood `celum`, ambience `market`. Generator: scratchpad `gen_celum.py` (gone next session; the JSON is the source).
Tests: `unit_celum_map` (10: reach from the gate, two-way exits, arrivals on free floor, signed doors, moved doors, moods);
`unit_economy`, `unit_portal`, `sim_book3_stages` follow the moved Stitchworks door; `sim_celum_start`, `sim_celum_trip`,
`sim_erin_in_celum` walk the extra hop.

## M16.5.1-3 result (rooms)
The three rooms keep their size, door cell and every existing object, so schedules and stages (Stenei (10, 2), Octavia (4, 2), Agnes
(6, 3), Erin's and the Horns' Hare spots, the 3.04 and 2.47 fight tiles) still stand on free floor. Added furniture only, from
existing kinds: Runners' Guild (potion and supply shelves, two runners' tables, a bench; two idle runners and one walker), Frenzied
Hare (common-room fire, two more tables, bench, kitchen shelves, woodpile; three patrons), Stitchworks (herb and potion shelves,
mixing desk; one customer). The Hare's upstairs rooms, the Runners' Guild's floors and Stitchworks's upstairs and kitchen are not
drawn (canon gives no plan). Each room's door leads back to its street. Test: `sim_celum_rooms` (Stenei, Octavia and Agnes at work at noon).

## M16.5 summary
Celum is now 6 street maps and 3 rooms (9 maps). Not done, on purpose: rooms for the Mage's, Adventurers' and Merchants' Guilds (signed
and closed), the Rat's Tail room (still a door shop), the Reinhart mansion, a second gate, Springbottom Street as a separate street
from Stitchworks's (the text does not join them), the Hare's stage. The full suite runs once at M16.6 (M16.5 changed no `game/core/` code).

# ADR 0026 — M16.6 The other maps

Date: 2026-09-29 · Status: M16.6.0-5 done; full suite run once (118 scripts, 1101 tests), one failure fixed

## Context
M16.0-M16.5 fixed the art and rebuilt Liscor and Celum as districts. What was left of the audit (ADR 0023): items 13 (interior
walls), 19 (gates), 22-25 (Esthelm ruins, inn hill, ruins entrance, caves). User answers (2026-09-29): Esthelm = polish the ruins only;
extras = gates, interior windows, cave decoration.

## Decisions
- No `game/core/` change, no save change, no JSON schema change. New pieces use existing fields: `plaque` objects with `sign`
  (M16.3), `house` tiles (M16.2), object kinds in `objects.json`, one new tile `wood_window` (sprite only).
- Never invent canon (rule 9): no stable, fence or well on the inn hill (the text has none). Guesses are named in each map's `note`.
- Positions that schedules, stages and starts use stay free (Liscor gate (2,10), (2,13), (3,12); Gazi's stage tile (18,9); Wesle's post
  (15,2) on Celum's gate; Celum's farewell stage (17-20, 4-6)). `unit_other_maps` checks the important ones.
- A plaque on a house wall has to keep a free cell next to it (`unit_map_db` "reaches every object"): shacks are placed with free floor
  below the plaque.

## Canon basis (chapter numbers as in the raw files; paraphrased)
| Place | What the text says | Used as |
|---|---|---|
| Inn outside | new inn (2.11+) on a hill, Liscor 20 min west; varnished wood, glass windows, gold-lettered sign; a "No Killing Goblins" board hammered in by the door (1.18); outhouses; stream a few hundred feet away; no stable, fence, well, garden or hitching post (3.33) | board plaque by the door (guess that it stands again after the rebuild); nothing else |
| Liscor gate | about 40 ft grey wall, battlements with guards, two solid metal doors, one guard, closes at sundown (1.11, 2.11, 3.34); towers, moat, gatehouse not stated | two stone gatehouses flank the gate (guess), signed exit "Liscor" |
| Celum gate | tall grey walls, spearmen and archers in towers, gates open with a winch, gatehouse with a merchant fee stand (1.19R, 2.44, 3.24) | two stone towers flank the gate, fee-stand plaque "Gate fee", signed exit "Celum" |
| Esthelm | a city; after the fall walls torn down, gates forced, towers shattered, rubble, salvage huts, refugee camps (3.17T-3.19T) | four refugee shacks (plain houses, guess), green square removed |
| Ruins entrance | black-stone doors in a hillside; palisade of stakes, deep ditch, twenty guards (2.02) | ditch strips beside the palisade and two Watch tents (guess: the text does not say where) |
| Road camp | not in the text (the map is a guess) | signed roads, an abandoned cart |

## Results
| Audit item | What changed |
|---|---|
| 19 gates | `celum_gate`: two `building` towers (3x4) beside the gate, brazier moved to (11,4), fee-stand plaque. `liscor_gate`: two `building` gatehouses (2x3) in the wall on each side of the gate. Both gate exits are signed. |
| 22 Esthelm | four shacks (`plain_house` / `plain_house_b`) at (2-4, 1-2), (1-3, 18-20), (22-24, 9-10), (17-19, 19-21), "Refugee shelter" plaques, the green grass square at (26,16) is cobble. |
| 23 inn hill | `inn_goblin_board` plaque at (14,12); floodplains: "Ford" plaque at the stepping stones (23,17). |
| 24 ruins entrance | fence and iron gate kept; ditch (`chasm`) at x=9 and x=22, rows 4-8; two "Watch post" tents; two trees moved off the tent rows. Road camp: three signed exits, a cart. |
| 13 interior walls | new tile `wood_window` (`game/assets/tiles/windows.png`, `tools/build_windows.py`, drawn on the wall cell of `lpc_interior`) in the top wall of 11 rooms (spacing 4, never above an object or beside an exit). |
| 25 caves | new object kinds `cobweb`, `bones`, `glow_mushrooms` (`tools/build_objects.py`, `objects.json`; mushrooms give a small blue light) placed on `liscor_depths`, `liscor_crypt`, `bee_cave`, `esthelm_creler_cave` (19 props). `dungeon_rift` is open grass and stays as it is. |

Lesson: a first layout put a shack at (7-9, 9-11), 3 cells below the siege player's spot (8, 6). `sim_esthelm_siege` `test_holding_the_barricade_changes_the_battle` then never got a melee hit on the commander (the full suite caught it: 1 of 1101 failed). Shack 1 moved to the top-left corner; the siege stage's `from` cells (10,6), (15,21), (29,11), (26,16) and the foes' lanes stay clear. Keep decoration out of the fight lanes of a stage map.

Tests: `unit_other_maps` (8, new), `tools/tests/test_build_windows.py` (3, new), `unit_map_db`, `unit_ground_art`, `unit_sign_art`,
`unit_world_view`, `sim_canon_book1`-`5`, `sim_canon_fights`, `sim_gazi_attack`, `sim_liscor_rooms`, `sim_celum_rooms`, `sim_liscor_depths`,
`sim_book5_creler_nest`, Python 95, validator 0 errors.

## Left for later (on purpose)
- Rooms for Esthelm before the fall (guild courtyard, well): the game only shows Esthelm after the burning.
- Windows on side and bottom walls, and on the `inn_watchtower`.
- A Liscor gate with real tall walls and battlement art (the wall is still one flat tile).
- Pines still carry no snow in winter.

# World wireframe (compass rules for the open map)

Purpose: when we add roads, landmarks and maps, nobody breaks canon direction.
Picture: `docs/world_wireframe.svg` (left: continents, right: the Izril corridor).

Sources: wiki.wanderinginn.com (Izril, Map, Innworld, city pages) and the Book 1 – 7 ebook text in `canon/raw/`.
Fan maps from the wiki, read on 2026-10-08: the political map `PolMapIzril.png`, the topographic map by auspiciousoctopi, and the world map `Innworld_SynMap.png`.
The political map says: "None of the borders are story canon." Use these maps for **direction and order only** (confidence **M**). Their scale is wrong (see section 3).
The Fandom wiki answered "402 Payment Required", so it was not read. The wiki follows the web serial: the ebook wins.

Confidence: **M** = fan maps agree, books do not contradict. **A** = ebook text. **B** = wiki, clear. **C** = wiki estimate or guess. **X** = sources disagree.
Rule: the game uses the **direction and order** of places as hard rules. It uses **distances** as soft numbers.

## 1. Frame

- North is up. +x east, +y north. Origin (0,0) = Liscor. Units = miles.
- The world has 5 named continents and the Drath remnant. Rough size: about 3 times Earth (B).
- Seasons are the same in both hemispheres (B). Do not add a "southern winter".

## 2. Continents (schematic)

| Place | Rule | Conf |
|---|---|---|
| Izril | Centre of the map. Third largest. A narrow waist (Liscor, the High Passes) joins a small north lobe to a big south. | M |
| Terandria | North of Izril, a little to the east. Only Terandria and Baleros have year-round snow. | A/M |
| Baleros | **Far west** of Izril (1.34, SynMap). Big jungle south, "hammer" north. | A/M |
| Chandrar | South of Izril. Southernmost. Biggest (desert). Most story places are in its north-east corner. | B/M |
| Rhir | **Far east** of Izril, NW of Chandrar (8.61), the NE corner of Ryoka's chess set. | M |
| Drath Archipelago | **North-east**, past Izril and Terandria, near the Edge. (Map page: "east of Izril", 1.03 R.) | M |
| Isles of Minos | East of Chandrar. | B/M |
| Wistram | A lone island east of Izril, between Izril and Rhir (SynMap). The wiki text puts it on the Izril – Baleros route and "equidistant". Treat as **X**. | X |
| Edge of the World | North-east corner of the map, past Drath and Rhir. | M |

Outliers, not used: the wiki Rhir page says "north-west of Izril", the Drath article says "west of Izril", and one line says Chandrar is "far south **and west** of Liscor". The maps, the chess set and ch 8.61 agree on the layout above.

## 3. Izril, north to south (the spine)

| Order | Place | From Liscor | Conf |
|---|---|---|---|
| 1 | First Landing (northernmost city) | about 4,000 mi N | B |
| 2 | Reizmelt (Laiss 30 mi S of it, Walta 79 mi W) | 600 – 800 mi N (estimate) | C |
| 3 | Invrisil | 430 mi N | X (see below) |
| 4 | Riverfarm | 50 – 80 mi **south-west** of Invrisil | B |
| 5 | Lellisdam | 80 mi N of Celum | B |
| 6 | Celum | 88 mi N | A |
| 7 | Esthelm (southernmost human city) | 30 mi N | B |
| 8 | **Liscor**, in the valley through the High Passes | 0 | A |
| 9 | Blood Fields | edge 90 mi S | B |
| 10 | Hectval (closest Drake city, past the Blood Fields; Whitterbone Pass between) | about 100 – 200 mi S | C |
| 11 | Pallass (north-most Walled City), a bit **west** of the Liscor line, west edge of the Gnoll Plains | **400 mi S** (Book 7, ch 5.04 and the "north to Liscor" trade route) | A (distance) / M (side) |
| 12 | Comoller | 160 mi S of Pallass | B |

Scale warning: on the fan maps Pallass is 1.5 times as far from Liscor as Invrisil. The books say 400 and 430 mi (about equal). Use the book miles. Do not measure the fan map.

Invrisil conflict: Book 3 (3.09) "over four hundred miles"; Book 2 (2.15) "six hundred"; wiki Invrisil page 300 N of Celum
(= about 390); wiki Celum page 600 S of Invrisil. Pick **430** for the game. The order Liscor – Esthelm – Celum – Invrisil is certain.

The High Passes are a mountain belt across Izril. Liscor is the only normal way through, and its valley has a north and a south gate (B).
The Black Castle (Az'kerash) is in a forest on the west side of the Blood Fields, against the High Passes (B).
Selys's map: humans live north of a line about two-thirds up the continent (B).

## 4. The Celum – Invrisil – Riverfarm chain (the road you asked about)

Hard rules for the road:
1. Riverfarm is **not on the road to Invrisil**. It lies 50 – 80 mi **south-west** of Invrisil. Invrisil is the nearest big city (A, 3.01 E).
2. Riverfarm is "decently far from the High Passes" (A) and a runner can reach Invrisil in about 2 days (B).
3. Riverfarm villages: Windrest (14 mi **east**, destroyed), Filk (32 mi), Bells (30+ mi), Lancrel (north of Filk and Riverfarm), Heldeim (east of Filk), Neunham (near). Wiki also lists Acran, Batte, Gec, Kemse, Mafalt, Tabeil.
4. Near Invrisil: Sovvex, Rhogit, Feindel (south of or near it), Toremn (east), Embrie, Talizmet, Vitti.
5. Near Celum: Wales, Remendia, Pelingor, Lindol, Ocre, Celers. Wales and Remendia have Runners' Guilds in Book 1.
6. Celum is "one of the southernmost cities before the High Passes". Nothing human lies between Celum and Esthelm except farms.
7. Open: Laken said (3.37) Riverfarm is "to the... east, I think". He was lost and guessing. Do **not** use it. If a map needs it, ask the user.

Suggested graph (miles, soft): Liscor –30– Esthelm –58– Celum –~340– Invrisil –~65 (SW)– Riverfarm.
The long Celum – Invrisil stretch needs 3 – 5 waypoints from rule 4. The data already has `road_to_invrisil` and `riverfarm_road`.

## 5. Southern Izril (fan maps agree, no border is canon)

Bearings from Liscor:

| Place | Bearing | Note | Conf |
|---|---|---|---|
| Pallass | S, a bit W | West edge of the Gnoll Plains, by the Blood Fields | A/M |
| Manus | SW | Nearest Walled City to the Antinium lands (B) | B/M |
| Antinium lands (Hivelands) | W and SW, north-west coast below the High Passes | 1.34 text | A |
| Gnoll Plains | S and E, around Pallass | Split by the East and South High Passes | B/M |
| Fissival | far E, on the east coast, plateau | East of the East High Passes | B/M |
| Salazsar | SE, east of the South High Passes | Built into a mountainside | M |
| Oteslia | S, inland, in the Gnoll Plains | Landlocked. Nearest Walled City to the Plains | B/M |
| Zeres | far S tip, south-west coast | Port. The New Lands rose in the SW (B) | M |
| Hectval, Drisshia, Luldem, Sasil | S, past the Blood Fields | Drake cities. Whitterbone Pass links Hectval and the Blood Fields | B |
| Comoller | 160 mi S of Pallass | | B |

Mountain belts (M): Western High Passes run north-west of Liscor, the East High Passes run south-east of it, the South High Passes lie further south.
Blood Fields: a red plain just south of Liscor. The Black Castle is west of them, in a forest by the High Passes (B).
The Great Plains are about a fifth of their old size, and the New Lands roughly doubled or tripled them after the Meeting of the Tribes (B).

## 6. Rules for map makers

1. A new road keeps the order in section 3. A trip Liscor to Invrisil always passes Esthelm and Celum.
2. Riverfarm is entered from the Invrisil side, from the south-west. Never put it north-east of Invrisil.
3. Never put a Walled City north of Pallass. Never put a human city south of Esthelm.
4. Liscor is the only land gate between north and south Izril (the "infested route" is a dungeon-grade exception).
5. North of the High Passes is cold in winter, and Terandria and Baleros keep snow all year (A). Izril does not.
6. Draw Wistram only as "an island east of Izril" until the ebook settles it. Keep Drath and the Edge off any playable map.
7. Mark any new distance with `"confidence"` in data (project rule 9).

## 7. Decisions (user, 2026-10-08)

1. Wistram: draw it only as "an island east of Izril" until the ebook settles it.
2. Game scale: use the **book miles** (Celum 88, Invrisil 430, Pallass 400). Do not measure the fan maps. Ryoka's 8,000 mi is not used.
3. Invrisil: 430 mi north of Liscor.

## 8. Still open

1. Drath: confirm "east / north-east" in 1.03 R.
2. Riverfarm is not on any fan map. Its place comes only from the wiki and Book 3 text (SW of Invrisil).

The wiki is thin on directions. Most Walled City pages say only "in Izril". The fan maps fill that gap, but they are speculation.

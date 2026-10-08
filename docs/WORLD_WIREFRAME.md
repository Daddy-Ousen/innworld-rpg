# World wireframe (compass rules for the open map)

Purpose: when we add roads, landmarks and maps, nobody breaks canon direction.
Picture: `docs/world_wireframe.svg` (left: continents, right: the Izril corridor).

Sources: wiki.wanderinginn.com (Izril, Map, Innworld, city pages) and the Book 1 – 7 ebook text in `canon/raw/`.
The Fandom wiki answered "402 Payment Required", so it was not read. The wiki follows the web serial: the ebook wins.

Confidence: **A** = ebook text. **B** = wiki, clear. **C** = wiki estimate or guess. **X** = sources disagree.
Rule: the game uses the **direction and order** of places as hard rules. It uses **distances** as soft numbers.

## 1. Frame

- North is up. +x east, +y north. Origin (0,0) = Liscor. Units = miles.
- The world has 5 named continents and the Drath remnant. Rough size: about 3 times Earth (B).
- Seasons are the same in both hemispheres (B). Do not add a "southern winter".

## 2. Continents (schematic)

| Place | Rule | Conf |
|---|---|---|
| Izril | Centre of the map. Third largest. About 8,000 mi north to south. | B |
| Terandria | North of Izril. Only Terandria and Baleros have year-round snow. | A/B |
| Rhir | North-west of Izril. Smallest and northernmost. Hivelands face it. | B |
| Baleros | West of Izril (1.34), a bit south. Ryoka's chess set said south-west. | A/B |
| Chandrar | South of Izril. Southernmost continent. Biggest (desert). | B |
| Wistram | An island near the middle of the sea routes. Izril-east to Baleros-west, Chandrar-south to Terandria-north cross there. | C |
| Isles of Minos | East of Chandrar. | B |
| Drath | **X.** Drath article: west of Izril. Map page: east (cites 1.03 R). Do not draw it until the ebook text is checked. | X |
| Edge of the World | West and north of Rhir. Drath is the closest land to it. | C |

Do not trust: Rhir "north-east" and Chandrar "far south **and west** of Liscor". Both conflict with other lines (X).

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
| 11 | Pallass (north-most Walled City) | **400 mi S** (Book 7, ch 5.04 and the "north to Liscor" trade route) | A |
| 12 | Comoller | 160 mi S of Pallass | B |

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

## 5. Southern Izril (low confidence: placed by relation only)

- Antinium Hivelands: **north-west coast below the High Passes** (A, 1.34). Manus is the Walled City nearest to them (B).
- Great Plains (Gnolls): central-south, split by the east and south High Passes. Oteslia is the closest Walled City and is landlocked (B).
- Fissival: far south-east coast, on a plateau (B).
- Salazsar: built into a mountainside. Sserys' Line links it to the west and centre trade roads (B). Side not stated.
- Zeres: port city, ally of Pallass, Soieln river by it. Which coast: **not stated**. The New Lands (rising south-west after the Meeting of the Tribes) pushed Drake cities such as Zeres. Do not place it on a coast yet.
- Drisshia, Luldem, Sasil: south of Liscor. Wicess: south of Liscor and the Blood Fields. Hectval, Luldem, Drisshia form the Three Cities Alliance.
- Pallass x-position is unknown (only "400 mi south"). Pallass sits on the trade route north to Liscor (A, 5.02).

## 6. Rules for map makers

1. A new road keeps the order in section 3. A trip Liscor to Invrisil always passes Esthelm and Celum.
2. Riverfarm is entered from the Invrisil side, from the south-west. Never put it north-east of Invrisil.
3. Never put a Walled City north of Pallass. Never put a human city south of Esthelm.
4. Liscor is the only land gate between north and south Izril (the "infested route" is a dungeon-grade exception).
5. North of the High Passes is cold in winter, and Terandria and Baleros keep snow all year (A). Izril does not.
6. Do not draw Drath, Wistram or the Edge until a later book check settles them.
7. Mark any new distance with `"confidence"` in data (project rule 9).

## 7. Open questions (need the ebook or the user)

1. Drath: east or west? (1.03 R)
2. Zeres, Salazsar, Manus: which side of Izril? Search later books before building those maps.
3. Is the Hivelands coast really north-west, and how far is it from Liscor in miles?
4. Pallass: how far east or west of the Liscor line?
5. Invrisil: keep 430 mi?

The wiki is thin on directions. Most Walled City pages say only "in Izril". Many Izril positions here are relative ("closest to", "below") not coordinates.

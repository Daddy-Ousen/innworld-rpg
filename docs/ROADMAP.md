# Roadmap

Rule: finish a milestone's acceptance tests before starting the next. Tick boxes as you go.

## M0 — Setup
- [x] `git init`, `.gitignore` (books folder, `canon/raw/`, `.godot/`) — `*.import` is kept in git, see ADR 0001
- [x] Godot 4 project in `game/`, GUT installed in `game/addons/gut`
- [x] Folder layout from CLAUDE.md
- [x] `core/rng.gd` (seeded), `core/game_state.gd` (empty, save/load JSON, `save_version`)
- [x] One passing GUT test run from the headless command
**Done when:** the headless test command exits 0.

## M1 — Sim core (text only)
- [x] Clock: minutes, day counter, forced collapse
- [x] Action log + tag system (`data/actions.json`, 32 actions, `data/tags.json`)
- [x] XP formula with novelty/risk/conviction multipliers (+ outcome, ADR 0002)
- [x] Class candidates, offers, accept/decline, permanent blacklist (`data/classes.json`, ~15 classes)
- [x] Levels, exponential curve, multi-class dilution
- [x] Skills from weighted pools (`data/skills.json`, ~40 skills)
- [x] Night resolution pipeline (DESIGN §2), steps 1–4 and 8
- [x] Debug text console scene: type actions, sleep, see System messages
**Done when:** `sim_30_days` test drives 30 days of scripted actions with a fixed seed, and gets the same offers/levels every run; a decline test shows the class never returns.
  Done: `tests/sim_30_days.gd`, `tests/sim_decline.gd` (ADR 0003).

## M2 — Canon pipeline
- [x] `tools/extract_epub.py` → chapter text files + `index.json` (chapter id, title, word count)
- [x] Event/NPC/location JSON schemas + a validator (`tools/validate_data.py`) — ADR 0004
- [x] Extract the first ~10 chapters of Book 1 into event candidates; human review — 1.00–1.09, 26 events, reviewed
**Done when:** validator passes on `canon/events/book1/` (now `game/data/canon/book1/`).
  Done: `python tools/validate_data.py canon/events/book1` → 0 errors (ADR 0004).

## M3 — World director
- [x] Event nodes, windows, roles, requires, `on_fail`, effects
- [x] Substitute / delay / mutate / cancel + dependency propagation
- [x] Drift value; T1 rumors in the morning summary
- [x] Tests with toy data: "save a doomed NPC", "kill a future-important NPC", "prevent an event"
**Done when:** the three toy scenarios give the expected history and drift.
  Done: `tests/sim_divergence.gd`; real Book 1 week in `tests/sim_canon_book1.gd` (ADR 0005).

## M4 — 2D world
Split into 5 sub-modules, one branch + PR each (plan approved 2026-09-23).
The player is one of the Earthers of the Great Ritual (night 7). They start outside the Liscor east gate on day 8;
days 1–7 run as canon history at new game (Celum start: later, see ADR 0006).
- [x] M4.1 Canon data 1.10–1.14 (NPCs for the market and gate; `sim_canon_book1` to day 9)
- [x] M4.2 World grid core (headless): maps as JSON, player position, grid movement, interact, time cost per step — save v4 (ADR 0006)
- [x] M4.3 2D view: tilemap (placeholder tiles) for Liscor gate + market, a Floodplains patch, the inn on the hill; camera, input, HUD (ADR 0007)
- [x] M4.4 NPC schedules + utility AI for 14 NPCs — save v5, exact float saves (ADR 0008)
- [x] M4.5 System message UI: System dialog (night pages, offers with Accept / Decline + confirm), sleep in the inn bed, character sheet (ADR 0009)
**Done when:** from a new game the player walks from the Liscor gate to the market and the inn,
does 3 actions through map objects, meets NPCs who follow their schedules, sleeps, and answers
a class offer in the System dialog. `sim_walk_day` and `sim_npc_day` are deterministic.
Checked by `sim_m4_done` (the first offer comes on day 22 with a plain inn workday; see ADR 0009).

## M5 — Combat
Split into 3 sub-modules, one branch + PR each (plan approved 2026-09-23, ADR 0010).
Enemies: Goblin grunt, Rock Crab, Razorbeak. HP 0 = knocked out (no death). One held improvised item.
- [x] M5.1 Combat core (headless): stats, HP, enemy + item data, attack / block / throw / drop, bump attack, knock-out + safe wake spot, one action record per action kind at fight end — save v6
- [x] M5.2 Monsters on the map: spawn tables, monster turns and AI (pack, ambush, territorial), aggro, flee, take items from map objects, seed cores scare crabs
- [x] M5.3 Combat UI: monster markers, HP in the HUD, combat keys, knock-out System page, console commands
**Done when:** from a new game the player walks to the Floodplains, takes a seed core, meets all 3 enemy
types from the spawn tables, attacks with fists and an item, blocks, throws, scares a Rock Crab, flees a
Razorbeak, is knocked out once and wakes at 06:00 in the inn with low HP; that night's records carry
`combat.melee`, `combat.block`, `combat.thrown`, `combat.improvise` and `running.escape`. `sim_m5_done`
is deterministic, and save/load mid-fight plays on the same.
Checked by `sim_m5_done` through the main scene (seed 2; see ADR 0010 M5.3).

## M6 — Vertical slice
Split into 5 sub-modules, one branch + PR each (plan approved 2026-09-23, ADR 0011).
Canon: all chapters 1.15–1.25. The player changes canon through `hooks` on canon events. First offer on night 2–3.
- [x] M6.1 Play loop: title menu, 3 save slots + autosave, pause menu (Esc), journal with focus (J), welcome page, XP pacing (ADR 0011)
- [x] M6.2 Canon data 1.15–1.20R (`sim_canon_book1` to the new last day)
- [x] M6.3 Canon data 1.21–1.25 (`sim_canon_book1` to day 19)
- [x] M6.4 Player hooks on canon events, local news page, journal history + drift, 3 divergence cases in data — save v7
- [x] M6.5 Canon fights (the Chieftain at the inn), sparing Goblins, NPCs flee monsters, guards fight; `sim_m6_done` — save v8
- [x] The first ~14 in-game days of Book 1 playable end to end
- [x] Save/load at any point; 3 divergence cases work in play
**Done when:** a new player can play two weeks, get a class, and change one canon event.
Checked by `sim_m6_done` through the main scene (seed 1; see ADR 0011 M6.5).

## M7 — Rest of Book 1
Split into 4 canon batches of about 10 chapters, one branch + PR each (plan approved 2026-09-24, ADR 0012).
New engine systems only when a batch needs them; a new schema or system is asked for first (rule 11).
- [x] M7.1 Canon 1.26R–1.34 (days 19–23): the Goblin raid on the inn on day 21 as a canon stage (Klbkch still dies; `change` hook), Pawn, the Watch leaves the inn, Ryoka's crushed leg
- [x] M7.B Big battles: NPC HP (down, not dead), monsters fight allies, stage waves, allies and helpers join, HP bars and fewer labels; the raid remade with 40 Goblins — save v9 (ADR 0013)
- [x] M7.2 Canon 1.35R–1.44R (days 24–33): Pisces mends Ryoka's leg, Gazi of Reim, Relc makes peace, the skeleton, Ryoka's High Passes run and Teriarch's geas; the adventurers' brawl in the inn on day 28 as a canon stage (`change` hook); fleeing monsters leave indoor maps by the door
- [x] M7.3 Canon 1.45–1.54 (days 34–37): Ryoka learns magic, fights Yvlon and Calruz and runs for the Blood Fields; Krshia learns Erin's secret; Ksmvr maims Pawn; the Horns lodge at the inn; Gazi leaves to hunt Ryoka; the Goblin battle on the Floodplains on day 35 as a canon stage (`change` hook)
- [x] M7.4 Canon 1.55R–1.63 (days 38–41): Ryoka breaks the geas at the Bloodfields; the expedition and Skinner; the dead attack Liscor and the inn; the Workers name themselves; Klbkch is reborn (new `revive` effect); Rags kills Skinner; Magnolia and Ryoka come to Liscor. Two canon stages on the night of day 39 (the east gate, the inn hill), each with a `change` hook
**Done when:** all Book 1 canon is event data; `sim_canon_book1` runs to the last canon day with drift 0;
each batch has at least one hook or stage the player can use to change canon; the validator reports 0 errors.

## M8 — Book 2 (Fae and Fare) + Celum
Plan approved 2026-09-25 (ADR 0014). One branch + PR each. Book 2 comes in 5 canon batches like M7.
Celum becomes a playable map and a second start (day 8, 06:00, outside Celum's gate). Travel between
Liscor and Celum: a paid ride and a road with one roadside camp map. Full economy: coins, a goods bag,
simple hunger (one meal a day), a paid room in Celum. Winter systems added in M8.1 (user choice, 2026-09-25):
snow look, cold rules and Frost Fairies on the map, as their own engine step (M8.W, like M7.B).
- [x] M8.1 Canon Interlude – The Call + 2.00–2.09 (days 41–44): the magic call, Ryoka meets Erin, the rescue of Ceria and Olesm from the Ruins, Gazi's attack outside the Ruins as a canon stage on a new `ruins_entrance` map (`change` hook; Gazi cannot die: enemy `escape`), winter arrives, Ryoka back in Celum, Octavia
- [x] M8.W Winter: snow look + Toren's snow wall (map overlays), mild cold (indoors, fires and winter clothes keep you warm), Frost Fairies on the map (talk for `fae` XP, snow when annoyed, iron keeps them away) — save v10
- [x] M8.2 Canon 2.10T–2.18 (incl. Interlude – Mating Rituals Pt. 1, days 43–47): the inn destroyed by Toren's boom-bark firewood and rebuilt in a day near Liscor by the Antinium, hamburgers, Toren falls into the Skinner ruins and flees an armored guardian at the distant "death beyond death" rift (Rags sees him there), Ryoka gets a homing stone from Teriarch, meets Courier Valceif, recovers her memory of Teriarch's dragon form, and Erin's iPhone concert as a new non-combat "scene" stage (`kind: "scene"`, M8.2)
- [x] M8.3 Canon 2.19G–2.26 + 1.00C/1.01C (days 47–55, plus a day-8 placeholder for the unsynced Rhir thread): Rags' tribe takes a golem-guarded mountain dungeon, then conquers the small Jawbreaker Tribe; Relc publicly beats Rags over the chess incident, and Erin stands between them. Erin wins the Frost Faeries' favor with an all-day ritual banquet as a new "scene" stage, gaining [Inn's Aura] and [Wondrous Fare] (the "gold" turns out to be flowers). A noblewoman is caught stealing, exiled into the snow, and rescued by Erin — Lyonette du Marquin, taken in as inn help over Krshia's objections. Toren sneaks off on a week-long hunting montage, is "killed" twice and looted by the Gold-rank team Griffon Hunt, and returns just as Krshia's kinsman Brunkr leads a Silverfang war party on the inn — the M8.3 combat stage, ended when the Gold-rank Halfseekers (Jelaqua, Seborn, Moore) force the brawl apart and offer Ceria a spot on their team. In Reim, Gazi reports to King Flos's war council as the Empire of Sands sends Drevish's severed head, starting a war. A new Book 2-era interlude (1.00C/1.01C) introduces Tom, an Earther on the distant continent of Rhir, fighting Demons in the Blighted Lands — real canon per the user, not flavor-only, expected to matter in later books. New NPCs: Rockgaw, Lyonette, Brunkr, Griffon Hunt (Halrac, Typhenous, Revi, Ulrien), the Halfseekers (Jelaqua, Seborn, Moore), Dreshhi, Mars, Takhatres, Trey, Teresa, Drevish, Tom, Richard, Emily, Wilen. New locations: the mountain dungeon, Jawbreaker camp, Empire of Sands, Rhir, the Blighted Lands. New enemy `silverfang_gnoll_warrior`. Validator 0 errors (`--all`); `sim_canon_book2` extended to day 55; GUT 533/533; Python 51/51.
- [x] M8.4 Canon 2.27G–2.38 (days 56–67): Rags absorbs the Gold Stone Tribe, survives Garen's week of raids, then wins the legendary Red Fang Tribe in a valley duel - Garen submits and warns a Goblin Lord is rising in the south; she and Garen later sneak disguised toward the Wandering Inn. Ryoka is nursed by the Stone Spears Gnolls after a week of Frost Faerie torment, earns their truce with Earth stories, stumbles into the Zel Shivertail/Wall Lord Ilvriss war, escapes captivity into Az'kerash's hidden castle to deliver Teriarch's letter, then returns to find the cub Mrsha missing; she rescues her from a crevasse only for the Goblin Lord's army to overrun the camp, killing Chieftain Urksh - a faerie cancels the [Barefoot Runner] class the System offers her; she never gains a level. Erin invents pizza, discovers harmless faerie-gold coins, calms Halrac's grief with a faerie drink, and tells Bible stories that spontaneously grant Pawn Liscor's first Antinium [Acolyte] class (new `kind: "scene"` stage with a hook); the Horns of Hammerad reform and fight off a disciplined goblin raid tied to the Blood Fields threat; Magnolia hosts Erin, tests her, loses a chess rematch, and delivers a grim world-war briefing. New NPCs: Garen, Urksh, Mrsha, Zel Shivertail, Ilvriss, Periss, Az'kerash, Reynold, Imani, Joseph, Rose. New locations: red_fang_territory, stone_spears_camp, azkerash_castle, magnolia_estate. No new enemies. Validator 0 errors (`--all`); `sim_canon_book2` extended to day 67; GUT 533/533; Python 51/51.
- [x] M8.5 Celum map + Celum start: `rules.world.starts` list (Liscor first, Celum second), title start chooser, 3 Celum maps (gate, town square, Runners' Guild inside), Wesle at the gate, Stenei at the guild counter
- [x] M8.6 Economy + travel (ADR 0015): coins (copper/silver), goods bag, shops + haggling, deliveries at the Celum Runners' Guild, yields from foraging, hunger (each hungry night -10% max HP, floor 50%; Erin feeds inn workers), sleep places (bed full heal, floor indoors or at a camp half, no sleep outdoors), a paid room at the Rat's Tail, the road Celum ↔ roadside camp ↔ Liscor (10 h each), a paid wagon (8 h, no cold) — save v11
- [x] M8.7 Canon Interlude – Quiet Discussions + 2.39–2.48 (days 67–71): Ryoka returns with Mrsha and takes on the Gnoll debt; Rags banned from the inn; the level-cap secret; Toren drags Erin north and leaves her; Erin reaches Celum, beats muggers, meets Octavia and takes over the kitchen of the Frenzied Hare (new indoor map); Teriarch scries for her; Esthelm burns, the Liscor dungeon opens. Antinium Wars interludes kept as history, not events. 4 stages: Snow Golems, the sledding crowd (scene), the Celum muggers, the Hare bar fight. Erin lives in Celum from day 71; Toren leaves the map from day 70
**Done when:** all Book 2 canon is event data and `sim_canon_book2` runs to the last Book 2 day with drift 0;
a new player can start in Celum or Liscor and travel between them by ride or on foot, and earn, spend, eat
and rent a room; each batch has a hook or stage the player can use; the validator reports 0 errors.

## M9 — Book 3 (Flowers of Esthelm)
Plan approved 2026-09-26 (ADR 0016). One branch + PR each. Book 3 comes in 4 canon batches.
Laken (Riverfarm) and Geneva (Baleros) are events only, like Tom on Rhir. Esthelm becomes a playable map
with the siege as a wave stage. Lyonette, Mrsha and Zel get NPC schedules at the Liscor inn.
- [x] M9.1 Canon 3.00 E – 3.05 L + 1.00 D / 1.01 D (days ~71–76): Laken becomes [Emperor]; the Horns enter Albez; Ryoka, Erin and Ivolethe in Celum; Ryoka beats Persua; Lyonette reopens the inn; Geneva the [Doctor]. Lyonette and Mrsha schedules
- [x] M9.2 Canon 3.06 L – 3.14 (days ~73–80): Pawn and the Soldiers; the Albez treasury; Ocre; Ryoka meets Magnolia; Nemor's attack; Laken claims Riverfarm. Ryoka and Fals at the Hare (scene + hook); Corusdeer soup keeps the cold off (save v12)
- [x] M9.3 Canon 3.15 – 3.20 T (days ~77–80): Erin's play; Toren, the Redfang Goblins, the Florist and Ylawes at Esthelm; new `esthelm_ruins` map and the last battle as a wave stage (Redfang helpers); the play as a scene
- [x] M9.4 Canon 3.21 L – 3.25 (days ~81–87): Lyonette's bees and classes; the painted Soldiers; the Antinium delegation; Scalelings and Zel; the Horns in Celum; the Albez door (flags only); Erin leaves Celum. New `bee_cave` map and the dawn bee raid as a wave stage; four scenes (the painted Soldiers, Zel at the inn, Frozen, Erin's leaving); Zel, Jasi and Yvlon schedules
**Done when:** all Book 3 canon is event data and `sim_canon_book3` runs to the last Book 3 day with drift 0;
Esthelm is playable with its siege stage; each batch has a hook or stage the player can use; the validator reports 0 errors.

## M10 — Book 4 (Winter Solstice)
Plan chosen 2026-09-26 (ADR 0017). One branch + PR each. The Albez door first, then 5 canon batches.
The seven "Wistram Days" interludes are the past (Ceria and Pisces at Wistram): history and NPC notes only,
no events on the calendar, like the Antinium Wars interludes.
- [x] M10.0 The Albez door: a magic door the player can use between the Liscor inn and the Frenzied Hare in Celum, with the limits the text gives (engine + save v13)
- [x] M10.1 Canon 3.26 G – 3.29 G
- [x] M10.2 Canon 3.30 – 3.31 G + Wistram Days 1–7 as history notes
- [x] M10.3 Canon 3.32 – 3.35 (the wagon home, Erin's Level 30, the door runs, the Esthelm relief, Ryoka and Laken in Invrisil)
- [x] M10.4 Canon 3.36 – 3.39 (Ryoka and Laken in Invrisil, Valceif dead, Erin home and Christmas named, the Go lesson, Brunkr's arm, the Rock Crab scene)
- [x] M10.5 Canon 3.40 – 3.42 + Interlude – Winter Solstice (the wand deal, Riverfarm fed, matches, the Santa thieves, Christmas and Wrymvr, the solstice visitors)
**Done when:** all Book 4 canon is event data and `sim_canon_book4` runs to the last Book 4 day with drift 0;
the player can use the Albez door within its limits; each batch has a hook or stage the player can use;
the validator reports 0 errors.

## M11 — Graphics, characters and animation
Plan accepted 2026-09-27 (ADR 0018). New books are paused. One branch + PR each.
2D top-down pixel art, 32×32 cells, LPC characters and tiles plus our own edits. Core and saves do not change.
Art is picked by data (`tiles.json` sprites, object sprites, new `appearance.json`); missing art falls back to today's squares.
- [x] M11.0 Art spike: LPC parts and licences checked, `game/assets/` + `CREDITS.md`, cell size 32, `liscor_gate` in LPC tiles, the player walks as an LPC character. The user approves the look
- [x] M11.1 Tiles and objects: all 16 tiles (plus winter and terrain edges), all map objects on the 15 maps
- [x] M11.2 Characters: `appearance.json`, baked character sheets, 4 directions; the player and the 33 NPCs with a schedule (Human, Drake, Gnoll, Antinium, Goblin, half-Elf, Minotaur, skeleton), generic looks per race
- [x] M11.3 Animation: smooth steps, walk cycle, facing, attack swing, hit flash, damage numbers, knock-out fall
- [x] M11.4 Monsters: all 36 enemies with art (30 LPC people looks, 6 creatures from `tools/build_creatures.py`)
- [x] M11.5 Atmosphere: day/night light, falling snow, fire and lamp light
**Done when:** every map, every NPC with a schedule and every enemy draws with art; walking and combat animate;
GUT and the validator pass; the user has checked the game on screen.

## M12 — Audio: music, sound effects, ambience
Plan accepted 2026-09-27 (ADR 0019). One branch + PR each. Core and saves do not change.
Sources: free CC0 / CC-BY / CC-BY-SA packs (Kenney, OpenGameArt) plus `tools/build_sfx.py` for UI blips.
Music follows the place, time, winter and danger, plus special tracks for canon moments (data in `audio.json`).
Volumes are user settings in `user://settings.cfg`, not game state.
- [x] M12.0 Audio spike: sources and licences checked, `game/assets/audio/`, CREDITS, buses, `Audio` autoload skeleton, first blips; one title track, footsteps and a hit. The user approves the sound
- [x] M12.1 Audio core + settings: `audio.json`, cross-fade, volume settings, Options menu (title and pause)
- [x] M12.2 Sound effects: UI, System pages, footsteps by ground, doors, object use, combat, monster voices
- [x] M12.3 Music: a track per kind of place with day / night / winter, fight, big battle, warm scene
- [x] M12.4 Ambience: area beds (birds, crickets, wind, cave, crowd) and object sounds (fires, well, bees)
- [x] M12.5 Canon moments: special tracks for at least 6 canon moments; a sad sting for deaths in the news
**Done when:** every map has mood music; night, winter, fights, battles and scenes change it with a
cross-fade; walking, using objects, combat, menus and System pages make sounds; volumes are saved; at least
6 canon moments have their own music; missing audio gives silence, not errors; GUT, the Python tool tests
and the validator pass; the user has listened to the game.

## M13 — Book 5 (The Last Light)
Plan accepted 2026-09-28 (ADR 0020). One branch + PR each. World and traps first, then 7 canon batches.
4.00 K – 4.05 K and the Trey half of 4.06 (Flos in Chandrar, the past) are history notes only, like the Wistram Days.
Stage and hook choices are asked at the start of each canon batch.
- [x] M13.0 World: exits gated by flags, inn third floor + Bird's watchtower, the dungeon depths and crypt maps, new enemies (no save change)
- [x] M13.T Traps: hidden traps, search and disarm, a trap system in the depths (engine + save v14)
- [x] M13.1 Canon 4.00 K – 4.07 (Flos history notes, Magnolia's gathering, Xrn's plan, Erin's magic soups)
- [x] M13.2 Canon 4.08 T – 4.12 (Toren in the depths, Ryoka home, the Horns' gear, the building contract, new staff)
- [x] M13.3 Canon 4.13 L – 4.17 (the Hive battles, the staff trouble, the Goblin Lord crushes the Drakes, the Strongheart farm)
- [x] M13.4 Canon 1.02 D – 1.06 D (Geneva in Baleros; off-map only)
- [x] M13.5 Canon 4.18 – 4.23 E (the chess marathon, the building starts, the undead from the rift, Laken's Riverfarm)
- [x] M13.6 Canon 4.24 – 4.27 H (winter ends, Brunkr knighted, "Regrika" and "Imenet", Magnolia's army, the Creler nest)
- [x] M13.7 Canon 4.28 – 4.31 ([Word of Death], Brunkr and Ulrien killed, the third floor done, Venitra's attack, Ryoka dies and is revived)
**Done when:** all Book 5 canon is event data and `sim_canon_book5` runs to the last Book 5 day with drift 0;
the third floor and tower open after the building flag; the depths are reachable by rope with working traps;
each batch has a hook or stage; GUT, the Python tool tests and the validator pass.

## M14 — Engine works
Plan accepted 2026-09-28 (ADR 0021). One branch + PR each. Inn play first, balance last.
- [x] M14.0 Bag screen: every good in one screen (I), eat / drink / hold a tool / leave behind, tools stow in the bag
- [x] M14.1 Cooking recipes: `recipes.json`, ingredients from shops, cook actions turn them into dishes
- [x] M14.2 Guests and serving: patrons at meal times, canon NPCs as guests, serve dishes for coin (save v15)
- [x] M14.3 Relationships and reputation: night step 7 decay, town/faction reputation, prices and helpers read it (save v16)
- [x] M14.4 Missing NPC schedules: canon NPCs who live on our maps get schedules and looks
- [x] M14.5 Attack NPCs: attack any NPC, a one-time fate warning for major NPCs, witnesses and reputation react
- [x] M14.6 UI skin: one theme and a free pixel font for every menu
- [x] M14.7 Portraits: NPC faces cut from the character sheets in talk, System pages and news
- [x] M14.8 Balance pass: probe tests, HP per level, tuned XP, prices and fights
**Done when:** the inn earns coin from cooked food served to guests; relationships and reputation change over
time and change prices and help; the on-map canon NPCs have schedules; any NPC can be attacked with the fate
warning; menus share one skin with portraits; the balance probes pass; GUT, the Python tool tests and the
validator pass; the user has played it.

## M15 — Readability and lore fixes
Plan proposed 2026-09-29 from the user's play report (ADR 0022). One branch + PR each. Small and fast; do first.
- [x] M15.0 Font: Pixel Operator (CC0) replaces Pixelify Sans in the theme; every size a multiple of 16; a
  "Large text" box in Options (16 / 32 px, `user://settings.cfg`, not game state). Download approved by the user
- [x] M15.1 The player's day: every screen counts days from the player's arrival (arrival = Day 1). The canon
  day stays inside the engine (director, windows, saves). One helper reads `rules.clock.start_minute`; no save change
- [x] M15.2 HUD and log: the log shows at most 3 lines, bottom left, under half the width, see-through, and fades
  after a few seconds; L opens the full message history; the key list moves to a help page (H) with a one-line
  "H: help" hint
- [x] M15.3 No XP numbers: the action line, character sheet, hints and journal show no XP. The sheet shows each
  class and its level only; the "Total level" line goes (the total level is a secret of the world). The debug console (`) keeps the numbers (developer tool)
**Done when:** the new font is in every menu; no player screen shows "Day 8" at the start or any XP number; the
log covers at most a strip at the bottom left; GUT tests for the changed UI pass; the user has checked it on screen.

## M16 — Maps, art and cities
Plan proposed 2026-09-29 (ADR 0022). One branch + PR each. Core does not change; maps and art are data.
- [x] M16.0 Art audit: a screenshot of every map; a list of every bad tile or prop (rocks, cliffs, thin water,
  flat building blocks) in the ADR. The user checks the list
- [x] M16.1 Nature art: boulder props (1x1, 2x2) that read as rocks; a cliff tile set (top and face) for rock walls
  and mountains; water edges that work for thin water; a bridge / stepping-stones object for crossings; fix the maps
- [x] M16.2 Buildings: a building block draws as a house: roof on top, front wall with windows and a door on the
  bottom row. Styles: Drake stone (Liscor), Human timber and brick (Celum), plain (villages)
- [x] M16.3 Doors and signs: a door or shop shows what it is: a hanging sign icon (bread, anvil, potion, guild
  badge) and its name when the player is near; doors you can enter get a marker; other doors say "Closed" or
  "A private home". New optional object field `sign`
- [x] M16.4 Liscor districts: Liscor becomes 5–7 small district maps (east gate, market street, guild street,
  the Watch and the walls, homes, other gates), joined by streets. Map edges show roofs and streets that go on,
  but the player cannot walk there. A crowd of passers-by (view only). Canon places from Books 1–5; guesses marked
  Sub-steps (user, 2026-09-29: 6 street maps and interiors for the main rooms):
  - [x] M16.4.0 Crowd: view-only walkers (`crowd` map field, `game/world/crowd.gd`)
  - [x] M16.4.1 Streets: plaza and park, guild street, Watch and walls, homes; market west exit
  - [x] M16.4.2 Rooms: Adventurers' Guild, Mages' Guild
  - [x] M16.4.3 Room: Watch barracks
  - [x] M16.4.4 Rooms: Gnoll tavern, Tailless Thief
- [x] M16.5 Celum districts: the same for Celum (gate, town square, guild street with the Runners' Guild, the
  Frenzied Hare street, the Stitchworks street, homes)
  Sub-steps (user, 2026-09-29: 4 new streets and 3 furnished rooms; ADR 0025):
  - [x] M16.5.0 Streets: main street, Springbottom Street, Frenzied Hare street, poor quarter; square doors moved
  - [x] M16.5.1 Room: Runners' Guild
  - [x] M16.5.2 Room: Frenzied Hare
  - [x] M16.5.3 Room: Stitchworks
- [x] M16.6 The other maps: new buildings, props and signs on Esthelm, the road camp, the inn hill and the rest
  Sub-steps (user, 2026-09-29: Esthelm ruins only; plus gates, interior windows, cave decoration; ADR 0026):
  - [x] M16.6.0 Inn hill goblin board, floodplains ford sign
  - [x] M16.6.1 Gates: Celum towers and fee stand, Liscor gatehouses, signed exits
  - [x] M16.6.2 Esthelm ruins: refugee shacks
  - [x] M16.6.3 Ruins entrance ditch and Watch tents, road camp signs and cart
  - [x] M16.6.4 Interior windows (`wood_window` tile) in 11 rooms
  - [x] M16.6.5 Cave decoration: cobwebs, bones, glowing mushrooms
**Done when:** every map passes the audit list; buildings look like buildings; every door and shop says what it
is; Liscor and Celum each have at least 5 districts; NPC schedules and canon places still work
(`sim_canon_book1` … `sim_canon_book5`, validator 0 errors); the user has walked the cities.

## M17 — Tactical combat (XCOM-style)
Plan proposed 2026-09-29 (ADR 0022). One branch + PR each. Engine + save change. Replaces the M5 "one command =
one turn" fights. Combat stays on the same map grid (DESIGN §1); a fight switches the map into combat mode.
Rules from the user (2026-09-29):
- Every fighter (player, NPC allies, helpers, each monster) acts in order of Agility (seeded roll on ties).
- Base 6 AP per turn. One tile of movement = 0.25 AP. A turn may spend at most 1 AP on movement (4 tiles);
  classes and skills can raise that cap ([Runner]: 2 AP = 8 tiles). A normal attack = 2 AP. Skills cost 1–10 AP.
  Spells cost 1–10 AP plus 1–10 MP. Move, attack, move, attack is allowed while AP and the move cap last.
- Extra AP: skills give permanent AP (for example a lesser stamina Skill +1, a greater one +2; names checked
  against the Book text); +1 AP when the TOTAL level (all classes added) reaches 10, 25, 50 and 75. The total
  level is a secret: the player never sees it, and no message says why AP went up.
- MP (mana) is kept between fights like HP and comes back slowly with time.
- AP is stored in quarter points (integers), so the rolls stay deterministic.
- [x] M17.0 Spike + ADR (ADR 0027, 2026-09-30): `rules.combat.tactical` numbers; three fights worked out on paper (Rock Crab, a goblin
  pack, the day-21 raid); how a fight starts, who joins, what a round costs in world time (6 s). The user approves
- [x] M17.1 Core encounter (ADR 0027, 2026-09-30; combat mode off until M17.2): encounter state in `GameState` (turn order, round, AP left, movement used; save v18 +
  migration), start / join / end, order by Agility, move with the cap, attack for 2 AP, end turn; monsters use
  AP too. Headless tests
- [x] M17.2 Port the old fight parts (ADR 0027, 2026-09-30; combat mode on; FightBot test helper): block, throw, improvised weapons, drop, flee, knock-out, fighting NPCs,
  helpers, attack-an-NPC (brawl), traps, stage waves (join at the start of a round), fight records for the
  System. Every sim fight test moved to the new rules (full suite)
- [x] M17.3 Combat screen (ADR 0027, 2026-09-30; turn log + replay, mouse in fights only): move range, path preview, hit chance before you act, AP pips, turn order bar with
  portraits, end-turn button, mouse click to move and attack (keys still work), camera on the active fighter
- [x] M17.4 Skills in combat (ADR 0027, 2026-09-30; cooldowns in rounds, [Runner] class moves 2 AP, strike /
  area / self, NPC allies Erin, Relc, Toren use Skills; save v19): new skill effects `combat_action` (an active Skill: AP cost, range, area, effect),
  `ap_mod` (permanent AP), `move_ap_mod` (move cap); AP at levels 10/25/50/75; a Skill bar. Existing combat
  Skills get their action where the Book text fits
- [x] M17.5 Mana and spells (ADR 0027, 2026-09-30; Intellect + total level, teacher or spellbook, NPC casters Ceria and
  Pisces, save v20): MP stat and regen (save), `data/spells.json` (AP, MP, range, shape, effect,
  `canon_ref`), learning a spell from a teacher or a spellbook (not from nothing), a [Mage] class path, spell
  targets (one foe, line, blast, around). First spells from Books 1–5 only
- [x] M17.6 Cover and position (ADR 0027, 2026-09-30; cloud session; no save change): half and full cover from walls, trees, rocks and solid objects (data: tile and
  object `cover`, `rules.combat.tactical.cover`), walls block sight for throws, shots and targeted spells, pincer +15, monsters: archers and
  shamans take cover, melee monsters close the pincer; cover bars on the combat screen
- [x] M17.7 Enemy abilities and balance (ADR 0027, 2026-09-30; cloud; no shell by the user; no save change; hidden XP moved to M17.8): monster moves in data (archers, Shield Spider leap, Ghoul leap),
  balance probes redone for the new rules, the day-21 raid checked again. Level cost follows the TOTAL level
  (Ryoka's theory, 2.41) with a hidden cap of 100 total levels; `rules.levels` curve retuned (core change)
- [x] M17.8 Hidden XP (ADR 0027, 2026-09-30; cloud; no save version change; the player never sees it): a **duress** multiplier on XP, capped at x2.0. Fights: x0.5 when the
  player lost no HP, x1.0 at 10% lost, then +0.01 per 1% more, on the worst HP drop in the fight, foe damage only. **Event windows** in data:
  `xp_window` on the canon event (pending + day window + hours), a tier x1.5 / x2 / x3, never shown (first: the Skinner nights at the end of Book 1, x2 for all actions). Other classes
  (cooks, runners, healers: duress from crowd, cold, hurt patients, own hunger) get their own sources in a later step, so fighters lead for a while.
  The pace probe (`sim_balance_fighter`) found fighters level about 2x faster than the inn worker; the curve was NOT changed (see ADR 0027 "M17.8")
- [x] M17.9 Work duress (ADR 0027 "M17.9", 2026-10-05; cloud; no save change; hidden): an optional `duress` list on an action in
  `actions.json`; the crowd raises cooking, serving and dishes (up to x2.0), the winter cold raises outdoor work (up to x1.5). Never below
  x1.0. The busy inn worker reaches level 5 on night 10 (was 14); fighters are unchanged (night 6 – 7)
**Done when:** every fight in the game (monsters, stages, brawls) runs in combat mode with AP; the player can use
combat Skills and learned spells; MP and AP gains work; saves from v17 load; the GUT tests that touch it, the Python tool
tests and the validator pass; the user has played fights with the new screen.

## M18 — Book 6 (The General of Izril)
Planned 2026-10-01 (ADR 0028). Work runs in cloud sessions (`docs/CLOUD.md`); the book text is in `canon/raw/book6/` there.
26 chapters, about 280,000 words: 4.32 G, 1.02 C – 1.05 C (Tom in Rhir), 4.33 – 4.47 (letters E, O, B, G, L, M),
Interlude – The Antinium Wars (Pt. 3 – 5), 4.48, 4.49, The Depthless Doctor.
- [x] M18.P Plan + ADR 0028 (2026-10-01, cloud): six reading agents, summaries only. Liscor days 115 – 130; far battles
  are news; Zel dies on day 130. User answers: chapter order number, three new maps, Esthelm as a wave stage, and
  Laken's calendar = his journal day + 45 in every book (no squeeze). The user approves the plan by merging its PR
- [x] M18.0 Canon timing (engine + data, 2026-10-01, cloud): optional chapter key `order` (same-day events follow
  book, chapter order and place in the file; Books 1 – 5 order unchanged, `unit_event_order`); the Book 3 and Book 5
  Laken events moved to his journal day + 45 (days 46 – 91 and 100 – 115); `sim_canon_book3` and `sim_canon_book5`
  fixed. No save change (ADR 0028 "M18.0")
- [x] M18.1 World (2026-10-01, cloud): Wirclaw's village, the inn basement, the Ruins hall and the ossuary (the text
  puts the ossuary in the Ruins of Liscor, so it is two maps there, with a one-way chute and a corridor to
  `liscor_crypt`); the Eater Goat (`leap`, drawn art); looks for the Redfang five, Wirclaw, Falene, Dawil,
  `race_dwarf`, Purple Smile; 38 Book 6 NPC records with no events yet. No save change (ADR 0028 "M18.1")
- [x] M18.2 Canon 4.32 G, 1.02 C – 1.05 C (days 114 – 121): the army passes the inn by night; Rags; Tom in Rhir (off-map)
- [x] M18.3 Canon 4.33 – 4.34 (day 115): Bird's duel, the Eater Goats at Wirclaw's village, Bugear dies, the Redfang five
  move into the inn
- [x] M18.4 Canon 4.35 E – 4.38 B (days 116 – 127): Laken (Day 72 – 82 = days 117 – 127), Olesm (Raskghar, Niers' ring, the crypt chute,
  the rat contract), the Esthelm wave stage, Zel leaves through the door
- [x] M18.5 Canon 4.39 G – 4.42 L (days 126 – 129): Greydath, the Hive front, Mrsha and the Goblins, the party (scene stage in the inn; Rose Knights and Hive as events)
- [x] M18.6 Canon 4.43 – 4.47 (days 128 – 129): Ilvriss and the Pallass anchor, the Silver Swords (scene stage at the inn), Erin Level 33,
  the Goblin Lord's victory, Zel's speech, Liscor's council
- [x] M18.7 Canon Antinium Wars Pt. 3 – 5, 4.48, 4.49 (days 129 – 130): history notes, the battle of Invrisil (news),
  Zel's death (day 130), Liscor mourns (scene stage in the inn, talk hook with Erin), the Chosen data fixes
**Done when:** all Book 6 canon is event data and `sim_canon_book6` runs to the last Book 6 day with drift 0;
each batch has a hook or stage; the GUT tests that touch it, the Python tool tests and the validator pass.

## M19 — Book 7 (The Rains of Liscor)
Planned 2026-10-07 (ADR 0030). Same flow as M18; the book text is in `canon/raw/book7/` (local: cut from the epub;
cloud: the private repo). 22 chapters, about 286,000 words: 5.00 – 5.08 (with 5.06 M), Interlude – Flos, 5.09 E – 5.11 E,
5.12 – 5.15, 5.16 S – 5.18 S, 5.19 G, 5.20 G.
- [x] M19.P Plan + ADR 0030 (2026-10-07, local): seven reading agents, summaries only. Days 133 – about 143; far threads are
  news. User answers: rain and flood (the door is the way to Liscor), a door with several links plus a small Pallass map,
  the moth attack as a wave stage with an XP window x3, the dungeon dive as events only. The user approves the plan by merging its PR
- [x] M19.0 Engine: door links (`portal.links`, pick the stone; schema change approved in ADR 0030) and the rains (season
  flag, rain on screen and in the sound, flood overlays that block walking). No save change expected
- [x] M19.1 World (2026-10-07, local): Pallass door map, the door's Liscor wall end, flood overlays, the [Grand Theatre] and the smashed
  watchtower, the Face-Eater Moth and the moth swarm, looks, Book 7 NPC records
- [ ] M19.2 Canon 5.00 – 5.03 (days 133 – 135): the Pallass crisis, the embargo, the lease, the rains begin
- [ ] M19.3 Canon 5.04 – 5.06 M (days 135 – 136): Octavia and the Players, [Grand Theatre], Toren, Vuliel Drae, Mrsha
- [ ] M19.4 Canon 5.07, 5.08, Interlude – Flos (day 137): the moth wave stage (`xp_window` x3), the aftermath, Flos notes
- [ ] M19.5 Canon 5.09 E – 5.11 E (days 130 – 142): Laken, the banquet and the fae (off-map)
- [ ] M19.6 Canon 5.12 – 5.15 (days 138 – 140): the flood, the door in the west wall, Embria, the parade, the dive (events)
- [ ] M19.7 Canon 5.16 S – 5.18 S (days 140 – 143): the will, Zel's funeral, Selys in Pallass, the Heartflame lease
- [ ] M19.8 Canon 5.19 G, 5.20 G (days 141 – 143): Rags, Garen and Tremborag, the road battle (off-map)
**Done when:** all Book 7 canon is event data and `sim_canon_book7` runs to the last Book 7 day with drift 0;
each batch has a hook or stage; the GUT tests that touch it, the Python tool tests and the validator pass.

## Releases
- [x] v0.1.0-alpha (ADR 0029, published 2026-10-01): export presets (Windows, Linux), `tools/release.ps1` with a smoke test, version on the title
  screen, GitHub pre-release with two zips. Android skipped: no touch controls yet.
- [x] v0.1.1-alpha with the web build (ADR 0031, published 2026-10-02, https://daddy-ousen.github.io/innworld-rpg/): "Web" preset, web zip in `tools/release.ps1`, GitHub Pages workflow,
  itch.io upload by the user
- [ ] Touch controls (on-screen pad, menu buttons), then an Android build: M20 below

## M20 — Touch controls (ADR 0032)
Planned 2026-10-05 (cloud, `docs/plans/m20.md`). User answers: InputMap actions (not fake key events), a 4-way D-pad,
in a fight a tap shows the plan and a second tap acts, M20.0 + M20.1 in one PR.
- [x] M20.0 Input actions (2026-10-05, cloud): every command is a named action in `project.godot` `[input]` with
  today's keys; `world/main.gd` and the panels read actions, not key codes. No behaviour change (Delete now also
  drops the held item outside the bag). No save change
- [x] M20.1 Touch layer (2026-10-05, cloud): `ui/touch_controls.gd` (pad, Use / Bag / More / Menu, More grid, Back,
  Cancel), option Touch controls Auto / On / Off (`user://settings.cfg`, not `GameState`), one tap picks a list item,
  fight tap = plan then act, Bag buttons for X and P, a Back button on the Load list. No save change
- [ ] The user plays it on a phone (the browser build after the next release) and on a PC with a touch screen
- [ ] M20.2 Android build (local session: Android SDK, JDK and a keystore on the user's PC); landscape only
- [x] M20.3 UI scale (ADR 0033, 2026-10-05, cloud): Options "Menu size" Auto / 100% / 150% / 200%; Auto is 200%
  on a touch screen under 5 in; the map and the touch pad keep their size; the Journal, Character sheet, Bag and
  text pages fit a small view. No save change
**Done when:** the whole game (title, walking, menus, fights, the System dialog) can be played with touch only;
the keys work as before; the GUT tests that touch it pass; the user has played it on a phone.

## Later
- optional LLM flavour layer

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
- [ ] M9.4 Canon 3.21 L – 3.25 (days ~78–90): Lyonette's bees and classes; the painted Soldiers; the Antinium delegation; Scalelings and Zel; the Horns in Celum; the Albez door; Erin leaves Celum
**Done when:** all Book 3 canon is event data and `sim_canon_book3` runs to the last Book 3 day with drift 0;
Esthelm is playable with its siege stage; each batch has a hook or stage the player can use; the validator reports 0 errors.

## Later
- Audio · polish (art tiles, balance, missing NPC schedules) · optional LLM flavour layer

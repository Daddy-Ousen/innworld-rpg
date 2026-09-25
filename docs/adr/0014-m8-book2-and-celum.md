# ADR 0014 — M8 Book 2 and Celum

Date: 2026-09-25 · Status: plan accepted (user, 2026-09-25); M8.1 accepted, events reviewed by the user 2026-09-25 (timeline, Invrisil, Gazi balance as proposed); M8.W done; M8.2 built, batch decisions accepted by the user 2026-09-25, events not yet reviewed.

## User choices (plan)
- M8 = Book 2 canon + Celum. Audio, polish and the LLM layer move to "Later".
- Book 2 in five canon batches: M8.1 Interlude – The Call + 2.00–2.09 · M8.2 2.10T–2.18 · M8.3 2.19G–2.26 + 1.00C/1.01C · M8.4 2.27G–2.38 · M8.7 three interludes + 2.39–2.48.
- Celum is a playable map and a second start: day 8, 06:00, outside Celum's gate (M8.5).
- Travel Liscor ↔ Celum by a paid ride and by a road with one roadside camp map; a full economy (coins, goods bag, simple hunger, a paid room in Celum) (M8.6, ADR 0015).
- Winter and snow: asked per batch. In M8.1 the user chose snow look + cold rules + Frost Fairies on the map. They get their own engine step, M8.W, after M8.1 (the M7.B pattern); its details are asked first.
- Calruz stays `missing` (the text never shows his body).

## M8.0 Cross-book tooling
- `tools/validate_data.py` loads the ids of earlier books (book1 … book N-1, sibling folders) as known: a Book 2 event may use Book 1 NPCs, locations and events (roles, requires, depends_on with the window check, mutate targets, NPC home, location parent). Redefining a known id is an error (CanonDb merges all books into one set of ids). New flags: `--no-earlier` (the folder alone) and `--all` (every `book<N>` under a canon root).
- Book 2 is extracted to `canon/raw/book2` (gitignored): 56 chapters, 501,634 words.
- A Book 1 NPC that Book 2 changes is edited in its Book 1 record, with the Book 2 chapter in `canon_ref.note`. No schema change.
- `sim_canon_book1` counts `b1.` events only (Book 2 starts on day 41, inside its run); its rumor count covers every book.
- New `sim_canon_book2`: sleeps to day 40 once, then each test loads a copy of that save.

## M8.1 Canon Interlude – The Call + 2.00–2.09 (days 41–44)

**Timeline (guesses).** Day 41: the call (1.63: Ryoka's phone rings), Ryoka comes back to the inn and meets Erin (2.00), the party (2.01). Night 41–42: Ceria's message reaches Pisces. Day 42: Zevara refuses, Krshia hears of her dead kin, the rescue in the Ruins, Pisces restores the call log, Gazi's attack, winter arrives, the talk at the inn, Ryoka runs north at sunset, the fairies bury the inn (2.02–2.07). Day 43: Toren's snow wall, the Tailless Thief, Ceria will lodge at the inn, winter prices (2.09). Day 43–44: Magnolia hears Theofore's report (2.06). Day 44: Ryoka in Celum, Octavia (2.08, 'nearly two days' after she left).

**21 events**, reviewed by the user 2026-09-25, in 12 chapter files under `game/data/canon/book2/chapters/`.
- New NPCs (book2 `npcs.json`): `octavia` ([Alchemist], String People, Celum) and `peslas` (Level 30 [Innkeeper], the Tailless Thief).
- New locations (book2 `locations.json`): `wistram_academy`, `invrisil` (Magnolia's winter home is likely there, not stated), `tailless_thief` (Liscor), `stitchworks` (Celum).
- The people in the call (BlackMage, Kent Scott and the others) are not NPCs: they appear once, by handle.
- Ceria and Olesm are found (`*.missing` cleared). Calruz is not found and stays missing and alive in the data.
- Klbkch hands the Prognugator's post back to Ksmvr (`ksmvr.deposed` cleared). Rags gives back Ryoka's haste potion (`ryoka.has_speed_potion` set again).
- Winter: `izril.winter` is set on day 42 (tier 1, news and rumor). M8.W reads it.

**Stage and hook — `b2.gazi_attacks_outside_the_ruins` (2.04–2.05).**
- **Map.** New `ruins_entrance` (location `liscor_dungeon`): the stone doors in the hillside, a palisade, a Watch brazier. Reached from the east edge of `floodplains_south` (180 minutes each way, a guess). The knock-out wake spot is the Liscor gate.
- **Stage.** Day 42, 13–17, when `gazi.hunts_ryoka`. One foe, `gazi_of_reim`. Wave 0: Relc, Klbkch, Ksmvr, Erin and three `liscor_guardsman` helpers. Wave at 90 s: Krshia and four `gnoll_hunter` helpers. Zevara is down from the first blow, so she is not on the map.
- **Gazi cannot die.** New optional enemy field `escape: {"below", "line"}`: a hit that takes her below 75% of her hp removes her with the line (her portal). She counts as routed, not killed, so the fight is won with `killed: false`. `Combat.damage_monster` does this for every attacker (player, NPCs, helpers).
- **Hook.** `player_fought_gazi`: a won fight whose top foe is `gazi_of_reim`, on day 42. A `change`: flag `liscor.earther_fought_gazi`, Erin → player +3, Relc +2, Krshia +2, a news line. Erin still takes her eye; everything after runs.
- **Balance.** Gazi: hp 80, armor 5, accuracy 8, evasion 8, damage 2–4, a turn every 6 s, escape below 75%. A probe over six seeds (player walks up and attacks, allies unfrozen): she escaped five times, usually with the player at 4–10 HP; once the player was knocked out. Canon: she bleeds her foes rather than kills.
- Ksmvr gets an `npc_behaviour` entry (off the map, in the Hive) and a combat block; Krshia gets a combat block.

**Tests.**
- `sim_canon_book2` (new): `LAST_DAY` 44; every `b2.` event done with drift 0, one news line per news event, a rumor per tier 1 event; end state (Ceria and Olesm rescued, Gazi gone with one eye, winter, Calruz still missing). Killing Pisces early: no message, no rescue, no Gazi fight, Ceria stays missing; winter and Celum still happen.
- `sim_gazi_attack` (new): stage data; an escaping foe never dies; fighting her off changes the event; a knock-out keeps the canon; no stage on day 41.
- `unit_combat_db`: 18 enemies; bad `escape` data. `sim_player_hooks`: 10 hooks.

**Known limits.**
- The Ruins inside (the Ghouls, the zombies, the coffins) are not a map; only the entrance is.
- Helpers fight in melee: the Gnolls' bows and Gazi's teleport scroll are not modelled.
- News is not tied to where the player is.

## M8.W Winter (engine step after M8.1)
Status: in review. User choices (2026-09-25): mild cold; warm = indoors, near a fire, or in winter clothes; Frost Fairies as pests you can talk to, with XP for a new `fae` tag; snow look plus Toren's snow wall.

**When.** Everything starts with the canon flag `izril.winter` (set by `b2.winter_arrives_with_the_frost_fairies`, so from the morning of day 43). New optional `rules.winter` (flag, cold, fairies); toy dbs have none.

**Cold (`core/winter.gd`).** Outdoors and not warm, every 30 minutes the player loses 1 HP, never below 1 HP (the cold never knocks you out). Warm = a map with `"indoor": true` (new optional map field; only `inn_interior` now), or within 2 tiles of an object with `"warm": true` (new optional object field: the Market Street braziers, the Watch brazier at the Ruins). Winter clothes (flag `player.warm_clothes`) make a tick twice as long; they can be bought in M8.6 (console `flag` until then). Warmth resets the chill. A night does not chill (`Night.run` calls `Winter.night`). The first winter night adds a morning warning line (once, flag `player.warned_of_cold`). HUD: " · Cold".

**Frost Fairies.** On entering an outdoor map: a 60% chance of 2–4 fairies at least 3 tiles away. They fly (any tile in the map, not onto the player or each other), one random step per 6 s; gaps over 300 s re-scatter them; they are gone indoors and after a night. Talking to one (Interact option `fairy:<id>`, action `talk_to_fairy`, tags `fae` 1.0 + `social.conversation` 0.3) gives a rude line. After the first talk of the day, each talk has a 50% chance to annoy: snow drops (1 HP, same floor) and the next 10 steps cost double time (" · Slowed"). Walking into a fairy is a swat: it dodges and drops snow; the swat costs a turn. Holding an item tagged `iron` (new item `horseshoe`, lying on the inn hill) makes them keep at least 4 tiles away and never drop snow. Drawn as small pale diamonds. All randomness goes through `gs.rng`.

**Snow look and the snow wall.** Tiles may have `winter_color` (grass, tall grass, road, cobble, tree, rock, shallows); the view draws it once winter has come. New map field `overlays` (`id`, `tile`, `rects`, `when_flags`, `unless_flags`?): tiles laid over the map while the flags hold; they must not cover an exit or an object. The inn hill's `toren_snow_wall` (tile `snow_wall`, not walkable) rings the inn from flag `wandering_inn.snow_wall` (day 43 event, so from day 44), with a gap on the road to the door. `MapDb.sync_flags(flags)` switches overlays; it is a cache on the db, so every command, `Movement.step`, new games, loads and `WorldView.refresh` call it with the game's flags (the debug console makes its own spare game at start).

**Save v10.** `GameState.winter` (`WinterState`: sec, chill, fairies' area and positions, next id, slowed steps). Migration 9 → 10: no cold yet, no fairies.

**Tests.** `unit_winter` (toy maps: cold, floor, fire, indoor, chill reset, clothes, night and warning, fairies outdoors only, talk XP, snow, swat and slow, iron, overlays on and off, bad overlays and winter rules, save round trip, v9 save). `sim_winter` (real data: no cold before winter, the warning and two bites in an hour at the gate, warm by a Market brazier, the snow wall from day 44 with the road gap to the door, the wall covers no NPC goal or stage tile). `unit_data_db` and `ToyData` drop `rules.winter`.

**Known limits.** Fairies do not follow Ryoka or Erin, and NPCs do not feel the cold. Travel through an exit counts its minutes as cold. Winter never ends yet (Book 2 has no spring).

## M8.2 Canon 2.10T–2.18 + Interlude – Mating Rituals Pt. 1 (days 43–47)

**58 events**, 10 chapter files under `game/data/canon/book2/chapters/`. User choices asked per batch, 2026-09-25:
- The ruin Toren falls into is part of `liscor_dungeon` (he recognises the corridors from the book1 Skinner dungeon), but the far end he later bursts out of (`death_beyond_death`, a distant mountain rift in Red Fang territory) is **not walkable from that end yet** — a later book may open the path. The connection is recorded in both locations' `canon_ref.note` only.
- Erin's iPhone concert (2.17) is a stage, but it has no fight, so a new **stage `kind: "scene"`** was built (below) rather than faked with harmless "monsters".
- Interlude – Mating Rituals Pt. 1 is **floating flavor canon**: its 6 events are not `depends_on` anything and nothing depends on them; the Toren seen there does not clear the main-timeline `toren.missing` flag (`b2.toren_flees_armor_guardian_meets_rags` does that instead).
- New NPCs `valceif_godfrey` and `niers_astoragon` (tier 1, Erin's anonymous chess rival, only known through the enchanted board) added now since both recur; `culyss` (Interlude, one-off) added too since he already has a name and two scenes. `hawk`, `persua` and `fals` are reused from book1.

**Stage `kind: "scene"` (M8.2).** Extends the M6.5 stage (ADR 0011): `{"area", "hours", "kind": "scene", "npcs": [{"npc", "pos"}], "line"?, "when_flags"?, "unless_flags"?, "note"?}` — no `foes`, no `waves`. `Stage.run` moves each npc onto the map (`Stage.place_npc`, factored out of the wave-ally code) instead of spawning a hostile pack. New `Stage.is_scene_live` / `Stage.scene_npcs_here`: while a scene is live (staged today, player still in its area and hours), `NpcSim.advance_to` holds those NPCs in place instead of following their normal schedule goal — without this an NPC placed by the scene would walk off again on the very next tick. `CanonDb`/`CombatDb`/`tools/validate_data.py` all check the new shape (a scene npc still needs an `npc_behaviour` entry to be moved, same as a fight's allies). Used once so far: `b2.erin_iphone_concert_night` on `inn_hill`, with Ceria, Pisces, Selys, Relc and Krshia (Erin is already home on her schedule; Ryoka has no `npc_behaviour` entry yet, so she keeps the `runner` role but is not placed).

**Timeline (guesses, anchored on two stated gaps: "a day since I pissed off Teriarch" opens 2.15, and 2.09 ends morning day 43).** Day 43: Toren's firewood errand blows up the inn; the Antinium rebuild it in a day near Liscor; Toren wanders, resists the necromancer's call, falls into the ruins that night. Rags' tribe hunts a Rock Crab, is found and spared by Relc, warned by Ceria, and builds crossbows. Day 44: Erin's hamburger stand, Hawk, an unidentified hungry girl; Ceria's nightmare and Olesm's crypt-guardian lore reveal that night; Rags leads her tribe toward death beyond death; Ryoka tells Garia the Horns died and gets a stench potion from Octavia. Day 45: Ryoka crosses the High Passes and confronts Teriarch for a homing stone; Toren bursts out at death beyond death, seen by Rags. Day 46: Ryoka's second arc (Celum) — a bandit ambush on Garia, meeting Valceif, losing a race to him, finding the wrecked guardian's armor, arriving at the inn, a cursed dreamcatcher restoring her memory that Teriarch is a dragon; the iPhone concert that night. Day 47: the mystery chess opponent is revealed as Niers Astoragon; Hawk briefs Ryoka on the Blood Fields and Az'kerash.

**Tests.** `sim_canon_book2`: `LAST_DAY` 44 → 47; still drift 0 through the whole batch. `unit_stage` (+4): a scene stage moves its npcs with no fight and runs once; `CanonDb`/`CombatDb` scene-shape errors. `sim_winter`'s stage/wall-overlap check now covers scene npcs too, not just fight foes. `tools/tests/test_validate_data.py` (+4) for the Python-side scene schema.

**Known limits.** Exact days are guesses except the two anchors above. The hungry girl in 2.13 gets no name or hook yet (identity unconfirmed in the text). Niers Astoragon's location is a placeholder (distant Baleros has no location entry). The concert's npc positions on `inn_hill` are a temporary guess at a "yard" spot, clear of Toren's snow wall overlay.

## M8.4 Canon 2.27G–2.38 (days 56–67)

Built by a delegated agent (chapters read and drafted outside the main session, per the context-discipline rules in `CLAUDE.md`), then independently re-verified: validator re-run, full GUT and Python suites re-run, and the diff spot-checked against the M8.2/M8.3 schema before trusting the batch summary.

**Threads.** Rags absorbs the Gold Stone Tribe, survives Garen's week of testing-by-raid, then wins the legendary Red Fang Tribe in a valley duel; Garen submits and warns that a Goblin Lord is rising in the south. Ryoka is nursed by the Stone Spears Gnolls after a week of Frost Faerie torment, earns their truce with Earth stories, stumbles into the Zel Shivertail/Wall Lord Ilvriss war, escapes captivity into Az'kerash's hidden castle to deliver Teriarch's letter, then returns to find the cub Mrsha missing - she rescues her from a crevasse only for the Goblin Lord's army to overrun the camp (Chieftain Urksh killed), gaining her first class, [Barefoot Runner]. Erin invents pizza, discovers faerie-gold coins, calms Halrac's grief, and tells Bible stories that earn Pawn Liscor's first Antinium [Acolyte] class; the Horns of Hammerad reform and fight off a goblin raid; Magnolia hosts and briefs Erin on the coming war.

**New data.** 11 NPCs (Garen, Urksh, Mrsha, Zel Shivertail, Ilvriss, Periss, Az'kerash, Reynold, Imani, Joseph, Rose), 4 locations (`red_fang_territory`, `stone_spears_camp`, `azkerash_castle`, `magnolia_estate`). No new enemies - none of this batch's fights land on a player-reachable map.

**Stage + hook.** One `kind: "scene"` stage, `b2.pawns_faith_crisis_earns_the_acolyte_class` (2.31, `inn_interior`, Pawn placed on-map), with a `change` hook `player_heard_erins_stories` (`talk_with_guest`/`comfort_someone`). Halrac has no `npc_behaviour` entry yet, so he keeps a narrative role but is not placed.

**Timeline.** Days 56-67. The Erin/Liscor thread is the day-by-day backbone; Rags' and Ryoka's remote arcs use placeholder days in the same spirit as M8.3's 2.22K/2.24T, noted in each event's `canon_ref.note` rather than forced into tight cross-thread sync.

**Two judgment calls (not yet put to the user).**
- Periss's death fighting Az'kerash's undead is implied (a shattered ring, a distant scream) but never shown on-page - left alive with a new flag `periss.presumed_dead` rather than asserted dead, per rule 9 (don't invent canon facts).
- Ksmvr's second demotion (2.32H) uses a new flag `ksmvr.relieved_of_duty` rather than reusing `ksmvr.deposed`, since `sim_canon_book2` already asserts `ksmvr.deposed` is false through `LAST_DAY`. Two distinct demotions now have two distinct flags; worth reconsidering as a single acting-officer field if a third demotion ever happens.

**Tests.** `sim_canon_book2`: `LAST_DAY` 55 → 67, drift 0 through the whole batch. `sim_player_hooks` hook count 11 → 12. Validator 0 errors (`--all`); GUT 533/533; Python 51/51.


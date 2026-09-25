# ADR 0014 — M8 Book 2 and Celum

Date: 2026-09-25 · Status: plan accepted (user, 2026-09-25); M8.1 accepted, events reviewed by the user 2026-09-25 (timeline, Invrisil, Gazi balance as proposed).

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

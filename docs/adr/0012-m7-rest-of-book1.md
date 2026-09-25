# ADR 0012 — M7 Rest of Book 1

Date: 2026-09-24 · Status: accepted for the split and the M7.1 raid (user, 2026-09-24); M7.1 events are `candidate` until the user reviews them.

## User choices (plan)
- Four canon batches of about 10 chapters, one branch + PR each: M7.1 1.26R–1.34, M7.2 1.35R–1.44R, M7.3 1.45–1.54, M7.4 1.55R–1.63.
- New engine systems only when a batch needs them. A new schema or system is asked for first (CLAUDE.md rule 11).
- The Goblin raid on day 21: a player who fights and wins gets a `change` hook. Klbkch still dies (not a mutate where he lives).

## M7.1 Canon 1.26R–1.34 (days 19–23)
Data only. No schema change, no save version change.

**Timeline.** 1.26R–1.27R are day 15: Ryoka's Lich run and the crushed leg are the same day, a week before 1.32R (the Horns' words; user choice over Ryoka's 'three days'). 1.28A is day 19. 1.29 is day 20 (Hive) and day 21 (the raid). 1.30–1.31 are day 21. 1.32R–1.33R are day 22 (guess). Eterell steps down on day 23 (Magnolia says 'tomorrow'). 1.34 is day 23–24 (guess; the red-gold message to Pisces is likely Ceria's from 1.33R).

**19 events**, all `candidate`. There are 11 new NPCs: the Horns (`calruz`, `ceria_springwalker`, `gerial`, `sostrom`), Persua's group (`persua`, `claudeil`, `toriska`), `jeiss`, `stenei`, `eterell` and `designated_worker`. There are 8 new locations: `ruins_of_albez`, `wales`, `wales_runners_guild`, `celum_runners_guild`, `magnolia_celum_mansion`, `celum_rats_tail_inn`, `selys_home` and `raiders_grave`. `pawn` is now named. `beilmark` is a Gnoll: 1.28A calls her Jeiss's Gnoll partner. `klbkch` gets the tag `prognugator`. Changed entries go back to `candidate`.

**The raid — `b1.klbkch_dies_defending_erin` (1.29).** The id `b1.goblin_raid_on_inn` was already taken (1.02).
- **Roles.** `rescuer` prefers Klbkch, with the fallback tag `senior_guard`. If Klbkch is already dead, another senior guard comes and dies in his place (the effect is remapped). `worker` prefers `designated_worker`.
- **Effects.** Kills Klbkch and the Designated Worker. Sets `klbkch.died_saving_erin`, which gates the day-21 events that follow.
- **Stage.** Area `inn_interior`, 12–14. Six foes stand at the door: one `goblin_raid_leader` and five `goblin_grunt`. Erin is an ally. Canon has forty Goblins; six fit the map (design).
- **Hook.** `player_fought_raid` matches a won fight whose most dangerous foe is `goblin_raid_leader` on day 21. It is a `change`: flag `wandering_inn.earther_fought_raid`, clears `erin.stabbed_by_goblins`, Erin → player +3, and a news line of its own. Klbkch still dies, so every later event runs.

**Enemy `goblin_raid_leader`** (guess). A head taller than a Goblin, not yet a Hob, with a short sword.
- Stats: hp 14, armor 0, accuracy 4, evasion 3, damage 2–4, danger 0.8, `flee_below` 0.2, no ranged attack.
- It comes only from the stage, never from a spawn. Its danger is above a grunt's, so the fight's records name it.

**Spawn `crab_hill_unpatrolled`** (guess). A Rock Crab by the inn hill's rocks, 06–20, chance 0.3, gated by `when_flags: liscor_watch.no_inn_patrols`. Zevara stops the patrols on day 21 (1.30), and Pisces and Selys warn that monsters will come closer (1.34). The text does not show which monsters yet; the Rock Crab stands in. It is not a Goblin, because 1.34 says only Rags's band came back.

**Behaviour.** `pawn` visits the inn from 18–22 once `pawn.named` is set. `relc` stops visiting the inn once `relc.blames_erin` is set.

**Review answers (user, 2026-09-24).**
- Runners' Guilds: most cities and towns have their own Runners', Mages', Merchants' and Adventurers' Guilds. Remendia (1.20R), Wales (1.26R) and Celum (1.33R) are three guilds, not a conflict.
- 1.32R: use the Horns' 'a week ago'. The Lich run and the crushed leg move to day 15; 1.32R stays on day 22.
- The raiders' grave is several hundred feet from the inn (1.30), not a mile (1.31): location `raiders_grave`.

**Tests.**
- `sim_canon_book1`: `LAST_DAY` is 23. A new test checks that on day 21 Klbkch dies, the Watch leaves the inn and Pawn is named. Another test kills Klbkch early; then a senior guard dies in the raid, and the Hive's chess day is cancelled.
- `sim_goblin_raid` (new): stage data. A win next to Erin changes the event, Klbkch still dies, and the rest of day 21 is canon. A knock-out leaves the canon. There is no raid after 14:00. The new spawn opens only after the patrols stop.
- `sim_m6_done` marks the raid as staged (it tests M6). Counts are updated in `sim_player_hooks`, `unit_combat_db` and `sim_canon_fights`.

**Known limits.**
- The stage is only inside the inn, so a player out on the hill at noon misses it.
- Rags's band does not join the fight on the map.
- The raiders' name labels overlap at the door.

## M7.2 Canon 1.35R–1.44R (days 24–33)
Status: accepted; events reviewed by the user 2026-09-24 (timeline, Relc and the brawl hook as proposed). No schema change, no save version change.

**Timeline (all guesses).** Pisces answers Ceria on day 23 or 24 (1.34); the Horns leave Celum that night, Ryoka has a fever for two days, and they reach the inn on day 25. Day 25 also holds 1.36–1.38 on Erin's side: the Shield Spider nest, Gazi, the Guild, Lism, the Titan's puzzle and Relc at the inn. 1.41 is days 26 (ruins) and 27 (bounty paid, inn ransacked, acid for Rags, the skeleton). 1.42 is day 28. Ryoka is back in Celum on day 27, is shut out for four days, and runs the High Passes on day 30 (1.39R, 1.40R, 1.43R). 1.44R is day 33, some days after the geas.

**24 events**, all `candidate`, in 10 new chapter files.
- New NPCs: `gazi_pathseeker`, `teriarch`, `ksmvr`, `toren` (the skeleton; named Toren in 1.46, so the id already uses it), `princess_thief` (never named in Book 1) and `theofore`.
- New locations: `shield_spider_nest`, `krakk_forest`, `esthelm` and `teriarch_cave`.
- The 1.44R Celum bully (Arnel), the traders Goeln and Cervial, Pestrom and Ylss are not NPCs: they appear once. Arnel is an anonymous `adventurer` role.
- **Teriarch (user, 2026-09-24).** It is not confirmed that Teriarch is the Dragon of 1.00. So `teriarch` is his own NPC with his own cave `teriarch_cave`; `cave_dragon` and `dragon_backup_lair` are unchanged. Link them only when the text says so.
- The new ruins near Liscor in 1.41 are the existing `liscor_dungeon` (ten miles out), not `ruins_of_albez` (1.26R, far north).
- `relc.ignores_erin` is cleared on day 25, but `relc.blames_erin` stays set. So Relc does not visit the inn every evening yet: canon does not show it, and he would win the day-28 brawl alone.

**Stage and hook — `b1.adventurers_attack_goblins_at_inn` (1.42).**
- **Stage.** Area `inn_interior`, 19–21, day 28. Three foes at the door: one `adventurer_axeman` and two `adventurer_brawler`. Allies: Erin, Pawn and the skeleton. A wave at 0 seconds brings Rags and two Goblin helpers (they were eating inside). Gazi is not on the map: in canon she comes back after the fight.
- **Enemies** (guess, stage only). Human adventurers with `flee_below` 0.5 / 0.4, because in canon they run and do not die. The axeman's danger (0.9) is above the brawler's (0.7), so the fight's records name him.
- **Hook** `player_fought_adventurers`: a won fight against either type on day 28–29 is a `change`. It sets `wandering_inn.earther_defended_goblins`, Rags → player +2, Erin → player +1, Pawn → player +1, and has its own news line.
- **Behaviour.** `toren` works in the inn once `wandering_inn.has_skeleton` is set (night 27), with a small `combat` block. Before that it is off the map.

**Engine fix: fleeing indoors.** A fleeing monster stepped away from the player and left only at the map edge. The inn's edge is all wall, so fleeing foes got stuck in a corner and the fight never ended (this also hit the day-21 raid). Now, in an area whose walkable edge tiles are all exits, a fleeing monster walks to the nearest exit and is gone there. Outdoor maps keep the old behaviour, so the seeded sims do not change.

**Tests.**
- `sim_canon_book1`: `LAST_DAY` is 33, drift 0. New tests: days 25–28 (the leg is mended, Gazi, Relc, the skeleton, the brawl), Ryoka's geas and escape, and 'kill Pisces early' (Ryoka's whole chain and the skeleton are cancelled; Erin's days go on).
- `sim_inn_brawl` (new): stage data, the skeleton's schedule, a win changes the event, a knock-out keeps the canon, no brawl on day 27, and the adventurers leave by the door.
- `unit_monster_sim`: a fleeing Goblin in the inn walks out of the door.
- Counts updated in `unit_combat_db` (7 enemies) and `sim_player_hooks` (6 hooks).

**Known limits.**
- A player can still chase and kill a fleeing adventurer. The hook does not check `killed`.
- NPC name labels still overlap when NPCs stand close (only monster labels are de-overlapped, M7.B).
- The market thief and Ksmvr have no map schedule yet.
- The High Passes run, the spider nest and the Celum brawl are not playable: they are off the player's map.

## M7.3 Canon 1.45–1.54 (days 34–37)
Status: accepted; events reviewed by the user 2026-09-24 (timeline, the Goblin battle stage, the Horns schedules and the `likely` links as proposed). No schema change, no save version change.

**Timeline (all guesses).** Ryoka escapes Celum on night 33 and reaches Esthelm at dawn on day 34 (1.45, 1.47R, 1.48R). Erin's side of 1.45–1.46 is the same day. The Horns leave Esthelm at dusk on day 34 and reach the inn on night 35 (a day's travel), so 1.49 is day 35. The Market Street fire is 'last night' in 1.49: night 34. 1.50–1.51 are day 36 and that night; 1.53–1.54 are day 37. Ryoka's first day out (1.52R) is day 35. Conflict: on day 37 Gerial says Ryoka was in Esthelm 'two days ago'; by this timeline it was three.

**24 events**, all `candidate`, in 10 new chapter files.
- New NPCs: `yvlon_byres`, `cervial_dermondy` (the 1.37 [Ranger], now back as a raid captain) and `tkrn` (Krshia's nephew in the Watch).
- New locations: `esthelm_adventurers_guild` and `krshia_home`.
- Updated NPCs (back to `candidate`): `toren` is named Toren (Level 3); `relc` is Relc Grasstongue, [Spearmaster] 33 and [Guardsman] 12 (Ksmvr's figures); `sostrom` is Human; `gerial` is a Level 17 [Warrior]; `ceria_springwalker` is also a [Cryomancer].
- Not NPCs: Gregor, Menes, Rois (captains), Marian and Hunt (Horns), Charlez, the Gnoll Runners Lv and Tshana, the feathered chieftain.
- **Conflicts in the Book (flagged in data):** Relc was a sergeant of the 1st Wing (1.51) or the 4th Wing (1.10). Sostrom is bald (1.54) or has a wisp of black hair (1.32R).
- **Likely links (not confirmed, per the 'confirmed links only' rule):** the market thief who burns Market Street is the [Princess]; the tiny Goblin leader in 1.52R is Rags; the potion Ryoka loses is Teriarch's speed potion, and it is the orange-pink potion Rags carries on day 37. Each is marked `likely` in its canon_ref.

**Stage and hook — `b1.rags_kills_the_feathered_chieftain` (1.52R).**
- **Stage.** Area `floodplains_south`, 08–11, day 35. Five foes in the valley: one `goblin_feathered_chieftain` and four `goblin_grunt`. Wave at 0 s: Rags and three Goblin helpers (her line). Wave at 60 s: three more helpers (her flank attack).
- **Enemy `goblin_feathered_chieftain`** (guess, stage only): hp 18, armor 1, accuracy 4, evasion 2, damage 2–5, danger 0.95, `flee_below` 0 (he dies in canon). His danger is above a grunt's and a Rock Crab's, so the fight's records name him.
- **Hook** `player_fought_beside_rags`: a won fight against him on day 35–36 is a `change`. It sets `rags.earther_fought_beside_her`, Rags → player +2, and has its own news line. Rags still kills him, and her band still chases Ryoka.
- Why this fight: it is the one fight in 1.45–1.54 the player can join on the map without breaking canon. The Horns attacking Rags's Goblins (1.49) and Ksmvr's visit (1.49, 1.51) end with no one hurt or with named NPCs only.

**Behaviour.** The Horns (`calruz`, `ceria_springwalker`, `gerial`, `sostrom`) eat in the inn 06–09 and 18–23 once `horns_of_hammerad.stay_at_inn` is set (night 35); otherwise they are off the map in Liscor. They sleep upstairs, which is not on the map. `pawn` does not visit while `pawn.taken_for_judgment` is set (night 35 to night 36).

**Tests.**
- `sim_canon_book1`: `LAST_DAY` is 37, drift 0. New tests: days 34–37 (days of 16 events, flags), and 'kill Ksmvr early' (Pawn is never taken or maimed; the Horns, Olesm, Toren and the Goblin battle go on). The Teriarch test now stops at day 33 (1.45 clears `ryoka.bound_for_esthelm`).
- `sim_goblin_battle` (new): stage data, a win beside Rags changes the event, a knock-out keeps the canon, no battle on day 34, the Horns lodge from night 35, Pawn stays away while judged.
- Counts updated in `unit_combat_db` (8 enemies) and `sim_player_hooks` (7 hooks).

**Known limits.**
- The Goblin battle is only in the `floodplains_south` map, in the morning. A player elsewhere misses it.
- The Horns have no combat blocks: if a monster gets into the inn, they step away.
- Gazi, Tkrn, Ksmvr and the market thief still have no map schedule.
- Monster and NPC name labels still overlap in a crowd.

## M7.4 Canon 1.55R–1.63 (days 38–41)
Status: proposed; events `candidate` until the user reviews them. Two engine changes (a `revive` effect, user choice 2026-09-24, and a fix for stage allies). No save version change.

**Timeline (all guesses).** Ryoka reaches the Bloodfields three or four days out of Esthelm: day 38 (1.55R). 1.56 is day 38, the day after 1.54; the ruins are 'tomorrow'. 1.57H–1.62 are day 39: the expedition goes in that morning, Skinner wakes in the afternoon, the dead reach Liscor at sunset and the inn at night, and Klbkch is reborn before dawn (the director counts the night as day 39). 1.63 is day 40 (Erin at dawn, Toren, Pisces) and day 41 (Selys's 'even after a day'; Ryoka comes back 'the day after Skinner died', after two days' running). Book 1 canon now ends on day 41.

**21 events**, all `candidate`, in 9 new chapter files.
- New NPCs: `bird` (a Worker who lives), `tekshia` (Guildmistress, Selys's grandmother) and `hawk` (Hawk the Hare, Liscor's Courier).
- Updated (back to `candidate`): `klbkch` (reborn), `toren` (Level 11), `olesm` ([Tactician] 24), `sostrom` ([Elementalist] 16), `selys` (Selys Shivertail; [Warrior], [Hunter]); location `liscor_dungeon` (the Ruins of Liscor).
- Not NPCs: Ysara, Buleth, Rometh, Gregor, Menes, Hunt, Marian, Menolit, Alonna, and the named Workers except Bird (Knight dies in 1.61).
- Deaths: Toriska (1.55R); Gerial, Sostrom and Cervial (1.59H).
- **Missing (user choice, 2026-09-24).** Calruz, Ceria and Olesm stay alive in the data with the flags `calruz.missing`, `ceria.missing` and `olesm.missing`. The Book 1 text never shows them die: Calruz and Ceria are last seen overrun, and Olesm is not seen again. The Horns' lodging flag is cleared, so they leave the map.
- **Conflict in the Book (flagged in data):** 1.62 calls the Guildmistress 'Tekshia Silverfang' once, but Selys is a Shivertail and Silverfang is Krshia's tribe. The NPC is named just 'Tekshia'.
- **Likely links (not confirmed):** Ysara is Yvlon's sister; the Silverfang warriors Gazi fights are the ones Krshia expected (1.51); Gazi killed them (1.63); Rags's fire spell is [Firefly]. Each is marked `likely` in its note.

**Engine: `revive` effect.** Canon events and `change` hooks may list NPCs in `effects.revive`. The director applies it after `kill`. CanonDb and `validate_data.py` check the ids; the validator also rejects an NPC in both lists. There is no save change: WorldState already stores alive per NPC. `b1.klbkch_is_reborn` revives Klbkch, and he walks his old schedule again from day 40. It needs only the Free Queen alive and `klbkch.died_saving_erin`; it does not need the Rite flag from Pawn's event (1.53), so killing Ksmvr does not stop it.

**Engine fix: stage allies on a long step.** A long command (over `rules.npc.jump_seconds`, for example 20 minutes of walking onto the hill) jumps every NPC to its goal. If a stage started in that same command, its wave moved an ally in and the jump sent the ally straight back. Now a stage ally in the player's area, whose goal is in another area, stays while the fight is on. Allies whose goal is in the same area jump as before, so the older seeded sims do not change.

**Two stages and hooks (user choice: inn hill + city gate).** Both need `adventurers.ruins_raid_planned` (`when_flags`).
- **Gate — `b1.skinner_leads_the_dead_into_liscor` (1.60).** Area `liscor_gate`, 18–23, day 39. Eight foes (zombies, skeletons, ghouls). Waves: at once Relc and Zevara; at 60 s a Crypt Lord and four zombies; at 150 s three ghouls; at 180 s Pisces; at 240 s three Soldier helpers. Skinner is not on this map (canon: he meets Relc and leaves). Hook `player_held_the_gate`: a won fight whose top foe is `crypt_lord`, at `liscor_east_gate`, on day 39–40, is a `change`: flag `liscor.earther_held_the_gate`, Zevara → player +2, Relc +1, and its own news line. The location check keeps a Crypt Lord fight on the hill from matching.
- **Inn hill — `b1.rags_kills_skinner` (1.62).** Area `inn_hill`, 20–24, day 39. Eight foes. Waves: at once Erin, Toren, Bird and five Worker helpers; at 60 s a Crypt Lord and five more; at 150 s Skinner and four more; at 240 s three Soldier helpers; at 300 s Rags and five Goblin helpers. Hook `player_fought_skinner`: a won fight against `skinner` on day 39–40 is a `change`: flag `wandering_inn.earther_fought_skinner`, Erin → player +3, Bird +2, Rags +1. Rags still kills Skinner. Klbkch is not on the map: he is reborn that night, after the fight.
- **New enemies** (guesses, stage only, never in a spawn): `zombie`, `skeleton`, `ghoul`, `crypt_lord` (spits bile at range 3), `skinner` (hp 45, armor 3, danger 1.0, fights to the end). Helper types `antinium_worker` and `antinium_soldier` only fight on the player's side.

**Behaviour.** The Horns still eat breakfast at the inn on day 39, but their dinner goal stops once `ruins_expedition.leave_at_dawn` is set (night 38). Pawn's evening visits stop once he is back in the Hive (`pawn.back_in_hive`, 1.53). `bird` is off the map unless a stage brings him. Zevara and Pisces get combat blocks.

**Tests.**
- `sim_canon_book1`: `LAST_DAY` is 41, drift 0. New tests: days 38–41 (days of all 21 events, deaths, the missing, Klbkch alive again) and 'kill Rags early' (Skinner's event and Toren's eye are cancelled; the rest goes on). The Free Queen test now also checks that Klbkch stays dead and the Workers do not guard the inn.
- `sim_skinner_night` (new): stage data, a win at the gate and a win against Skinner change their events, a knock-out keeps the canon, no stage on day 38, the Horns miss dinner, Klbkch patrols again on day 40.
- `unit_director`: revive (with a save), kill and revive in one event, unknown id. `unit_battle`: an ally brought in during a long step stays. Python: the validator's revive checks.
- Counts updated in `unit_combat_db` (15 enemies) and `sim_player_hooks` (9 hooks).

**Known limits.**
- Skinner's fear and the Crypt Lord's poison are not modelled: they deal plain damage.
- A player inside the inn or in the city streets on the night of day 39 sees no fight; the fights are on the hill and at the east gate.
- The fights are small: 19 foes on the hill and 16 at the gate. Canon has about a hundred dead at the inn and thirty thousand at Liscor.
- Ryoka's Bloodfields run and the ruins are off the map.
- Balance (checked on screen): zombies and ghouls were softened after a first look, but Erin, Toren and Bird still rush into the pack and go down within minutes. Tune in play-testing.

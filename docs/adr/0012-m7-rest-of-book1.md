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
Status: events are `candidate` until the user reviews them. No schema change, no save version change.

**Timeline (all guesses).** Pisces answers Ceria on day 23 or 24 (1.34); the Horns leave Celum that night, Ryoka has a fever for two days, and they reach the inn on day 25. Day 25 also holds 1.36–1.38 on Erin's side: the Shield Spider nest, Gazi, the Guild, Lism, the Titan's puzzle and Relc at the inn. 1.41 is days 26 (ruins) and 27 (bounty paid, inn ransacked, acid for Rags, the skeleton). 1.42 is day 28. Ryoka is back in Celum on day 27, is shut out for four days, and runs the High Passes on day 30 (1.39R, 1.40R, 1.43R). 1.44R is day 33, some days after the geas.

**24 events**, all `candidate`, in 10 new chapter files.
- New NPCs: `gazi_pathseeker`, `ksmvr`, `toren` (the skeleton; named Toren in 1.46, so the id already uses it), `princess_thief` (never named in Book 1) and `theofore`.
- New locations: `shield_spider_nest`, `krakk_forest` and `esthelm`.
- The 1.44R Celum bully (Arnel), the traders Goeln and Cervial, Pestrom and Ylss are not NPCs: they appear once. Arnel is an anonymous `adventurer` role.
- **Teriarch (to review).** `cave_dragon` is renamed Teriarch, and `dragon_backup_lair` is his 1.40R cave. The text never says the 1.00 Dragon and Teriarch are the same Dragon (confidence `likely`). Both entries go back to `candidate`.
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

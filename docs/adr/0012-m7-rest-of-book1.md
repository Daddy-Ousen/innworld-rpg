# ADR 0012 — M7 Rest of Book 1

Date: 2026-09-24 · Status: accepted for the split and the M7.1 raid (user, 2026-09-24); M7.1 events are `candidate` until the user reviews them.

## User choices (plan)
- Four canon batches of about 10 chapters, one branch + PR each: M7.1 1.26R–1.34, M7.2 1.35R–1.44R, M7.3 1.45–1.54, M7.4 1.55R–1.63.
- New engine systems only when a batch needs them. A new schema or system is asked for first (CLAUDE.md rule 11).
- The Goblin raid on day 21: a player who fights and wins gets a `change` hook. Klbkch still dies (not a mutate where he lives).

## M7.1 Canon 1.26R–1.34 (days 19–23)
Data only. No schema change, no save version change.

**Timeline.** 1.26R–1.27R and 1.28A are day 19. Ryoka's Lich run and the crushed leg are the same day, three days before 1.32R. 1.29 is day 20 (Hive) and day 21 (the raid). 1.30–1.31 are day 21. 1.32R–1.33R are day 22 (guess). Eterell steps down on day 23 (Magnolia says 'tomorrow'). 1.34 is day 23–24 (guess; the red-gold message to Pisces is likely Ceria's from 1.33R).

**19 events**, all `candidate`. There are 11 new NPCs: the Horns (`calruz`, `ceria_springwalker`, `gerial`, `sostrom`), Persua's group (`persua`, `claudeil`, `toriska`), `jeiss`, `stenei`, `eterell` and `designated_worker`. There are 7 new locations: `ruins_of_albez`, `wales`, `wales_runners_guild`, `celum_runners_guild`, `magnolia_celum_mansion`, `celum_rats_tail_inn` and `selys_home`. `pawn` is now named. `beilmark` is a Gnoll: 1.28A calls her Jeiss's Gnoll partner. `klbkch` gets the tag `prognugator`. Changed entries go back to `candidate`.

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

**Conflicts flagged for review.**
- Ryoka's Runners' Guild is in Remendia in 1.20R, in Wales in 1.26R, and in Celum in 1.33R. Each event uses the guild its own chapter names; 1.20R is not changed.
- In 1.32R the Horns say Ryoka's delivery was a week ago, but Ryoka says her 'accident' was three days ago, and both happened on the same day.
- The Goblin grave is 'several hundred feet' from the inn in 1.30 and 'a mile' in 1.31. No event needs the location.

**Tests.**
- `sim_canon_book1`: `LAST_DAY` is 23. A new test checks that on day 21 Klbkch dies, the Watch leaves the inn and Pawn is named. Another test kills Klbkch early; then a senior guard dies in the raid, and the Hive's chess day is cancelled.
- `sim_goblin_raid` (new): stage data. A win next to Erin changes the event, Klbkch still dies, and the rest of day 21 is canon. A knock-out leaves the canon. There is no raid after 14:00. The new spawn opens only after the patrols stop.
- `sim_m6_done` marks the raid as staged (it tests M6). Counts are updated in `sim_player_hooks`, `unit_combat_db` and `sim_canon_fights`.

**Known limits.**
- The stage is only inside the inn, so a player out on the hill at noon misses it.
- Rags's band does not join the fight on the map.
- The raiders' name labels overlap at the door.

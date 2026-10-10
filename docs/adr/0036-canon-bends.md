# ADR 0036: Canon bends (M23)

Status: accepted (2026-10-10, M23.1 Book 2; M23.2 Book 3, M23.3 Book 4 and M23.4 Book 5 (2026-10-11) added). Applies to M23.5 – M23.6 (Books 6 – 7) too.

## Problem
Books 2 – 7 had only `cancel` in `on_fail`, and few hooks. One dead NPC cancelled long chains that did not need
that NPC, because many `depends_on` links were only story order. In Book 2, Erin's death cancelled 140 of 207
events, and Yvlon's death gave drift 107 (the Horns of Hammerad chain into Books 3 – 4).
The M23.0 report (`docs/divergence/report.md`) and the user's picks (`docs/divergence/picks.md`) name the key NPCs
and events per book.

## Decision
1. **`depends_on` only for a real cause.** If the later event makes sense without the earlier one, the link goes.
   Example: Rags builds crossbows because the Broken Spear tribe rejects her, not because Ceria warned her.
   Side effect: the run order inside one day can change a little (the statuses do not). `sim_canon_book<N>` must
   stay at drift 0.
2. **Substitute only with a plain local stand-in.** A role gets `fallback_tags` and `on_fail` starts with
   `substitute` only when someone nearby would clearly do the same thing. The tags are picked so the best match is
   that NPC (the director scores all NPCs in the world, ties go to the lowest id). The kill sim checks the pick.
3. **Mutate with a flag hand-off.** A mutated event "never happened", so `_propagate` cancels everything that
   `depends_on` it. When an alt event should keep a chain alive, the next events do not `depends_on` the canon event.
   They wait on a flag that both the canon event and its alt set, with `on_fail: ["delay", "cancel"]` and
   `delay_limit: 3`.
4. **Engine (director): an alt runs on its own day.** During propagation, a dependent with a `mutate:` step whose
   window has not opened is left pending. It fails and mutates when it is due. Before, the alt ran on the day the
   chain broke (Ryoka dies, her day-56 thread breaks, the day-65 Goblin Lord alt ran on day 56).
   `unit_director.test_cancel_propagates_down_the_chain` changed for this; a new test covers an open window.
   No save change.
   **M23.2:** a dependent also waits while a dependency is still pending, even past its own last day
   (`Director._wait_until`). Before, a flag hand-off that was delayed early in the day (ids sort before the event
   that mutates and sets the flag) made its same-day dependents cancel at once. It cancels with the dependency if
   that one cancels. Two new `unit_director` tests. Canon runs do not change (they never delay).
5. **Alt events are not in the book.** `canon_ref.confidence` is `guess`, the note starts "Not in the book (M23.x,
   divergence only)". An alt kills no one. Alts are `alt_only`: they never run on their own.
6. **Hooks: one per day of on-map canon.** A day has on-map canon when a book event on it is at a location that has
   a game map. Each such day gets at least one player hook (mostly `change`: a flag plus relationships).
7. **A kill sim per book** (`sim_kill_book<N>`): each key NPC dies on the book's first day. The sim checks a ceiling
   for lost book events and total drift (a regression guard), the threads that must go on, and the bends
   (substitutes and alts) by name. It also checks the hook-per-day rule.

## Book 2 (M23.1)
- Links cut or moved: Pisces's call log, Rags's crossbows / Jawbreaker ambush / Esthelm, Val's chessboard, Ryoka's
  run north / reunion / dreamcatcher / morning run, the iPhone night, the faerie banquet, Ryoka's return with Mrsha
  and the 2.40 scenes after it, Erin's protection of Lyonette, the inn battle, Niers's alarm map.
- Substitutes: Klbkch leads the Ruins rescue (2.02) if Erin cannot; Relc carries Selys's warning (2.23) if Pisces
  cannot.
- Mutates: `ceria_reforms_the_horns_of_hammerad` → `ceria_reforms_the_horns_short_handed` (Yvlon or Pisces dead;
  Ceria founds the Horns, so her death still ends them); `goblin_lords_army_destroys_stone_spears_camp` →
  `goblin_lord_overruns_the_stone_spears` (the Ryoka / Mrsha thread or Urksh gone); `toren_drags_erin_north_and_leaves_her`
  → `erin_winters_in_liscor` (no Toren).
- Flag hand-off + delay: `ksmvr_joins_the_horns_of_hammerad` (flag `horns_of_hammerad.reformed`; Erin no longer
  required), `drake_assembly_silences_zel` and `magnolia_plans_to_bring_zel_north` (Goblin Lord flags).
- 19 new `change` hooks: every one of the 22 on-map days (41 – 71) has a hook.

| Dies on day 41 | Book 2 lost before → after | Drift before → after |
|---|---|---|
| Erin | 140 → 109 | 261.5 → 161.25 |
| Ryoka | 76 → 64 | 127 → 103.75 |
| Toren | 77 → 57 | 135 → 117 |
| Rags | 42 → 27 | 40.5 → 26 |
| Ceria | 42 → 25 | 136 → 122 |
| Pisces | 30 → 13 | 124.5 → 11.25 |
| Yvlon | 7 → 4 | 107.5 → 4 |

"Lost" counts cancelled and mutated canon events. Most of what is left is real: the dead NPC's own scenes, and
stories that need them (no Erin, no Lyonette at the inn; no Toren, no inn explosion and no trip to Celum).

## Book 3 (M23.2)
- Links cut: Ryoka's Celum thread from Erin's crepes, Erin's Celum days from Octavia's soups, the Ivolethe and Magnolia
  scenes, Lyonette's inn days, the Antinium delegation and Zel's room, the plays and the farewell from Octavia's goodbye,
  some Laken and Toren story order. Kept on purpose: the last battle of Esthelm still waits for the Florist's scene
  (the battle kills Grunter, whom the Florist splints that day).
- Real cause, not the canon order: the Horns leave Remendia because they escaped Albez (`escaped_albez`), bank their
  loot in Ocre for the same reason (not the volley at Ksmvr), Klbkch praises Pawn's patrol (not the paint), and the
  street battle needs Pawn's Soldiers (`pawn.leads_a_soldier_patrol`, painted or not).
- Delay: `horns_run_out_of_coin_at_albez` (waits up to 3 days for the Albez map). Flag hand-offs with delay: the Creler
  nest, Thresk's vault (new flag `horns_of_hammerad.out_of_the_pit`, set by the bone stair and its alt), the burnt
  vault gold, the Ocre bank, Ryoka's coach ride, Klbkch's sword at Pawn, Pawn's patrol.
- Substitute: Ceria goes with Pisces for the Albez door if Ksmvr cannot (`fallback_tags` adventurer + wistram).
- Mutates (9 alt events): Pisces's dig → `horns_dig_into_albez_by_hand`; the bone stair →
  `horns_climb_out_of_the_pit_by_hand`; Yvlon's strike → `horns_outlast_the_flame_guardian`; Ressa in Ocre →
  `reynold_fetches_ryoka_from_celum`; Pawn's resolve → `pawn_resolves_alone_to_tell_klbkch`; the Soldiers at the inn →
  `pawn_takes_twenty_soldiers_above_ground`; Erin leaving Celum → `erin_and_the_horns_leave_celum_without_the_door`,
  else `erin_goes_home_without_the_horns`, else `the_horns_leave_celum_without_erin` (three mutate steps in order).
  The leaving alts set `erin.on_wagon_south` / `horns_of_hammerad.bound_for_liscor` for Book 4 to hand off on (M23.3).
- Ceria still leads the Horns: her death ends the Albez trip (same rule as Book 2).
- Book 2: the Goblin raid (`b2.horns_of_hammerad_fight_off_the_goblin_raid`) no longer needs Ksmvr (waits on
  `horns_of_hammerad.reformed`). A Ksmvr death on day 41 now loses 1 Book 3 event, was 40.
- 13 new `change` hooks: every one of the 23 on-map days (46 – 91, Laken's Riverfarm days too) has a hook.

| Dies on day 72 | Book 3 lost before → after | Drift before → after |
|---|---|---|
| Erin | 52 → 27 | 113 → 73.25 |
| Octavia | 49 → 4 | 110 → 5 |
| Ceria | 40 → 30 | 101.5 → 91.25 |
| Pisces | 39 → 9 | 100.5 → 55.25 |
| Lyonette | 34 → 19 | 81 → 66 |
| Yvlon | 33 → 3 | 94.5 → 2.5 |
| Ksmvr | 31 → 1 | 92.5 → 1.25 |

What is left is real: each NPC's own scenes, Pisces's confession to Erin, and the Horns' trip (Ceria). Most of the
drift left is Book 4 (Erin's trip home waits on `b3.erin_leaves_celum_on_the_wagon`; M23.3 can hand off on the
leaving flags).

## Book 4 (M23.3)
No engine change. Data and a kill sim only.
- Links cut: the trip home is one chain no more. The door move, the old man on the road, the Wistram story, the
  soup, Esthelm and the homecoming each wait on the trip flags (`erin.on_wagon_south`, and
  `horns_of_hammerad.left_celum` for the Horns' scenes; `horns_of_hammerad.bound_for_liscor` is stale-true since
  Book 1). The homecoming party, the door running dry, level 30 and the relief pitch wait on `erin.home_at_the_inn`
  / `erin.level_30`, not on each other. Ryoka's library no longer waits for the slime at Esthelm. Also cut: the
  Rags story order (Ulvama, the raid, Noears), Hedault without Reynold, Laken's court, Zel and Ilvriss at the gate.
- Real cause, not the canon order: Pawn is at Esthelm because the Antinium went (`antinium.expedition_to_esthelm`);
  the carol, the slime and the ride home wait for the convoy; the actors' visit to Celum needs the door at the inn;
  Brunkr's scene needs Mrsha's flight from the inn; Laken's request waits for Ryoka's replies (she meant to go home).
  `ryoka.heading_home_to_liscor` moved from Erin's chat to Ryoka's replies, so Erin's death does not change it.
- Optional now: Pisces at the soup, the door and the pitch; Ceria at the pitch and at "where is Erin from"; Klbkch
  as Santa's partner; Reynold at Hedault's; Ryoka at Laken's "Enough".
- Mutates (5 alt events): Klbkch's rescue in the Hive → `pawn_leads_mrsha_out_of_the_hive`; the old man's snowstorm
  → `the_wagon_hides_from_the_goblin_army`, else `the_horns_hide_from_the_goblin_army` (Erin dead); the homecoming
  → `erin_comes_home_without_the_door` (no Albez door); the Celum wagons → `liscor_sends_wagons_to_esthelm`
  (no door at Octavia's).
- Flag hand-offs with delay: Brunkr's scene (`mrsha.met_the_free_queen`), the relief convoy
  (`liscor.sends_aid_to_esthelm`).
- 4 new `change` hooks: Esthelm on day 90 and 92, the solstice kitchen and Ryoka at Riverfarm on day 96. All 9
  on-map days (85, 89 – 96) have a hook.

| Dies on day 85 | Book 4 lost before → after | Drift before → after |
|---|---|---|
| Erin | 85 → 55 | 88.25 → 58.5 |
| Zel | 83 → 14 | 78.5 → 13 |
| Ceria | 85 → 15 | 89.25 → 22 |
| Teriarch | 83 → 2 | 78 → 1.25 |
| Klbkch | 77 → 6 | 73 → 5 |
| Lyonette | 79 → 5 | 74.5 → 5 |
| Pisces | 85 → 11 | 84.75 → 14.25 |

What is left is real: each NPC's own scenes; with no Zel, Mrsha never flees the inn, so no rift, no Brunkr bite and
no honey dressing; with no door (Ceria or Pisces dead before day 87), no Celum trips or Octavia research. Erin's
death still loses the homecoming, the relief and Christmas (her ideas), but not the Ryoka, Laken, Mrsha or Rags
threads.

## Book 5 (M23.4)
No engine change. Data and a kill sim only. Book 5 has few story-order links (lost was close to pinned), so the
work is mostly alt events and hand-off flags. Most chains here hang on flags, not `depends_on`; the M23.0 report
undercounts them (it counts `depends_on` only), so the numbers below come from a director run.
- Hand-off flags (new): `earthers.joined_the_last_light` (Ken's walk to the Last Light and its alt; the Red Cross
  waits on it, Ken optional there), `bird.to_guard_the_inn` (Bird's watch no longer `depends_on` the contract),
  `azkerash.servants_in_liscor`, `ryoka.seized_by_the_necromancers_servants` (the feast standoff and the Word of
  Death wait on it, not on `venitra.seized_ryoka_in_liscor`). The accord waits on `ryoka.revived_by_teriarch`, not
  on Venitra being burned.
- Substitutes: Etretta (Gravetender's Fist veteran) marches the company to the valley if Quallet is dead
  (`fallback_tags` dullahan + soldier + mercenary); Ijvani carries the Word of Death if Venitra is dead
  (`fallback_tags` azkerash_servant + shadow).
- Optional now: Lyonette in Pawn's return, the firing of Safry and Maran, and the Soldiers' bee soup.
- Venitra now required where her presence is the cause: Ivolethe freezes the pass because Venitra chases Ryoka;
  Teriarch burns Venitra in the cave.
- Mutates (9 alt events): Ken's walk → `zt_luan_and_aiko_go_to_the_last_light`; Klbkch's contract (Ryoka cannot pay)
  → `t_erin_pays_the_antinium_to_build_the_inn`; Regrika's arrival → `zzzl_imenet_comes_to_liscor_alone`; the alley
  → `zzzzd_imenet_seizes_ryoka_in_an_alley`; the revival with no Venitra → `zzzzx_teriarch_revives_ryoka_and_flies_her_home`
  (it revives Ryoka too); no accord → `zzzzzj_the_necromancer_calls_his_servants_home` (he still turns to the Goblins);
  Ulrien alive → `zzzzz_the_gnolls_burn_brunkr`; Laken dead → `zzo_durene_drives_off_a_mossbear`,
  `zzp_riverfarm_takes_in_windrest`.
- 4 new `change` hooks: the new staff's first day (103), Mrsha and Bird before the firing (105), boarding up the inn
  (114), Riverfarm's graves (115). All 16 on-map days (100 – 115) have a hook. The Baleros days (77 – 90) are off-map.

| Dies on | Book 5 lost before → after | Drift before → after |
|---|---|---|
| Ryoka (97) | 34 → 31 | 33.5 → 29.5 |
| Erin (97) | 30 → 30 | 31 → 30.5 |
| Laken (97) | 15 → 15 | 14.5 → 13.5 |
| Venitra (97) | 30 → 20 | 29.5 → 18.25 |
| Lyonette (97) | 12 → 8 | 12 → 8 |
| Ken (78) | 7 → 3 | 6.5 → 2.5 |
| Quallet (78) | 6 → 0 | 6 → 0.25 |

What is left is real: Ryoka is the climax of the book (her return, the farm, the Word of Death, the run); Erin's
own scenes, and with no Erin no bone steak, so Regrika is never exposed and Ulrien lives; Laken's Riverfarm is his
Emperor's arc (the riders came with him, so the Goblin fights need him); with no Venitra, no Gnoll murders and no
Ivolethe sacrifice. A Book 5 death never cancels a Book 6 – 7 event (only one Book 6 event reads a Book 5 flag).

## Open
- Drift counts later-book cancels at once, so a Book 2 death shows drift for Books 3 – 7 too.
- Event effects are not remapped for flags: a substitute in Erin's rescue role still sets `erin.fought_in_the_ruins`.
  Later events that read such flags need Erin anyway.

# ADR 0027 — M17 tactical combat (XCOM-style)

Date: 2026-09-30 · Status: approved by the user 2026-09-30; M17.1–M17.7 done

## Context
M17 replaces the M5 fights (ADR 0010) with rounds, action points (AP) and turn order. The user's AP rules are in
ADR 0022. M17.0 fixes the numbers, works three fights out on paper and plans M17.1. No core code changes here.

Today (M5): one player command spends `world.step_seconds` (6 s). `MonsterSim._turns` then gives each monster
turns by its `act_seconds` (4–8 s) in id order (`core/monster_sim.gd:186`); NPCs act after (`core/npc_sim.gd:74`).
Hit = `0.7 + 0.05 × (accuracy − evasion)`, clamp 0.1–0.95; damage = weapon + STR/3 − armor, min 1
(`core/combat.gd:175`, `:274`). There is no Agility stat.

## User answers (2026-09-30)
1. **Agility is the `speed` stat**, shown to the player as "Agility". Speed did almost nothing before (it only cut
   a monster's chase). Skills that raise speed ([Quick Movement], [Quick Prep]) now also raise turn order.
   Monsters get an `agility` number in `enemies.json` (M17.1).
2. **AP rules stay as given.** Every side now hits up to 3 times per round, so fights are about 3x shorter in
   rounds. Fix it with more HP (about x2) in M17.7, not with fewer attacks.
3. **MP:** 1 MP per 10 minutes awake; a full sleep refills all MP.
4. **A fight covers the whole map area.** Anyone who arrives later joins at the start of the next round.

## Decisions
### Numbers (`rules.combat.tactical`, data)
| key | value | meaning |
|---|---|---|
| `ap_base_q` | 24 | 6 AP per turn |
| `move_cost_q` | 1 | one tile = 0.25 AP |
| `move_cap_q` | 4 | at most 1 AP (4 tiles) on moving per turn; Skills raise it (M17.4) |
| `attack_cost_q` | 8 | normal attack = 2 AP |
| `block_cost_q`, `throw_cost_q` | 8 | block and throw = 2 AP |
| `item_cost_q` | 4 | pick up / drop / use an item = 1 AP |
| `ap_total_levels` | 10, 25, 50, 75 | +1 AP at each TOTAL level (secret, silent; ADR 0022) |
| `round_seconds` | 6 | one round = 6 s of world time |
| `initiative` | stat `speed`, ties `rng` | monster default 3; from `act_seconds` 4 s → 5, 6 s → 3, 8 s → 2 |
| `monster.move_cap_q` | 4 | monsters move like the player |
| `mp` | regen 10 min, sleep refill 1.0 | used from M17.5 |
| `hp_scale` | 1.0 | set in M17.7 (paper fights suggest 2.0) |

- **Quarter points:** AP is stored as integers (6 AP = 24 q), so costs never round and replays stay exact.
- AP does **not** carry over to the next round. Unspent move cap is lost too.
- A move is one side step (n, s, e, w), as the player and `Pathfind` walk today; melee reach is side by side.
  (M17.1 fix: the first draft said king steps, but the game has no diagonal moves.)

### Encounter life
- **Start:** a monster turns hostile on the player's map, a brawl starts (`Brawl.attack`), or a fight stage runs.
- **Who is in it:** every hostile monster, helper, fighting NPC (guards, stage allies, friends) and the player on
  that map. Others on the map keep to the side (NpcReact "step away" stays).
- **Join:** a new hostile, a stage wave or an arriving ally joins at the start of the next round and is sorted in.
- **Round:** everyone acts once, in Agility order, highest first; ties by a seeded `gs.rng` roll made when the
  fighter joins (kept in the save, so a load gives the same order).
- **World time:** each round spends 6 s (`round_seconds`) once, after the last fighter. Clock, hunger and
  schedules move; the rest of the world waits during a round.
- **End:** no hostile left on the map (won / they fled), the player leaves the map (fled), or the player falls
  (knocked out). `Combat.end_fight` keeps writing the fight record for the System.

### Old fight parts mapped to AP (done in M17.2)
- Attack 2 AP; moving into a foe is an attack. Throw 2 AP (range and per-tile malus stay).
- Block 2 AP: the guard lasts until your next turn (today: one command).
- Pick up / drop / use an item 1 AP. Improvised weapons and breakage stay as they are.
- Flee: walk through an exit or off the map edge on your turn (move cap still applies).
- Traps spring on the step that enters them, in or out of a fight.
- Brawl NPCs, helpers and stage allies get their own turn by Agility.
- Monsters: 6 AP and move cap 1 AP; the same AI (chase, melee, ranged roll, flee), spent in AP. After M17.1,
  `act_seconds` only sets the default Agility.

## Paper fights (2026-09-30)
A throwaway Monte Carlo (scratchpad, not in the repo; 400 runs each; today's hit and damage formulas; the new AP
rules; foes start 5 tiles away, the raid 1–3 tiles). Win rate / mean rounds / HP left on a win:

| fight | HP x1 | HP x1.5 | HP x2 |
|---|---|---|---|
| Rock Crab, L0 or L5, fists or chair | 0% / 2.5–3.9 | 0% / 3.4–5.5 | 0% / 4.3–7.3 |
| 1 goblin, L0 fists | 100% / 2.8 / 15 | 100% / 3.3 / 23 | 100% / 3.8 / 31 |
| 3 goblins, L0 fists | 30% / 3.7 | 32% / 4.8 | 36% / 5.8 |
| 3 goblins, L5 fists | 82% / 4.7 / 13 | 90% / 6.0 / 18 | 96% / 7.2 / 26 |
| Day-21 raid, L5 chair + Erin + waves | 0% / 3.3 | 0% / 4.5 | 0% / 5.7 |

What it shows:
- Win odds barely move with the HP scale: every side speeds up the same. The scale sets **fight length**. At x1 a
  3-goblin fight is over in under 5 rounds, too short for moving and cover to matter. **x2 gives about 7 rounds.**
  Proposed `hp_scale` = 2.0 in M17.7 (player, NPC and monster HP).
- Same picture as M14.8 (ADR 0021): the Rock Crab beats fists and a chair (armor 4 eats small weapons; use the
  seed core), 3 goblins are a hard win at level 5, and the raid cannot be won alone.
- Who moves first matters more now (3 hits in one go). Goblins (Agility 3) tie with the player; the crab (2) acts
  last.
- The raid model has no map: 8 raiders reach the player at once. In the game the door at (12,14) is a choke; cover
  (M17.6) and the door choke are the player's tools. The raid is checked again in M17.7.

## Risks
- **Long rounds:** the raid has up to 12 foes plus 8 allies on the map. Monster turns must stay fast and the view
  must not wait on each one (M17.3 plays them quickly; tests run headless).
- Every fight test changes (44 test files use `Combat.` or `Commands.attack`). M17.2 ports them with a full suite.
- The M14.8 balance numbers are void until M17.7.

## M17.1 plan (core encounter)
- New `core/encounter.gd` (RefCounted, static): `start`, `join`, `order`, `begin_turn`, `move`, `attack`,
  `end_turn`, `run_monsters_until_player`, `end`.
- `core/combat_state.gd`: `encounter` dict (`round`, `order` [ids], `tie` {id: roll}, `turn` index, `ap_q`,
  `moved_q`, `pending` [ids to join]).
- `core/game_state.gd` SAVE_VERSION 18; `core/save_migrations.gd` `_migrate_17_to_18` adds an empty encounter
  (pattern: `_migrate_13_to_14`).
- `core/monster_sim.gd`: hostile turns spend AP inside an encounter; world-time turns stay for non-fight time.
- `core/commands.gd`: move / attack / end turn go through the encounter while one runs.
- `core/stats.gd`: `agility()` reads `speed`. `data/enemies.json`: optional `agility` (default from `act_seconds`).
- Tests: `unit_encounter.gd` (order, ties, AP, move cap, join at round start, end), `unit_save_migrations` 17→18.
  Full suite in a subagent (core + save change).

## M17.1 Core encounter (2026-09-30)
- New `core/encounter.gd` (`Encounter`). State in `gs.combat.encounter` (save v18, `_migrate_17_to_18` adds `{}`):
  `round`, `order`, `tie` (seeded roll per fighter), `turn`, `ap_q`, `moved_q`. Monsters take their whole turn at
  once, so only the player's AP is stored.
- **Switch:** `rules.combat.tactical.enabled` is `false` in the real data until M17.2 has ported the old fight
  tests. `ToyCombat.tactical(d)` turns it on in tests. With it off nothing changes.
- The order is rebuilt at every round's start from who is on the map, so a late arrival (spawn, stage wave, an
  idle monster that notices the player) joins the next round. No "pending" list is needed.
- A round's end spends `round_seconds` once, gives monsters outside the fight (idle, hidden, going home) one
  ordinary `MonsterSim._turn`, then runs `Commands._after` (NPCs, spawns, stage waves move on). In combat mode
  `MonsterSim.run` drops monster `carry` instead of giving world-time turns.
- Monster turn on AP: flee / give-up checks once (`MonsterSim._hostile_checks`), then at most one ranged roll
  from afar, steps up to the cap, and melee hits while AP lasts. `chase` grows once per round without reaching
  the target. Helpers use `MonsterSim._nearest_hostile`. A fleeing monster takes up to 4 flee steps.
- Player: `Commands.move` (1 q, cap 4 q; walking into a seen monster = attack), `Commands.attack` (8 q),
  `Commands.end_turn`, and `Commands.wait` ends the turn. `block`, `throw`, `take`, `drop` say
  "Not in combat mode yet." (M17.2). Debug console: `end`.
- Optional enemy field `agility` (>= 1, checked by `CombatDb`); none set yet, defaults come from `act_seconds`.
- NPC fighters (brawl, react) still act in world time, once per round's 6 s (until M17.2).

## M17.2 Port the old fight parts (2026-09-30)
User answers (2026-09-30): the turn ends by itself when the AP left pays for nothing; all NPCs share one
default Agility for now (own numbers in M17.7, no schema change); no new UI in M17.2 (M17.3 is the screen).
- **On:** `rules.combat.tactical.enabled` is `true`. Toy dbs (`ToyData`) set it `false`, so the M5 unit tests
  keep testing the world-time parts; `ToyCombat.tactical(d)` turns it on.
- **Time:** `Movement.spend_turn` spends nothing while an encounter runs, so block, throw, take, drop, the bag,
  a brawl blow and a fairy swat take no world time in a fight; a round spends `round_seconds` at its end.
  `Combat.player_attack` lost its M17.1 `spend` flag.
- **AP costs** (`Commands._encounter_act`): block `block_cost_q`, throw `throw_cost_q`, take / drop / hold /
  stow / drop a good `item_cost_q`, attack an NPC and swat a Frost Fairy `attack_cost_q`. A refused or failed
  action costs nothing. A fate warning costs nothing.
- **Auto end:** after a paid action, if the AP left is below one step (or the move cap is used) and below
  `item_cost_q`, the turn ends ("Your turn is over."). `Commands.wait` in a fight returns -1 when there is no
  turn to end (knocked out).
- **Guard:** a raised guard lasts until the player's next turn (`Combat.begin_command` keeps it in a fight;
  the encounter drops it when the player's turn starts).
- **NPCs in the order:** `"npc:<id>"` for an NPC in the player's area who is up, alive, not held by a scene
  stage, and Brawl-hostile or an `NpcReact` fighter with a foe in reach. Agility `initiative.npc_default` (3).
  Their turn: steps (monster move cap) and hits while AP lasts (`NpcReact._hit` / `Brawl._hit_player`).
  `NpcSim` skips them in world time; bystanders still step away at a round's end.
- **Brawl:** a Brawl-hostile NPC starts an encounter too; it is over when no fight is on and no hostile NPC
  is near (`Encounter._over`).
- **Optional `tactical.monster.ap_q`:** monster AP per turn (default `ap_base_q`); 0 = monsters skip their
  turns. Not in `rules.json`; `ToyCombat.freeze` sets 0 so "frozen" tests keep working in combat mode.
- **Tests:** helper `test_support/fight_bot.gd` (`FightBot`): a command refused for AP, the move cap or the
  turn ends the turn and runs once more; `wait_seconds` lets real seconds pass (a fight wait is one round).
  `ToyMaps.walk_to` and the main-scene sims (`sim_m5_done`, `sim_m6_done`) press Space the same way.
  `sim_big_battle` runs in combat mode.
- **Balance seen (for M17.7):** at level 5, 2-3 Goblins won 1-2 of 3 seeds (was 3 of 3); `sim_balance_fights`
  asserts single foes only until M17.7. Two thieves knock out an idle player before the 30 s Santa wave. Allies
  with a turn before the player's first can fell a foe (raid, Creler nest tests count joined foes).

## M17.3 Combat screen (2026-09-30)
User answers (2026-09-30): the camera replays each fighter's turn (not only the player's); a click on a far foe
walks up to it and hits it if the AP left pays; the mouse works in fights only (keys everywhere, as before).
- **Core helpers (read only):** `Movement.can_enter` (the step test without moving; a hidden trap does not
  count, so the screen never gives one away). `Encounter.reach` = breadth-first tiles in `Pathfind.ORDER` within
  min(AP left, move cap left); an exit tile ends a path (a step onto it flees). `Encounter.plan_to(cell)` =
  what a click does: walk, or walk to the free side of a foe with the fewest steps and hit it
  (`"attack"` is "" when the AP left is short). `Combat.player_hit_chance` is the one formula for the screen
  and `_strike` (same numbers, same rolls).
- **Turn log:** `CombatState.turns` lists what each fighter did in the last command, in order: `{"id", "path",
  "strikes": [{"target", "hit", "damage", "ranged"}], "lines", "line_from", "line_to"}`. Damage comes from the
  target's HP change around each blow, so the hit code did not change. It is **not saved** (not in `to_dict`,
  no save version change): it is animation data for one command. `Combat.begin_command` clears it. The
  player's own action is logged first (closed before `Commands._after`), so entries never nest.
- **Screen:** `ui/combat_bar.tscn` (bottom right: round, faces in turn order framed by side, gold for the one
  acting, AP pips by quarters, move left, End turn; monsters show their whole front frame, since a crab has no
  head to crop). `world/combat_overlay.gd` (move range in blue, exits in yellow, the click path as dots, a red
  frame and the hit chance under the foe; "T: n%" when the held item can be thrown at it).
- **Replay:** after a command in which others acted, `WorldView.replay` walks each fighter along its path,
  swings at its targets (flash, number, sounds), with the camera on it (`top_level` while it plays); the HUD
  gets each entry's lines as it starts. Then the redraw runs with `replayed`, so AnimDiff plays only falls and
  gone monsters. Any key or click skips the rest; a command sent during a replay skips it first. Replays are
  off headless (`main.replay_turns`), so the sims that drive the main scene see each end state at once.
- **Tests:** `unit_combat_preview` (15: reach, plan, hit chance, turn log), `unit_combat_screen` (11: the bar,
  the overlay, clicks, End turn, replay skip and end, on the real data at `ruins_entrance`).

## M17.4 Skills in combat (2026-09-30)
User answers (2026-09-30): a Skill has a **cooldown in rounds**; the **[Runner] class** raises the move cap (not
a Skill); action kinds **strike, area, self** (no guard kind); **NPC allies use Skills now** (monsters in M17.7).
Schema changes approved with the plan.
- **Data:** skill effects `ap_mod` `{"value_q"}` (AP per turn for good) and `combat_action` `{"kind", "ap_q",
  "cooldown", ...}`. strike: one foe side by side; `hits`, `hit_bonus`, `damage_mult`, `damage_bonus`;
  `thrown` (throws the held item, its range and damage); `sure_hit`. area: `shape: "around"` (the 8 tiles
  around). self: `heal` (share of max HP), `move_q` (more move cap this turn). A skill with a combat action may
  have no pool (NPC only). Class field `combat.move_ap_mod_q`. NPC `combat.skills`: `[{"id", "after_event"?,
  "until_event"?}]`, so an NPC has a Skill only after (or until) the canon event that gives (or changes) it.
- **Core:** `core/combat_skills.gd` (`why_not`, `targets`, `use`, `tick`, `npc_pick`, `npc_use`);
  `Commands.use_skill`; `Encounter.player_ap` adds `ap_mod`, the move cap comes from `CombatSkills.move_cap_q`;
  `Combat._strike` / `NpcReact._hit` take the mods (the hit roll is made even for a sure hit, so the random
  stream does not change); a new round ticks the cooldowns; a turn does not end by itself while a ready self
  Skill can be paid. Only monsters are Skill targets. Save v19: the encounter gets `cool` ({fighter: {skill:
  rounds}}) and `move_bonus_q`.
- **Cooldown:** `cooldown` N set on use; each round's start takes one off; ready at 0. So cooldown 1 = once a
  round, cooldown 2 = every other round.
- **Canon (Book 1–5 search):** only Skill names that are in the Book. [Power Strike] (1.56; was a +1 STR stat)
  is now a x2 blow; new [Lesser Stamina] (+1 AP; Lyonette 2.42, Geneva 1.01D), [Unerring Throw] (1.14, a sure
  throw), [Quick Strike] (4.22E, a 1 AP blow), [Triple Thrust] (Relc 1.51, rare), [Whirlwind Cleave] (1.58H,
  name only: guess), [Fast Sprint] (1.55R), [Quick Recovery] (Erin 1.63, name only: guess); NPC only
  [Mirage Cut] (Toren 2.24T) and [Minotaur Punch] (Erin 2.26, replaces her [Power Strike]). NPC allies with
  Skills: Erin, Relc, Toren (Klbkch has none in the text). No "greater stamina" name was found, so no +2 AP
  Skill yet. Lore flag, not fixed: the game's [Tavern Brawling] is [Bar Fighting] in the Book (1.14). Most
  other old combat Skill names ([Iron Guard], [Battle Focus], [Hold the Line], [Rally], ...) are not in the
  Book 1–5 text; they stay as passive Skills.
- **Screen:** a Skill row in the combat bar (`ui/skill_bar.gd`, built in code; keys 1-9; key, name, AP, the
  rounds left). A self or area Skill, or a strike with one foe in reach, fires at once; with more foes the
  strike is armed, gold frames mark its foes (`CombatOverlay.marks`), the hover shows its hit chance, and a
  click or a direction key uses it. Esc, a right click or the same key again lets it go.
- **Tests:** `unit_combat_skills` (21, toy arena and real data: AP, Runner cap, every kind, cooldowns,
  refusals, seeds, save v19, bad data, Erin's canon gating, Relc uses [Triple Thrust]), `unit_skill_bar` (5).

## M17.5 Mana and spells (2026-09-30)
User answers (2026-09-30): max MP = **Intellect and total level**; learning = a **teacher's talk option and a spellbook
good**, the [Mage] class offered once you know a spell; **NPC casters (Ceria, Pisces) cast now**; a line stops at a
wall and spells hit **foes only** (never allies, helpers or NPCs). Schema changes approved with the plan.
- **MP:** `PlayerState.mp` (-1 = full, like hp) and `mp_minutes` (awake minutes toward the next MP). `Stats.max_mp` =
  `tactical.mp.base` (0) + `per_intellect` (2) x Intellect + `per_level` (1) x total class level + each class's
  `combat.mp_bonus` x its level; hunger does not touch it. A new base stat `intellect: 3` in
  `rules.combat.base_stats` (was only a Skill stat). A new player has 6 MP. `core/mana.gd`: `current`, `set_mp`, `spend`,
  `tick` (1 MP per `regen_minutes` = 10, called from `Movement._spend_seconds` and `Actions.perform`, so fight rounds
  regen too), `refill`. A night refills `sleep_refill` x `Rest.share`; a collapse refills half and a knock-out a quarter
  (the same shares as HP). `Movement._spend_seconds` now takes `db`.
- **Save v20:** `player.mp`, `player.mp_minutes`, `progression.spells`, and `encounter.npc_mp` ({} when an encounter runs).
- **Data:** `data/spells.json` (`SpellDb`, checked in `DataDb.load_dir`): `name`, `shape` (`one` range; `line` length;
  `blast` range and radius; `around`), `ap_q` 1-40, `mp` 1-10, `damage` [a, b], `hit` (`auto` or `roll`), `cooldown`,
  optional `intellect_div` (3), `learn` {`teacher`, `after_event`, `minutes`, `book`}, `canon_ref`. Names and who uses them are
  canon; **every number and every teacher is a design guess** (noted in each `canon_ref`). First spells: [Ice Spike] (one,
  Ceria teaches), [Flashfire] (around, Ceria), [Frozen Wind] (line, Pisces), [Fireball] (blast, spellbook only). Left out:
  [Light], [Flare], [Water Spray] (Ryoka's cantrips: her class-less magic stays hers, and they are not combat spells),
  [Barrier of Air], [Illumination], [Ice Wall].
- **Damage:** `roll(damage) + Intellect / intellect_div - armor`, at least `min_damage`. A `roll` spell hits like a blow with
  Intellect as accuracy against the foe's evasion (NPCs use their `accuracy`); the hit roll is made for an `auto` spell too, so
  the random stream never changes. Line: up to `length` tiles from the caster toward the aim (the side with the larger gap),
  stopping at the first unwalkable tile. Blast: the square of `radius` round the aim tile. There is no line of sight for `one`
  and `blast` yet (M17.6 may add it with cover).
- **Cast:** `Commands.cast(spell, aim_tile)` -> `Spells.why_not` -> `_encounter_act_q` (AP paid on success; MP is paid inside
  `Spells.use`). The cooldown table key is `spell:<id>` (never meets a Skill id); `CombatSkills.start_cooldown` is now public.
  Each foe hit is one ranged blow in the turn log; the entry also gets `cells` (the replay lights those tiles).
  `Encounter.maybe_end_turn` keeps the turn open while a ready spell can be paid. A fight's casts become one action record
  `cast_spell` (tag `magic`) in `Combat.end_fight`.
- **Learning:** `Spells.learn_from_teacher` (Commands.learn_spell): the NPC must be next to the player, the spell's `teacher`, its
  `after_event` done, the spell unknown. It costs `learn.minutes` as the action `study_spell` (tags `magic`, `study`), which
  feeds the hidden [Mage] pool. A spellbook is a good with `"teaches": <spell>` (`EconomyDb.USES`): Enter in the bag reads it
  once (`Economy.use_good` -> `Spells.read_book`), the book is used up, a refused book is kept. Learning sets the flag
  `player.knows_spell`, the [Mage] prerequisite. No shop sells `spellbook_fireball` yet (no canon shop source; debug `give`).
  `Interact.options` gives an NPC a `teach` list; the use menu shows "Learn [Spell] (2 h)" rows.
- **[Mage]:** `classes.json` (prereq flag `player.knows_spell`, tags `magic` 1.0 and `study` 0.3, threshold 30, `combat.mp_bonus`
  1) with two passive guess Skills ([Mana Sense], [Steady Casting]: +1 / +2 Intellect) so the class has Skills to find.
- **NPC casters:** npc_behaviour `combat` gets `mp` and `spells` [{`id`, `after_event`?, `until_event`?}] (`BehaviourDb` checks
  them). Ceria: [Fireball] after 1.47R's captains' plan, [Flashfire] after 1.54's Gazi hunt, [Ice Spike] after 2.23's
  reforming of the Horns; 12 MP. Pisces: [Frozen Wind] after 1.22's flies; 8 MP. An NPC's MP is full when it first casts in a
  fight and lives in `encounter.npc_mp`; it does not come back inside a fight and is not kept after it. `_npc_turn` casts
  before it tries a Skill or a blow, from afar (one / blast in range, around next to a foe, line toward a foe). Other NPCs
  keep to Skills and blows (own numbers in M17.7).
- **Screen:** spells share the Skill bar after the Skills (nine keys in all; text "2 [Ice Spike] 2 AP 2 MP"); "MP a/b" beside the
  AP; the HUD line shows MP once a spell is known; the sheet lists "Spells:". An `around` spell, or a `one` spell with one foe in
  range, is cast at once; otherwise it is armed: `one` shows gold frames, `line` and `blast` show orange tiles under the mouse and the
  foe count, a click or a direction key casts, Esc, a right click or the same key lets it go, a refused click keeps it armed.
  Console: `spell <id>`, `cast <id> [x y]`.
- **Tests:** `unit_mana` (17), `unit_spell_learning` (16), `unit_spells` (31: toy arena and real data, Ceria casts), `unit_spell_ui` (13).
- **Open lore flags:** every teacher and number is a guess; Book text for the spell teachers should be checked in M17.7 or later
  (Pisces and Ceria as teachers of the player, spellbooks for sale, [Light] as a combat flash).

## M17.6 Cover and position (2026-09-30, cloud session)
User answers (2026-09-30): **walls block sight** (throws, shots and `one` / `blast` spells); **half cover -15, full cover -30 points**;
**pincer +15 points**; **shooters take cover and melee monsters close the pincer** (no retreat to cover: M17.7). Plan:
`docs/plans/m17.6.md`. Schema (approved in ADR 0022): tile field `cover`, map object field `cover`, `rules.combat.tactical.cover`.
All optional, so old data stays valid. **No save change** (cover comes from the map and the fighters' places).
- **Levels:** `none`, `half`, `full`, `wall`. `data/tiles.json`: walls, houses, cliffs (`city_wall`, `building*`, `brick_house*`,
  `plain_house*`, `ruin_wall`, `wood_wall`, `wood_window`, `snow_wall`, `cliff`, `stone_cliff`) are `wall`; `tree`, `boulder` `full`;
  `rock` `half`. A **solid object** has its own `cover`, else `rules.combat.tactical.cover.kinds[kind]` (tables, counters, beds,
  benches, stoves, braziers, stalls, wells, graves: `half`; shelves, wagon, trees: `full`; `stone_doors`: `wall`; campfire and stairs:
  none). The higher of tile and object counts. `MapDb.validate` checks all of it (`solid_at` is the new accessor).
- **`core/cover.gd` (`Cover`):** `level`, `line` (Bresenham, same tiles both ways), `sight` (a `wall` strictly between blocks it;
  `cover.sight: false` turns it off), `against(target, from)` (the tiles beside the target on the side(s) that face the shooter: the
  larger gap; both on a tie; the best level counts), `side_at` (FRIEND = player, helpers, NPCs fighting for them; FOE = hostile
  monsters and NPCs hostile to the player; fleeing monsters count for nobody), `pincered` (two fighters of a side on opposite tiles),
  `details` / `hit_bonus`, `sides` and `note` for the screen.
- **Effects:** cover lowers a **ranged** hit chance (throws, foe stones, spells with `hit: roll`). **Melee ignores cover** (an
  adjacent attacker has no barrier between). A spell with `hit: auto` ignores cover but still needs sight. A shot from where the
  target has no cover on the facing sides is the flank: it gets the full chance. The **pincer** adds +15 points to any attack from
  that side (player, helper, NPC fighter, monster, brawler; melee and ranged). `Combat.position_bonus` is the one hook, called from
  `player_hit_chance`, `monster_attack`, `_attack_other`, `helper_attack`, `NpcReact._hit`, `Brawl.attack` / `_hit_player` and
  `Spells._chance`. The roll is still made once, so the random stream is unchanged; only the threshold moves.
- **Sight:** `Combat.throw_at` and the thrown strike Skill refuse with "You cannot see it from here." (`Combat.NO_SIGHT`);
  `Spells.why_not` (one / blast), `one_targets` and `npc_pick` need sight; a foe's stone needs sight (`Encounter._hostile_turn`,
  `MonsterSim._hostile_turn`). `line` spells still stop at the first unwalkable tile; `around` and melee need none. A blast's
  explosion tiles are not checked for sight once its aim tile is seen.
- **Monsters:** `MonsterSim.is_shooter(enemy)`: the ranged blow's top damage is at least the melee blow's (the Goblin Lord archer
  and shaman; NOT the grunt, chieftain or crypt lord). A shooter, while its chase count is below `cover.hold_rounds` (6), first
  walks (`MonsterSim.cover_spot`: within the move cap, keeping 2 AP for the shot, in range, in sight, not beside the target,
  strictly better cover; best cover, then fewest steps, then lowest y, x) and shoots; if it stands in cover it then **holds**
  instead of walking on. `MonsterSim._pincer_goals`: of the free tiles beside the target, those opposite a fighter of the
  monster's side win a tie with the nearest one. **Why the shooter rule:** a first draft gave every monster with a `ranged` entry
  this behaviour; the Goblin Chieftain then hid behind a table in the inn and Erin killed him first, so `sim_m6_done` no longer
  showed the changed canon event. The rule is data-derived and M17.7 (enemy `abilities`) may make it an explicit flag.
- **Screen:** bars on the edges of the tiles you can walk to (and your own) that have cover beside them (short gold = half, full
  blue = full or wall); the hit-chance label gets "(half cover)", "(full cover)", "(pincer)"; a throw hint is hidden and a spell
  aim shows nothing where a wall blocks sight; one help line. No display in the cloud: the tests check overlay state only.
- **Tests:** `unit_cover` (14), `unit_cover_attacks` (9), `unit_cover_position` (10, incl. real archer near a tree), `unit_cover_ui`
  (4). Dice moved in two old sims (the pincer changes thresholds): `sim_big_battle` now seed 4 (7 leaves one routed goblin boxed
  in by idle NPC allies, and its bot never hits a fleeing goblin), `sim_inn_brawl` (run out of the door) seed 5 (a passive
  player already lost it on seeds 2, 6 and 8).
- **Open (for M17.7 and the user):** all cover numbers are guesses; a foe that flees into a corner can be boxed in by idle NPC allies
  (real hazard for a player who ignores fleeing foes; they still count as fighters); the `is_shooter` rule; melee monsters do not
  seek cover from the player's throws and spells; no retreat to cover; the user should look at the cover bars
  (`godot --path game`, walk next to a tree on the floodplains, then fight a goblin).

## M17.7 Enemy abilities and balance (2026-09-30, cloud session)
User answers (2026-09-30): abilities are **three fixed kinds with numbers in data**, but **no shell** (only `shooter` and `leap` are built);
**cost by total level with a hidden cap 100 and a gentler curve after level 10**; **NPC own Agility** and **flat HP numbers x hp_scale** yes,
shooters retreating to cover and a cornered foe that fights no. The hidden XP idea (duress) is **M17.8**. Plan: `docs/plans/m17.7.md`.
No save change (no shell, so no flag to save).
- **Level cost:** `Levels.cost(p, rules)` = `xp_to_next(total level)`; every class pays the total-level price (one class: unchanged; Ryoka's
  theory, 2.41). `rules.levels`: `late_from` 10, `late_growth` 1.12 (above level 10 each level costs 12% more instead of 25%), `total_cap` 100.
  At the cap `level_up` stops (XP stays), `is_blocked` is false and `ClassSystem.can_offer` refuses. Nothing shows it. Cumulative XP to total
  level 20 falls from about 10,900 to about 6,300. `xp_to_next` stays the pure curve (`unit_levels` numbers). The console `status` line shows
  the total-level price. The cap is only a first setting until M17.8 changes the XP supply.
- **hp_scale = 2.0** (`rules.combat.tactical`). `Combat.hp_scale`, `scaled_hp`, `foe_max_hp`, `scaled_enemies` (for the view). Read by:
  `Stats.max_hp` (before the hunger share), `Combat.add_monster`, the escape check, `MonsterSim._beaten` (flee ratio; new `db` argument),
  `NpcReact.stats` (NPC HP; damage, armor, accuracy unchanged), bandage, potions, cold and fairy snow (`Winter._hurt`), traps (`Traps._spring`),
  the HUD bars and the console monster list. Damage, armor and accuracy do not scale: each side needs twice as many blows. Toy dbs pin 1.0.
- **`core/monster_abilities.gd` (`MonsterAbilities`):** optional `abilities` on an enemy (`CombatDb` checks them). `shooter` replaces the derived
  rule of M17.6 (archer, shaman). `leap` {`name`, `range` >= 2, `ap_q` 1-40, `cooldown` rounds}: in `Encounter._hostile_turn`, a monster not
  side by side with its target, with the AP and the leap ready, jumps to the nearest free tile beside the target within `range` and sight (the
  move cap does not apply), then hits with the AP left. The cooldown uses `encounter.cool` (key `ability:leap`). Ghoul: range 4, 2 AP, cooldown 3
  (1.58 H "leaps and claws"). Shield Spider: "Pounce" range 3, 1 AP, cooldown 2 (4.08 T; the roadmap's leap). All numbers are guesses.
  **No shell:** the Rock Crab has no ability; it keeps armor 4 and its scare rule.
- **NPC Agility:** optional `agility` in the `combat` block of `npc_behaviour.json` (`BehaviourDb.check_fight_stats` >= 1); `Encounter.agility`
  reads it, else `initiative.npc_default` (3). 24 numbers, all guesses: Klbkch 7; Relc, Gazi, Ryoka 6; Zevara, Krshia, Ksmvr, Halrac 5;
  Rags, Ylawes, Yvlon, Typhenous, Tkrn, Jeiss, Umbral 4; Erin, Pisces, Ceria, Lyonette, Bird, Revi, Designated Worker 3; Zel, Toren 2.
- **Probe (`sim_balance_fights`, seeds 1-3, fists, hp_scale 2.0):** 1 Goblin: level 0 wins 3/3, level 5 wins 3/3 (at scale 1: 2/3 and 3/3). 2 Goblins:
  level 0 wins 1/3, level 5 wins 3/3. 3 Goblins: level 0 wins 0/3, level 5 wins 1/3. Razorbeak: every level wins. Rock Crab: 0/6. Raid: still not
  winnable by one player, and it lasts 15-24 player turns (M17.2: 3). Player max HP: 40 at level 0, 70 at level 5. **Deviation from the plan:**
  the target "2-3 Goblins: level 5 wins on 2 of 3 seeds" holds for 2 Goblins only; 3 Goblins stay a hard fight. I did not tune enemy stats
  further (all guesses). The sim now asserts what holds.
- **Test changes:** `FightBot.sink` / `sink_on` collect every line of a command that ends the turn first (`sim_goblin_raid` lost a wave line to
  that, not to a game fault); HP literals in `unit_world_view`, `unit_console`, `unit_economy`, `unit_battle`, `sim_winter` follow the scale.
- **Tests run (no full suite, by the user's rule):** new `unit_hp_scale` 7, `unit_monster_abilities` 9, `unit_npc_agility` 5; changed `unit_levels`
  15, `unit_tactical_rules`; and the scripts that touch the code or read HP on the real data: unit_class_system, unit_night, unit_stats, unit_combat,
  unit_combat_db, unit_combat_skills, unit_monster_sim, unit_encounter, unit_cover_position, unit_spells, unit_brawl, unit_npc_react, unit_traps,
  unit_winter, unit_economy, unit_console, unit_world_view, unit_battle, unit_game_state, unit_rest, unit_system_messages, unit_travel, and the
  fight sims (sim_balance_fights, sim_balance_progress, sim_big_battle, sim_book3_finale, sim_book3_stages, sim_book4_christmas,
  sim_book4_relief_home, sim_book5_creler_nest, sim_book5_last_light, sim_book5_rift_undead, sim_canon_fights, sim_combat, sim_esthelm_siege,
  sim_gazi_attack, sim_goblin_battle, sim_goblin_raid, sim_inn_brawl, sim_inn_third_floor, sim_liscor_depths, sim_player_hooks, sim_skinner_night,
  sim_winter, sim_celum_trip, sim_m5_done, sim_m6_done). Validator 0 errors.
- **Open (for M17.8 and the user):** the XP supply and the level curve are tuned together in M17.8; every ability, Agility and cost number is a guess;
  the user should play a fight with a leaping Ghoul or Shield Spider and check the turn order with the new NPC Agility numbers.

## M17.8 Hidden XP (2026-09-30, cloud session)
User answers (2026-09-30): fight XP by HP lost on **your shape** (x0.5 at nothing lost, x1.0 at 10%, +0.01 per 1% more, cap x2.0; a knock-out is
x1.9); duress and an XP window **multiply**; the window data lives **on the canon event**; **no save version change** ("I don't care about old
saves: no one besides me played the game"; rule 8 of CLAUDE.md asks for a migration on a schema change, the user waived it for this field);
other classes' duress (cooks, runners, healers) **later**. Plan: `docs/plans/m17.8.md`. The player never sees any of it: no number, no message.
- **Formula:** `xp = base x intensity x risk x novelty x conviction x outcome x skill x duress x window`. `Xp.compute` takes the last two (default 1.0);
  `Actions.perform` reads `opts.duress` (default 1.0) and `opts.window` (default `XpWindow.mult`), and the record keeps both. Old records lack the keys;
  nothing reads them after the record is made.
- **Duress (`rules.xp.duress`: floor 0.5, even_at 0.1, per_percent 0.01, cap 2.0; `Xp.duress_mult(lost)`):** `lost` is the share of max HP the player lost to
  foes at the worst point of the fight. The fight record (`CombatState.fight`) keeps `peak` (highest HP before a foe's blow) and `low` (lowest after one), in per
  mille, -1 = no foe hit yet. `Combat.damage_player(..., from_foe = true)` writes them; a trap passes `false` (cold, hunger and healing use `set_hp`, so
  they never count). `lost = (peak - low) / 1000`: a fight started at 40% HP and ending at 10% is 30% lost, not 90%; healing never raises `low`.
  `Combat.end_fight` computes it once and every record of that fight (attacks, blocks, throws, casts, flee, spare) carries it. A knock-out is x1.9 and its
  `fail` outcome (x0.5) still applies. A tolerant read in `CombatState.from_dict` gives -1 for a save without the fields.
- **Windows (`core/xp_window.gd`, `CanonDb.windows`):** canon event key `xp_window` `{"boost": whole >= 1, "hours"?: [from, to]}` (hours may wrap past
  midnight). Open while the event is **pending** (events resolve in the night, so a slept-through night closes it: no double dipping), today is inside its
  window with delays (`WorldState.latest`), and the hour is inside `hours`. All actions, anywhere. Two windows at once: the highest boost, no product.
  `rules.xp.boosts` maps the tier to the multiplier (1 = 1.5, 2 = 2.0, 3 = 3.0); content never holds a raw multiplier. `CanonDb` and `tools/validate_data.py`
  check the shape; `XpWindow.validate` checks the tier exists; a window on a mutate target is an error.
  **Why the event and not a flag:** a probe showed `skinner.awake`, `skinner.hunts_the_inn` and `skinner.dead` are all false on the morning of day 39 and all true
  on day 40 (the events resolve together in the night), so no flag can mark the Skinner evening. A pending event can.
- **Data:** `b1.skinner_leads_the_dead_into_liscor` (1.60) and `b1.rags_kills_skinner` (1.62): boost 2, hours [18, 6]. So the Skinner night (day 39 from
  18:00 until the night resolves, or until 06:00 on day 40) pays double for every action. Both events keep it open; a night slept on day 39 closes it.
- **Toy dbs** drop `rules.xp.duress` (toy fights pay the plain XP); `ToyData.with_duress(db)` puts the shipped curve back.
- **Pace probe (`sim_balance_fighter`, 3 seeds, 22 days, two Goblin fights a day, full HP before each; inn worker = `sim_balance_progress`):** first class on
  night 1-3; total level 5 by night 6-7 (inn worker: night 14); level 9 by night 14-16, then it waits at the capstone (level 10 needs a breakthrough).
  Without the duress factor the fighter is at level 4-5 on night 7, so the duress adds about one level in the first week (a bot at full HP that takes real
  hits pays more than x1.0 on average). **The fighter levels about 2x faster than an inn worker. I did not change `rules.levels`:** a global cost rise would
  slow the worker (already on target) to fix a gap that only more XP sources for non-fighters can close (the user deferred those).
  Measured, not guessed: with `base_xp` 52 (run once, then reverted) the fighter has level 5 on night 7-9 (was 6-7) and the worker on night 18 (was 14).
  The gap stays about 2 to 1, so a global cost change only slows everyone. The gap closes with more XP sources for non-fighters, not with the curve.
- **Tests:** new `unit_fight_duress` 10, `unit_xp_window` 12, `sim_balance_fighter` 1; changed `unit_xp` +6 (17), Python `test_validate_data` +2 (97 pass),
  `sim_skinner_night` (the gate fight pays window 2.0 and duress 0.5 with frozen foes). Run: unit_xp, unit_actions, unit_skill_system, unit_combat, unit_traps,
  unit_brawl, unit_game_state, unit_console, unit_encounter, unit_combat_skills, unit_spells, unit_canon_db, unit_data_db, unit_director, and the sims
  (sim_m5_done, sim_m6_done, sim_canon_book1-3, sim_balance_fights, sim_balance_progress, sim_balance_fighter, sim_skinner_night, sim_goblin_raid and the
  other FightBot sims). Validator 0 errors, Python 97 OK. No full suite.
- **Open (for the user):** (1) the fighter-vs-worker gap; other classes' duress (crowd size for cooks, cold for runners, patients for healers) is the planned fix
  and is not built. (2) Clean wins pay half: the cover and position rules of M17.6 reward exactly that play, so a careful fighter levels more slowly. The
  floor is data (`rules.xp.duress.floor`). (3) Only the Skinner night has a window; other big nights of Books 1-5 need the same two lines of data.
  (4) The user cannot see any of this in the game; only the debug console's record shows the factors.

# ADR 0027 — M17 tactical combat (XCOM-style)

Date: 2026-09-30 · Status: approved by the user 2026-09-30; M17.1 and M17.2 done

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

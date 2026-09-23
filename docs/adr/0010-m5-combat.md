# ADR 0010 — M5 Combat

Date: 2026-09-23 · Status: accepted (M5 plan approved by the user 2026-09-23). This ADR grows with each part: M5.1 now, M5.2 and M5.3 later.

## User choices (plan)
- HP 0 = knocked out. There is no player death in M5.
- One held item (no inventory). Items come from map objects: chair, rolling pin, stone, seed core.
- 3 enemy types: Goblin grunt (pack), Rock Crab (hidden ambusher, scared by seed cores), Razorbeak (guards its nest).
- A monster at 0 HP dies.
- Knock-out wake spot: the nearest safe place. Floodplains and inn hill wake you inside the inn. Liscor gate and market wake you at the gate. Other areas wake you where you fell.
- 3 parts: M5.1 combat core, M5.2 monsters on the map, M5.3 combat UI.
- Canon goblin NPCs stay non-hostile. Fights tied to canon events, and guards who fight, are M6.

## No combat mode
The world is already turn-based: time moves only on commands. Each combat command (attack, block, throw, drop) costs one step of time (`world.step_seconds`, 6 s). Monsters act after each command (M5.2). `Commands._after` runs `Combat.sync`, then `NpcSim.sync`, after every command that moves the clock.

## Data — `data/enemies.json`, `data/items.json` (new schemas, approved in the plan)
- **Enemy:** `name`, `confidence`, optional `canon_ref`, `tags`, `color`, `danger` (0–1, the XP risk of the fight), `behaviour` (`pack` | `ambush` | `territorial`), `hp`, `armor`, `accuracy`, `evasion`, `damage` [min, max], `act_seconds`, `aggro_radius`, `lose_radius`, `chase_turns`, `flee_below`, `scared_by` (item tags), `scare_turns` (needed if `scared_by` is set), optional `ranged` {`range`, `damage`, `chance`}, optional `ambush` {`spot_radius`, `hit_bonus`}.
- **Item:** `name`, `confidence`, optional `canon_ref`, `melee` [min, max], `throw` [min, max], `throw_range`, `break_chance`, `tags`.
- All stats are `guess`. The behaviour follows Book 1:
  - Goblins: groups, knives and stones, they run when they lose (1.02).
  - Rock Crab: looks like a boulder, gives up fast (1.01); a seed core makes it panic (1.02).
  - Razorbeak: nests in the long grass (1.05).
- `CombatDb` loads and validates both files. Its errors join `DataDb.errors`. A missing file gives empty data (toy dbs).
- `enemies.json` `spawns` is `[]` until M5.2.

## Rules — `rules.json` `combat` (new required section, approved in the plan)
`base_stats` (per race, or `default`), `hp_base`, `hp_per_endurance`, `unarmed`, `hit`, `strength_div`, `min_damage`, `block`, `spot`, `spawn`, `jump_seconds`, `max_turns_per_sync`, `heal_actions`, `night_heal`, `knockout` {`wake_hp_frac`, `wake`: area → {area, pos}}, `xp`. `CombatDb.validate` checks that every wake tile is walkable.

## Stats — `core/stats.gd`
- `Stats.of` = the race's base stats + the `stat_mod` effects of held skills (`SkillSystem.stat_effects`). This makes `stat_mod` live.
- Stats are not stored. They are worked out when needed.
- Max HP = `hp_base + hp_per_endurance × endurance` (20 at base stats).

## Formulas
- **Hit chance:** `clamp(base + per_point × (accuracy − evasion) + bonus, min, max)`. The player's accuracy and evasion are both dexterity.
  - A throw loses `throw_per_tile` per tile after the first.
  - A raised guard gives the monster `−block.hit_malus`.
- **Player damage:** weapon roll (the item's `melee` or `throw`, or `unarmed`) `+ strength / strength_div − armor`, at least `min_damage`. A Rock Crab (armor 4) barely feels fists; the seed core is the answer.
- **Monster damage:** a roll of `damage` (or `ranged.damage`), at least `min_damage`. When the player blocks, it is multiplied by `block.damage_mult` and rounded down, so it can be 0.
- **Break:** after a melee hit with an item, `break_chance`.
- **Scare:** an item tag in the enemy's `scared_by` sets `state = flee` and `scared = scare_turns`. A melee attack needs a hit. A throw scares even on a miss (it lands next to the enemy).
- **Throw range:** king-move distance ≤ `throw_range`. Range only, no line of sight (known limit). The item is gone after a throw. There are no items on the ground.
- **RNG order per strike:** hit roll, damage roll, break roll. All rolls go through `gs.rng`.

## Runtime state — `core/combat_state.gd` (`GameState.combat`, save v6)
- Top-level fields: `next_id`, `sec`, `area`, `checked` and `spawn_last` (M5.2), `blocking`, `lines`, `monsters`, `fight`.
- **Monster:** `type`, `spawn`, `group`, `area`, `x`, `y`, `hp`, `state` (`hidden` | `idle` | `hostile` | `flee` | `home`), `home_x`, `home_y`, `carry`, `chase`, `scared`, `rolled_spot`.
  - Ids are `"m" + number`, always sorted by number.
- **Fight:** `{}`, or `start`, `foes` {id: type}, `attacks`, `improvised`, `blocks`, `throws`, `kills`, `routed`.
- **`lines`:** the combat text of the last command. `Combat.begin_command` clears it and drops the guard at the start of every command, so command return shapes do not change.
- **`PlayerState`:** gains `hp` (−1 = full, 0 = knocked out) and `held`.
- **Save v6:** `_migrate_5_to_6` adds `player.hp = -1`, `player.held = ""` and `combat = {}`.

## Fights and XP
- A fight starts when a monster turns hostile, or when the player attacks one.
- **Danger:** `Combat.in_danger` is true while a fight is on and a monster is hostile. While in danger, `Commands.perform`, `interact` and `sleep` are refused ("Not with enemies near."; the reason goes in `lines`, and `sleep` returns `{}`).
- **How a fight ends:**
  - leaving the area: fled (the monsters are gone);
  - no hostile or fleeing monster left: won if any foe died or ran off, else fled (`settle_fight`);
  - a knock-out.
- **XP:** there is no record per turn (it would crush novelty and spam the log). `end_fight` writes one record per kind of action used:
  - melee with fists;
  - melee with an item (context `weapon: "improvised"`, so the existing context rule adds `combat.improvise`);
  - blocks (every monster attack the player blocked, hit or miss);
  - throws (always improvised);
  - `flee_danger` (success) when the player fled.
- **Record fields:**
  - intensity = count / `xp.count_per_intensity`, capped at `xp.max_intensity`;
  - risk = the most dangerous foe's `danger`;
  - outcome: won → success, fled → partial, knocked out → fail;
  - `minutes: 0` (the turns already spent the time);
  - context `enemy` and `location`.
- There is no new action id. `Actions.perform` gets `allow_collapsed`, so a fight that ends in a collapse still logs.
- `Commands.sleep` settles a fight that is not in danger before the night, so its records are part of the night.

## Knock-out
- **At hp 0:**
  - `Movement.step` and `Movement.wait` are refused;
  - combat commands give "You are knocked out.";
  - the UI calls `Commands.knock_out`.
  - A sleep while down, or a collapse with enemies near, is a knock-out too.
- **`Commands.knock_out`:** `end_fight(knocked_out)`, then `Night.run(gs, db, true, true)`, then `_after`.
- **`Night.run(gs, db, collapsed, knocked_out)`:**
  - a knock-out counts as a collapse for the System (`last_sleep_collapsed`), but the player wakes at the normal wake time, not after the 12 h collapse sleep;
  - line `Night.KNOCKOUT_LINE`; the result has a new key `knocked_out`.
- **Night step 6 (`Combat.night`), before the NPCs move:**
  - monsters and the fight are cleared;
  - the player heals: a sleep to `night_heal.sleep` (full), a collapse to `night_heal.collapse` (half), a knock-out to `knockout.wake_hp_frac` (25%);
  - a knocked-out player is moved to `knockout.wake[area]`, if the area is listed.
- `bandage_wound` heals 6 (`heal_actions`), from `Commands.perform` or a map object.

## Commands (M5.1)
- `attack(dir)`, `block`, `throw(target_id)`, `drop`, and the debug `spawn_monster(type, pos)` → {id, error}.
- `move` into a monster attacks it (bump attack); the result has `attack`. `Movement.step` returns `monster` and treats monster tiles as blocked.

## Tests (M5.1)
`unit_combat` (27), `unit_combat_db`, `unit_stats`, `unit_night` (knock-out wake time, collapse unchanged), `unit_game_state` (v5 → v6), `unit_data_db` (`rules.combat` is required). The toy content is `ToyCombat` (goblin, crab, stick, vase, stink).

## Later
- M5.2: spawn tables, `MonsterSim` (turns, AI per behaviour, aggro, ambush, flee), take items from map objects.
- M5.3: combat UI and the M5 "Done when".
- M6: NPCs react to monsters, guards fight, the Chieftain fight, sparing Goblins, XP tuning.

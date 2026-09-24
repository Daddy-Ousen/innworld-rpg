# ADR 0013 — M7.B Big battles

Date: 2026-09-24 · Status: accepted (the user picked the full battle upgrade and approved the plan with its schema changes and save v9).

## Why
Canon has fights with many fighters. The first is the day-21 raid, with about 40 Goblins, and later books have battles with many named characters. The M6.5 rules could not show these fights:
- NPCs had no hit points, and monsters attacked only the player.
- A stage ally had to be in the fight's area already.
- All foes came at once.
- Name labels overlapped.

A benchmark showed that speed was never the problem: 80 Goblins cost about 2 ms per monster turn.

## User choices
- Option 1: the full battle upgrade.
- **An NPC at 0 HP is down, not dead.** It gets up after the fight. Only the director (the canon story) decides deaths, so a random fight can never kill a canon NPC.

## Rules
**NPC hit points.** NPCs who fight have HP. These are the guards (`rules.npc.react.fight_tags`) and the stage allies.
- **Stats** (`NpcReact.stats`) come from the NPC's own `combat` block in `npc_behaviour.json`, if it has one. Otherwise they come from `rules.npc.react.fighter` (a fight tag) or `.ally`, which now have `hp`, `evasion` and `armor`.
- **At 0 HP** the NPC is `down` ("X falls."). It lies still, is no target, and does not act.
- **When the fight ends**, every downed NPC gets up with 1 HP.
- **A long gap (a night)** heals every NPC.

Bystanders are never attacked; they step away as before.

**Monster targets** (`Combat.monster_target`). A hostile monster goes for the nearest (in king moves) of:
- the player;
- a standing NPC who fights;
- a helper.

Ties go to the player, then to NPCs, then to helpers. The leash and chase still count from the player. A monster hits an NPC or a helper with its accuracy against their evasion, and its damage minus their armor.

**Helpers** (the new monster state `ally`) are nameless fighters on the player's side, for example Rags's band.
- On its turn, a helper walks to the nearest hostile monster and hits it. Its kills count for the fight. It never flees.
- The player cannot bump, attack or throw at a helper. The target search (`nearest_foe`) skips it.
- A dead helper is not a kill. Helpers leave when the fight ends.
- A helper is shown as "allied Goblin" with a blue edge.

**Reachable targets.** A fighting NPC picks the nearest foe it can reach: it is already side by side, or the foe has a free side tile. Without this, in a crowd the NPC skipped turn after turn.

**Stage waves** (a canon event `stage.waves`; schema approved). The first wave is still `foes` (with tiles). Each later wave looks like this:
```json
{"after_seconds": 60, "left_at_most": 3, "from": [12, 14],
 "foes": ["goblin_grunt", ...], "helpers": ["goblin_grunt"], "allies": ["klbkch"], "line": "..."}
```
- `Stage.run` starts `combat.stage_run`, which holds the event, the start second and the next wave.
- `Stage.tick` runs after every command. The next wave comes when any of these is true:
  - its `after_seconds` have passed;
  - no more than `left_at_most` of the stage's foes are on the map;
  - none are.
- A wave waits while `rules.combat.stage.max_on_map` (12) of the stage's foes are on the map.
- Foes and helpers appear at `from`, or on the nearest free tile.
- An ally NPC in another area is moved onto that tile and fights. It must have an `npc_behaviour` entry, because only roster NPCs can be moved.
- The fight does not end while waves are left (`Combat.settle_if_over`).
- When the player leaves the area, the rest of the stage is dropped.

**Save v9** (migration 8 → 9):
- Roster entries get `hp` (-1 means full) and `down`.
- `combat` gets `stage_run` (`{}`).

**UI.**
- **HP bars:** every monster, and every hurt NPC, has a small HP bar.
- **Labels:** with more than 4 monsters, only these keep a label:
  - the most dangerous foe;
  - the helpers;
  - the 3 foes nearest the player.

  A label is also left out if it would overlap an NPC's name, or an earlier label on the same row within 3 tiles.
- **Fallen NPCs** are faded, with "(down)".
- **HUD:** it shows "Foes left: N" (on the map plus the waves still to come) while a staged fight is on.

**Validation.**
- `CanonDb` checks the wave shape.
- `CombatDb` checks the enemies, the `from` tile, allies with behaviour entries, and `max_on_map`.
- `BehaviourDb` checks the `combat` blocks and the react defaults.
- `tools/validate_data.py` checks the wave shape, the ally NPCs and the copy check on wave lines. Foe lists may repeat the same enemy. There are 39 Python tests.

## Data
- **The raid** (`b1.klbkch_dies_defending_erin`), in `inn_interior` from 12 to 14:

  | Wave | When | Who comes |
  |---|---|---|
  | 0 | at the start | the leader + 7 grunts at the door |
  | 1 | after 60 s, or when 3 are left | 10 grunts |
  | 2 | after 150 s | 10 grunts, with Klbkch and the Designated Worker |
  | 3 | after 240 s | 12 grunts, with Rags and 3 helper grunts (her band) |

  That makes 40 foes. Wave lines are in my own words. The hook is unchanged.
- **`npc_behaviour.json`** (all guesses):

  | NPC | HP | Accuracy | Evasion | Armor | Damage |
  |---|---|---|---|---|---|
  | `erin_solstice` | 24 | 4 | 4 | 0 | 1–3 |
  | `klbkch` | 80 | 10 | 7 | 2 | 6–10 |
  | `relc` | 80 | 9 | 5 | 3 | 6–11 |
  | `rags` | 10 | 5 | 6 | 0 | 1–3 |
  | `designated_worker` | 10 | 2 | 2 | 1 | 1–2 |

  There is also a new minimal entry for `designated_worker` (off map in `liscor`). Erin's damage is low on purpose: with more she killed the Chieftain before the player could reach him, and in canon she barely wins that fight.
- **`rules.json`:** the react `hp`/`evasion`/`armor` fields (fighter 20/4/0, ally 12/3/0) and `combat.stage.max_on_map` 12.

## Tests
- `unit_battle` (16 toy tests):
  - targets, and bystanders are never targets;
  - down, not dead;
  - helpers;
  - waves by time, by count, and at once when the map is clear;
  - `max_on_map`;
  - allies pulled in;
  - leaving drops the stage;
  - same seed, and after a load;
  - v8 → v9;
  - wave checks.
- `sim_big_battle`: 40 toy foes, 3 allies and 3 helpers. Same seed, same battle; about 5 ms per command (limit 60).
- `sim_goblin_raid`:
  - 40 foes in 4 waves; never more than 23 on the map;
  - Klbkch comes with wave 2 and fights;
  - a win gives `change`, and a knock-out leaves the canon.
- `unit_world_view`: labels, bars, the helper edge, fallen NPCs, and "Foes left".

## Known limits
- **Balance:** a player who does not fight is knocked out about a minute into the raid. The raid is hard to win at 20 HP. Balance is left for play-testing.
- NPCs still never leave the area when they flee.
- Only roster NPCs can be pulled into a stage. Other canon NPCs need an `npc_behaviour` entry first.
- A stage is still tied to one map area.

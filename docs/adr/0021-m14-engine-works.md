# ADR 0021 — M14 Engine works (inn play, living world, UI skin, balance)

Date: 2026-09-28 · Status: plan accepted by the user 2026-09-28 (sub-steps get their own sections)

## Context
- Books 1–5 are event data; art (M11) and audio (M12) are done. The user chose engine work over Book 6 and
  picked all four "Later" areas of the roadmap.
- Gaps found: the inn earns no coin (`guests` is never set by the game); cooking gives XP but no food; the
  player holds one item and bought goods have no screen; night step 7 (relationships, reputation) is missing and
  nothing reads `WorldState.relationships`; 180 of 223 canon NPCs have no schedule (about 20 live on a map we
  have); the player cannot attack an NPC; the UI has the default Godot look and no portraits; max HP never grows.

## User choices (2026-09-28)
1. **Scope:** inn play, living world, UI skin + portraits, balance pass. One milestone, 9 sub-milestones,
   one branch + PR each.
2. **Killing NPCs:** the player can attack any NPC. A major NPC gives a one-time fate warning first
   (DESIGN §4.6). A kill lowers standing with witnesses and their town.
3. **Guests:** unnamed patrons (existing race looks) plus canon NPCs whose schedule puts them in the inn.
4. **Font:** a free pixel font (CC0 or OFL). Ask the user before the download (file, source, size).
5. **Schema changes approved with the plan (rule 11):** good `item` field (M14.0), `data/recipes.json`
   (M14.1), `GameState.inn` + save v15 (M14.2), `WorldState.reputation` + `rules.standing` + save v16 (M14.3),
   optional System page `npc` field (M14.7), `rules.stats.hp_per_level` (M14.8).

## Plan
- M14.0 Bag screen · M14.1 Cooking recipes · M14.2 Guests and serving · M14.3 Relationships and reputation ·
  M14.4 Missing NPC schedules · M14.5 Attack NPCs + fate warning · M14.6 UI skin · M14.7 Portraits ·
  M14.8 Balance pass.

## M14.0 Bag screen (2026-09-28)
- The bag stays `EconomyState.bag` (good id → count); the hand stays `PlayerState.held`. No save change.
- A good may name an `items.json` item with `item` (a tool: rolling pin, horseshoe, stone). An item good has no
  other use, and one item has at most one good (`EconomyDb.validate`).
- New `Economy.hold_good` (bag → hand), `stow` (hand → bag), `drop_good` (one good is gone). Each takes one
  turn. Holding a tool puts the held item in the bag if it has a good, else down (gone, like `take`).
- These work with enemies near (like take/drop) but not when knocked out or too tired
  (`Combat.cannot_act`, now public).
- New `ui/bag.tscn` on key **I**: purse, hand, fed line, one row per good. Enter eats / drinks / holds,
  X leaves one behind, P stows. F stays the quick eat menu. The bag opens again after each pick.

## M14.1 Cooking recipes (2026-09-29)
- New `data/recipes.json` (schema_version 1): recipe id → `action`, `inputs`, `outputs` (good → count),
  `stations` (map object kinds) and `confidence`. `EconomyDb` loads and validates it (known action and goods,
  counts > 0, outputs can be kept in the bag, at least one station). The Python validator checks canon only and
  does not read `economy.json`, so it does not read `recipes.json` either; `DataDb` validates it on load.
- New `core/cooking.gd`. After a done action (`Commands.perform` and `Commands.interact`, right after
  `Economy.after_action`), a recipe for that action at a station of the right kind whose inputs are all in the bag
  uses one batch of inputs and adds the outputs. Otherwise the action is only practice: XP is unchanged, no dish, and
  a line says why (no station, or which ingredients are missing). An action with no recipe is untouched, so the
  sim tests that cook with an empty bag still pass.
- Four recipes, all guesses (the text names no amounts): simple meal (1 vegetables; stove or campfire), stew
  (1 meat + 2 vegetables → 3 stew), pasta (1 dry pasta + 1 vegetables → 2 pasta dish), bread (2 flour → 4 bread).
  Stew, pasta and bread need a stove. `commands.perform` has no object, so it never cooks a dish.
- New goods: flour, vegetables, meat, dry pasta (ingredients: buy price, no sell price) and simple meal, stew,
  pasta dish (dishes: `food`, a sell price, no buy price). The dish sell price is the base for M14.2 serving
  income. Krshia's stall (Liscor) sells all four ingredients; the Celum stall sells flour, vegetables and meat.
- The interact menu adds a hint to a cook action: "makes 3 stew" or "needs 1 meat, 2 vegetables".
- Prices and yields are placeholders for the M14.8 balance pass.

## M14.2 Guests and serving (2026-09-29)
- Save v15: `GameState.inn` (`core/inn_state.gd`): `reputation` (0..100, -1 = start value from rules), `guests`
  (patrons), `income_today`, `guests_today`, `served_total`, `meal` (the last meal rolled), `served_npcs`,
  `next_id`. Migration 14 → 15 adds an empty `inn`.
- A patron is `{id, area, race, look, seat, order, arrive, until, paid}`. The plan named a `patience` field; we
  keep one deadline (`until`) instead: out of patience when not served, done eating when served.
- New `rules.inn` block (checked by `Guests.validate` on load): the inn area, meals (breakfast 7-10, lunch 12-14,
  dinner 18-22), `guest_curve` by reputation, `flag_bonus`, patron races (Drake, Gnoll, Human; a guess), dishes,
  patience, pay, reputation steps and the lines. All numbers are balance guesses for M14.8.
- Open: after `wandering_inn.open` (1.05); closed after `wandering_inn.destroyed` (2.10T) until
  `wandering_inn.rebuilt` (2.11).
- Patrons are rolled once per meal, at the first command in the meal while the player is in the inn's common
  room, never more than the free seats. They come over the first half of what is left of the meal. The roll uses its
  own `Rng`, seeded from the game seed and the meal key, so the main random stream (and every older test) is unchanged.
- Map objects may list `seats` (MapDb checks: next to the object, walkable, no exit). `inn_interior` has six tables
  and twelve seats, put away from NPC spots and walking lanes. A seated patron blocks the player's step; NPCs and
  monsters ignore patrons (a rare overlap is only visual).
- Serve (`Commands.serve`, menu "Serve <dish>"): a dish from the bag to a guest next to the player. It is the
  `serve_guests` action for 5 minutes (XP, inn work that feeds you). Pay = dish sell price x 2; the wrong dish pays
  half; reputation +1. A patron nobody serves leaves when out of patience: reputation -2, but only if the player is
  in the room (they were ignored). If the player is away, Erin copes and nothing is lost. A fight in the room sends
  all patrons away with no loss.
- Canon guests: an NPC in the room whose goal is `eat` or `visit_inn` is a guest (staff have `work`). They take any
  dish at full pay, once per meal slot; their relationship with the player goes up by 1.
- Cook actions at the inn get the context `guests` = patrons today + canon guests now (explicit context still wins).
- Night step 2c: a morning line with the day's takings; all patrons leave; the day's counts reset.
- The view draws patrons like NPCs (the `race_<race>` look, facing the table, "Drake patron (wants stew)").
- `sim_inn_service`: a week of cooking between meals and serving at every meal earns coin and reputation. Cooking
  during a meal lets patrons give up; that is intended.

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

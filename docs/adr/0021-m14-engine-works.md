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

## M14.3 Standing: relationships and reputation (2026-09-29)
- Save v16: `WorldState.reputation` (town or faction id → int, never 0) and `WorldState.contact` (canon NPC id →
  the last day the player had contact). Migration 15 → 16 adds both, empty. The plan named `reputation` only;
  `contact` is new because a relationship must fade "without talk", and serving a guest is contact too.
- New `core/standing.gd` and `rules.standing` (checked by `Standing.validate` on load; numbers are balance guesses
  for M14.8). A db without `rules.standing` (toy dbs) behaves as before.
- Keys: a **town** is the nearest `settlement` at or above a map's canon location (Liscor, Celum, Esthelm; the inn
  and the Floodplains have none). A **faction** is an NPC's canon `faction`.
- Gains: the first talk of the day with an NPC gives the map's town +1 and the NPC's faction +1
  (`NpcSim.note_talk`); serving a patron gives Liscor +1 (the guests come from there). Reputation stays within +-100.
- Night step 7 (`Standing.night`, after the off-screen sim): a relationship with the player that has had no contact
  for more than 7 days moves 1 toward 0 per night (grudges too). A relationship with no contact record starts its
  clock that night (old saves and event gifts do not fade at once). Every third day each reputation moves 1 toward 0.
  Relationships between NPCs (canon events) never fade.
- Readers, so it matters:
  - **Regard** = relationship + faction reputation / 10. It picks the greeting band (stranger, acquaintance,
    friend, close friend; wary, hostile below 0). The talk menu shows the band ("Krshia (friend)"); the first talk of
    the day adds the band's greeting line.
  - **Prices**: at a shop, the town's reputation x 0.004 (at most +-20%) lowers what the player pays and raises
    what a shop pays (both round to whole copper; a good that a shop does not buy stays at 0).
  - **Friends fight**: an NPC with regard 10 or more counts as a fighter in `NpcReact` (ally stats), so they help
    against monsters near the player. Never dead: the director still decides who dies.
  - **The inn**: a quarter of Liscor's reputation is added to the inn's own for the guest curve.
- The character sheet lists the inn's reputation and each non-zero town or faction.
- Open for M14.5: attacking an NPC will call `Standing.add_reputation` for witnesses' towns and factions.

## M14.4 Missing NPC schedules (data only)

- Rule for who gets a schedule: a canon NPC who has a place on one of our maps (or a scene there), so the player
  can meet them. NPCs whose place has no map (a guild hall, a tavern, a bakery, a mansion) stay out.
- Added (13): Liscor `tkrn`, `jeiss`, `dreshhi`, `culyss`, `gazi_pathseeker`; Celum `grev`, `hess`, `octavia`,
  `agnes`, `maran`, `safry`, `eterell`; Esthelm `umbral`. Every entry is `"confidence": "guess"` for hours and spots.
- Canon flags steer them: Gazi walks the market while `liscor.gazi_in_city` and guards the inn hill while
  `gazi.protects_the_inn` (1.37-1.54). Maran and Safry work at the inn while `*.works_at_the_inn` (days 103-105) and
  not at the Hare then. Eterell works only until `celum_runners_guild.new_guildmaster`. Umbral needs `esthelm.saved`.
- Guards (`tkrn`, `jeiss`, `umbral`) and Gazi have `combat` blocks for M14.5. Tkrn and Jeiss visit the inn in the
  evening after `erin.met_liscor_watch`, so they can be canon guests (M14.2).
- Looks: 13 new LPC sheets (`gazi_pathseeker` has the same parts as `gazi_of_reim`). Grev uses a `teen` body: the tool
  does not read LPC child hair (`hair/<name>/child/<colour>.png` is one file, not walk/ folders).
- Left out on purpose:
  - No map: `terbore`, `tekshia` (Adventurers' Guild), `peslas` (Tailless Thief), `timbor_parithad`, `ulia_ovena`,
    `theofore`, `termin`, `ressa`, `magnolia_reinhart` (her Celum house has no map).
  - `esthelm_florist`: a Horror, not a schedule NPC.
  - `princess_thief`: the Book 1 placeholder for Lyonette (2.23 names Lyonette). The data keep them apart until the
    text links them (see the "confirmed links only" rule).

## M14.5 Attack NPCs (core, save v17)

- `core/brawl.gd` (new) and `rules.brawl` (new block, agreed in the M14 plan). The use menu lists **Attack** last
  on an NPC, in red. `Commands.attack_npc(gs, db, npc, confirmed)` is the one command.
- **Major NPC** is derived, no schema change: a pending canon event (one that runs by itself, not a mutate target)
  names them in a role's `prefer` list or in `requires.alive`. When the story no longer needs them, no warning.
- **Fate warning**: the first attack on a major NPC returns `warn` and nothing happens (no time). The UI shows a
  `fate` System page ("The Thread of Fate"). Its **Step back** button has the focus; **Strike them down** stays off
  for `fate_delay` seconds. A confirmed attack sets `gs.flags["fate_warned.<npc>"]`, so the warning comes once
  per NPC (and is saved).
- **A blow** is one turn. The NPC has the hit points, evasion and armor of `NpcReact.stats`. The player's hit uses
  the held item or fists like `Combat._strike` (item break included). At 0 HP the NPC is dead, not down:
  `Director.player_kill`. No XP: attacking is not an action record.
- **Hostile until the day ends**: the first blow of a day sets the roster field `hostile_day` (save v17; the
  migration sets 0). A hostile NPC that is up walks to the player and hits them (`Brawl.act`, called by `NpcSim`
  before `NpcReact`), one turn per `act_seconds`, a raised guard works as against a monster. While one is in the
  player's area it counts as danger (`Combat.in_danger`): no talk, work or sleep, and patrons leave.
- **Witnesses** are the NPCs in the area. First blow of the day: victim -5, witnesses -2 relationship, town -3,
  the victim's faction -3 reputation (`Standing.add_reputation`). The kill: witnesses -5, town -5, faction -5 more.
  A witness with the guard tag turns hostile for the day too.
- The full suite showed that M14.4's `tkrn` and `jeiss` (guards, evening inn visits) broke `sim_inn_brawl`: they killed
  the day-28 adventurers at once. Their inn visits now also need `wandering_inn.adventurers_attacked_goblins` (set by the
  brawl event, done or changed), so they come from day 29.
- Not done on purpose: bystanders do not flee, a hostile NPC does not follow the player to another map, and no
  console command (the console `kill` still kills at once, with no warning).

## M14.6 UI skin

- Font: Pixelify Sans (OFL 1.1, 79 KB, from github.com/google/fonts), approved by the user on 2026-09-29. Import
  settings: no antialiasing, no hinting, no subpixel positioning (crisp pixels).
- `game/ui/theme.tres` is the project theme (`gui/theme/custom`): font, warm brown panels with a tan border, buttons
  (normal, hover, pressed, disabled, gold focus ring), ItemList, LineEdit, HSlider. Every menu picks it up with no
  per-scene code.
- Kept on purpose: the blue `[Title]` colour on System-voice headings and the System dialog's own blue panel (the System
  is a different voice from the inn). The title screen backdrop and title turned warm. HUD log 13 -> 16, hint 12 -> 14
  and it now wraps (a pixel font is blurry at odd small sizes).
- Tests: `unit_ui_theme` (5). Screenshots checked: title, pause, bag, character, journal, use menu.

## M14.7 Portraits

- `world/portrait.gd` (`Portrait`): a face is an `AtlasTexture` over the front standing frame of a baked character
  sheet, cropped to the head (`Rect2(16, 8, 32, 32)` inside the 64 px frame, drawn at 96 px with nearest filtering). No
  new art and no download. A look with no sheet gives no face (null) and the menu hides the face.
- Where it shows: the use menu (a face beside the list, for the selected row's NPC or patron; patrons use the
  `race_<race>` look stored on the guest) and the System dialog (a fate warning shows its NPC; the Local News page shows
  the first NPC whose death it tells, `SystemMessages.portrait_npc`).
- Not done on purpose: the journal is one text label, so its news lines have no faces (the night's news page has
  them). No core change and no save change: presentation only.
- Tests: `unit_portrait` (11). Screenshots checked: use menu with Erin, fate warning with Klbkch.

## M14.8 Balance pass

- Three probe tests print tables (set `BALANCE_LOG` to a file) and keep loose asserts. Same seeds every run.
  - `sim_balance_progress`: 3 seeds, 22 days of the scripted inn day. First class by night 3; total level 5–6 on day 22
    (matches the M6.5 note). XP and level cost were fine: not changed.
  - `sim_balance_money`: 3 seeds, 14 days at the inn (cook, serve, sleep), ingredients charged at Krshia's prices, three
    loaves a day. Takings 56 to 170 copper a day against about 35 spent: profit from day 1, week 2 takes about 2.5 x
    its costs. Prices, recipes and the guest curve were fine: not changed.
  - `sim_balance_fights`: real hit rules, nothing frozen. Duels on the Floodplains (fists) and the day-21 raid.
- The one rule change: `rules.combat.hp_per_level` (optional, 0 if missing) adds HP per total class level in
  `Stats.max_hp`. Before this HP stayed 20 for the whole game while enemies hit for 4–8. Tried 2, 3 and 4: at level 5 a
  pack of three Goblin grunts was a coin-flip loss with 2, a hard win (9–18 HP left) with 3 and an easy win with 4.
  Chosen: 3 (level 5 = 35 HP, level 20 = 80 HP). No save change: max HP is worked out, not stored; a hurt player keeps
  their HP when a level comes.
- Findings left open (not tuned, asked the user):
  - A Rock Crab (30 HP, 4–7 damage) beats a fist-only player at level 5 on every seed. Canon: it is a thing to avoid,
    and the player can flee, use the repel item or hold a weapon. Left as is.
  - The day-21 raid is not winnable by one player with the real rules. Erin (24 HP) falls in three turns to eight
    raiders; wave 2 (Klbkch and the Designated Worker) is held back while 12 or more Goblins stand on the map
    (`rules.combat.stage.max_on_map`), and there are 17–18 by then. Tried in the probe only: allies in wave 1, Erin at 60
    HP, both together. The player still fell (39–74 turns). A knock-out leaves the canon (the safe result), so this is
    a design choice for the user, not a bug. `sim_goblin_raid` still tests the win with foes frozen.
- Tests: `unit_stats` (+2), `sim_balance_progress`, `sim_balance_money`, `sim_balance_fights` (2).

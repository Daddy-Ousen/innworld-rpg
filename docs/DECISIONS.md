# Decisions

Short log of design decisions, oldest first. Add new entries at the end with the next ADR number.

## ADR 0001 — M0 setup choices
2026-09-23 · Accepted

- Godot 4.7.2, GUT 9.7.1 (first GUT with Godot 4.7 support), vendored in `game/addons/gut`.
- `.gutconfig.json` uses an empty file prefix so GUT finds `unit_*.gd` and `sim_*.gd` (default prefix is `test_`).
- `Rng` stores `seed` and `state` as strings. JSON numbers parse as floats and lose precision on 64-bit values.
- `*.import` files are committed (Godot docs say so); only `.godot/` is ignored.
- Save loading: `GameState.load_from_file` -> `from_json` -> `SaveMigrations.migrate` -> `from_dict`. A newer `save_version` or invalid JSON returns `null` with `push_error`. We parse with `JSON.new().parse()`, since `JSON.parse_string()` also logs an engine error on bad input.

## ADR 0002 — M1 data schemas (actions, tags, classes, skills, rules)
2026-09-23 · Accepted

- Every data file is `{"schema_version": 1, <map keyed by id>}`. Ids are lowercase snake_case; tags are lowercase dotted (`cooking.stew`). Display names keep brackets (`"[Innkeeper]"`). Canon content (classes, skills) has `canon_ref` and `confidence` (`confirmed|likely|guess`); actions are game rules and have none.
- `data/tags.json`: registry of all tags. Every used tag must be listed, and the parent of a dotted tag too. A weight on `cooking` also matches `cooking.stew`; the most specific key wins.
- `data/actions.json`: `name, minutes, base_xp, risk (0-1), tags {tag: weight}, context [{key, min|max|equals, add_tags, add_risk}]`. Weights are normalised to sum 1.0 after context rules.
- Action record (in `GameState`): `time, day, minute, action_id, tags, intensity, risk, novelty, conviction, outcome, witnesses, xp`.
- `data/rules.json` holds tunables only: `clock`, `xp`, `levels` (`base_xp`, `growth`, `capstones [10,20,30]`), `offers.max_per_night`.
- XP: `base_xp x intensity x risk_mult x novelty_mult x conviction_mult x outcome_mult`.
  - intensity clamped to `[0.25, 3.0]`; `risk_mult = 1 + 3 x risk`.
  - novelty: `w = sum 0.5^(age_days/half_life)` over same-action records in the window; `novelty = max(floor, 1/(1+k*w))`; first time ever x1.5.
  - conviction: `1 + (match_mult-1) x overlap` with the declared focus tags; no focus = 1.0.
  - outcome: success 1.0, partial 0.75, fail 0.5 (failing still teaches).
- Clock: one counter `total_minutes` plus `awake_minutes`. `day = total/1440 + 1`, `minute = total % 1440`. Sleep wakes at the next `wake_minute`, or after `min_sleep_minutes` if that is closer. At 36 h awake (2160 min) the player collapses and sleeps 720 min; new actions are refused while a collapse is due. Draft's `collapse_wake_minute` was replaced by `collapse_sleep_minutes` so time cannot run backward.
- `data/classes.json`: `name, tag_weights, offer_threshold, prereqs {classes, flags}, excludes, race_limits (null | {allow}), loss {neglect_days, neglect_tags}, consolidation (null | {from, level_cost}), canon_ref`.
- `data/skills.json`: `name, rarity, pools [{class, min_level, max_level, weight}], tag_affinity, effects, canon_ref`. Skills name their pools, so a new skill never edits `classes.json`. Effect types: `stat_mod`, `action_unlock`, `xp_mult`, `passive_trigger` (`special` names a script in `core/skills/special/`).
- `GameState` gets typed fields `clock`, `action_log` (last `window_days` only), `action_counts`, `tag_totals`, `focus_tags`. `SAVE_VERSION` stays 1 (no saves in use yet); floats are written at full precision.

## ADR 0003 — M1 class system, levels, skills, night pipeline
2026-09-23 · Accepted

- Save version 2 (`SaveMigrations._migrate_1_to_2`: a v1 save becomes an Earther with no class). New state: `race` ("human"), `flags`, `progression` (`core/progression.gd`), `morning`. Action records gain `skill_mult`.
- Class pools: each night every record adds `xp x Tags.match_score(tags, class.tag_weights)` to the pool of each class not held and not declined. Pools are not zero-sum, so adding classes does not slow others.
- Decline blacklists the class id for good and freezes its pool; related classes still fill from the same tags (tested in `sim_decline`).
- Offers: ready when pool >= `offer_threshold` and prereqs, flags, excludes (both ways) and race pass. Best fill ratio first, at most `offers.max_per_night` (shared with consolidation). Offers stay open until answered; a newly accepted class that excludes one withdraws it (not blacklisted).
- Accept: level 1, XP 0, plus `skills.on_accept` skills. Consolidation is offered only in step 4 when all `from` classes are held; the new level is `max(1, best from level - level_cost)`, skills stay.
- Levels: cost L -> L+1 is `base_xp x growth^(L-1)`. `levels.base_xp` was lowered from 100 to 60 (with 100, a 30-day script reached only [Innkeeper] 3).
- Dilution: best class match decides how much XP counts (`min(1, max m)`), split by `m_c / sum m`.
- Capstones (10/20/30) wait for a breakthrough (`ClassSystem.grant_breakthrough`); XP keeps building meanwhile.
- Skills: weight = `pool.weight x (skills.base_weight + affinity)`. Normal level gives a skill with `chance_per_level`; a capstone always gives one, preferring rare. Only `xp_mult` is applied at this point (`skill_mult`). `rules.json` `skills`: `on_accept 1, chance_per_level 0.75, base_weight 0.1`.
- Class loss: a class with `loss` that sees no matching XP for `neglect_days` loses 1 level per night, then is lost (moves to `lost`, pool restarts, can be offered again).
- Night pipeline (`core/night.gd`): 1 close_day, 2 resolve_xp, 3 new offers, 4 loss then consolidation offers, 5-7 later milestones, 8 `clock.sleep`. Messages go to `gs.morning`.
- `core/commands.gd` is the only door for presentation. `ui/console_commands.gd` parses text; `ui/debug_console.tscn` was the main scene until M4.
- Data: 17 classes, 47 skills. Only [Innkeeper] is `confirmed` (1.00); most others are `likely` or `guess`, to be checked against the Book 1 ebook in M2. Tag weights, thresholds and skill effects are game rules, not canon.

## ADR 0004 — M2 canon pipeline: extractor and canon data schemas
2026-09-23 · Accepted

- `tools/extract_epub.py`: stdlib only. Reads container.xml -> OPF -> spine; titles from NCX. Skips svg/image/img/head and art-credit lines. Output `canon/raw/book1/NNN_<id>.txt` plus `index.json`. Book 1: 66 chapters, ~448k words. `canon/raw/` stays gitignored.
- Chapter ids: `1.00`, `1.19R` (POV suffix kept), `interlude_the_great_ritual`.
- Layout: `game/data/canon/book<N>/{npcs.json, locations.json, chapters/<ch>.json}` (moved here from `canon/events/` in ADR 0005). One chapter file per chapter. A chapter file may later carry `"order"` (unique whole number >= 1, ADR 0028) so same-day events run in book order.
- Common fields: `canon_ref {book, chapter, confidence, note?}`, `status` (`candidate|reviewed`, per record), `summary` (own words, max 300 chars).
- Event fields: `tier` (1 or 2; T3 is emergent), `window {earliest, latest, confidence}`, `location`, `roles {role: {prefer, fallback_tags, optional}}`, `requires {alive, flags, not_flags}`, `depends_on`, `on_fail` (must end in `cancel`), `delay_limit`, `effects {set_flags, clear_flags, kill, relationship [{from,to,delta}]}`, `rumor` (T1 only), `status`, `canon_ref`, `summary`. Day 1 = the day Erin arrives. A role may have only `fallback_tags` (monsters are roles by tag).
- NPC: `name, race, tags, faction, home, classes [{name, level}], alive_at_start, status, canon_ref, summary`. Location: `name, kind (region|settlement|district|building|landmark|wild), parent, tags, ...`. Chapter `system` log: `[{who, kind, name, level, confidence, note?}]`.
- `tools/validate_data.py` (stdlib only, exit 0/1): checks required/unknown keys, enums, ids, windows, cross-references, `depends_on` cycles, unique event ids, location parent cycles. With `canon/raw/book<N>/` present it also checks chapter ids and that no summary/rumor/note shares a 7-word run with the chapter text (rule 10 guard). Tests: `python -m unittest discover -s tools/tests`.
- Relationship deltas in events are design values, not canon; marked in `canon_ref.note`.

## ADR 0005 — M3 world director
2026-09-23 · Accepted

- Canon data moved to `game/data/canon/` so the game can read it via `res://`. `canon/raw/` stays outside `game/`.
- `core/canon_db.gd` (`CanonDb.load_root`) merges all `book*` folders; `DataDb.load_dir()` sets `db.canon`. It precomputes `order` (Kahn sort; ties by `window.earliest`, then id), `dependents`, and `alt_only` (all `mutate:` targets, never scheduled alone). `validate_data.py` is the full check.
- `core/world_state.gd` (`gs.world`) stores only changes to canon defaults: NPC `alive` overrides, relationships, event runtime `{status, day, roles, latest}`, `history`, `drift`, `last_day`. Missing event = `pending`.
- Save version 3 (migration 2 -> 3 adds `"world": {}`).
- `rules.json` `director`: `default_delay_limit 3`, `drift {substituted 0.25, mutated 0.5, cancelled 1.0}`, `tier_weight {1: 0.5, 2: 1.0}`, `unreliable_at 5.0`.
- `core/director.gd` is night step 5. It runs each day from `last_day + 1` up to the day before the wake day, firing due events until nothing changes.
- Failure kinds: wait (missing flag, blocking not_flag, pending dependency; waits while `day < latest`), role (no living `prefer` NPC), hard (a `requires.alive` NPC is dead, or a dependency is cancelled/mutated; never waits).
- Roles take the first living `prefer` NPC. Roles with empty `prefer` are anonymous (`*<first tag>`). `requires.alive` is strict: substitution never covers it.
- `on_fail` steps: `substitute` (living named NPC with most `fallback_tags`, ties -> lowest id), `delay` (only wait failures, up to `delay_limit`), `mutate:<id>` (alt must pass now), `cancel` (always last). After cancel/mutate, pending dependents fail hard (recursive).
- Effects: `set_flags`, `clear_flags`, `kill`, `relationship`. Drift = sum of `drift[outcome] x tier_weight[tier]`; one morning line when it first crosses `unreliable_at`. Tier 1 events add `Rumor: <rumor>` to the morning summary. No RNG: choices follow data order and ids.
- Player hooks: `Commands.kill_npc` (history `killed`) and `Commands.set_flag`. Console: `kill`, `flag`, `history`, `drift`.
- Tests: `unit_canon_db`, `unit_director`, `sim_divergence`, `sim_canon_book1` (days 1-7, every event `done`, drift 0).

## ADR 0006 — M4.2 world grid core
2026-09-23 · Accepted

- Start is day 8 outside the Liscor east gate (`clock.start_minute` 10440 = day 8, 06:00). `GameState.new_game` runs the Director through day 7 first so canon history exists; its rumors are dropped. `ToyData` sets `start_minute` back to 360. A Celum start is for M7+.
- `data/tiles.json`: `{tiles: {id: {name, walk, color}}}`.
- `data/maps/<area>.json`: `id, name, location, confidence, note, legend, rows, zones (location id -> rects), exits, objects`. Exit: `{at: [x,y] | [x,y,w,h], to, arrive, minutes}` (wide exits keep the offset). Object: `{id, at, name, actions, solid?, sleep?, context?}`.
- Five maps, all `guess` layout: `liscor_gate` (start 3,12), `liscor_market`, `floodplains_south`, `inn_hill`, `inn_interior`. Travel: market <-> gate 10 min, gate <-> floodplains 20, floodplains <-> inn hill 20, hill <-> inside 0 (door).
- `rules.json` `world`: `{start {area, pos}, step_seconds 6}`. Action context `location` values use canon ids (`"inn"` became `"wandering_inn"`).
- `core/map_db.gd` validates tiles, row widths, legend, location/zone ids, rects, exits and arrive tiles (walkable, not an exit), exits with minutes > 0 need the `travel` action, object ids and actions, and the start tile.
- `core/player_state.gd` (`gs.player`): `area, x, y, facing, sub_seconds`. Save version 4 (migration 3 -> 4 adds `"player": {}`). `Movement.ensure_placed` places the player on first use.
- `core/movement.gd`: `Movement.step` returns `{moved, blocked, refused, exit_to, minutes}`. Blocked by non-walk tiles, solid objects, map edge. A step adds `step_seconds` to `sub_seconds`; whole minutes go to the clock. Exits with minutes > 0 run `travel` with intensity scaled to the trip; a 0-minute exit logs nothing. `Actions.perform` got an optional `minutes`.
- `core/interact.gd`: options are objects on or next to the player; context = map location + zone + object context + caller context.
- `core/pathfind.gd`: BFS in one map, fixed direction order.
- Console: `where`, `look`, `go`, `use`.
- A float save round-trip issue was found here and fixed in save v5 (ADR 0008).

## ADR 0007 — M4.3 2D world view
2026-09-23 · Accepted

- `ui/session.gd` autoload `Session` holds `db` and `gs` (seed 1) and emits `state_changed`. Scenes send Commands on `Session.gs`, then call `Session.changed()`. No `class_name` (clashes with the autoload name). Main scene is `res://world/main.tscn`.
- Debug console stays headless; the scene syncs `console.gs` with `Session.gs`. In the main scene it is an overlay toggled by the backtick key.
- `world/world_view.tscn`: one `TileMapLayer`, TileSet built in code from `tiles.json` colors (16x16 atlas cells). Redraws only on area change. Player is a red square with a facing nose; `Camera2D` zoom 3, limits = map size.
- Main scene: WASD/arrows (one step, then repeat every 0.14 s), E opens the use menu (`ui/interact_menu.tscn`), Z sleeps. No walking while a menu or console is open.
- HUD (`ui/hud.tscn`): day, time, map and place name, warning at 6 h or less awake time left, last 4 log lines.
- Tests: `unit_world_view`.

## ADR 0008 — M4.4 NPC schedules, utility AI, save v5
2026-09-23 · Accepted

- `data/npc_behaviour.json`: `entries` (off-map place -> `{map: [x,y]}`; places `liscor` and `wilds`) and `npcs` (canon id -> `{confidence, notes?, goals}`), 14 NPCs. The Dragon is not listed. Goal: `goal` (`sleep, work, guard_post, patrol, trade, eat, visit_inn, forage, travel, off_map`), `base`, `hours [[from,to,mult]]` (wraps past midnight), `days [first,last]`, `when_flags`, `unless_flags`, `target` (`{off_map}`, `{area,pos}`, or `{area,route}`). Targets must be walkable and not exits (`BehaviourDb.validate`). Most schedules are `guess`. `days` exists because the director fires a day's events at night, so the day's own flags are not set yet.
- `rules.json` `npc`: `step_seconds 8` (player 6), `jump_seconds 300`, `talk_actions`, `talk_relationship 1`.
- `core/utility_ai.gd`: score = base x hour mult, 0 if outside `days` or flag conditions fail. Best wins, ties go to the first listed goal, nothing above 0 = IDLE. No RNG.
- `core/npc_roster.gd` (`gs.npcs`, save v5): `sec` plus per NPC `area, x, y, facing, goal, route_i, carry, talked_day`. World seconds = clock minutes x 60 + `sub_seconds`.
- `core/npc_sim.gd`: `Commands` call `NpcSim.sync` after every command that moves the clock. In the player's area NPCs walk one tile per `step_seconds` (BFS, around the player; NPCs pass through each other). Other areas jump to the goal spot, appearing at the way-in tile when the route crosses the player's area. A gap over `jump_seconds` makes everyone jump. Dead NPCs are removed. Night step 6 runs `NpcSim.advance_to(wake time)` after the director.
- NPCs block the player (`Movement.step` returns `npc`). Talk actions give the NPC +1 relationship once per NPC per day. `Commands.wait(seconds)` (Space key, console `wait`), `Commands.settle`.
- Save v5: adds `npcs` (`_migrate_4_to_5` sets `{}`). Floats are saved as exact f64 text (`"f64:" + 16 hex digits`, big-endian, e.g. 0.5 -> `"f64:3fe0000000000000"`) because Godot's text-to-float is not exact (about 1 in 3 floats at 17 digits). Old plain-number saves still load.
- Tests: `unit_utility_ai`, `unit_pathfind`, `unit_behaviour_db`, `unit_npc_sim`, `sim_npc_day`.
- Later: relationship decay, NPC classes at low detail, NPC travel time between areas.

## ADR 0009 — M4.5 System message UI
2026-09-23 · Accepted

- `Night.run` result gains `lines`, `collapsed`, `progress`, `world` sections; the UI reads sections, not text. `Night.COLLAPSE_LINE` is the collapse text.
- `ui/system_messages.gd` (`SystemMessages`, headless) builds pages in fixed order: collapse, Levels and Skills, rumors, drift warning, one page per open offer, morning. Page shape `{kind, title, lines, choices, class}`. Offer pages come from `gs.progression.offers`, so older unanswered offers show too. `is_open` skips withdrawn offers. An empty night shows "The System is silent."
- `ui/system_dialog.tscn`: "Voice of the World" panel, canvas layer 4. Accept -> `Commands.accept_class`; Decline -> confirm page -> `Commands.decline_class`. No skip: every offer needs an answer. The debug console cannot open while the dialog waits. Buttons connect deferred.
- Z sleeps anywhere; a refused action when a collapse is due runs a collapse sleep.
- Map objects get optional `"sleep": true` (schema change). The inn bed has it. `Interact.SLEEP` is not an action; the UI calls `Commands.sleep`. A bed does not change the night yet.
- `ui/character_sheet.tscn` (C key): read-only, static `lines(gs, db)`.
- Known issue: with a plain inn workday the first offer ([Innkeeper]) arrives on day 22. In canon it comes on the first night. XP/threshold numbers were not changed; balance is left to M6.
- Tests: `unit_system_messages`, `sim_m4_done`.

## ADR 0010 — M5 Combat
2026-09-23 · Accepted

- Choices: HP 0 = knocked out (no player death in M5). One held item, no inventory. Three enemies: Goblin grunt (pack), Rock Crab (hidden ambusher, scared by seed cores), Razorbeak (territorial, guards its nest). A monster at 0 HP dies. Canon goblin NPCs stay non-hostile; canon-tied fights are M6.
- Knock-out wake spot: Floodplains and inn hill -> inside the inn; Liscor gate and market -> the gate; other areas -> where you fell.
- No combat mode: the world is turn-based by time. Each combat command (attack, block, throw, drop) costs one step (6 s). `Commands._after` runs `Combat.sync`, then `NpcSim.sync`.
- `data/enemies.json`: `name, confidence, tags, color, danger, behaviour (pack|ambush|territorial), hp, armor, accuracy, evasion, damage, act_seconds, aggro_radius, lose_radius, chase_turns, flee_below, scared_by, scare_turns, ranged?, ambush?`, plus `spawns`. `data/items.json`: `name, confidence, melee, throw, throw_range, break_chance, tags`. All stats are `guess`. `CombatDb` validates both.
- `rules.json` `combat` is a required section: base stats, hp formula, unarmed, hit, strength_div, min_damage, block, spot, spawn, jump_seconds, max_turns_per_sync, heal_actions, night_heal, knockout, xp.
- `core/stats.gd`: stats are derived, not stored: race base + `stat_mod` skill effects. Max HP = `hp_base + hp_per_endurance x endurance` (20 at base).
- Formulas: hit chance = `clamp(base + per_point x (accuracy - evasion) + bonus, min, max)`, throws lose chance per tile, a raised guard gives the monster a malus. Player damage = weapon roll + strength/strength_div - armor, min `min_damage`. Block multiplies monster damage by `block.damage_mult`, rounded down. RNG order per strike: hit, damage, break. All rolls go through `gs.rng`.
- Scare: an item tag in `scared_by` sets state `flee` for `scare_turns`. A melee scare needs a hit; a throw scares even on a miss. Throw range is king-move distance, no line of sight. A thrown item is gone.
- `core/combat_state.gd` (`gs.combat`, save v6): `next_id, sec, area, checked, spawn_last, blocking, lines, monsters, fight`. Monster states: `hidden|idle|hostile|flee|home`. `PlayerState` gains `hp` (-1 = full) and `held`. `_migrate_5_to_6` adds `player.hp = -1`, `player.held = ""`, `combat = {}`. Monster `pack` field has a default, so no migration.
- Fights: start when a monster turns hostile or the player attacks. While in danger, `perform`, `interact` and `sleep` are refused ("Not with enemies near."). A fight ends by leaving the area (fled), no hostile monsters left (won if any died or ran, else fled), or knock-out.
- Fight XP: no per-turn records. `end_fight` writes one record per action kind used (fist melee, improvised melee, blocks, throws, `flee_danger`). Intensity = count / `xp.count_per_intensity`, capped at `xp.max_intensity`. Risk = most dangerous foe's `danger`. Outcome: won success, fled partial, knocked out fail. No new action id. `Actions.perform` gets `allow_collapsed`.
- Knock-out: `Commands.knock_out` ends the fight, runs `Night.run(gs, db, true, true)`. It counts as a collapse for the System but wakes at the normal time. Night step 6 (`Combat.night`) clears monsters and heals: sleep full, collapse half, knock-out 25%. `bandage_wound` heals 6.
- Commands: `attack(dir)`, `block`, `throw(id)`, `drop`, `take(object_id)`, debug `spawn_monster`. Moving into a monster attacks it.
- `core/monster_sim.gd` (M5.2): monsters act once per `act_seconds` of world time, in id order. Entering an area gives no turns. A long gap gives no turns unless a hostile monster is near (then up to `max_turns_per_sync`). AI by state: hidden (spot roll, ambush bonus), idle/home (aggro by radius; packs turn hostile together), hostile (flee on low HP or pack morale, give up past `lose_radius` or `chase_turns`; territorial monsters measure from home, which is how you escape the faster Razorbeak), flee.
- Spawns (all `guess`): `crab_valley`, `goblins_orchard`, `goblins_hill` (not while `goblin_tribe.leaderless`), `razorbeak_nest`. Entry has `count, chance, cooldown_minutes`, one of `zone|rects|home`, optional `hours, days, when_flags, unless_flags`. Checked on area entry and every `spawn.check_minutes`; picked by `gs.rng`.
- Items on the map: objects may have `"item"` (validated by `MapDb`, so `DataDb` loads combat data first). Scenery objects with no actions are allowed. Added zone `razorbeak_nests` and object `razorbeak_nest`. Razorbeak `aggro_radius` is 3.
- M5.3 UI (no schema or save change): monster markers on `WorldView` with name and HP, hidden monsters drawn as rock; HUD HP line (warning at 25% or less); log keeps 6 lines. Keys: bump = attack (once per key press), `B` block, `T` throw at `Combat.nearest_foe`, `X` drop. Knock-out page `SystemMessages.KNOCKOUT`. Character sheet shows HP and stats.
- Console: `attack`, `block`, `throw`, `drop`, `monsters`, `spawn`, `knockout`.
- Tests: `unit_combat`, `unit_monster_sim`, `sim_combat`, `unit_combat_db`, `sim_m5_done` (fixed seed 2).
- Known limits: NPCs ignore monsters (M6); monsters do not use exits; fleeing is greedy and can get stuck in corners.

## ADR 0011 — M6 Vertical slice
2026-09-23 to 2026-09-24 · Accepted

Five parts: M6.1 play loop, M6.2/M6.3 canon 1.15–1.25, M6.4 player hooks and news, M6.5 canon fights.
- **Save slots** (`core/save_slots.gd`): slots `1`–`3` plus `autosave`, files `slot_<n>.json` / `autosave.json` in `user://saves`. `load_game` runs `Commands.settle`. A file that does not parse is "cannot be read". Tests save to `user://test_saves` via `test_support/gut_pre_run.gd`.
- **UI:** `ui/title_menu.tscn` is the main scene (New / Continue / Load / Quit). Pause menu (Esc) has Resume, Save, Load, Quit to title. Journal on J. Autosave runs each morning, after a knock-out, on quit to title and on window close.
- **XP pacing:** all `offer_threshold` values in `data/classes.json` cut to one third (rounded to 5). Later (M6.5) `rules.levels` `base_xp` 60 → 40 and `growth` 1.35 → 1.25.
- **Canon event fields (schema change, M6.4):** `news` (one line, max 200 chars, own words) and `hooks`: `{id, did:[{action, outcome, context}], days:[from,to], then, effects, news}`. `days` span is at most 7 (the action log keeps 7 days). `then` is `cancel`, `mutate:<alt id>` or `change` (event runs with the hook's `effects`). `changed` counts as happened for `depends_on`. Drift weights: changed 0.25, mutated 0.5, cancelled 1.0. A hook's relationship effect may use `"player"` as `to`.
- Action records keep their `context` (enemy, location, NPC). **Save v7:** old records get `"context": {}`, `world.news` starts empty. News entries are `{day, event, kind, text}`, kind `news` or `rumor`.
- **Canon event field `stage` (M6.5):** `{area, hours, when_flags, unless_flags, foes:[{enemy,pos}], allies, line, note}`. Runs when the player is in `area` during `hours` on a day in the event window. Each event stages once (`world.staged`). `requires.flags` are not checked (the director sets them at night). Code: `core/stage.gd`, `Stage.check` runs from `MonsterSim.run`.
- **NPCs near a fight** (`core/npc_react.gd`): tagged fighters (`rules.npc.react.fight_tags`, e.g. `guard`) within `help_radius` 8 walk to the nearest hostile monster and hit it. Others within `flee_radius` 4 step away. NPCs act every `react.act_seconds` (6). All rolls use `gs.rng`.
- **Sparing:** every fight record has `killed`. A won fight where foes ran and none died, against `rules.combat.spare_tags` (`goblin`), adds a `spare_foe` record.
- **Save v8:** `world.staged` empty, old monsters get `"stage": ""`.
- Data: `goblin_chieftain` enemy (guess stats), hooks on `b1.erin_screams_off_rock_crab` (mutate), `b1.inn_first_regulars` (change), `b1.rags_brings_goblins_to_eat` (cancel; later needs `killed: true`), and `b1.erin_kills_chieftain` (stage + change hook).
- Validator checks `news`, `hooks`, `stage`. Known limits: hooks see only the last 7 days; Klbkch still fights Goblins after promising Erin not to (`klbkch.spares_goblins` is not read yet).

## ADR 0012 — M7 Rest of Book 1
2026-09-24 · Accepted

Four canon batches, one branch each: M7.1 1.26R–1.34, M7.2 1.35R–1.44R, M7.3 1.45–1.54, M7.4 1.55R–1.63. Book 1 canon ends on day 41. No save change, one engine change (`revive`).
- **Goblin raid (1.29)**, event `b1.klbkch_dies_defending_erin`: Klbkch (fallback tag `senior_guard`) and the Designated Worker die. Sets `klbkch.died_saving_erin`. Hook `player_fought_raid` is a `change`; Klbkch still dies. Enemy `goblin_raid_leader` (guess). Spawn `crab_hill_unpatrolled` opens on `liscor_watch.no_inn_patrols`.
- **Review answers:** most cities have their own Runners', Mages', Merchants' and Adventurers' Guilds (not a conflict). 1.32R uses the Horns' "a week ago", so the Lich run and crushed leg are day 15. The raiders' grave is several hundred feet from the inn.
- **Teriarch** is his own NPC (`teriarch`, `teriarch_cave`). He is not linked to the 1.00 Dragon (`cave_dragon`) unless the text says so. The new ruins in 1.41 are `liscor_dungeon`, not `ruins_of_albez`.
- **Engine fix, fleeing indoors:** in an area whose walkable edge tiles are all exits, a fleeing monster walks to the nearest exit and leaves. Outdoor maps keep the old behaviour.
- **Brawl stage (1.42):** `inn_interior` 19–21, day 28, adventurer enemies flee, not die. Hook `player_fought_adventurers` (does not check `killed`).
- **Goblin battle (1.52R):** `floodplains_south`, day 35, `goblin_feathered_chieftain` (guess). Hook `player_fought_beside_rags`.
- Horns schedule: eat at the inn 06–09 and 18–23 once `horns_of_hammerad.stay_at_inn` (night 35). Likely, not confirmed, links are marked `likely` (the thief is the [Princess]; the tiny Goblin leader is Rags; the speed potion).
- **`revive` effect (M7.4):** events and `change` hooks may list NPCs in `effects.revive`; applied after `kill`. No save change. `b1.klbkch_is_reborn` revives Klbkch from day 40 and does not need Pawn's Rite flag.
- **Engine fix, stage allies on long steps:** a stage ally in the player's area whose goal is in another area stays while the fight runs (a long command no longer sends it away).
- **Two stages on day 39:** Liscor gate (`b1.skinner_leads_the_dead_into_liscor`, hook needs top foe `crypt_lord` at `liscor_east_gate`) and inn hill (`b1.rags_kills_skinner`). Both need `adventurers.ruins_raid_planned`. New stage-only enemies: zombie, skeleton, ghoul, crypt_lord, skinner, plus helper types antinium_worker / antinium_soldier.
- Calruz, Ceria, Olesm stay alive but go `*.missing` (the text never shows them die). Periss-style deaths are not asserted without text.
- Known limits: the fights are small (about 19 and 16 foes); Skinner's fear and the Crypt Lord's poison are plain damage; balance left for play-testing.

## ADR 0013 — M7.B Big battles
2026-09-24 · Accepted

Canon has fights with many fighters (the day-21 raid has about 40 Goblins). The old rules could not show them. Speed was never the problem: 80 Goblins cost about 2 ms per monster turn.
- **NPC hit points:** fighting NPCs (guards via `rules.npc.react.fight_tags`, and stage allies) have HP. Stats come from the NPC's `combat` block in `npc_behaviour.json`, else `rules.npc.react.fighter` (20/4/0) or `.ally` (12/3/0). At 0 HP an NPC is `down`, not dead. It gets up with 1 HP when the fight ends, and a night heals all. Only the director decides deaths.
- **Monster targets:** a hostile monster goes for the nearest of player, standing fighting NPC, or helper (ties: player, NPC, helper).
- **Helpers:** monster state `ally`, nameless fighters on the player's side. They never flee, the player cannot attack them, and they leave when the fight ends.
- **Stage waves** (schema change): `stage.waves` items `{after_seconds, left_at_most, from, foes, helpers, allies, line}`. A wave comes when its time has passed, or when no more than `left_at_most` foes remain, or none remain. Waves wait while `rules.combat.stage.max_on_map` (12) stage foes are on the map. The fight does not end while waves remain. Leaving the area drops the rest.
- **Save v9:** roster entries get `hp` (-1 = full) and `down`; `combat.stage_run` added.
- **UI:** HP bars, fewer labels with more than 4 monsters, fallen NPCs faded with "(down)", HUD "Foes left: N".
- Raid data: 40 foes in 4 waves. Guess stats in `npc_behaviour.json`: Erin 24 HP, Klbkch 80, Relc 80, Rags 10, Designated Worker 10. Erin's damage is low on purpose.
- Known limits: the raid is hard at 20 HP; NPCs never leave the area when they flee; only roster NPCs (with an `npc_behaviour` entry) can be pulled into a stage; a stage is tied to one area.

## ADR 0014 — M8 Book 2 and Celum
2026-09-25 to 2026-09-26 · Accepted

M8 covers Book 2 canon plus Celum. Batches: M8.1 Interlude – The Call + 2.00–2.09, M8.2 2.10T–2.18, M8.3 2.19G–2.26 + 1.00C/1.01C, M8.4 2.27G–2.38, M8.7 three interludes + 2.39–2.48 (days 67–71). Calruz stays missing.
- **M8.0 tooling:** `tools/validate_data.py` loads earlier books' ids as known (flags `--no-earlier`, `--all`). Redefining a known id is an error. A Book 1 NPC changed by Book 2 is edited in its Book 1 record with a `canon_ref.note`. New `sim_canon_book2`.
- **M8.1:** `b2.gazi_attacks_outside_the_ruins` stage at new map `ruins_entrance`. New optional enemy field `escape: {below, line}`: a hit below 75% HP removes Gazi (routed, not killed). Hook `player_fought_gazi`. Winter arrives day 42 via flag `izril.winter`.
- **M8.W Winter** (`core/winter.gd`, `rules.winter`): outdoors and not warm, lose 1 HP per 30 minutes (never below 1 HP); winter clothes (`player.warm_clothes`) double the interval. Warm = map with `"indoor": true`, within 2 tiles of an object with `"warm": true`, or clothed. Frost Fairies: 60% chance of 2–4 on entering an outdoor map, talk gives XP for tag `fae`, swats and annoyance slow you, an item tagged `iron` (`horseshoe`) keeps them away. Tiles may have `winter_color`; maps may have `overlays` (`id`, `tile`, `rects`, `when_flags`, `unless_flags`) switched by `MapDb.sync_flags`; Toren's snow wall is one. **Save v10:** `GameState.winter`.
- **M8.2:** new stage `kind: "scene"` (`{area, hours, kind:"scene", npcs:[{npc,pos}], line, when_flags, unless_flags}`), no foes. `Stage.is_scene_live` holds the scene NPCs in place. Used by `b2.erin_iphone_concert_night`. Interlude – Mating Rituals Pt. 1 is floating flavor canon (nothing depends on it). Toren's fall into the ruins is part of `liscor_dungeon`; the far end (`death_beyond_death`) is not walkable yet.
- **M8.4:** stage + `change` hook `player_heard_erins_stories` (Pawn's Acolyte class, 2.31). Periss stays alive with `periss.presumed_dead`. Ksmvr's second demotion uses `ksmvr.relieved_of_duty` (not `ksmvr.deposed`).
- **M8.5 Celum:** `rules.world.start` replaced by `rules.world.starts` (list of `{id, name, area, pos, intro}`; first is default). `Movement.start_of`, `GameState.new_game(seed, db, start_id)`. Starts: `liscor`, `celum` (both day 8, 06:00). Maps `celum_gate`, `celum_square`, `celum_runners_guild`. Wesle guards the gate, Stenei works the guild counter.
- **M8.7:** Erin moves to Celum from day 71 (Frenzied Hare, map `celum_frenzied_hare`); Toren leaves the map from day 70; Rags banned from the inn. Four stages (Snow Golems, sledding crowd, Celum muggers, Hare bar fight). Niers corrected to a Fraerling, Level 64.
- **Ryoka never levels.** 2.35 now sets `ryoka.class_offer_cancelled` (event id kept for old saves); the [Barefoot Runner] records became `other` records of an offered, refused class.
- Flagged, not linked: Selys "Shivertail" vs Zel; Goblin Lord's eyes vs Az'kerash; Mihaela vs Valceif Godfrey; Lyonette's [Princess] vs Book 1's `princess_thief`. The two Antinium Wars interludes are history only. Web-serial author's notes are ignored.

## ADR 0015 — M8.6 Economy and travel
2026-09-25 · Accepted

- **Sleep:** no sleeping outdoors except on a campsite. Indoors or on a campsite without a bed: half heal. A bed: full heal. A collapse or knock-out still happens anywhere. (`core/rest.gd`; the bed id `Rest.ANYWHERE` = `*` is for debug and old sims.)
- **Hunger:** one meal a day. Each hungry night lowers max HP by 10% (floor 50%). Inn work at `wandering_inn` while Erin lives counts as fed.
- **New file `game/data/economy.json`** (`EconomyDb`): `goods` (buy/sell in copper, one use: `food`, `heal`, `wear_flag`, `eat_now`), `shops` (`sells`, `buys`), `yields`, `jobs`. Map objects get optional `shop`, `price` (on `sleep` objects), `ride`; maps get `camp: true`. `rules.economy`: `copper_per_silver` 10 (guess), `trade_minutes` 5, `haggle_share`, `rest`, `hunger`.
- New action `deliver_parcel` (60 min, pays 3–6c). Haggling gives 10% better prices for the day.
- **Road:** Celum gate ↔ `road_camp` 600 minutes each way; `road_camp` ↔ Liscor gate 600 minutes. Winter cold applies on the walk. **Wagon:** 40c, 480 minutes, covered (no chill).
- **Save v11:** `economy {coins, bag, fed_day, hunger, haggled}`.
- Known limits: no shop stock or price changes; the wagon ignores canon events on the road.

## ADR 0016 — M9 Book 3 (Flowers of Esthelm)
2026-09-26 · Accepted; M9 done

Four batches: M9.1 3.00E–3.05L + 1.00D/1.01D, M9.2 3.06L–3.14, M9.3 3.15–3.20T, M9.4 3.21L–3.25. Book 3 ends on day 87.
- Laken (Riverfarm) and Geneva (Baleros) are events only (no maps). Laken's "Day N" originally used placeholder days; later replaced (ADR 0028): game day = his Day + 45.
- Name clashes kept apart: maid Teresa (3.13), dead Horn Marian (3.08) and Laken's friend Teresa are not the existing NPCs of those names. "E" in chapter ids can mean Laken, not Erin.
- **M9.1:** stages `b3.ryoka_beats_persua_in_the_runners_guild` (fight; `persua_courier` escapes below 40%) and `b3.lyonette_reopens_the_inn` (scene). New schedules for `lyonette`, `mrsha`, `ryoka_griffin`.
- **M9.2 (Corusdeer soup, save v12):** `economy.json` goods may have `warm_minutes` and `from_flag`. `WinterState.warm_until` (-1 = none). `corusdeer_soup` sells at Stitchworks (8c, 240 min). Scene at the Frenzied Hare with Ryoka and Fals. `ryoka.gone_to_magnolia` ends her Celum schedule.
- **M9.3:** map `esthelm_ruins`; the last battle of Esthelm is a wave stage (22 foes, Redfang band as helpers in a late wave, hook `player_held_the_esthelm_barricade`). Nine stage-only Goblin Lord enemies. Ylawes is Yvlon's older brother (confirmed in 3.24).
- **M9.4:** new tile `cave_floor`, map `bee_cave` (indoor, no faeries), enemy `ashfire_bee` (14 bees stand in for hundreds). Four scene stages with hooks (Soldiers painted, Zel at the inn, Frozen, Erin leaves on the wagon). Albez door is flags only here (`erin.has_albez_door`, `albez_door.linked_to_frenzied_hare`).
- Toren is not killed; `toren.heading_to_liscor` stays set. Pisces' Floodplains nights now also stop on the Celum flags.

## ADR 0017 — M10 Book 4 (Winter Solstice) and the Albez door
2026-09-26 to 2026-09-27 · Accepted; M10.0–M10.5 done

Albez door first (M10.0), then M10.1 3.26G–3.29G, M10.2 3.30–3.31G + Wistram Days, M10.3 3.32–3.35, M10.4 3.36–3.39, M10.5 3.40–3.42 + Winter Solstice. Book 4 ends on day 96. The Wistram Days interludes are history and NPC notes only.
- **M10.0 door engine (save v13):** map objects get `when_flags`/`unless_flags` (hidden otherwise, must not be solid) and `portal: {to, pos, power_flags}`. `rules.portal`: `trips_per_day` 4, `minutes` 1, `line`, `dry_line`, `spent_line`. `core/portal.gd` `Portal.use` (via `Commands.portal`, use menu, or console `portal <object>`). `PlayerState` gets `portal_day`, `portal_trips`. Map `celum_stitchworks` holds Octavia's counter and the Celum end of the door. Both doors need `erin.magical_grounds`. Player gets 0 trips before it, then 4 a day.
- **Door facts:** 3.30 moves the Celum anchor from the Frenzied Hare to Octavia's shop and clears `albez_door.linked_to_frenzied_hare`; 3.33 Erin reaches Level 30 and the door can carry people daily. The only link in Book 4 is Liscor–Celum, free for anyone.
- **M10.1:** two scenes on day 85 (`floodplains_south` search, new map `dungeon_rift` with tile `chasm`). Spellings: `griffon_hunt`, Jawbreaker/Rockgaw (book spelling in `canon_ref.note`). Toren lives (weak, new sword). Rags's chapters are off-map.
- **M10.2:** 3.30 is day 89. Wistram story scene at the Hare, night 89. 8 Wistram NPCs. The old man on the road is Teriarch (flagged, not linked to the 1.00 Dragon).
- **M10.3:** classes/skills added: `magical_innkeeper` (threshold 400, prereq `erin.magical_grounds`), `inn_magical_grounds`, `inn_field_of_preservation` (effects empty, guesses). Erin's schedule gets an Esthelm `off_map` goal. `Stage.place_npc` does not move an NPC already in the area. Flag `erin.home_at_the_inn` replaces the old Erin location flags on day 91.
- **M10.4:** the Rock Crab fight scene (day 93, Erin and Lyonette allies). Esthelm slime scene moved to day 92 so Erin is home before dawn on 93. Valceif dies on day 93. Dependency chains are cut on purpose so one dead NPC does not cancel a whole day.
- **M10.5:** two scenes: Santa thieves in Liscor market (day 94, allies come 30 s late) and Erin in the snow on Christmas night (day 95). Enemy `liscor_house_thief`. Ryoka reaches Riverfarm night 94, leaves day 96. Brunkr's hand stays infected. Hook counts: 24 → 30 across the batches.

## ADR 0018 — M11 graphics, character sprites and animation
2026-09-27 · Accepted

- **Look:** 2D top-down pixel art, 32×32 tiles, characters about 32×48 (LPC frame 64×64). Not 16 px, not 3D. Art from free LPC packs plus our own edits; no AI art. Every file gets a `CREDITS.md` line (LPC is CC-BY-SA 3.0 / GPL 3.0 / OGA-BY by part).
- Core and saves do not change (no save bump in M11). `WorldView.TILE` is 32, camera zoom 2. Missing art falls back to coloured squares.
- **Characters are baked by `tools/build_sprites.py`** (Pillow) into `game/assets/characters/<id>.png`, not layered at run time. Sheet layout v2 is 768×1088: 64 px rows walk 0-3, hurt 4, idle 5-8, then a 128×128 attack block (4 rows × 6 frames). Creatures are baked by `tools/build_creatures.py`.
- **Data:** `tiles.json` entries get `sprite`, `prop`, `winter_sprite`, `winter_prop`, `edges`, `z`. New `data/objects.json` maps object `kind` to `{sheet, region, frames, winter_region, light, sound}`. New `data/appearance.json`: `{schema_version, looks:{id:{body, skin, parts, confidence, note}}}`. Look ids: NPC id, enemy type, `player`, `race_<race>` (generic), and creature looks `{creature, ramp, hue, sat, val, light, die, ...}`. Colour `all.lpcr.<name>` and parts `innworld_extra_arms`, `innworld_antennae`, `innworld_mandibles` are our edits. Colours not in the text are `"confidence": "guess"`.
- **Terrain edges are done in code** (`world/ground_art.gd`, `GroundArt.plan`), not Godot terrain sets. z order: chasm 8, snow wall 7, water 6, shallows 5, tall grass 4, grass/snow 3, dirt/cave floor 2, cobble 1.
- **Animation:** `AnimDiff` (`world/anim_diff.gd`) compares snapshots and yields move/hit/fall/gone/swing events; swings are read from state because core records no attacker. Hit flash, damage numbers, fall pose, fairy bob. Nothing blocks input.
- **All 36 (later 44) enemies have sheets**, tested by `unit_monster_art`. Every NPC with a schedule needs its own look (`unit_art`).
- **Atmosphere (M11.5):** `world/atmosphere.gd` with day/night tint, indoor room light, `PointLight2D` from a kind's `light: {color, radius, energy, flicker}`, falling snow in winter. Flicker is a fixed wave (no RNG).
- Known limits: sizes (Hobs, Soldiers) not drawn; buildings are flat brick; no shells on Antinium, no Toren eye-flames.

## ADR 0019 — M12 audio: music, sound effects and ambience
2026-09-27 · Accepted

- Audio is presentation only; no save change. Volumes live in `user://settings.cfg` (not `GameState`). No randomness: variants play round-robin with a fixed pitch table. Bad or missing cues give silence and one warning.
- Sources: CC0/CC-BY packs plus `tools/build_sfx.py` (standard library only, makes UI blips and chimes). No AI audio. Budget about 60 MB (raised from 40); audio is about 56 MB at the end. Music `.import` files have `loop=true`.
- **Buses:** Master with Music, Ambience, SFX, UI (`game/default_bus_layout.tres`). Autoload `ui/audio.gd` (`Audio`) with cross-fade (1.5 s), effect pool of 8, UI player.
- **Data `game/data/audio.json`:** `sounds`, `music`, `moods` (`by_map`, `by_location`, `default`), `mood_tracks` (day/night/winter_day/winter_night with fallback), `states` (title, fight, battle, scene), `moments`, and cue maps `footsteps`, `actions`, `combat`, `pages`, `ui`, `ambience`, `enemies`. `AudioDb` validates it; `AudioSettings` stores volumes; Options menu has sliders and mute.
- **Cues:** `world/sound_cues.gd` maps AnimDiff events, ground tiles, actions and System page kinds. Each cue plays at most twice per change (`MAX_SAME`). Gnolls, Goblins and Antinium use human pain sounds, not barks.
- **Music pick** (`world/music_pick.gd`): moment > battle > fight > scene > place mood (day/night/winter) > default. Night is `Atmosphere.darkness` ≥ 0.5.
- **Ambience:** `ambience` has `by_map` and `beds`; object loops via `objects.json` `"sound": {cue, radius}` placed as `AudioStreamPlayer2D` (`Audio.place_loops`). Loops are cut with a scratchpad script (not in repo).
- **9 canon moments** (lament, undead_siege, faerie_night, heavenly, stage_play, last_stand, christmas). `SystemMessages.news_deaths` plus `pages.death` plays the `sad_sting` when the news page reports a death with news.

## ADR 0020 — M13 Book 5 (The Last Light)
2026-09-28 · Accepted; M13.0–M13.7 done

Book 5: 37 chapters, about 439k words, runs about day 97 to day 114. Event ids use `b5.`; `CanonDb` loads `book5/` with no code change. Seven canon batches, one branch each. Hive stays off-map. Flos history (4.00K–4.05K and the Trey half of 4.06) is history notes only (it clashes with Book 2 dates).
- **Approved schema changes:** exit `id`/`when_flags`/`unless_flags`; map `traps`; `rules.traps`; enemy `look` (borrow another enemy's art); save v14.
- **Gated exits (M13.0):** a hidden exit is plain floor for movement, pathfinding, monsters and NPCs. `MapDb` has `exit_on`, `exits_on`, `raw_exit_at`; validators use raw exits. A gated exit needs a unique `id` and an ungated way back.
- **New maps:** `inn_upper_floor` (7 paid beds, 8c; opens with `wandering_inn.third_floor_built`), `inn_watchtower`, `liscor_depths`, `liscor_crypt` (no leech pool; a leech wall). Rift ropes open with `liscor_dungeon.new_section_found`. New enemies: `crypt_worm`, `giant_leech`, `shield_spider`, `cave_goblin` (look `goblin_grunt`), `not_gnoll`.
- **Traps (M13.T, save v14):** `core/traps.gd`. Map `traps` items `{id, at, name, damage, hidden, spot, disarm, once, rearm_minutes?, drop_to?, line?, when_flags?, unless_flags?}`. Uses `rearm_minutes`, not days. Found armed traps block the player; monsters and NPCs ignore them. Actions `search_for_traps` (10 min) and `disarm_trap` (15 min). `CombatState.traps` stores `"<area>/<id>"` changes only. All rolls use the seeded RNG. 9 traps in the depths (damage numbers are design values).
- **M13.1 (days 97–100):** Magnolia's gathering is day 97 (guess); Flos's timeline conflict is flagged, not fixed. Erin's magic soups are flags only, no items. Three scenes on day 100.
- **M13.2 (days 101–102):** new dungeon section opens night of day 101. Safry and Maran are flags only until M13.3. New NPC `ilvriss` with schedule and look. Team Vuliel Drae (5 NPCs). Door conflict flagged: the text gives about 50 round trips and 8.2 h recharge; we keep 4 trips a day.
- **M13.3 (days 101–111):** 4.16 "Day 59" = game day 103 (offset +44). Strongheart farm is a location only. Drassi and Ishkr get schedules from day 104. Ryoka and Mrsha away at the farm from day 106 until M13.5.
- **M13.4 (1.02D–1.06D, days 77–90):** Geneva arc squeezed into 14 days, off-map, no scene or hook. 15 core NPCs.
- **M13.5 (4.18–4.23E):** Ryoka and Mrsha home on day 106. Laken's Day 55–70 squeezed into days 111–118 (later replaced by ADR 0028). Fight on the Floodplains day 109 (our rift is south of the Floodplains; the text has it north of the inn).
- **M13.6 (4.24–4.27H):** winter handled in M13.7. New map `esthelm_creler_cave`, enemies `creler_hatchling` and `creler_juvenile`. Regrika at Liscor is Venitra in disguise (flag `venitra.disguised_as_regrika_blackpaw`, no Regrika NPC).
- **M13.7 (4.28–4.31, days 111–114):** Imenet merged into Ijvani (NPC `imenet` removed; `ijvani.disguised_as_imenet`). Brunkr dies day 111, Ulrien day 112. Ryoka dies and is revived the same night (`kill` then `revive`); she leaves north on day 114. Ivolethe is a flag (`ivolethe.banished_by_the_faerie_king`), not a death. Winter ends (clears `izril.winter`, `frost_fairies.abroad`). Enemy `regrika_blackpaw` (hp 90, armour 6, escapes below 75%). Lyonette and Mrsha shelter in Celum. Enemy types total 44; hook count 48.
- Rule kept throughout: link two entities only where the text says so (Imenet/Ijvani, Regrika/Venitra were stated outright).

## ADR 0021 — M14 engine works (inn play, living world, UI skin, balance)
2026-09-28 · Accepted (sub-steps M14.0 to M14.8 added 2026-09-28/29)

Books 1-5 were data, art and audio were done. Gaps: the inn earned no coin, cooking gave XP but no food, the player held one item, nothing read `WorldState.relationships`, 180 of 223 NPCs had no schedule, NPCs could not be attacked, the UI was default Godot, max HP never grew. One milestone, nine sub-milestones, one branch each.
- **M14.0 Bag:** bag stays `EconomyState.bag`, hand stays `PlayerState.held`. A good may name an `items.json` item with `item` (one item, at most one good). New `Economy.hold_good`, `stow`, `drop_good`; `ui/bag.tscn` on key I. No save change.
- **M14.1 Cooking:** new `data/recipes.json` (schema 1: `action`, `inputs`, `outputs`, `stations`, `confidence`), loaded by `EconomyDb`, new `core/cooking.gd`. Runs after a done action; no station or inputs means practice only. Four guessed recipes (simple meal, stew, pasta, bread). New ingredient and dish goods; dish sell price is the base for serving income. Prices are placeholders.
- **M14.2 Guests and serving (save v15):** `GameState.inn` (`core/inn_state.gd`: reputation 0..100, guests, income_today, guests_today, served_total, meal, served_npcs, next_id). Patron = `{id, area, race, look, seat, order, arrive, until, paid}`; one `until` deadline replaces a separate patience field. New `rules.inn` block (meals, guest curve, flag bonuses, races, pay, reputation steps), validated by `Guests.validate`. Inn opens at `wandering_inn.open`, closes at `.destroyed`, reopens at `.rebuilt`.
- Patrons are rolled once per meal with their own `Rng` seeded from game seed + meal key, so the main random stream is unchanged. Map objects may list `seats`. `Commands.serve`: pay = dish sell price x 2 (wrong dish half), reputation +1; an ignored patron costs -2 only if the player is in the room. Canon guests (goal `eat` / `visit_inn`) take any dish at full pay once per meal slot. Test: `sim_inn_service`.
- **M14.3 Standing (save v16):** `WorldState.reputation` (town or faction id -> int) and `WorldState.contact` (NPC id -> last contact day; added so relationships can fade). New `core/standing.gd`, `rules.standing`. First talk of the day: town +1, faction +1. Night step 7: relationships with no contact for 7+ days move 1 toward 0 per night; reputations move 1 toward 0 every third day. Regard = relationship + faction rep / 10 picks the greeting band. Shop prices shift by town rep x 0.004 (max +-20%). Friends (regard 10+) fight as allies in `NpcReact`. A quarter of Liscor's rep counts toward the inn's guest curve.
- **M14.4 Schedules:** 13 NPCs got guessed schedules (Liscor: tkrn, jeiss, dreshhi, culyss, gazi_pathseeker; Celum: grev, hess, octavia, agnes, maran, safry, eterell; Esthelm: umbral), flag-steered by canon flags. Rule: only NPCs with a place on an existing map. Tkrn and Jeiss visit the inn only after `wandering_inn.adventurers_attacked_goblins` (otherwise they killed the day-28 adventurers in `sim_inn_brawl`). `princess_thief` and Lyonette stay separate until the text links them.
- **M14.5 Attack NPCs (save v17):** `core/brawl.gd`, `rules.brawl`, `Commands.attack_npc`. "Major" NPC is derived (named in a pending canon event's `prefer` or `requires.alive`). First attack on a major NPC returns `warn` and shows the "Thread of Fate" page; flag `fate_warned.<npc>` is saved. A blow is one turn; at 0 HP the NPC is dead (`Director.player_kill`), no XP. First blow sets roster field `hostile_day` (migration sets 0); hostile NPC hunts the player until the day ends. Witnesses: victim -5, witnesses -2, town -3, faction -3; a kill adds -5 each. Not done: bystanders fleeing, hostile NPCs following across maps; console `kill` stays instant.
- **M14.6 UI skin:** `game/ui/theme.tres` is the project theme (brown panels, tan border, gold focus). Blue System-voice colour kept on purpose. Test: `unit_ui_theme`.
- **M14.7 Portraits:** `world/portrait.gd`; a face is an `AtlasTexture` over the front frame of the baked sheet, `Rect2(16, 8, 32, 32)` drawn at 96 px. Shown in the use menu and System dialog. No core or save change. Test: `unit_portrait`.
- **M14.8 Balance:** probes `sim_balance_progress`, `sim_balance_money`, `sim_balance_fights`. Only change: `rules.combat.hp_per_level` = 3 (level 5 = 35 HP, level 20 = 80 HP; 2 was a coin flip vs three Goblin grunts, 4 too easy). Max HP is computed, not stored, so no save change. XP, level cost, prices and the guest curve were left alone.
- Decision: the Rock Crab (beats a fist-only level-5 player) and the day-21 raid (not winnable by one player) stay as they are.

## ADR 0022 — M15-M17 from the first play report
2026-09-29 · Plan accepted; order M15 -> M16 -> M17

The first play test gave eight problems: curly font, "Day 8" at start and a huge HUD log, bad rock/cliff/water art, unlabeled doors, empty and flat cities, tiny city maps, XP numbers on screen, and a wish for XCOM-style grid combat.
- **AP model (user's own):** base 6 AP/turn; 0.25 AP per tile; at most 1 AP (4 tiles) of movement per turn unless a class or Skill raises it ([Runner]: 2 AP). Normal attack 2 AP; Skills 1-10 AP; spells 1-10 AP plus 1-10 MP. MP persists between fights. +1 AP at total level 10, 25, 50, 75. Turn order by Agility. A fight covers the whole map area. AP is stored in quarter points (6 AP = 24) so replays stay exact. One round = 6 s of world time.
- **Total level is secret:** no screen shows it and the AP gain is silent. Ryoka's level-cap theory (2.41) is the basis: level cost follows total level, cap near 100. Implemented later in M17.7.
- **Day shown to the player:** `Clock.player_day(canon_day, rules.clock)` = calendar day - (`start_minute` / 1440); arrival is Day 1. Core, director and saves keep the canon day; the debug console prints calendar days. No save change.
- **Font (M15.0):** Pixel Operator (CC0), `PixelOperator.ttf` + Bold, with `CC0-PixelOperator.txt`; Pixelify Sans removed. Font sizes must be multiples of 16 (`unit_ui_theme` checks). World labels draw at 32 and scale down by 3 (`WorldView.NAME_FONT_SIZE`). `TextSettings` keeps `large_text` in `user://settings.cfg`; `Session.set_large_text` sets the theme `default_font_size` (16 or 32). No stretch mode in the project.
- **HUD log (M15.2):** `Hud.LOG_LINES` = 3, bottom left, fades after `FADE_AFTER` 6 s over `FADE_TIME` 1.5 s; `Hud.history()` keeps 500 lines (presentation only). New `ui/text_page.tscn` (`TextPage`) used for the message log (L) and help (H). Key list moved to `SystemMessages.KEYS`.
- **No XP shown (M15.3):** action lines, the class lines on the sheet, "Total level" and the XP wording are gone from player screens. The debug console and the saved class XP stay. Test: `unit_no_xp_shown`.
- Schema changes approved for the plan: object `sign` (M16.3), `rules.combat.tactical` (M17.0), encounter state + save v18 (M17.1), skill effects `combat_action`/`ap_mod`/`move_ap_mod` (M17.4), `data/spells.json` + MP + save v19 (M17.5), cover on tiles and objects (M17.6), enemy `abilities` (M17.7).
- Risks noted: M17 changes every fight test (a full port in M17.2); M14.8 balance numbers get redone in M17.7; new art must stay LPC-compatible and licences go in `CREDITS.md`.

## ADR 0023 — M16.0 art audit and M16.1-M16.3 results
2026-09-29 · Done (audit list, then M16.1, M16.2, M16.3)

The audit rendered all 20 maps in summer and winter and listed 25 problems. Root causes: one `rock` tile did three jobs (prop, cliff, wall); one `building` tile was a single brick cell; doors were bare floor cells; water had one tile; each city was 2-3 yard maps. Fixes are art in `tiles.json` / `objects.json` plus map edits. No core or save change.
- **M16.1 (nature):** tile field `cliff` / `winter_cliff` = `{sheet, block [x, y]}`. New tiles `cliff` (earth) and `stone_cliff` (caves); `GroundArt.cliff_piece` picks rim/top/face/side from the cell's place in the wall mass. Art in `game/assets/tiles/cliffs.png` from `tools/build_cliffs.py`. `rock` is now one grey rock; new `boulder` tile. `shallows` uses the water ground plus a stepping-stones prop. Water freezes in winter; cliffs get snow tops. `dead_tree` is drawn by `tools/build_objects.py`. `GroundArt.edge_pieces` and `mix` fix corner/tail problems (rift tips, tall grass). Pines still carry no snow (no art).
- **M16.2 (buildings):** tile field `house` / `winter_house` = `{sheet, block [x, y], group, door, see_through}`. Art `game/assets/tiles/houses.png` from `tools/build_houses.py`. Touching cells of one block+group form one house; `GroundArt.house_piece` picks roof/wall/door pieces. Tiles: `building`, `building_b` (Drake stone, Liscor), `brick_house*` + `brick_door` (Celum), `plain_house*` + `plain_door` (villages, inn), `ruin_wall`. `_b` tiles start a new house next to the same style. Inn on `inn_hill` is now `plain_house`. `unit_ground_art` fails if a tree stands within 4 cells below a house or city wall.
- **M16.3 (signs):** optional `sign` = `{"icon": <key of objects.json "signs">, "text"?}` on a map object and on an exit; not read by core, `unit_sign_art` checks shape. Art `game/assets/objects/signs.png` from `tools/build_signs.py` (`--check` compares it with the `signs` table). `SignArt` (`game/world/sign_art.gd`) is pure: unsigned exits get an arrow plus "To <map>" label; label fades full within 2 cells, gone at 4. New object kind `plaque` ("A private home", "Closed"). Yellow exit tint removed.
- Kept as good: trees, ground edges, bushes, campfire, interior floors and furniture.
- Later changes noted: side doors have no art; Liscor/Celum big roofs rebuilt in M16.4/5; interior windows moved to M16.6.

## ADR 0024 — M16.4 Liscor districts
2026-09-29 · Done

Liscor was two yard maps. It is now 6 street maps and 7 rooms (13 maps).
- Ids `liscor_gate` and `liscor_market` are kept (events, schedules and about 25 tests use them). New: `liscor_plaza`, `liscor_guild_street`, `liscor_watch`, `liscor_homes`, joined by exits from `liscor_market`. Streets "go on" by running to the map edge (no invisible wall). Doors face south only, so enterable buildings sit on the north side of east-west streets.
- **Schema (approved):** optional map field `crowd` = `{"lanes": [{"path": [[x,y],...], "walkers": n, "looks": [...], "hours"?: [from, to]}]}`. View only (`game/world/crowd.gd`); walkers never enter `GameState`. `unit_crowd`: lane cells walkable and free, looks have sheets, max `Crowd.MAX_WALKERS` (12) per map. Walkers move one cell per 0.7 s real time, default hours 6-22.
- Rooms: `liscor_adventurers_guild`, `liscor_mages_guild`, `liscor_watch_barracks`, `liscor_watch_office`, `liscor_tailless_thief`, `liscor_gnoll_tavern`. Guild/Watch/tavern doors are signed exits.
- Guessed schedule additions in `npc_behaviour.json`: Selys at the Guild desk 8-12 and 13-18; Zevara in the office 9-18; Beilmark at the Watch desk 14-22; Klbkch writes the ledger 21-24; Relc eats at the guards' table 12-13; Krshia eats at the Gnoll tavern 19-21; Ilvriss eats at the Tailless Thief 20-22 from day 97.
- Merchants' and Runners' Guilds are signed and closed (the text does not place them). No west/north/south gate, no Terbore/Tekshia/Peslas (no look sheet), no playground, no upper floors.
- Test lesson: a sim that parks the player in a doorway blocks NPCs leaving the room; park away from doors. Tests: `unit_liscor_map`, `sim_liscor_rooms`.

## ADR 0025 — M16.5 Celum districts
2026-09-29 · Done

Celum went from two yard maps plus three rooms to 6 street maps and 3 rooms (9 maps). Four new streets, existing rooms furnished.
- All `celum_*` ids kept. `celum_square` stays the hub; the Runners' Guild, Frenzied Hare and Stitchworks doors moved onto streets. Three new exits from the square: north gap (15-16, 0), west edge (0, 9-10), east edge (31, 10); the off-map arrival cell (31, 9) stays free.
- New maps: `celum_main_street`, `celum_stitchworks_street`, `celum_hare_street`, `celum_poor_quarter`. Crowd lanes on every street.
- Rule: an exit rectangle wider than one cell shifts `arrive` by the cell offset, so `arrive` must be free floor for every exit cell.
- `stitchworks_door` became a `plaque` object with `sign: {icon: none}` (empty sign) so the door does not draw twice.
- Rooms keep size, door cell and all objects (schedule and stage spots like Stenei (10,2), Octavia (4,2), Agnes (6,3) still valid); only furniture added from existing kinds.
- Mage's, Adventurers' and Merchants' Guilds stay signed and closed; no Reinhart mansion, second gate, or Hare upstairs. No schema or core change.
- Test lesson: `ToyMaps.walk_to_area` is one hop; tests now walk square, street, room. Tests: `unit_celum_map`, `sim_celum_rooms`; `sim_celum_start`, `sim_celum_trip`, `sim_erin_in_celum` walk the extra hop.

## ADR 0026 — M16.6 the other maps
2026-09-29 · Done; one full-suite run (118 scripts, 1101 tests) found one failure, fixed

Finished the audit: gates, Esthelm ruins, inn hill, ruins entrance, interior windows, caves. No core, save or schema change.
- **Gates:** `celum_gate` gets two stone towers and a "Gate fee" plaque; `liscor_gate` gets two gatehouses. Both gate exits signed.
- **Esthelm ruins:** four refugee shacks (plain houses) with "Refugee shelter" plaques; the green square became cobble.
- **Inn hill:** only a "No Killing Goblins" board plaque at (14,12) and a "Ford" plaque on the floodplains. No stable, fence or well (not in the text).
- **Ruins entrance:** fence and iron gate kept; ditch (`chasm`) at x=9 and x=22; two Watch tents (guess). Road camp: signed exits and a cart.
- **Windows:** new tile `wood_window` (`game/assets/tiles/windows.png`, `tools/build_windows.py`) in the top wall of 11 rooms, spacing 4, never above an object or beside an exit.
- **Caves:** new object kinds `cobweb`, `bones`, `glow_mushrooms` (small blue light), 19 props.
- Lesson: a shack placed 3 cells from the siege player's spot (8,6) broke `sim_esthelm_siege`. Keep decoration out of a stage map's fight lanes (siege `from` cells (10,6), (15,21), (29,11), (26,16)). A plaque on a house wall needs a free cell next to it (`unit_map_db`).
- Tests: `unit_other_maps` (positions schedules and stages rely on stay free). Left: pre-fall Esthelm rooms, windows on side walls, tall Liscor gate wall, snowy pines.

## ADR 0027 — M17 tactical combat (XCOM-style)
2026-09-30 · Approved; M17.0-M17.9 done (M17.9 on 2026-10-05)

Replaces the M5 world-time fights (ADR 0010: one command = one 6 s turn, monsters act by `act_seconds`) with rounds, AP and turn order. Moves are 4-direction steps; melee is side by side.
- **Numbers (`rules.combat.tactical`):** `ap_base_q` 24, `move_cost_q` 1, `move_cap_q` 4, `attack_cost_q` 8, `block_cost_q`/`throw_cost_q` 8, `item_cost_q` 4, `ap_total_levels` [10,25,50,75], `round_seconds` 6, initiative = `speed` stat (shown as Agility), `monster.move_cap_q` 4, MP regen 1 per 10 min and full refill on sleep. AP does not carry over. Monsters get optional `agility` in `enemies.json` (default from `act_seconds`: 4 s -> 5, 6 s -> 3, 8 s -> 2).
- **Encounter life:** starts when a monster goes hostile, a brawl starts or a fight stage runs; includes all hostile monsters, helpers, fighting NPCs and the player on the map. Order rebuilt every round (late arrivals join next round); ties by a seeded roll. One 6 s world-time step per round, after the last fighter. Ends when no hostile is left, the player leaves, or the player is knocked out.
- **M17.1 (save v18):** `core/encounter.gd`; state in `gs.combat.encounter` (`round`, `order`, `tie`, `turn`, `ap_q`, `moved_q`). `Commands.move/attack/end_turn`; `wait` ends the turn. Switch `rules.combat.tactical.enabled`; toy dbs pin it off and `ToyCombat.tactical(d)` turns it on.
- **M17.2:** enabled in real data. Block/throw/take/drop/hold/stow take AP and no world time; the turn ends itself when AP left pays for nothing; a guard lasts until your next turn. NPC fighters are in the order as `"npc:<id>"` with `initiative.npc_default` 3. Optional `tactical.monster.ap_q` (0 freezes monsters in tests). Test helper `test_support/fight_bot.gd` (`FightBot`).
- **M17.3 screen:** read-only helpers `Movement.can_enter`, `Encounter.reach`, `Encounter.plan_to`, `Combat.player_hit_chance`. `CombatState.turns` (turn log for replay) is not saved. `ui/combat_bar.tscn`, `world/combat_overlay.gd`, camera replay of each fighter's turn (off headless). Mouse works only in fights.
- **M17.4 Skills (save v19):** skill effects `ap_mod {value_q}` and `combat_action {kind: strike|area|self, ap_q, cooldown, ...}`; class field `combat.move_ap_mod_q`; NPC `combat.skills` with `after_event`/`until_event`. `core/combat_skills.gd`. Cooldown in rounds, ticked at round start. Only Book 1-5 Skill names used ([Power Strike] now x2, [Lesser Stamina] +1 AP, [Unerring Throw], [Quick Strike], [Triple Thrust], etc.; guesses flagged). Lore flag: the game's [Tavern Brawling] is [Bar Fighting] in the Book. Skill bar `ui/skill_bar.gd`, keys 1-9.
- **M17.5 Mana and spells (save v20):** `PlayerState.mp`, `mp_minutes`, `progression.spells`, `encounter.npc_mp`. Max MP = `per_intellect` 2 x Intellect + `per_level` 1 x total level + class `combat.mp_bonus`; new base stat `intellect: 3`. `core/mana.gd`. `data/spells.json` (`SpellDb`): shapes `one`/`line`/`blast`/`around`, `ap_q`, `mp`, `damage`, `hit` (auto/roll), `cooldown`, `learn {teacher, after_event, minutes, book}`. Damage = roll + Intellect/3 - armor. Learn from a teacher (`Commands.learn_spell`, action `study_spell`) or a spellbook good (`"teaches": <spell>`). First spells: [Ice Spike], [Flashfire], [Frozen Wind], [Fireball]; all numbers and teachers are guesses. [Mage] class needs flag `player.knows_spell`. NPC casters (Ceria, Pisces) have `mp` and `spells` in `combat`. Spells hit foes only.
- **M17.6 cover:** no save change. Levels `none/half/full/wall` on tiles (`cover`), map objects (`cover`) and `rules.combat.tactical.cover.kinds`. `core/cover.gd`. Walls block sight for throws and `one`/`blast` spells. Half cover -15 and full cover -30 points on ranged hit chance only; melee ignores cover; pincer +15 points. `Combat.position_bonus` is the one hook. Monster shooters take cover; melee monsters close pincers. The shooter rule was first applied to every monster with a `ranged` entry, but the Goblin Chieftain then hid in the inn and broke `sim_m6_done`, so it is limited to monsters whose ranged top damage >= melee top damage. Two sims changed seed (`sim_big_battle` seed 4, `sim_inn_brawl` seed 5).
- **M17.7 abilities and balance:** `hp_scale` = 2.0 (player, NPC and monster HP; damage/armor/accuracy unchanged). Level cost now follows total level (`Levels.cost`); `rules.levels` gets `late_from` 10, `late_growth` 1.12, `total_cap` 100 (hidden; at the cap `level_up` stops). Enemy `abilities` in `core/monster_abilities.gd`: `shooter` and `leap {name, range, ap_q, cooldown}` (Ghoul range 4, 2 AP, cooldown 3; Shield Spider "Pounce" range 3, 1 AP, cooldown 2). No shell ability: Rock Crab keeps armor 4. NPC `agility` in the `combat` block (24 guessed values, e.g. Klbkch 7, Relc/Gazi/Ryoka 6, Erin/Bird 3, Zel/Toren 2). No save change. Probe: 3 Goblins stay a hard fight at level 5; raid still not winnable alone.
- **M17.8 hidden XP (no save bump, waived):** `xp = base x intensity x risk x novelty x conviction x outcome x skill x duress x window`. Fight duress from HP lost to foes (`rules.xp.duress`: floor 0.5, even_at 0.1, per_percent 0.01, cap 2.0; knock-out x1.9); the fight record keeps `peak` and `low` in per mille. XP windows live on canon events as `xp_window {boost 1-3, hours?}` (`core/xp_window.gd`; `rules.xp.boosts` 1=1.5, 2=2.0, 3=3.0), open only while the event is pending; first windows on `b1.skinner_leads_the_dead_into_liscor` and `b1.rags_kills_skinner` (boost 2, hours 18-6). Fighters level about 2x faster than inn workers; `rules.levels` was not changed.
- **M17.9 work duress:** optional `duress` entries on actions in `actions.json`: `{key, from, to, max}`, linear from x1.0, capped at 2.0, no floor below 1.0. `Xp.work_duress`. Crowd (`guests` 2->12, up to x2.0) on cooking/serving/dishes; cold (0->1, up to x1.5) on travel, chopping, foraging etc. A busy inn worker now reaches level 5 on night 10 (was 14). `sim_winter` fixed (Bird stood on a snow wall tile).
- Open: all cover, ability and Agility numbers are guesses; healers have no mechanic; windows for other big nights not yet added.

## ADR 0028 — M18 Book 6 (The General of Izril)
2026-10-01 · Accepted; M18.0-M18.7 built

Book 6: 26 chapters, about 280,000 words, days 114-130. Event ids use `b6.`. Far battles are news events, not stages (Invrisil, Laken, Rags, Tom in Rhir). The Hive stays off-map. Goblin guests cost the inn trade (`flag_bonus` -1 for `wandering_inn.goblins_in_residence`). The door does not change (new limits only in flags).
- **Calendar rule:** game day = Laken's journal day + 45, for every book. Firm anchors: Christmas (day 93), Zel leaves Liscor on day 127 (Laken Day 82), the battle of Invrisil and Zel's death on day 130 (Day 85). The tie to Liscor's first winter day (day 42, +22) was rejected because it breaks two firm links. Liscor day map: Zel leaves 127, party 128, Silver Swords 129, battle and death 130.
- **M18.0 event order:** chapter files may carry an optional top-level `order` (whole number >= 1, unique in the book). `CanonDb` sorts by `depends_on`, `window.earliest`, then rank `[book, order, place in file]`, then id. Books 1-5 have no `order` and keep their order (`unit_event_order` checks); a book mixing ordered and unordered files gets a validator warning. Book number is part of the rank so `b10.` does not sort before `b9.`. Not saved. Laken's Book 3 (16) and Book 5 (15) events moved to journal day + 45; ids unchanged. `sim_canon_book3` runs Laken's thread to day 91; `sim_canon_book5` ends on day 115.
- **M18.1 world:** maps `wirclaw_village`, `inn_basement` (trapdoor at `inn_interior` [14,11], gated by `wandering_inn.expansion_begun`), `liscor_ruins_hall` (through the ruins doors once `ruins.vault_found_looted`; illusion wall is an overlay removed by `liscor_ruins.hidden_chute_found`), `liscor_ruins_ossuary` (one-way chute; corridor back to `liscor_crypt`). The ossuary is in the Ruins of Liscor, not under the dungeon. No sewer map, no rat enemy. Enemy `eater_goat` (`leap` range 3, ap_q 4, cooldown 2; HP 22). 38 NPC records in `book6/npcs.json`. New `build_sprites.py` option: edit part `"paint": "#rrggbb"`.
- **M18.2-M18.7 canon:** 4.32 G + 1.02-1.05 C (march past the inn as a scene stage; Tom in Rhir off-map), 4.33-4.34 (Eater Goat fight stage at Wirclaw's village, feast stage; Bugear killed by event; Redfang five lodge in the inn basement), 4.35 E-4.38 B (Olesm's crypt search stage; Esthelm attack as news; Zel leaves through the door), 4.39 G-4.42 L (goblin party stage; Greybeard's reveal is flag `greybeard.is_greydath_of_blades`, id unchanged), 4.43-4.47 (Silver Swords stage; Erin level 33; Zel's speech), Antinium Wars Pt. 3-5, 4.48, 4.49 (Zel's death, mourning stage on day 130). No `xp_window` in any Book 6 batch.
- Zel's death event `b6.zel_names_the_goblin_lord_reiss_and_dies` sets `goblin_lord.named_reiss`, `world.believes_the_goblin_lord_killed_zel` (public belief) and `azkerash.and_the_chosen_killed_zel` (truth).
- Data fixes: Bugear's tag is `sword`; flag renamed `azkerash.lost_some_teleport_scrolls`; Oom, Bea, Kerash notes corrected in `book5/npcs.json`; Raskghar is the display name of enemy `not_gnoll`.
- Gotchas: a `keep_watch` hook has no location context, so hooks use talk or trap search; `sim_canon_book5` broke when 4.33 cleared the Celum shelter flags on its last day. Open: Magnolia's golem count (three in 4.26 M, two in Book 6) and the Rockfall Chieftain naming conflict. No save change in M18.

## ADR 0029 — Release builds (v0.1.0-alpha)
2026-10-01 · Accepted

First release: Windows and Linux, GitHub pre-release. Android skipped then (no touch controls).
- `game/export_presets.cfg` has "Windows Desktop" and "Linux" (x86_64, release). `include_filter="*.json"` is required because data is read with `FileAccess`. `exclude_filter` drops `tests/*`, `test_support/*`, `addons/gut/*`, `_scratch/*`. `embed_pck=true`; `modify_resources=false`.
- Version lives in `project.godot` (`application/config/version`) and shows on the title screen (`TitleMenu.version_text()`).
- `tools/release.ps1` exports to `export/` (gitignored), runs the smoke test, zips with `README.txt` (from `tools/release/README-PLAYERS.txt`), `CREDITS.md` and asset licences. Smoke test `tools/release/smoke.gd` runs with the editor exe and `--main-pack <exported binary>`; it checks data, textures, no tests in the pack, plays 5 nights, exits 1 on a problem.
- Zips use `tar.exe` (PowerShell 5 `Compress-Archive` writes `\` paths). Linux zip loses the exec bit, so the README says `chmod +x`. Export templates for 4.7.2 are installed locally, not in git.
- Release steps: bump `config/version` and Android `version/name` + `version/code`, run `tools/release.ps1`, tag `v<version>` on main, upload the zips and the Android `.apk` (every release carries the apk; ADR 0034). Alpha saves may not load in later builds.

## ADR 0030 — M19 Book 7 (The Rains of Liscor)
2026-10-07 · Accepted; M19.0-M19.8 built (to 2026-10-08)

Book 7: 22 chapters, about 286,000 words, days 133-143. Event ids use `b7.`; every chapter file has an `order` (40+ for Laken, 30-51 overall). Far threads (Laken, Tyrion's camp, Rags, Invrisil, Chandrar, Flos) are news only. No named deaths near the player. No Liscor sewer or graveyard map. No save change (SAVE_VERSION stays 20).
- **Decisions:** rains with a flood (inn hill stays dry); several door links plus a Pallass map; the moths are a fight stage with a tier-3 (x3) XP window; the dungeon dive is events only.
- **M19.0 engine:** portal object may hold `links: [{id, to, pos, name?, power_flags?, when_flags?, unless_flags?, hours?}]`; old `{to, pos, power_flags}` still loads. `Portal.links_of/open_links/link_open/link_powered/link_name`; menu action `portal:<link id>`; `Commands.portal(gs, db, object, link_id = "")`; console `portal <object> [link]`; optional `rules.portal.shut_line`. Trips stay one shared count a day. Rains: `rules.rains {season_flag: "izril.rains", flood_flag: "izril.flood"}`; `Rains.on/flooded`; rain streaks in `Atmosphere.rain`; rain sound variant `amb_rain` made by `tools/build_rain.py`. Flood is just map overlays gated on `izril.flood`. No rain duress. Tests `unit_portal_links`, `unit_rains`.
- **M19.1 world:** inn `albez_door` has links `celum`, `pallass` (flag `albez_door.anchor_at_pallass`, map `pallass_door_street`) and `liscor` (flag `albez_door.anchor_at_liscor_wall`, end on `liscor_watch`). Flood overlays on `floodplains_south`, `liscor_gate`, `dungeon_rift`, `inn_hill` (rows 16-23). Exits that would land on water are gated `unless_flags izril.flood` (`liscor_market` east gate, `road_camp` south road, `ruins_entrance` west road). Flag `wandering_inn.grand_theatre` opens the common room's east wall; `wandering_inn.watchtower_smashed` closes the tower ladder. Enemies `face_eater_moth` (flying `leap`) and `moth_swarm` (art via `tools/build_creatures.py`, source `moth`). `book7/npcs.json` (33 NPCs), `locations.json` (14).
- **M19.2-M19.4:** two scene stages for 5.00-5.03 (lunch day 133, Venim deal day 134); the rains start via `izril.rains` set by the deal event. The player does not walk into Pallass until day 137. 5.04-5.06 M: one stage (Players' play night, day 135). Records fixed: Toren, Wesle, Halrac, Mrsha. 5.07/5.08/Flos: moth stage `b7.face_eater_moths_attack_the_inn_and_liscor` (`inn_hill`, day 137, 13-20 h, 6-7 waves, `xp_window` x3 13-19 h); aftermath scene with a talk hook. Day 137 sets `pallass.embargo_lifted` and `albez_door.anchor_at_pallass`. Gotcha: a wave `from` tile must not be an exit; rain stopping at dawn is not modelled.
- **M19.5 Laken:** Laken journal Day 85-97 = days 130-142. `maps/riverfarm.json` (32x24) built with no exits (Riverfarm lies south-west of Invrisil, not on the Celum road; a road comes later from an Invrisil map). Banquet stage on day 142 with two hooks. Off-map place `north_izril`. Gap: no character sheets for these NPCs.
- **M19.6 flood:** `izril.flood` is set on day 137 so the water shows on the morning of 138; `albez_door.anchor_at_liscor_wall` set on day 138. Three scene stages (Soldiers' dinner day 138, victory party 139, Vuliel Drae confession 140); the quillfish fight is a pair of events. Gotcha: a seated guest can block `ToyMaps.walk_to` in a crowded stage.
- **M19.7 Zel and Selys:** two stages (Zel's funeral day 142 at `liscor_plaza`; lease haggle day 143 at the inn). Selys gets [Heiress] 4, then [Receptionist] 19 and [Heiress] 6. Locations only: `liscor_city_hall`, `liscor_sewers`, `pallass_archive`.
- **M19.8 Rags:** 21 events, days 141-143, all off the map and all guesses; no stage, hook or window. Locations `northern_swamp`, `northern_high_road`.
- Loose text ties kept as noted: funeral day is 142 by the event chain though 5.17 S says "a week ago"; Magnolia's banquet kept at Day 97 (day 142). Tests: `sim_book7_world`, `sim_book7_pallass_crisis`, `sim_book7_players_and_toren`, `sim_book7_moths`, `sim_book7_riverfarm`, `sim_book7_flood_and_parade`, `sim_book7_zel_and_selys`, `sim_book7_goblin_road`.

## ADR 0031 — Web build
2026-10-01 · accepted

- Third export preset "Web" in `game/export_presets.cfg`: same filters as desktop, `variant/thread_support=false` (no cross-origin headers needed, any static host works), `html/canvas_resize_policy=2`, no PWA.
- `tools/release.ps1` builds `export/InnworldRPG-v<version>-web.zip` with `index.html` at the zip root (itch.io and Pages need that).
- Web only in `project.godot`: `display/window/stretch/mode.web="canvas_items"`, `aspect.web="expand"`. Desktop is unchanged. Without it the HUD text was cut off in small windows.
- Title screen hides Quit in a browser (`TitleMenu.shows_quit`).
- GitHub Pages: `.github/workflows/pages.yml` does not build. On a published release it downloads the `*-web.zip` and publishes it. The `github-pages` environment needs a tag rule `v*` (added 2026-10-02), or run `gh workflow run pages.yml --ref main -f tag=v<version>`.
- itch.io: the same web zip is uploaded by hand.
- Browser saves live in site data; itch.io and Pages keep separate saves. First load is about 70 MB (pck 64 MB, wasm 40 MB).
- A custom domain later is a CNAME `play.<domain>` to `daddy-ousen.github.io` plus Settings, Pages, Custom domain. The workflow stays the same.

## ADR 0032 — Touch controls (M20)
2026-10-05 · accepted

- The game had no InputMap and about 10 scripts read raw keys. Fix: every command is now a named action in `project.godot` `[input]` (`move_n/s/e/w`, `wait`, `use`, `eat`, `bag`, `sleep`, `sheet`, `journal`, `log`, `help`, `back`, `block`, `throw`, `drop`, `stow`, `page_up`, `page_down`, `console`, `skill_1` to `skill_9`). Same physical keys as before. `InputNames.key_of` gives key names for UI text. Rejected: touch buttons sending fake key events (ties touch to key codes, blocks remapping).
- `ui/touch_controls.gd` in `TouchLayer` (CanvasLayer 2). Buttons send `InputEventAction` via `Input.parse_input_event`, so the game cannot tell touch from keys. Plain `Button`s with `FOCUS_NONE`; one finger at a time.
- Walking uses a floating stick on the left half (changed 2026-10-08, replacing the D-pad). It stays 4-way: stronger axis wins, a turn needs a 1.3x lead, dead zone 18 px. Off during fight turns and open panels. Wait is a separate button.
- Right side: Use, Bag, More, Menu. Back appears only with a panel open. Cancel appears above the column while a Skill is armed or a walk runs.
- `TouchSettings` (`user://settings.cfg`, section `touch`): Auto, On, Off. Auto shows after `is_touchscreen_available()` or the first screen touch (`Session.touch_seen`). Not game state, no save change.
- Fight taps: first tap shows the plan (path, hit chance), second tap on the same cell acts. A real mouse click acts at once.
- With controls shown: one tap picks an `ItemList` item; bag gets X and P buttons; Load list gets a Back button. HUD log moves right of the pad (`Hud.make_room_left`).
- Delete now also drops the held item outside the bag. Debug console is not touch-enabled.

## ADR 0033 — UI scale for phones (M20.3)
2026-10-05 · accepted

- One knob: the root window `content_scale_factor`. `ui/ui_scale.gd` (`UiScale`), mode Auto / 1 / 1.5 / 2, stored in `user://settings.cfg` (section `display`, key `ui_scale`). Options row "Menu size". Not game state.
- Auto: 2 on a touch screen with short side under 5 inches, else 1. Desktop without touch is always 1. `Session` applies it at start, on resize, and after the first touch.
- Map keeps its pixel size: world camera zoom is `2 / factor`. Touch pad also keeps its size (one box scaled by `1 / factor`). Rejected: zooming the map with the menus (too few tiles) and growing the pad (covers half the screen).
- `UiScale.keep_fit` limits Journal, Character sheet, Bag and text pages to the view minus 8 px. Journal focus list takes at most 30% of view height.
- Later change (M34.4, 2026-10-21, ADR 0045): on phone and tablet OS, map and pad grow by dpi (`UiScale.touch_grow`, `map_grow`; touch buttons at least 48 dp, map tiles about 40 dp). Desktop unchanged.
- Tests that fake a touch must call `Session.apply_ui_scale()` after resetting `touch_seen`.

## ADR 0034 — Android build (M20.2)
2026-10-08 · accepted

- Export preset `Android` in `game/export_presets.cfg`: arm64-v8a only, no Gradle (prebuilt template), package `org.daddyousen.innworldrpg`, no permissions, immersive mode.
- `project.godot`: `window/handheld/orientation=6` (sensor landscape) and `rendering/textures/vram_compression/import_etc2_astc=true` (export refuses without it).
- Debug build: `& $env:GODOT --headless --path game --export-debug Android ../export/android/InnworldRPG-debug.apk`, then `git checkout -- game/assets` because export rewrites `.import` files. Needs Android SDK (build-tools 34.0.0), JDK 17, 4.7.2 Android templates.
- Release APK is signed with `%USERPROFILE%\.android\innworld-release.keystore` (alias `innworld`), kept outside the repo; `*.keystore` is gitignored. Back it up: losing it means no updates. Export reads `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `_USER`, `_PASSWORD`; the preset holds no secret.
- Icon is `game/icon.png`, drawn by `tools/build_icon.py`. AAB for Play came in ADR 0037. Not yet played on a real device at this point.

## ADR 0035 — Breakthroughs (M22)
2026-10-09 · accepted

- Problem: `Levels.level_up` stops a class at 9 / 19 / 29 until the class id is in `Progression.breakthroughs`, and only the debug console set it. A breakthrough is now a key earned by a moment, not XP. Pure functions of `GameState` and data: no RNG, no new save data.
- A moment only counts while the class is at 9 / 19 / 29 with no key. The key is kept until XP fills. Class loss erases it.
- Source 1, hard moment (all classes): an action record that fits the class (`Tags.match_score >= min_match`), is not `fail`, and meets `need` of the bars risk / duress / window. `need` is 1 / 2 / 3 for level 10 / 20 / 30. Numbers in `rules.json` `levels.breakthrough`: `min_match` 0.5, risk 0.6, duress 1.8, window 2.0.
- Source 2, class trial: optional `breakthrough` block in `classes.json` (schema change) with `hint`, `default`, and `trials` (`action`, `outcome`, `min`, `at`). `default: false` means only trials count.
- Source 3, canon moment: hook result `"then": "boon"` plus effect `{"breakthrough": {"tags": {...}}}` or `{"class": id}`. Allowed in hook effects only, never in an event's own effects (`CanonDb` refuses it). With `tags`, the best-fitting held class is picked and nothing else is tried.
- Night order: step 2 `Night.resolve_xp` checks sources 1 and 2 before `level_up`; step 5b `Night.resolve_canon_keys` handles source 3 and levels up the same night.
- Player sees one hint line at 9 / 19 / 29 and `Breakthrough: [Class] can grow past level 9.` when earned. Debug console `breakthrough <class>` still works.
- Logic is in `core/breakthrough.gd` (`Breakthrough.validate` checks data). Trials added for innkeeper, cook, warrior, runner, mage, scout, priest, carpenter; six `boon` hooks added (hook count in `sim_player_hooks` 68 to 74).
- Consolidation (M22.3) is automatic at night step 4 once the player holds every `from` class, one is level 10 (`rules.offers.consolidation_min_level`) and the pool is full. New class starts at `best - level_cost` and needs its own key later. `ClassSystem.make_offers` lost its `kind` argument; `consolidate_ready` is new.
- Probe (M22.4, `sim_breakthrough_probe`, days 1 to 87): busy inn worker reaches level 10 around night 31; quiet worker waits for a Book 3 moment (night 73); fighter is fastest (night 17 to 22). Bar numbers stay as set.
- Rejected: random chance per night (unfair feel, hard to test); key by XP alone (capstone would be just a bigger number).

## ADR 0036 — Canon bends (M23)
2026-10-10 (Books 2 to 7 finished 2026-10-11) · accepted

- Problem: books 2 to 7 only had `cancel` in `on_fail`, so one dead NPC cancelled long chains (Erin's death cancelled 140 of 207 Book 2 events). Reports: `docs/divergence/report.md`, picks in `docs/divergence/picks.md`.
- Rules:
  1. `depends_on` only for a real cause. Story-order links are cut or replaced by flags. `sim_canon_book<N>` must stay at drift 0.
  2. Substitute (`fallback_tags` plus `substitute` first in `on_fail`) only when a local stand-in would clearly do the same thing. The director scores all NPCs, ties go to the lowest id.
  3. Mutate with a flag hand-off: a mutated event "never happened", so `_propagate` cancels its dependents. To keep a chain alive, dependents wait on a flag that both the canon event and its alt set, with `on_fail: ["delay", "cancel"]`, `delay_limit: 3`.
  4. Alt events carry `canon_ref.confidence: guess`, a note starting "Not in the book (M23.x, divergence only)", are `alt_only` and kill no one.
  5. Every day with on-map canon (an event at a location with a game map) gets at least one player hook, mostly `change`.
  6. One kill sim per book (`sim_kill_book<N>`): each key NPC dies on the book's first day; it checks ceilings for lost events and drift, threads that must continue, bends by name, and the hook-per-day rule.
- Engine changes (Director, no save change): an alt with a `mutate:` step whose window has not opened stays pending and runs on its own day. M23.2: a dependent also waits while a dependency is pending, even past its last day (`Director._wait_until`). Tests in `unit_director` changed or added.
- Book summaries (data only after Book 3):
  - Book 2: 19 hooks; substitutes (Klbkch for Ruins rescue, Relc for Selys's warning); mutates for the Horns, Goblin Lord, and Toren/Erin winter. Erin death: lost 140 to 109.
  - Book 3: 9 alt events, flag `horns_of_hammerad.out_of_the_pit`; Erin leaving Celum has three ordered mutate steps and sets `erin.on_wagon_south` / `horns_of_hammerad.bound_for_liscor` for Book 4. 13 hooks.
  - Book 4: trip-home chain split on flags (`erin.on_wagon_south`, `horns_of_hammerad.left_celum`, `erin.home_at_the_inn`, `erin.level_30`); 5 alts; flag `mrsha.met_the_free_queen`; `ryoka.heading_home_to_liscor` moved to Ryoka's replies. 4 hooks.
  - Book 5: few `depends_on` links, so work was alts and flags (`earthers.joined_the_last_light`, `bird.to_guard_the_inn`, `azkerash.servants_in_liscor`, `ryoka.seized_by_the_necromancers_servants`, `ryoka.revived_by_teriarch`). Substitutes Etretta and Ijvani; 9 alts; 4 hooks. The M23.0 report undercounts because it only counts `depends_on`; use a director run.
  - Book 6: many scenes ran with their cause dead, so real-cause flags were added (`zel.met_magnolia`, `zel.allied_with_magnolia`, `zel.speech_at_invrisil`, `goblin_lord.ordered_to_attack_invrisil`, `invrisil.battle_begun`, `redfang.survivors_met_erin`, `silver_swords.arrived_at_the_inn`). Loss counts for Zel, Magnolia, Goblin Lord, Erin went up on purpose. Substitute: Zevara for Olesm. 9 alts, 9 hooks. Riverfarm map got actions on the well (`carry_water`), scaffolding (`repair_furniture`) and trebuchet frame (`chop_wood`, `repair_furniture`).
  - Book 7: almost no `depends_on` or flag checks, so it was rebuilt on flags: flood and mourning no longer need Erin (`izril.rains`, `izril.flood`), Pallass door chain, `redfang.in_the_inn`, `wandering_inn.fought_the_moths`, `liscor.face_eater_moths_attacked`, `liscor.moths_driven_back`, `fourth_company.charged_the_walls`, `heartflame.selys_inherits`, `pallass.selys_kidnapped`, `riverfarm.hosts_the_northern_nobles`. Substitutes Relc, Ilvriss, Tekshia if Zevara is dead. 10 alts, 5 hooks. A Book 6 death now reaches Book 7 (Erin dying on day 114 loses 64 Book 7 events).
- Known gaps: drift counts later-book cancels at once, so a Book 2 death shows drift for Books 3 to 7. Event effects are not remapped for flags, so a substitute still sets the original flag (e.g. `erin.fought_in_the_ruins`). The old Zel-before-Invrisil gap was closed in ADR 0044: Book 7 mourning needs `zel.dead_at_invrisil`.

## ADR 0037 — Google Play preparation
2026-10-11 · accepted

- Play needs an AAB built with Gradle, target API 36. New export preset `Android Play` (Gradle, AAB, target SDK 36, arm64-v8a, same package and version as `Android`). The old `Android` preset still makes the GitHub apk.
- Plan: build everything now, upload only after the author says yes in writing (the fanworks policy does not name games; see `docs/DESIGN.md` section 7).
- `game/android/` (Gradle template) is gitignored. `tools/release.ps1` installs it if missing and sets `org.gradle.jvmargs=-Xmx2g` because the 4.5 GB default ran out of memory on a 16 GB PC.
- Play App Signing: Google holds the app key, our release keystore is the upload key. So the Play app and the GitHub apk have different signatures and cannot update each other.
- Store kit: `docs/PLAY_STORE.md`, `PRIVACY.md` (no data collected), `tools/build_store_art.py` (outputs to `export/play/`). Target audience 16+ to avoid Families policy.
- Each upload needs a higher `version/code` in both Android presets.
- With API 36, Android ignores the landscape lock on screens 600 dp and wider. Tablet check still open.

## ADR 0038 — NPC levels at low detail (M25.0)
2026-10-12 · accepted

- Canon NPC classes were fixed data (168 class entries on 144 NPCs; 140 have `"level": null`; only 57 names match a class id). `NpcLevels` (`game/core/npc_levels.gd`) now grows levels once a day; `Director.run` calls `NpcLevels.grow` after each day's canon events, including days before the player arrives. No RNG.
- Who: living canon NPCs with at least one class. NPCs with no class (Ryoka, Dragons, Erin until data gives her one) never level. Later-book NPCs start on their book's first day (`CanonDb.book_start`).
- XP: `rules.npc.levels.daily_xp` per day plus `event_xp` on a day a done / substituted / changed canon event cast the NPC by name; split evenly across the NPC's classes. Cost follows the player's curve (`Levels.xp_to_next(total level)`), and `levels.total_cap` applies. Totals are never shown.
- Capstones (10, 20, 30): a class waits until it has a key; being cast in a canon event while waiting gives it.
- A canon `null` level counts as `unknown_level` and readers get `"known": false`; data keeps `null`.
- Guess values in `rules.json` `npc.levels`: `unknown_level` 12, `daily_xp` 12, `event_xp` 50 (chosen from a probe over Books 1 to 6).
- State: `gs.world.npc_levels` (NPC id to class name to {gain, xp, key?}); only the change from canon is saved. Save v21; v20 to v21 migration adds an empty table.
- NPC levels do not change fight stats, skills, or add new classes yet (a new canon class would need an event effect, a schema change).
- M25.3 (2026-10-12): NPC row "Appraise" opens the NPC sheet (`core/npc_sheet.gd`, `NpcSheet.lines`) when the player holds the skill in `rules.npc.appraisal_skill` (`appraisal`). Unknown levels show `?`. No time passes, nothing saved.

## ADR 0039 — Talk topics (M25.1)
2026-10-12 · accepted

- `TalkTopics` (`game/core/talk_topics.gd`). On the first talk of the day with an NPC (`NpcSim.note_talk`), `Interact.perform` adds one topic line (`rules.talk.line`).
- Pool: world news of the last `rules.talk.news_days` days (`own` = cast this NPC, `town` = event in the NPC's town, `rumor` = T1 rumours anyone can pass on) plus topics from the new `game/data/talk.json`. Town is the nearest settlement at or above the NPC's canon `home` (`Standing.town_of_location`); an NPC with no home tells only own news, rumours and ungated topics.
- `talk.json` (schema_version 1): `topics`: id to {kind `news` | `rumor` | `request`, text, confidence, who?, flags?, not_flags?, days?, canon_ref?, note?}. `who` has `npcs`, `tags`, `towns` (any match). Validated in `DataDb.load_dir` via `TalkTopics.validate`. Request hints are `confidence: guess`.
- One weighted pick (`rules.talk.weights`) with `gs.rng`. An NPC with regard under `rules.talk.min_regard` (0) says nothing.
- Requests are hints only: no state, reward or save change. Real tasks may come with job boards (M25.2).
- No save change, but one extra RNG roll per talk with a canon NPC changes later rolls in seeded runs. Toy dbs have no `rules.talk` so toy worlds have no topics.

## ADR 0040 — Split the game screen script (M26.0)
2026-10-13 · accepted

- `game/world/main.gd` had reached 967 lines. It now has `class_name MainScreen` (499 lines) and keeps the commands and turn replay. No behaviour change; tests unchanged.
- Four `RefCounted` helpers made by `MainScreen._ready`: `MainInput` (`world/main_input.gd`: keys, held direction keys, fight mouse), `MainAim` (`main_aim.gd`: armed skill or spell, click walk, touch tap, turn overlay, plan), `MainTravel` (`main_travel.gd`: long-road prompt; `main.travel` still points to the node), `MainPanels` (`main_panels.gd`: panel focus `is_busy`, console, use menu, bag, touch pad and UI scale, message history, night pages, morning autosave).
- Members used by tests and other scripts stay on `MainScreen` and pass through to the helpers.
- Helpers hold the screen in an untyped `_m`. A typed `_m: MainScreen` makes a script cycle and Godot keeps the scripts alive at exit ("resources still in use").
- Rejected: helpers as child nodes (needs scene changes and `_process` order rules).
- New input or panel work goes in the helper that owns it.

## ADR 0041 — Split the world view script (M26.1)
2026-10-13 · Accepted

- `game/world/world_view.gd` had grown to 1285 lines. Goal: files under about 500 lines, no behaviour change.
- `WorldView` keeps its scene nodes, state, `setup`, `refresh` and `_process`. Four helpers take the rest:
  - `ViewArt` (`world/view_art.gd`): static only. Cell size, sheet files, tile sets, object art, node makers. Never names `WorldView`.
  - `ViewMap` (`view_map.gd`): ground and edge tiles, map objects, props, signs, crowd, animated objects.
  - `ViewMarkers` (`view_markers.gd`): NPCs, patrons, monsters, fairies, traps, HP bars, label rules.
  - `ViewEffects` (`view_effects.gd`): AnimDiff effects (`play`) and turn replay.
- The helpers are `RefCounted`, each holds the view in an untyped `_v` (as in ADR 0040) to avoid script cycles. `GroundArt`, `SignArt` and `CombatOverlay` now name `ViewArt`, not `WorldView`; otherwise Godot reports "resources still in use at exit".
- All public names used by other scripts and tests stay on `WorldView` (constants copied, static functions and `play`/`replay`/`skip_replay`/`is_replaying` pass through). Tests unchanged.
- Result: `world_view.gd` is 335 lines, the largest helper 345. New map art goes in `ViewMap`, markers in `ViewMarkers`, effects in `ViewEffects`. Fairies now bob on their own clock in `ViewMarkers`.

## ADR 0042 — Balance from player feedback (M27)
2026-10-15 · Accepted

- Problems reported from long play: levels above 5 too slow, consolidation needs a level-10 source class, selling many goods takes n times as long as one, one trip away makes Liscor forget the player.
- Level cost still follows total level (ADR 0022, M17.7); that rule stays. All numbers below are balance guesses, not canon.
- Levels (M27.0): `rules.levels.base_xp` 40 -> 30, `growth` 1.25 -> 1.2 (late growth 1.12 above level 10 stays). Level 10 costs 624 XP total (was 1032).
- Repeat penalty: `rules.xp.novelty.k` 0.35 -> 0.2, `floor` 0.1 -> 0.3. Fights keep their danger/duress bonus.
- Consolidation (M27.1): `rules.offers.consolidation_min_level` 10 -> 5. Level cost of a consolidation (2 or 3) unchanged.
- Trade many (M27.2): `Economy.buy/sell` take a count. n goods take `trade_minutes + trade_extra_minutes x (n-1)` (5 + 1 per extra) and make one action record. Use menu adds "Sell all N" and "Buy 5" (`rules.economy.bulk_buy`). Picks carry the count after `#` (`sell:herbs#10`, `Interact.trade_action` / `trade_parts`). Console: `buy|sell <object> <good> [n]`. New `rules.economy` keys are optional.
- Forgetting (M27.3): `rules.standing.decay_after_days` 7 -> 30, `reputation_decay_every` 3 -> 10.
- Sims (3 seeds): `sim_balance_progress` reaches level 5 on night 7 (was 9-10), total level 11 on day 22; `sim_balance_fighter` total 14-15 on day 22. Sim targets moved to match.
- No save change. If level 10+ comes too fast, raise `base_xp` first. Still needs a real play check.

## ADR 0043 — M28 Book 8 (Blood of Liscor)
2026-10-16 · Accepted

Book 8 is the Raskghar arc: Calruz, raids on Liscor and the inn, the dungeon, the three-door battle.
- Decisions: three fight stages (raid on Liscor and the inn 5.34, daylight raid 5.38, three-door battle 5.44), each with `xp_window`. Moon state is set by flags (no moon clock). Dungeon dive is events only. North thread (Laken, Tyrion, Rags, Reiss, Garen) is off-map news and events. Calruz is alive from Book 8 and is the same entity as in Book 1. Ryoka's masked swordswoman stays unnamed, no records. Event ids `b8.`, chapter `order` 52-77.
- Engine (M28.0): optional `rules.inn.race_boycott` `[{flag, race, factor}]`. `Guests.race_weights` multiplies a race's patron weight by `factor` (0..1) per set flag; `Guests.validate` checks it. No save change. Data: Drake, `wandering_inn.drake_boycott`, factor 0.15 (guess), set by `b8.ilvriss_storms_out_and_drakes_boycott_the_inn` (day 155).
- World (M28.1): enemies `raskghar_armoured`, `awakened_raskghar` (guess stats, Gnoll art stand-in). Map `raskghar_camp` (32x20 hall, doors `raskghar_door_north/west/east`, no exits, used only by the 5.44 stage). `canon/book8/npcs.json` (20 NPCs) and `locations.json` (4). Reiss is a name flag on `goblin_lord`, not a new record.
- Chapters: 5.21E-5.23G north (orders 52-54), 5.24L-5.26L Liscor (55-57; repair event, Lyonette's class loss and [Worldly Princess]), 5.27-5.29 (58-60; boycott, dungeon dive), 5.30G-5.32G north (61-63; siege of Dwarfhalls Rest, `laken.allied_with_tyrion`), 5.33B-5.35H (64-67; first raid stage), 5.36-5.38 (68-70; daylight raid stage, kill `fess`, abductions, Calruz revealed), 5.39-5.42 (71-74; kill `rebat`), 5.43-5.44 (75-77).
- Stages: 5.34 on `inn_hill` 21-24 h, 12 foes in 5 waves, hook `player_stood_with_headscratcher_after_the_raid` (hook count 128 -> 129). 5.38 on `inn_hill` 15-18 h, 11 foes, requires `raskghar.awakened_by_the_moons`. 5.44 on `raskghar_camp` 18-23 h, 12 foes in 6 waves. All `xp_window` tier 3; fighting never changes canon.
- Moon flags: `izril.moons_nearly_full` (5.34), cleared with `izril.moons_full` set on day 161.
- Entry to the camp: `inn_interior` `albez_door` gets a link to `raskghar_camp` (power `erin.magical_grounds`, `when_flags` `raskghar.camp_raid_failed`, `unless_flags` `raskghar.broken`). Camp door has a portal home; `rules.combat.knockout.wake` maps `raskghar_camp` -> `inn_interior`.
- Kills: `fess`, `rebat`, `cassa`, `vakk`. Nokha, Calruz, Erin, Ceria live. Calruz ends in the Watch prison. Captive flags clear in 5.44.
- Doubts kept as guesses: all Book 8 days (many marked guess), the 5.34 fight is mostly indoors in the book but staged on the hill, stage hours, Griffon Hunt members (lost member is Ulrien, not Corry), who forged the Riverfarm order.
- Rain: `izril.rains` and `izril.flood` stay on throughout Book 8.
- New sims: `sim_book8_world`, `sim_book8_north_one/two`, `sim_book8_liscor_one/two`, `sim_book8_raid_one/two`, `sim_book8_dive_one`, `sim_book8_battle_one`, `sim_kill_book8`.

## ADR 0044 — Player audit work (M29-M33)
2026-10-17 · Proposed; merging the plan PR approved the order. Each schema/save change was still asked at its step.

An audit of v0.1.5 found: no NPC voices, story as next-day news, no reaction to an Earther, off-screen or ignored climaxes in Books 6-8, early lore slips. Order: M29 lore polish, M30 voices and the Earther, M31 signposts and beats, M32 Books 6-8 climaxes, M33 depth.

Rules for all of it:
- One branch + PR per sub-step. Own words only (rule 10); lines carry `confidence` and a `canon_ref` where they rest on a book fact.
- A line that changes state picks with `gs.rng`. A display-only bark must not touch `gs.rng`; it uses a stable hash of (day, NPC id, minute bucket). Barks never change `GameState`.
- Signposts say what townsfolk could know, never the outcome. New logic lives in `game/core/` as `RefCounted`.

Save versions: v22 (M29.1), v23 (M30.5), v24 (M33.2).

**M29.0 System lines.** `core/system_voice.gd` (`SystemVoice`) builds every System line in the book style ("[Innkeeper Level 2!]", "[Skill – X obtained!]", "[Conditions Met: ... → X Class!]"). Own forms: "[X Class Offered!]", level fade, "[X Class Lost.]", "[Breakthrough: ...]". The action `talk_with_guest` shows "Talk" (id unchanged).

**M29.1 Inn name, signs, first guests.** Optional `names: [{flag, name}]` on a canon location (`CanonDb.location_name`): "The abandoned inn on the hill" until `wandering_inn.named`, then "The Wandering Inn". Optional `rules.inn.patron_flags` (no patrons until ANY flag set: `wandering_inn.has_regulars` from `b1.inn_first_regulars`, or `wandering_inn.full_house`). Optional `rules.inn.race_flags {race: flag}` (Goblin patrons weight 2 from `goblin_tribe.paying_guests`). Save v21 -> v22: old saves where `b1.inn_first_regulars` already ran get `has_regulars`.

**M29.2 Liscor wary of Humans.** Optional `rules.standing.race_regard` `[{town, race, start, fade, price?, shops?, except?}]`. `Standing.race_start` adds to regard; `Standing.shop_markup` raises BUY price only. Both shrink linearly with reputation in the town (gone at `fade`). Data (guesses): Liscor Drakes start -3, fade 10; `lism_stall` +15%; excepted `relc`, `olesm`, `selys`. No save change.

**M29.3-5.** New optional look key `scale` (Moore 1.35). End of story: `CanonDb.last_day()`, flag `story.end_shown`, page "The Story So Far". Fight view lifted by `WorldView.FIGHT_LIFT` (60 px).

**M30.0-30.2 Voices.** New `data/voices.json` (one object per canon NPC id): `confidence` (required), `canon_ref`, `greet` (keys `stranger` or band labels), `idle`, `lines` (gates `flags`, `not_flags`, `days`, `min_band`), `options` (own talk rows with `action`, `context`, gates). Text in brackets is an action. `rules.voice` {`bark_tiles` 4, `bark_minutes` 20, `max_words` 20, `line`}; none = no voices. `core/voice.gd` (`Voice`): first talk of the day gives the NPC's greet line plus one own line or a normal topic. Picks use an FNV-1a hash of "day|npc|kind", not `gs.rng`, so canon and balance sims keep drift 0. `Interact` rows carry `voice`; menu pick is `voice:<id>` (`Interact.VOICE`, `Interact.action_of`). Barks: `world/view_bubbles.gd` (`ViewBubbles`), view only. Validator checks `voices.json` (`check_voices`). Book 1 cast of 15 (all `guess`). A new game starts on day 8, so lines gated on the inn being closed never show; `unit_voice.test_book1_voice_flags_are_real` checks flags.

**M30.3.** 20 more voices for Books 2-8 (35 total), later lines wait for story flags. Book 6 flags checked only against our canon summaries. Laken and Wesle are thin.

**M30.4 Earther meeting.** Voice options gain `set_flags`, `relationship`, `page` {`title`, `lines`}. Option `earth` on Erin (+3, page "From Earth"), Ryoka, Laken (+2), plus small entries for Rose, Imani, Joseph. Flags `<name>.knows_player_is_earther`. `sim_earther_meeting` shows canon is untouched (drift 0, same RNG). No save change.

**M30.5 Who you are.** Save v23: `player.name` (default "Earther", max 20), `player.look`, `player.background`; `_migrate_22_to_23`. New `data/backgrounds.json`: `pool_start` 0.25, 6 looks, 6 backgrounds (student/Scholar, cook/Cook, nurse/Healer, athlete/Runner, office/Merchant, gamer/Strategist), flag `background.<id>`. `core/player_identity.gd`. Looks `player_2`-`player_6`. Create screen `ui/create_player.gd`.

**M31.0-31.3 Signposts and beats.** Event field `foreshadow` {`days_before`, `text`, `where`?, `hours`?}, `core/foreshadow.gd` (`Foreshadow.coming`), shown on a "Talk in Town" morning page and a journal "Coming up" list. Stage field `beats` [{`after_seconds`, `line`, `npc`?}], one due beat per command, `combat.stage_run` gets "beat" (old saves read 0, no version bump). Foreshadow on all 25 fight stages and 10 key scenes (`KEY_SCENES` in `unit_foreshadow`). All 47 scenes have 3-6 beats, all 25 fights 1-3, max 20 words, no song lyrics. Book 6 beats written from summaries only (no raw text then); copy check for book 6 skipped.

**M32.0 Picks.** Zel can be saved if the player drives off Bea and Ijvani before the last wave while Zel stands. Zel's stage is on a new map. Tremborag's hall stays news. Klbkch (1.29) always dies. If Zel lives he gives Selys the Heartflame via flag hand-off (ADR 0036). Reading facts: open field about four miles outside Invrisil, five Chosen (Venitra, Ijvani, Bea, Oom, Kerash), no Drakes beside Zel, Nokha is a swordswoman and flees.

**M32.1 Three-door battle.** No new enemy field: Calruz's yield and Nokha's flight use the `escape` field. New enemies `calruz` (id = NPC id for his art) and `nokha_awakened`. A fight names its foe by danger (Calruz 1.0, `awakened_raskghar` 0.95, Nokha 0.98). New object kind `cage`, object `raskghar_cages` (shown while `raskghar.camp_holds_the_gnoll_captives`). Hooks (all `change`): `player_stood_with_the_horns_against_calruz`, `player_reached_the_cages`, `player_held_the_inn_in_the_night_raid`, `player_fought_the_daylight_raid`.

**M32.2 Zel's stand.** New action `drive_off_foe` (tag `combat`): one record per driven-off foe with `enemy`, `waves_left`, `protect_standing`. Stage key `protect`, hook key `all`. Stage on `b6.the_battle_of_invrisil_opens` (4.48, day 130, hours 9-15, `xp_window` x3) on new map `invrisil_battlefield` (west exit to `invrisil_gate`, 80 minutes). New enemies `rose_knight`, `bea`, `ijvani`, `oom`, `venitra`, `kerash` (Chosen use `escape`). Hooks `player_fought_beside_zel`, `player_broke_bea_and_ijvani` (sets `zel.saved_by_the_player`).

**M32.3 Boss feel.** Three new ability kinds: `fear` {range, ap_q} (Skinner, range 6, 8 q), `bile` {range, ap_q, cooldown, chance, rounds, damage} (Crypt Lord, poison), `command` {radius, accuracy, tag}. Regrika uses `agility` 8 and a leap. New foe `goblin_lord` (Shaman art, `escape` at 60%, command radius 6, +2, tag `goblin`, danger 0.98). State stays in the encounter dict, no save change. Numbers are guesses.

**M32.4 Zel lives.** Data only. `b6.zel_names_the_goblin_lord_reiss_and_dies` has `not_flags: ["zel.saved_by_the_player"]` and `on_fail: ["mutate:b6.zel_spares_reiss_and_lives", "cancel"]`; the alt sets `zel.survived_invrisil`. Bounty, Az'kerash and mourning events mutate; Reiss-guarding-the-body and Klbkch-to-Grand-Queen cancel. Mourning needs `zel.dead_at_invrisil`; funeral stage uses `when_flags: ["zel.body_in_liscor"]`. `b7.zel_gives_selys_the_heartflame` needs `zel.wears_the_heartflame_breastplate`. Cost (`sim_book6_zel_lives`): 25 canon events lost, drift 15. `sim_kill_book7` Magnolia ceiling 12/18 -> 31/30.

**M33.0 Canon spells.** 12 new spells, all numbers guesses. Damage: [Stone Dart], [Ice Shard], [Lightning Jolt], [Stone Spray], [Frost Bloom], [Lightning Bolt], [Fire Arrow], [Grand Fireball]. New spell field `effect` (`core/spell_effects.gd`): `hold` ([Astral Binding]), `blink` ([Flash Step]), `hide` ([Invisibility]), `wall` ([Ice Wall]); new shapes `self`, `tile`. New `learn.band`: teachers need "friend" (6). State in `combat.encounter` (`held`, `hidden`, `walls`), no save bump.

**M33.1 Erin's food.** Data only. 5 recipes (blue fruit juice, hamburger and fries, Ashfire honey milk, milkshake, faerie flower drink), 5 dishes and ingredients. Ingredients gated by `from_flag`: potatoes `wandering_inn.hamburgers`, honey `erin.has_ashfire_honey`, nectar `erin.wary_of_faerie_flower_drink`.

**M33.2 Quest engine.** New `data/quests.json` (giver, offer, gate, fail, steps by `flag` or `did` + `count`, rewards, `done`). Quest starts from an auto talk row "Ask about: <title>" (`Interact.QUEST`). `Quests.after_action`, `Quests.update`. State `gs.quests` (`QuestState`), save v24. Spell `learn.flags` lets a quest unlock a teacher.

**M33.3 Quest lines.** Data only: `erin_gets_the_inn_going`, `pawn_and_the_painted_soldiers` (fails after day 125), `pisces_teaches_mana` (sets `quest.pisces_mana_lesson`, gates [Flash Step]). All `guess`.

**M33.4 Friend perks.** Optional `rules.standing.perks` [{npc, band, kind, value?, shops?, text}]; kinds `discount`, `talk_xp`, `fight_help`. 32 perks for 16 NPCs. `Night.run` announces each once (flag `perk.<npc>.<band>`). No save bump.

## ADR 0045 — Phone controls, second pass (M34)
2026-10-21 · Accepted

Problem (from play on an Android phone): the flat use menu was one `ItemList` with 15-40 rows, one tap ran a row, drag scrolling picked rows, rows were under the 48 dp touch minimum, and the Use button did not say what it would do. Presentation only; core, schemas and save format unchanged.
- M34.0 Action card: rewrote `ui/interact_menu.gd` in place (class `InteractMenu`, same `chosen` signal). Target first, then action. Pages `TARGETS`, `ACTIONS`, `CONFIRM`. `CardButton` fires on release and only if the finger moved under 12 px. Attack on touch is a 0.6 s hold (`HoldButton`); with keys or mouse a Yes/No box. `InteractMenu.action_rows` groups: talk, serve, trade, work, travel, learn, other, attack.
- M34.1 Shop: new `ui/shop_panel.gd` (`ShopPanel`), Buy/Sell tabs, item cards, count strip (-, +, Max, one deal button), 99 max. Sends existing trade picks with a count. `Economy._single` became public `Economy.is_single`.
- M34.2 Context button replaces Use. Shows verb + nearest target ("Talk / Erin") via `InteractMenu.verb_of`; up to 3 target chips to the left, "All" when more than 4 targets. Menu button top right. Key E still opens the whole menu.
- M34.3 Tap the world: `world/main_tap.gd` (`MainTap`). Outside a fight a touch tap on a target walks next to it (normal move commands, max 80 steps) and opens its card. Setting "Controls: Tap + stick / Stick only" lives in `user://settings.cfg` (`TouchSettings.controls`), not `GameState`.
- M34.4 DPI sizing: `UiScale.px_per_dp`, `touch_grow` (pad buttons 48 dp), `map_grow` (tile about 40 dp), `touch_ui_px`; mobile OS only, desktop unchanged. `InteractMenu.row_h()` replaces `ROW_H`. Earlier first-pass sizes were about 25-30 dp.
- M34.5 Fixes after first phone play (portrait): context button hides in fights and when nothing is near; bottom-right controls sit above the combat bar (`TouchControls.set_bottom_room`); shop count strip became an `HFlowContainer`, Buy button at least 4 button heights wide (`ShopPanel.DEAL_WIDTH`).
- Bag screen (2026-10-31): `ui/bag.gd` rewritten in the card look, one `CardButton` per good plus "Leave 1".
- Consequence: tests that drove the old list moved to the card. Real-phone dpi still to be checked by the player.

## ADR 0046 — M35 new content
2026-11-01 · Accepted

- M35.0 Ceria's fire lesson: data only. Ceria's classes are [Elementalist] and [Cryomancer] (the plan's [Pyromancer] was wrong, fixed). New quest `ceria_teaches_flashfire` (giver `ceria_springwalker`, gate flag `ryoka.knows_light_spell`, starts Book 1 day 36). Steps: talk twice, cook a meal, wait for `erin.has_a_cold` (days 37-38), cook hot soup or stew, tell Ceria. Reward +3 regard and flag `quest.ceria_fire_lesson`. `spells.json`: `flashfire` has `learn.flags: ["quest.ceria_fire_lesson"]`. No fail rule except her death. Her fight spell list is unchanged. Quest steps are guesses. Known gap: Ceria has no map goal between day 40 and Celum.
- M35.1: Reynold gets a past [Lieutenant] class with `level: null` (`book2/npcs.json`). The text states no levels for Merec, Raisha, Reynold, Rose, Imani, Joseph or the golems. NPC records have no place for Skills; adding one is a schema change (rule 11), not done. A null level counts as `unknown_level` (1) in `NpcLevels`.
- M35.2: No named Invrisil Runners' Guild staff in Books 2-8. Only candidate is Thasius Griff (Book 6), not placed. Nothing added.
- M35.3: Magnolia and Ressa get four flag-gated goals in `npc_behaviour.json`: army camp at Invrisil (off map, 8-20 h; flags `magnolia.recorded_the_speech` or `magnolia.levy_waits_at_invrisil`, until `invrisil.battle_begun`), `invrisil_battlefield` (until `magnolia.offered_a_bounty_on_the_necromancer`), then `invrisil_gate` by day (until `magnolia.defends_invrisil`), then the estate. Spots and hours are guesses. Tests: `unit_m25_whereabouts` (+4).

## ADR 0047 — M36 Book 9 (Tears of Liscor)
2026-11-01 · Accepted

Book 9 is the Goblin Lord's war on Liscor: Tyrion drives the northern tribes south, the rains end, the inn's tower is wrecked, the magic door is stolen, and the Floodplains battle kills Reiss, Garen, Pyrite, Headscratcher, Shorthilt and Yellow Splatters.
- Day rule: Book 9 "Day N" counts Tyrion's march. Game day = march Day + 163 (Day 1 = day 164). ADR 0028's +45 rule does not apply. All Book 9 days are guesses.
- No engine step, no schema or save change. M36.0 skipped. Rains end by events: `izril.rains` clears on day 172, `izril.flood` on day 174. Boycott `wandering_inn.drake_boycott` clears in the 5.49 batch (guess).
- Deaths: kill effects for the named dead with records (13 names in the plan). No kill for Numbtongue, Purple Smile, Osthia, Calruz.
- One entity, no merge: Reiss is the `goblin_lord` record. Greydath is `greybeard` (one id). Lord Erill is not Princess `erille`.
- Erin's [General] 6 is offered and cancelled (5.62): a `system` record, she keeps no class. North thread is off-map events. Ryoka is a City Runner at Reizmelt, no records.
- Event ids `b9.`, chapter `order` 78-99, data in `game/data/canon/book9/`.
- Fight stages: the door thieves on `road_camp` (day 172, 22-24 h, tier 1; Floodplains map is flooded), Halfseekers vs Garen's host on `road_camp` (day 173, tier 1), trebuchet barrage on `liscor_gate` (day 176, tier 1), the gate battle on `liscor_gate` (17-21, day 176, tier 2, ten named kills). Talk hooks: jail visit (`liscor_watch_cells`, day 173), Gnolls' spark (`liscor_market`, day 173); M36.2 scene hooks: victory parade (`liscor_plaza`), baseball game (`celum_north_gate`); M36.3 hooks: Raskghar hoard (`inn_upper_floor`), Bevussa's bird stories (`inn_interior`).
- New map `liscor_watch_cells`; flag goals put the jailed Hobs, Erin and Calruz there. New enemies `draug`, `brothers_thug`, `chell_sister`. 17 NPC and 3 place records.
- Magic door moves to city hall (`albez_door.at_liscor_city_hall`; inn flag clears). The inn is closed and barred after the battle. Muddy look stays a flag (`izril.floodplains_muddy`).
- Rule found: canon events resolve at day end, so a stage must not wait on a flag set the same day.
- M36.10 sims: `sim_canon_book9`, `sim_kill_book9`. 42 events with one clear subject now list that subject in `requires.alive` (data only). `reiss_dies_at_a_table` left alone.

## ADR 0048 — M37 Book 10 (The Wind Runner)
2026-11-04 · Accepted (details in `docs/plans/m37.md`)

Book 10 covers the spring weeks after the battle of Liscor. Five threads: Ryoka at Reizmelt (6.00, 6.01); the inn, Liscor and Pallass (6.02, 6.03, 6.08-6.11, 6.16); Daly's Earth people on Baleros (6.04D-6.07D); the King of Destruction on Chandrar (6.12K-6.15K).
- Day rule: anchor is the battle, day 176. 6.02's "eighth day" is day 184; 6.09's "two weeks" is day 190; 6.08-6.10 are one day (190). Days are guesses unless counted in the text.
- Ids: `6.` chapter ids with letters D and K, `b10.` event ids, `order` 100-116, data in `game/data/canon/book10/`. No tool or loader change needed; M37.1 adds a load test.
- No engine step (door stones, closed inn, Drake boycott are flags). M37.0 skipped.
- Baleros (D) and Chandrar (K): 8 chapters, 5-6 key events each, off map, no stage, no hook.
- One fight stage: night undead at the inn (`inn_hill`, day 183). Two hooks: walk with Numbtongue (`liscor_market`, day 184), Gold-rank farewell (`inn_interior`, day 192). One new map: Tails and Scales, a Pallass bar (M37.2).
- Ryoka: events and places only. No class, level or Skill record ([Runner's Wind] is a lie, [Barefoot Runner] never appears).
- No named kill. `sim_kill_book10` checks the Book 9 dead stay dead and early kills of Book 10 survivors cancel cleanly.
- Entities: Osthia Blackwing is the "Shieldscale" aide; Regrika Blackpaw may be Venitra (check); the new Quarass is the old one reborn (one record); Teres Atwood may be `teresa` (name fix if the text says Teres); Lawes of Pallass is not `ylawes_byres`.
- Adult scenes (6.04D opening, contraception scenes in 6.06D/6.07D) get a neutral one-line summary or no event.
- Estimate: about 9 steps, about 160 events. Steps: M37.1 world and records, M37.2 map, M37.3 6.00-6.01, M37.4 6.02-6.03, M37.5 6.08-6.10, M37.6 6.11 and 6.16, M37.7 Baleros, M37.8 Chandrar, M37.9 sims.

## ADR 0049 — Microsoft Store package (MSIX)
2026-11-04 · Accepted

- Ship to the Microsoft Store as an MSIX wrapping the same `InnworldRPG.exe` as the GitHub Windows zip (`binary_format/embed_pck=true`). No new export preset, no engine change.
- Built by `tools/windows_store.ps1` from the folder `tools/release.ps1` makes. Manifest from `tools/release/AppxManifest.template.xml`, logos from `tools/build_windows_store_art.py`. Uses `makeappx.exe`, `makepri.exe`, `signtool.exe` from the Windows SDK (no new dependency).
- The Store signs the package, so we upload it unsigned and need no certificate. A self-hosted installer would need a paid certificate each year, so we did not choose it.
- Capability `runFullTrust` only.
- Store version = game version with Major + 1 and last part 0 (`0.2.1-alpha` -> `1.2.1.0`); the Store reserves the last part and forbids a first part of 0.
- Package identity (`Name`, `Publisher`, `PublisherDisplayName`) is not in git. It comes from Partner Center via `%USERPROFILE%\.innworld-store.txt` or script parameters. `-Test` uses a throw-away identity and a self-signed certificate.
- Same author rules as Play (no book or series name, no book art, free, no ads). Text and answers in `docs/WINDOWS_STORE.md`.
- Consequences: the Store version has its own save folder (MSIX storage). The exe icon is still the Godot default (`application/modify_resources=false`); fixing it needs `rcedit` (ask first, rule 11). Installing and running the signed test package is not yet checked. Each release needs one more manual step: upload the new .msix in Partner Center.

## ADR 0050 — M37.1 Book 10 world and records
- 51 new people and 22 new places in `game/data/canon/book10/`. The plan guessed about 45; the extra ones are Reizmelt and
  Pallass people that the 6.00 – 6.11 events name. Nawal, Okasha and Siyal are not added yet; M37.7 / M37.8 add them only if
  an event needs them.
- Osthia = "Shieldscale" (6.11) and Venitra = "Regrika Blackpaw" (6.11): the text says so, so no new records. Each cover name is
  a note on the old record (`osthia_blackwing`, `venitra`). Disguise state is a story flag, set by the Book 10 events.
- Teres: Book 2 (2.22K) uses both "Teres" and "Teresa". Book 10 uses "Teres". The record keeps id `teresa` and name "Teresa"
  (her full name); the note says she goes by Teres. No rename, so no save or UI change.
- The new Quarass is the old one reborn (6.12K): one record `the_quarass`. Lawes of Pallass (6.11) is a new record, not
  `ylawes_byres`.
- Erin's [Warrior] (6.09): her record has no [Warrior]. M37.5 adds a `system` line in the 6.09 batch; no class change now.
- No schema change, no save change, no engine change.

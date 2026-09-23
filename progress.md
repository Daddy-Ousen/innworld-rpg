# Progress

## Roadmap status
- [x] M0 — Setup (done 2026-09-23, tag `m0-done`)
- [x] M1 — Sim core (done 2026-09-23, PR #2 merged, tag `m1-done`)
  - [x] Schemas: ADR 0002 accepted (outcome_mult yes, tags.json registry yes)
  - [x] Clock, tags, data loader, action log, XP, `Actions.perform` (part 1, PR #1 merged)
  - [x] Part 2: classes (17), skills (47), pools, offers, decline blacklist, levels, dilution, capstones, class loss, consolidation, night pipeline 1–4 + 8, `Commands` facade, debug console, `sim_30_days`, `sim_decline`
- [x] M2 — Canon pipeline (done 2026-09-23, PR #3 merged, tag `m2-done`)
  - [x] `tools/extract_epub.py` + tests. Book 1: 66 chapters, ~448k words, 6 images skipped.
  - [x] Schemas (ADR 0004 accepted) + `tools/validate_data.py` + tests (26 Python tests pass).
  - [x] Events 1.00–1.09 (now in `game/data/canon/book1/`): 26 events, 10 NPCs, 15 locations, all `reviewed`; validator 0 errors.
- [x] M3 — World director (done 2026-09-23, PR #4 merged, tag `m3-done` on merge commit 47412d1)
  - [x] Canon data moved to `game/data/canon/` (user choice).
  - [x] `CanonDb` loader, `WorldState` (save v3), `Director` (night step 5), rules `director` section.
  - [x] `Commands.kill_npc` / `set_flag`; console `kill`, `flag`, `history`, `drift`.
  - [x] Tests: `unit_canon_db`, `unit_director`, `sim_divergence` (3 scenarios), `sim_canon_book1` (real week 1, drift 0).
- [x] M4 — 2D world (done 2026-09-23, PR #9 merged, tags `m4.5-done` and `m4-done` on merge commit 0e2f19a)
  - [x] M4.1 Canon 1.10–1.14 (branch `data/book1-1.10-1.14`, PR #5): 12 events, 5 NPCs, 8 locations, reviewed by user; validator 0 errors, GUT 156/156 (canon runs days 1–9, drift 0). Merged, tag `m4.1-done` pushed.
  - [x] M4.2 World grid core (branch `feat/m4.2-world-grid`): `tiles.json`, 5 maps, `MapDb`, `PlayerState`, `Movement`, `Interact`, `Pathfind`, save v4, console `where/look/go/use`, day-8 start, ADR 0006. GUT 193/193. PR #6 merged, tag `m4.2-done`.
  - [x] M4.3 2D view (branch `feat/m4.3-world-view`): `Session` autoload, `WorldView` (tiles made in code), main scene with WASD/E/Z, use menu, HUD, console overlay (backtick). ADR 0007. GUT 203/203. PR #7 merged, tag `m4.3-done`.
  - [x] M4.4 NPC schedules + utility AI (branch `feat/m4.4-npc-ai`): `npc_behaviour.json` (14 NPCs, off-map places `liscor`/`wilds`), `BehaviourDb`, `UtilityAi`, `NpcRoster`, `NpcSim` (walk in the player's area, jump elsewhere), `Pathfind` avoid + area routes, night step 6, talk to NPCs (+1 relationship a day), `Commands.wait` (Space), save v5 with exact f64 floats (`SaveCodec`). ADR 0008. GUT 243/243. PR #8 merged, tag `m4.4-done`.
  - [x] M4.5 System message UI (branch `feat/m4.5-system-ui`): `SystemMessages` pages (collapse, levels/skills, rumors, drift, offers, morning), `SystemDialog` (Accept / Decline + confirm), sleep in the inn bed (map object `sleep: true`, user choice), character sheet (C), night result sections. ADR 0009. `sim_m4_done` checks the M4 "Done when". GUT 258/258. PR #9 merged.
- [ ] M5 — Combat (plan approved 2026-09-23; 3 sub-modules, see ROADMAP and ADR 0010)
  - [x] M5.1 Combat core (branch `feat/m5.1-combat-core`): `enemies.json` (goblin_grunt, rock_crab, razorbeak; spawns empty), `items.json` (chair, rolling_pin, stone, seed_core), rules `combat`, `CombatDb`, `Stats` (stat_mod live), `CombatState`, `Combat` (attack, block, throw, drop, bump attack, fight records at fight end, danger refusals, knock-out with safe wake spot, night heal, bandage heal), `Night.run(..., knocked_out)`, save v6. ADR 0010. GUT 302/302.
  - [x] M5.2 Monsters on the map (branch `feat/m5.2-monsters`): `MonsterSim` (turns by `act_seconds`, spawns, spot/ambush, pack aggro + morale, give up (crab hides, others go home), territorial leash from home, flee to the edge), 4 real spawns, map items (seed cores, stones, rolling pin, chairs) + `Commands.take`, Razorbeak nest zone/object, monster `pack` field. ADR 0010 M5.2 section. GUT 348/348. PR #11 merged, tag `m5.2-done`.
  - [x] M5.3 Combat UI (branch `feat/m5.3-combat-ui`): monster markers (state edge, dark ring, "Goblin 5/8"; hidden crab = rock tile), HUD `HP 14/20 · Held: Chair` (warning colour ≤ 25%), combat text in the log, bump attack once per key press, B/T/X, Take in the E menu, knock-out page (`SystemMessages.KNOCKOUT`), sheet HP + stats, console combat + debug commands, `Combat.nearest_foe`. `sim_m5_done` (seed 2) checks the M5 "Done when". ADR 0010 M5.3 section. GUT 358/358. PR open (waiting on the user).
- [ ] M6 — see `docs/ROADMAP.md`

## Completed
- Godot 4.7.2 project in `game/`, GUT 9.7.1 in `game/addons/gut`.
- Core: `rng`, `game_state` (SAVE_VERSION=6), `save_migrations` (1→…→6), `combat_db`, `stats`, `combat_state`, `combat`, `monster_sim`, `save_codec`, `behaviour_db`, `utility_ai`, `npc_roster`, `npc_sim`, `map_db`, `player_state`, `movement`, `interact`, `pathfind`, `canon_db`, `world_state`, `director`, `clock`, `tags`, `data_db`, `action_log`, `xp`, `actions`, `progression`, `levels`, `skill_system`, `class_system`, `night`, `commands`.
- UI: `ui/session.gd` (autoload), `ui/hud.tscn` (HP line), `ui/interact_menu.tscn`, `ui/system_messages.gd`, `ui/system_dialog.tscn`, `ui/character_sheet.tscn`, `ui/console_commands.gd`, `ui/debug_console.tscn` (also the overlay). World: `world/main.tscn` (main scene), `world/world_view.tscn`.
- Data: `tiles.json`, `maps/` (liscor_gate, liscor_market, floodplains_south, inn_hill, inn_interior), `npc_behaviour.json`, `enemies.json`, `items.json`; rules `npc`, `combat`.
- Tests: 37 GUT scripts, 358 tests, all pass, headless exit 0. Python tool tests: 26 pass (`python -m unittest discover -s tools/tests`).
- Tools: `tools/extract_epub.py`, `tools/validate_data.py`.

## Blockers
- None.

## Open balance note
- First class offer comes on day 22 with a plain inn workday (ADR 0009). Canon Erin gets [Innkeeper] on night 1. Tune XP / thresholds in a later pass (M6).

## Repo
- Public: https://github.com/Daddy-Ousen/innworld-rpg, branch `main`.

## M5 decisions (user, 2026-09-23)
- HP 0 = knocked out (no death). One held improvised item (no inventory). Enemies: Goblin grunt, Rock Crab, Razorbeak. A monster at 0 HP dies. Knock-out wake: nearest safe place (Floodplains / inn hill → inside the inn; Liscor gate / market → the gate; else where you fell). 3 sub-modules.
- Approved schemas: `enemies.json` (+ spawns), `items.json`, rules `combat`, map object `item` field + razorbeak zone/objects (M5.2), save v6.
- Canon goblin NPCs stay non-hostile; canon-event fights and guards who fight are M6. `[Bar Fighting]` / `[Unerring Throw]` need a separate OK.

## M4 decisions (user, 2026-09-23)
- Float saves (2026-09-23, user chose option 2): save floats as exact text. Done in M4.4 (ADR 0008).
- Start: the player arrives with the Great Ritual (night 7) and starts outside the Liscor east gate on day 8 (user choice). New game must run the director for days 1–7 first. Celum start deferred to M7+ (no Celum canon yet; first seen 1.19R).
- Art: placeholder colored tiles made in code; Kenney CC0 later (ask then).
- NPCs: extract 1.10–1.14 first (adds Selys, Krshia, Lism, Belsc, Drassi).
- Map: small linked areas (Liscor gate, market, Floodplains patch, inn hill, inn inside).
- Approved: new schemas `tiles.json`, `maps/<area>.json`, `npc_behaviour.json`; rules `world` + `npc`; `Actions.perform` `minutes` opt; `Session` autoload; save v4 and v5.

## Architectural decisions
- ADR 0010 (accepted, M5.1–M5.3): M5.3: presentation only, no schema/save change; bump attack once per key press (lock per direction); T throws at `Combat.nearest_foe` (seen monsters, hostile first, then distance, then id); a knock-out runs `Commands.knock_out` at once after any command and opens the knock-out page; `sim_m5_done` uses a fixed seed (2). M5.2: `MonsterSim.run` from `Combat.sync`; long gaps give no turns unless a monster is hostile (then capped); territorial give-up measured from home; goblins that give up go home (not routed); routed counts when a monster starts to flee; objects may have no actions; `DataDb` loads combat before it validates maps. M5.1: no combat mode (each command is a 6 s turn); `Commands._after` = `Combat.sync` + `NpcSim.sync`; monsters only in the player's area (`gs.combat`, save v6); fight counts → one record per action kind at fight end (minutes 0, risk = foe danger, won/fled/KO → success/partial/fail); improvise = context `weapon: improvised`; danger refuses actions/uses/sleep; knock-out wakes at the normal time at a safe place with 25% HP; `Stats` from base stats + stat_mod.
- ADR 0009 (accepted): night result sections (`collapsed`, `progress`, `world`); `SystemMessages` page order and page shape; offers from `gs.progression.offers`; decline asks once more; no skip; console blocked while the dialog waits; map object `sleep` flag (`Interact.SLEEP` is not an action); character sheet (C).
- ADR 0001: GUT version, RNG state as strings in JSON, `.import` files committed, save load path.
- ADR 0002: data schemas (tags, actions, rules, classes, skills), XP formula, clock as one absolute minute counter, saves use full float precision and keep key order.
- ADR 0003: non-zero-sum class pools, decline freezes the pool, offer order and cap, dilution formula, capstone breakthroughs, skill pick weights, xp_mult applied in XP, class loss, night pipeline, `Commands` facade.
- ADR 0004 (accepted): extractor rules; canon data layout (`npcs.json`, `locations.json`, `chapters/<ch>.json`), event schema changes vs DESIGN §4.3 (window.confidence, optional roles, tag-only roles, on_fail ends in cancel, delay_limit, clear_flags, rumor, tier 1–2), chapter `system` log, validator with 7-word copy check.
- ADR 0008 (accepted): `npc_behaviour.json` schema (entries per off-map place, goals with hours/days/flags, targets pos/route/off_map); rules `npc`; utility AI (ties → first goal, idle = stay); `NpcRoster` (save v5); `NpcSim` level of detail (walk in the player's area, jump elsewhere, pop in on the way, jump on gaps > 300 s); NPCs pass through each other, block the player; night step 6; talk +1 relationship once a day; floats saved as `"f64:<hex>"`.
- ADR 0007 (accepted): `Session` autoload; console syncs with it; `WorldView` makes its TileSet from tile colors; main scene input (held keys repeat every 0.14 s, E use menu, Z sleep, backtick console); HUD.
- ADR 0006 (accepted): day-8 start at the Liscor east gate; tiles/maps schemas; `MapDb` validation; `PlayerState` (save v4); steps cost `step_seconds`, exits run `travel` with scaled intensity; interact context = map location + zone + object context; action context uses canon ids (`wandering_inn`). Known issue: Godot JSON float parse is not exact.
- ADR 0005 (accepted): canon data in `game/data/canon/`, `CanonDb`, `WorldState` stores only changes (save v3), director rules (strict `requires.alive`, anonymous monster roles, wait/role/hard failures, propagation after cancel or mutate, effect remap to substitutes), drift weights in `rules.json` `director`.

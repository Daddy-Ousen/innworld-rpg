# Handoff

## Just done (2026-09-30, M17.8 hidden XP, cloud session)
- M17.7 merged (PR #86). Branch `claude/kind-feynman-y4x1mm` restarted from main ff7d757; the M17.8 PR is open (the user merges it).
  Plan: `docs/plans/m17.8.md`. Detail: ADR 0027 "M17.8".
- User answers: curve 1 point = 0.01 (x0.5 at 0% lost, x1.0 at 10%, cap x2.0); duress and window multiply; window data on the canon event; no save
  version change ("I don't care about old saves"); other classes' duress later.
- Core: `Xp.duress_mult`, `Xp.boost_mult`, `Xp.compute(..., duress, window)`; `Actions.perform` opts `duress` / `window` (default `XpWindow.mult`), both in the
  record; `Combat.damage_player(from_foe)` writes `fight.peak` / `fight.low` (per mille, -1 = none), `Combat.fight_lost`, `end_fight` passes `duress` to every
  record; traps pass `false`; `core/xp_window.gd` + `CanonDb.windows` + `_validate_xp_window` + `XpWindow.validate`; `tools/validate_data.py` `check_xp_window`.
- Data: `rules.xp.duress` and `rules.xp.boosts`; `xp_window {boost 2, hours [18, 6]}` on `b1.skinner_leads_the_dead_into_liscor` (1.60) and `b1.rags_kills_skinner` (1.62).
  Toy dbs drop `rules.xp.duress` (`ToyData.with_duress` adds it back).
- Tests: new `unit_fight_duress` 10, `unit_xp_window` 12, `sim_balance_fighter` (probe); `unit_xp` 17; Python 97 OK; validator 0 errors. NO full suite (user rule).
- **Finding:** `sim_balance_fighter` (two Goblin fights a day) gives level 5 on night 6-7; the inn worker (`sim_balance_progress`) night 14. The curve was not changed:
  `base_xp` 52 (measured once, reverted) gives fighter night 7-9 and worker night 18, the same 2:1. The fix is XP sources for non-fighters, not the curve.
- **User rule (2026-09-30, in CLAUDE.md "Test scope"): run only the minimum tests that touch the change; NO full suite unless the user asks.**
- Open: every duress, boost and ability number is a guess; only the Skinner night has a window; clean wins pay half, which fights the cover rules of M17.6
  (the floor is data); the user has not played any M17.6-M17.8 fight (`godot --path game`; no display in the cloud).

## Next
1. The user merges the M17.8 PR; then tags `m17.6-done`, `m17.7-done`, `m17.8-done` and `m17-done` on the right merge commits (tag pending: the cloud may not push tags).
2. Optional M17.9 (plan first, ask first): duress for non-fight actions so cooks, runners and healers close the gap (crowd size in a meal, winter cold, a badly hurt
   patient, acting hungry), more windows for other big nights of Books 1-5 (two lines of data each). Or move on.
3. M18.P (Book 6 plan, ADR 0028; needs the book text: add repo `Daddy-Ousen/innworld-canon-raw` to the session), M18 batches, M19.P (Book 7, ADR 0029), M19 batches.

## Gotchas (cloud)
- Not yet run in a real cloud VM. Unknowns: whether the proxy lets `git clone` reach the private repo when only
  `innworld-rpg` is attached (fallback: attach both repos and run `setup.sh --force` by hand; with two repos
  the hook does not run), and whether tag pushes are allowed (else write "tag pending" in progress.md).
- A cloud session can push only its own working branch: one sub-milestone per session, one PR.
- No display in the cloud: "the user plays" checks wait. Plans live in `docs/plans/`, not `~/.claude/plans/`.
- Books 1–5 text is not in the cloud.
- A fresh `--import` takes about 100 s. `setup.sh` reverts `.import` files the import rewrites.
- On Windows `python3` is the Store alias (fails); use `python` locally. Linux uses `python3`.

## Earlier (2026-09-30, M17.5 Mana and spells)
- Branch `feat/m17.5-spells` (from main 79490a6). Merged as PR #83 (68f5f38), tag `m17.5-done`. 5 commits: core MP (save v20),
  spell data and learning, casting and NPC casters, UI, docs. Plan: `C:/Users/rhasa/.claude/plans/encapsulated-orbiting-lollipop.md`.
  Detail: ADR 0027 "M17.5".
- User answers: max MP = Intellect + total level; teacher talk option + spellbook good; NPC casters now; line stops at
  walls, foes only.
- Core: `core/mana.gd` (`current/set_mp/spend/tick/refill`), `core/spells.gd` (learning, `cells`, `why_not`, `use`, NPC
  `npc_pick/npc_use`), `core/spell_db.gd` (`data/spells.json`), `Stats.max_mp`, `PlayerState.mp/mp_minutes`,
  `Progression.spells`, `Commands.cast/learn_spell/grant_spell`, `Movement._spend_seconds(gs, db, s)`,
  `CombatSkills.start_cooldown` (public now), cooldown key `spell:<id>`, fight record `cast_spell`.
- Data: 4 spells (ice_spike, flashfire, frozen_wind, fireball), `spellbook_fireball` good (no shop sells it: `give 0 spellbook_fireball`),
  [Mage] class + [Mana Sense] / [Steady Casting], action `study_spell` / `cast_spell`, tag `magic`, rules `tactical.mp`
  (`base 0, per_intellect 2, per_level 1`), base stat `intellect: 3`, Ceria and Pisces `combat.mp` / `combat.spells`.
- UI: spells in `ui/skill_bar.gd` (id `spell:<id>`, node name with `_`), MP label in `ui/combat_bar.gd`, HUD line, sheet "Spells:",
  `world/main.gd` (`pick_spell`, `cast_spell`, `_show_spell_plan`), `CombatOverlay.preview/burst`, teacher "Learn" rows in
  `ui/interact_menu.gd`, "Read" for spellbooks in the bag, console `spell <id>` / `cast <id> [x y]`.
- Tests: new `unit_mana` 17, `unit_spell_learning` 16, `unit_spells` 31, `unit_spell_ui` 13. Full suite (subagent): 128 scripts, 1339 tests, all pass (a single full run crashed once in unit_winter, a Godot crash; every script passes alone, so run the suite script by script). Validator 0 errors, Python 95 OK.
- Open lore flags: every spell number and teacher is a guess; check the Book for who could teach the player; a spellbook
  source (shop or loot) is missing; [Light] / [Flare] / [Water Spray] are Ryoka's and were left out.
- Next: the user plays a fight with a spell (`godot --path game`, then ` for the console: `spell ice_spike`, `spell fireball`,
  `give 0 spellbook_fireball`, `spawn goblin_grunt`, keys 1-9). Then M17.6 (cover and position, plan mode first).
- Gotchas: a multi-line Python patch must use the file's exact tab count (a wrong count fails the assert, nothing is written);
  the working copy has mixed line endings (`git ls-files --eol`), so patch with a helper that detects CRLF. New `class_name`
  scripts need one `--import`; it makes `.uid` files for new scripts (commit them). `-gselect=unit_combat` matches five
  scripts (substring) and Godot may hang at exit after them.
- Test runner: scratchpad `run_targets.sh [-t secs] <script>...` (gone next session).

## Earlier (2026-09-30, M17.4 Skills in combat)
- Merged as PR #82 (merge commit 79490a6), tag `m17.4-done` pushed. This note lives on branch
  `feat/m17.5-spells` (from main 79490a6; not pushed). Plan: `C:/Users/rhasa/.claude/plans/vast-foraging-rabbit.md`.
  Detail: ADR 0027 "M17.4".
- User answers: cooldown in rounds; the [Runner] CLASS gives the move cap (classes.json `combat.move_ap_mod_q`);
  kinds strike / area / self; NPC allies use Skills now (monsters in M17.7).
- Core: `core/combat_skills.gd`; `Commands.use_skill` (via `_encounter_act_q`, cost in q); `Combat.strike_at`,
  `throw_at(mods)`, `_strike(mods)`, `player_hit_chance(extra)`; `NpcReact._hit(mods)`; `Encounter` reads
  `CombatSkills.ap_bonus_q` / `move_cap_q`, ticks cooldowns at a round's start, NPC fighters try `npc_pick`
  first. Save v19 (`cool`, `move_bonus_q` in the encounter). DataDb checks `ap_mod`, `combat_action`, class
  `combat`; BehaviourDb checks NPC `combat.skills` (skill ids and canon event ids).
- Data: 9 new skills + [Power Strike] turned into an action; [Runner] `move_ap_mod_q: 4`; Erin / Relc / Toren
  `combat.skills` with `after_event` / `until_event`.
- UI: `ui/skill_bar.gd` (row in the combat bar, built in code), keys 1-9 in `world/main.gd` (`pick_skill`,
  `use_skill`, `disarm`, `armed_skill`), `CombatOverlay.marks` (gold frames), help line in `SystemMessages.KEYS`.
- Tests: full suite (subagent) 124 scripts, 1185 tests, all pass, no parse errors. Validator 0 errors, Python 95 OK.
- Open lore flag: [Tavern Brawling] is [Bar Fighting] in the Book (1.14); no "greater stamina" name found.
- Debug: console `skill <id>` (`Commands.grant_skill`, class "" level 0; the character sheet lists it without a
  class) and `useskill <id> [monster]`. Test in `unit_console`.
- Next: the user plays a fight with a Skill (`godot --path game`, then ` for the console, `skill power_strike`);
  then M17.5 (mana and spells, plan mode first) on `feat/m17.5-spells`. Line and blast shapes were
  left for M17.5 spells.
- Gotchas: a sure hit still rolls `randf` (keeps the random stream). The Bash safety check failed now and then
  this session; Edit / Grep still worked. `--import` segfaulted once but imported.
- Test runner: scratchpad `run_targets.sh [-t secs] <script>...` (gone next session).

## Earlier (2026-09-30, M17.3 combat screen)
- PR #80 merged (07f19a3); tag `m17.2-done` set and pushed. Branch `feat/m17.3-screen` from main, 3 commits
  (core, ui, docs). Merged as PR #81 (d470158), tag `m17.3-done` pushed. This note lives on branch
  `feat/m17.4-skills` (from main d470158; not pushed).
  Plan: `C:/Users/rhasa/.claude/plans/eventual-enchanting-teacup.md`. Detail: ADR 0027 "M17.3" section.
- User answers: the camera replays each fighter's turn; a click on a far foe walks up and hits; mouse in fights only.
- Core: `Movement.can_enter`, `Encounter.reach` / `plan_to` / `log_*` / `hp_of`, `Combat.player_hit_chance`,
  `CombatState.turns` (transient, NOT saved, no save version change), `Commands._encounter_act(prefix)`.
- UI: `ui/combat_bar.gd/.tscn` (in main.tscn HudLayer), `world/combat_overlay.gd` (node in world_view.tscn),
  `WorldView.replay / skip_replay / cell_at / refresh(replayed)`, `main.gd` (mouse, click walk, replay,
  `replay_turns` off headless, `end_turn`), help page lines in `SystemMessages.KEYS`.
- Tests: new `unit_combat_preview` (15), `unit_combat_screen` (11, real data on `ruins_entrance`). Full suite
  (subagent): 122 scripts, 1159 tests, all pass, no parse errors. Validator 0 errors, Python 95 OK.
- Screenshot for the user: `The Wandering Inn Books 1-17 Pirateaba/Temp/m17.3_fight.png` (gitignored).
- Next: the user plays a fight (`godot --path game`); M17.4 (Skills in combat, plan mode first) on `feat/m17.4-skills`.
- Gotchas: a replay only runs when a display exists; a main-scene test that wants it sets `main.replay_turns = true`.
  A non-headless Godot run rewrites every asset `.import`: `git ls-files -m game/assets | xargs -r git checkout --`.
  Main-scene tests leave GUT "orphans" (warnings only; old tests do the same).
- Test runner: scratchpad `run_targets.sh [-t secs] <script>...` (gone next session).

## Earlier (2026-09-30, M17.2 port the old fight parts)
- Tags `m17.0-done` (a24db19) and `m17.1-done` (a175d2a) set and pushed. Branch `feat/m17.2-port` pushed as
  PR #80 (https://github.com/Daddy-Ousen/innworld-rpg/pull/80). After the merge: tag `m17.2-done` on the merge commit. Plan: `C:/Users/rhasa/.claude/plans/agile-shimmying-duckling.md`.
- User answers: auto end turn when AP pays for nothing; one NPC Agility default (3) until M17.7; no new UI.
- Combat mode is ON in `rules.json`. Detail: ADR 0027 "M17.2" section.
- Core: `encounter.gd` (NPC fighters `"npc:<id>"`, `_npc_turn`, brawl starts an encounter, `_over`,
  `maybe_end_turn`, guard drops at the player's turn, optional `monster.ap_q`), `commands.gd`
  (`_encounter_act` / `_encounter_do`: AP for block, throw, take, drop, bag, attack_npc, fairy swat; wait -1
  when knocked out), `movement.gd` (`spend_turn` no-op in a fight), `combat.gd` (guard kept in a fight,
  `player_attack` without `spend`), `npc_sim.gd` (NPC fighters skip world-time acts).
- Tests: new `test_support/fight_bot.gd` (`FightBot.act/move/attack/throw/block/attack_npc/wait_seconds`);
  `ToyData` turns combat mode off for toy dbs; `ToyCombat.freeze` sets `monster.ap_q` 0; `ToyMaps.walk_to`
  uses FightBot. 20 real-data sims use FightBot for fight commands. `unit_encounter` 25, `unit_winter` +1.
- Balance seen (for M17.7): level 5 vs 2-3 Goblins now wins 1-2 of 3 seeds; `sim_balance_fights` asserts
  single foes only.
- Full suite (subagent): 120 scripts, 1133 tests, all pass, no parse errors. Validator 0 errors, Python 95 OK.
- Next: the user merges PR #80, then M17.3 (combat screen,
  plan mode first). The user should try a fight in the game: Space ends the turn.
- Test runner: scratchpad `run_targets.sh [-t secs] <script>...` (gone next session): one script per Godot
  run with a time limit, one summary line each. Much safer than the full suite when a sim may hang.

## Earlier (2026-09-30, M17.1 core encounter)
- Merged to main as PR #79 (a175d2a), with the M16 archive and M17.0. Tagged in M17.2.
- ADR 0027 approved by the user; M17.1 notes at its end. Save v18.
- New `game/core/encounter.gd`; changed `combat.gd` (`player_attack(spend)`, encounter cleared in `end_fight`,
  `night`, area change), `combat_state.gd` (`encounter`), `monster_sim.gd` (`_hostile_checks`,
  `_nearest_hostile`, carry dropped in combat mode), `movement.gd` (`step(spend)`), `commands.gd`
  (`_encounter_move`, `_encounter_attack`, `end_turn`, wait = end turn, `_after` ends with `Encounter.sync`),
  `save_migrations.gd` 17→18, `combat_db.gd` (`agility`), console `end`.
- Combat mode is OFF in `rules.json` (`combat.tactical.enabled: false`). `ToyCombat.tactical(d)` turns it on.
- Tests: `unit_encounter` 21/21, `unit_tactical_rules` 6/6, unit_combat/monster_sim/stage/combat_db/traps/brawl pass.
- Next: M17.2 (plan mode first): block/throw/take/drop on AP, brawl and react NPCs and stage allies in the
  order, flee, knock-out, fight records; port the 44 fight test files; set `enabled: true`; full suite.
- Test runner: scratchpad `run_targets.sh <script>...` (gone next session).

## Earlier (2026-09-30, M17.0 spike)
- Branch `feat/m17.0-spike` (stacked on `docs/archive-m16`, neither pushed). Ask the user before push / PR.
- User answers: Agility = `speed` stat; keep AP rules, raise HP ~x2 in M17.7; MP 1 per 10 min, sleep refills;
  a fight covers the whole map, late arrivals join next round. All in `docs/adr/0027-m17-tactical-combat.md`.
- `game/data/rules.json` `combat.tactical` (nothing reads it yet). Test `game/tests/unit_tactical_rules.gd`.
- Paper fights: scratchpad `paper_fights.py` (gone next session). Results table in ADR 0027.
- Tests run: unit_tactical_rules 5/5, unit_combat_db 14/14, unit_stats 6/6, validator 0 errors, Python 95 OK.
- Next: user approves ADR 0027, then M17.1 (plan in ADR 0027 "M17.1 plan"; save v18; full suite in a subagent).
- JSON numbers load as floats in GDScript: compare arrays after `map(int)`.

## Earlier (2026-09-29, M16 merged and archived)
- M16 (M16.0-M16.6) merged as PR #78 (main 98a3b08). M16 archived in `docs/PROGRESS_ARCHIVE.md`; `progress.md` marks M16 done.
  Branch `docs/archive-m16` holds this docs step (not pushed; ask before push / PR).
- Still waiting on the user: walk the changed maps in the game (`godot --path game`).
- Next: M17 (tactical combat). M17.0 = spike + ADR, plan mode first. Rules in `docs/ROADMAP.md` "M17" and ADR 0022.
  M17.1 changes the save format (v17 -> v18, migration in `core/save_migrations.gd`), so it needs the full suite in a subagent.
- Map / art gotchas kept from M16:
  - Keep props out of a stage map's fight lanes (ADR 0026 lesson: `sim_esthelm_siege`).
  - Map JSON is tab-indented CRLF, one object per line; `json.dumps` does not round-trip it, edit by lines.
  - A door plaque needs a `sign`; every enterable house door needs a sign (`unit_sign_art` lists the maps it checks).
  - `ToyMaps.walk_to_area` is ONE hop. A wide exit shifts `arrive` per cell: `arrive` must be free floor for every cell.
  - New map: a mood in `audio.json`; sim tests that wait in a room park the player away from doorways.
  - After `--import`, do NOT `git checkout` every modified asset blindly (it reverts a rebuilt `edits.png`).
  - Screenshot scene recipe: SubViewport + `WorldView` (see "Screenshot recipe" below); `game/_scratch` is deleted before commit.
  - Art tools: `tools/build_cliffs.py`, `build_houses.py`, `build_signs.py`, `build_windows.py`, `build_objects.py`.

## Screenshot recipe (M16.1)
- Scratch scene `game/_scratch/shot.tscn` + `shot.gd` (`extends Node`, `_ready` calls a deferred coroutine). For each map id in `db.maps.areas`:
  a `SubViewport` sized `MapDb.size * WorldView.TILE` (`UPDATE_ALWAYS`) holds a `WorldView` from `res://world/world_view.tscn`;
  `v.setup(db.maps, {}, db.combat.enemies, {}, "winter")`; `gs = GameState.new(1)`; `gs.flags["winter"] = true` for winter;
  `gs.player.place(id, Vector2i(0,0))`; `v.refresh(gs, db)`; hide `v.player` and `v.atmosphere`; camera zoom 1; wait 4 frames;
  `get_texture().get_image().save_png`. Run with the console exe (not `--headless`): `OUT=<dir> WINTER=1 ONLY=id1,id2 Godot..._console.exe --path game res://_scratch/shot.tscn`.
- `godot --headless --import` may segfault (known) but still imports; then `git checkout -- game/assets/audio game/assets/fonts`.

## Earlier (2026-09-29)
- The user played M14 and sent 8 problems (screenshots in `The Wandering Inn Books 1-17 Pirateaba/Temp/`, not in git).
- Plan written: M15 (readability, lore), M16 (maps, art, cities), M17 (XCOM-style combat) in `docs/ROADMAP.md`;
  decisions and the user's AP rules in `docs/adr/0022-m15-m17-play-report.md`; DESIGN §1 updated.
  Branch `docs/m15-m17-plan` (from main d75adfa). Docs only, no code.
- Earlier: M14 merged (PR #75, tags `m14-done`), archived (PR #76). Rock Crab and day-21 raid stay as they are.

## Next steps
1. Answered 2026-09-29: order M15 → M16 → M17 OK; extra AP uses the TOTAL level (secret: never shown, AP gains
   silent; M15.3 removes "Total level" from the character sheet); level cost by total level + hidden cap 100
   goes in M17.7. All in ADR 0022.
2. M15.0 done on branch `feat/m15.0-font` (stacked on `docs/m15-m17-plan`): Pixel Operator, Large text box in
   Options (`ui/text_settings.gd`, `Session.set_large_text`). Not pushed yet; ask the user before push / PR.
   Screenshot helper: `game/_scratch/shot.gd` (deleted before commit) + `--write-movie`; window size is ignored.
   Test runner: `scratchpad/run_targets.sh <script>...` (gone next session).
3. M15.1: done (see above).
4. M15.2: `ui/hud.tscn` (Bottom panel, Log label, Hint label), `ui/hud.gd` (`LOG_LINES` = 6).
5. M15.3: `world/main.gd:308` (XP line), `ui/character_sheet.gd:56-59`, `ui/system_messages.gd:41-42`,
   `ui/journal.gd:134`. Keep `ui/console_commands.gd` numbers.

## Probe notes (M14.8)
- A test that skips days with `ToyCanon.sleep_through` piles up hunger (max HP x0.5): set `gs.economy.hunger = 0`.
- `unit_bag` and `unit_brawl` leave state in `Session.gs`; a test that reads `Session.gs` should set its own game.
- The wave rule (`Stage.tick`): a wave waits while `here >= max_on_map` (12) and, if `here > 0`, until
  `after_seconds` has passed or `here <= left_at_most`. One player turn = 6 s.

## M14.7 notes
- Journal news stays text only (one Label). A face per news line would need a rebuilt journal.
- `Import` may rewrite `game/assets/fonts/*.import` line endings: `git checkout` them before committing.
- A menu test can feed `InteractMenu.open` hand-made option dicts (needs `id`, `name`, `npc`, `actions`, `sleep`,
  `item`, `price`, `trades`, `ride`); `Session.gs` may be null.

## M14.6 notes
- Theme covers Button, ItemList, PanelContainer, LineEdit, HSlider, Label, CheckBox, RichTextLabel. The System dialog
  keeps its own blue panel and `[Title]` headings stay blue on purpose (System voice).
- Font `.import` is edited by hand: antialiasing=0, hinting=0, subpixel_positioning=0. A reimport keeps it.
- Font (M15.0) is Pixel Operator on a 16 px grid: use 16 or 32 only (`unit_ui_theme` checks the scenes).

## M14.5 notes
- Major NPC = a pending, non-mutate-target canon event names them in a role `prefer` or `requires.alive`
  (`Brawl.is_major`). Warned ids live in `gs.flags["fate_warned.<id>"]`.
- Hostile lasts until the day number changes (`hostile_day == clock.day()`), not until sleep. A long gap heals
  the NPC's hp (old `NpcSim` rule) but not the hostility.
- A test that kills an NPC through `Commands.attack_npc` must keep the player up (`Combat.set_hp(gs, db, 9999)`
  each turn): the hostile NPC hits back after every command.
- `Combat.in_danger` is now also true for a hostile NPC: NPCs near it stand still (NpcReact) and patrons leave.
- `Import` of the project segfaults sometimes (known); GUT runs fine after it anyway.

## M14.4 notes
- Who gets a schedule: canon NPCs with a place on one of our maps. Left out (no map): terbore, tekshia, peslas,
  timbor_parithad, ulia_ovena, theofore, termin, ressa, magnolia_reinhart, esthelm_florist. `princess_thief` is the
  Book 1 placeholder for Lyonette: not linked (confirmed-links-only rule).
- Grev is a `teen` body: the sprite tool cannot read LPC child hair (single `child/<colour>.png`, no walk/ folder).
- The LPC clone is in this session's scratchpad (`.../4654847b-.../scratchpad/ulpc`; gone next session).
- The test-run helper `scratchpad/run_targets.sh` (gone next session) ran one GUT script per Godot call and grepped
  the summary. Monitor with an `until grep -q DONE` loop.

## M14.3 notes
- Town = nearest `settlement` above a map's location (`Standing.town_of`): liscor, celum, esthelm. The inn area
  has no town. Faction = the NPC's canon `faction`.
- A relationship fades only with the player ("player" key) and only after 7 days with no contact
  (`WorldState.contact`). No contact record: the clock starts that night.
- Shop prices use the town of the PLAYER's area, so a price read with the player elsewhere shows no shift.
- Friends (regard >= 10) fight like `rules.npc.react.ally`. A test that talks to one NPC on 10 days will now see
  them fight in a monster fight.
- `Standing.add_reputation(gs, db, key, delta)` is the one writer; M14.5 uses it for witnesses.

## M14.2 notes
- Patron rolls use `Rng.new(seed ^ meal_key * 2654435761)`, not `gs.rng`: the main stream stays the same.
- Patrons roll only at the first command in a meal while the player is in `inn_interior`. Tests that stand in the
  inn at 7-10, 12-14 or 18-22 now get patrons; a patron on a seat blocks the player (not NPCs or monsters).
- Cooking takes 45-120 min; cooking during a meal makes patrons give up (-2 each while the player is in the room).
- `sim_inn_service` cooks between meals for that reason.

## M13 notes
- `MapDb.exit_at` hides gated exits after `sync_flags`; before the first sync every exit shows. Validators must
  use `raw_exit_at`.
- New object kinds use existing sheets: `stairs`, `ladder`, `tombstone`, `grave_cross`, `papers`. Every map
  object needs a kind with art (`unit_ground_art`).
- A new enemy needs: a sheet (or `look`), a voice entry in `audio.json` "enemies" (`unit_sound_cues`), and the
  counts in `unit_combat_db` / `unit_monster_art`. A new creature look also bumps `tools/tests/test_build_creatures.py`.
- A new map needs a mood in `audio.json` and, with spawns, a knock-out wake spot (`sim_liscor_depths` guard).
- Skeletons and zombies now spawn in the dungeon; `sim_skinner_night` allows that only for dungeon maps.
- Traps (M13.T): walking helpers (`ToyMaps.walk_to`) do not avoid hidden traps. A walking test through the
  depths must disarm them first (`gs.combat.traps[Traps.key(area, id)] = {"disarmed": true}`), or a pit drops the
  player into the crypt mid-walk. Use `Traps.key`, never build the key by hand.
- Git Bash heredocs eat a `\` at the end of a line even with `<<'EOF'`. Write Python patch scripts to the
  scratchpad with the Write tool, then run them.
- Godot on this machine: `godot` (WinGet link) returns at once while the real process keeps writing; wait for
  the `Godot_v4` process to exit before reading a log. Better (M13.3): call the console exe directly, it blocks and
  exits cleanly: `/c/Users/rhasa/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe`.
  The link segfaulted once on `--import` in M13.3.

## Audio notes (M12)
- Downloads are in an old session scratchpad (may be gone): Kenney RPG Audio + Impact Sounds, swishes, rubberduck
  creature + water packs (the water pack has loops: rain, bubbles, water; useful for M12.4). Re-download from CREDITS.md links.
- M12.4 loop cutter: `scratchpad/amb/loopify.py` (ffmpeg + numpy; gone next session). It cuts a stretch and
  cross-fades the tail into the head, then writes OGG. ffmpeg is on PATH (WinGet). Not in the repo on purpose (no
  new tool dependency). Raw downloads (fire.wav 10 MB, crowd zip 20 MB) stay out of git.
- Music still unused (CC0): RandomMind "Minstrel Dance" (5.3 MB), "Harvest Season" (8.2 MB); Sir Gawain's
  "CC0 Fantasy Music & Sounds" collection (curator; authors differ per track) has "Forest Ambience", "New Sunrise",
  "Cave Theme" (licence unclear: CC0 or OGA-BY). Ask the user before each download (file, source, size).
- Music `.import` files need `loop=true` (a Python patch on bytes after the first import).
- After adding audio run `godot --headless --path game --import`, then set `loop=true` in a music `.import`
  and import again. Then `git checkout -- game/assets/characters game/assets/objects game/assets/tiles`
  (import noise).
- `Audio` hooks every button through `get_tree().node_added`: menus need no audio code.
- Godot `--import` also rewrites the audio `.import` files with LF: `git checkout -- game/assets/audio` too.
- Never `git commit -am` on a branch with work in progress: it sweeps every changed file into the commit.

## How to rebuild art
- Object edits: `python tools/build_objects.py` then `godot --headless --path game --import`. Append new edits at the END of `EDITS` (the order sets the regions in objects.json). Print regions with `--print`.
- Character sheets: the LPC generator part clone is in the session scratchpad (gone next session). Make a new one
  (the fastest: all parts, only the animations we use plus the oversize weapon slashes; about 200 MB, 1 min):
  `MSYS_NO_PATHCONV=1 git -C ulpc sparse-checkout add '/spritesheets/**/walk.png' '/spritesheets/**/slash.png' '/spritesheets/**/hurt.png' '/spritesheets/**/idle.png' '/spritesheets/**/thrust.png' '/spritesheets/**/walk/' '/spritesheets/**/slash/' '/spritesheets/**/hurt/' '/spritesheets/**/idle/' '/spritesheets/**/thrust/' '/spritesheets/weapon/sword/arming/' '/spritesheets/weapon/blunt/waraxe/'`
  (a new look with another oversize weapon needs that weapon's `attack_slash` folder too).
  Or part by part:
  `git clone --depth 1 --filter=blob:none --sparse https://github.com/LiberatedPixelCup/Universal-LPC-Spritesheet-Character-Generator.git ulpc`
  then in Git Bash use `MSYS_NO_PATHCONV=1 git -C ulpc sparse-checkout set --no-cone /CREDITS.csv /LICENSE /palette_definitions/ /sheet_definitions/` and `... sparse-checkout add /spritesheets/<part folder>/` for each part folder (the folder is `layer_1.<body>` in the part's sheet definition).
- `python tools/build_sprites.py --ulpc <clone>` then `godot --headless --path game --import`.
- Creatures: `python tools/build_creatures.py` (no clone needed; sources in `tools/art/creatures/`).
- The clone now also needs `/spritesheets/weapon/` and `/spritesheets/shield/` in full (halberd, mace, saber,
  scimitar, bows, shields): `MSYS_NO_PATHCONV=1 git -C ulpc sparse-checkout add '/spritesheets/weapon/' '/spritesheets/shield/'`.
- Without `MSYS_NO_PATHCONV=1`, Git Bash turns `/palette_definitions/` into `C:/Program Files/Git/...`.

## Waiting on the user
- Look at M14.6 and M14.7 in the game (`godot --path game`) and say if colours, sizes or the face crop need changes.
- Delete old remote branches `data/book4-*` (optional).

## Book 5 canon notes (M13.7)
- A fight stage with helpers who come at once lets them box the foe in on all four sides; the player never gets a
  hit and the hook never fires. Delay the helper wave (M13.7 uses 30 s). Klbkch joins inn fights 18-21.
- Ryoka dies and is revived in two same-night events (`kill`, then `revive`); nothing between them in id order may
  need her alive.
- 4.31 clears `izril.winter` on day 114: winter rules and snow end there.
- The LPC clone for M13.7 is in this session's scratchpad (`.../47ef78fc-.../scratchpad/ulpc`, only Regrika's parts;
  gone next session).
- The auto-mode safety check failed for a long stretch this session (Bash, PowerShell and Agent all blocked). Read,
  Grep, Write and Edit still worked, so chapter reading and data prep went on by hand.

## Gotchas
- M17.2 combat mode: a fight wait (`Commands.wait`) is ONE round (6 s), whatever seconds you pass; use
  `FightBot.wait_seconds` for "N seconds later" waves. A command refused for AP / move cap / turn changes
  nothing: loops must end the turn (`FightBot`). Frozen tests: `ToyCombat.freeze` (monster AP 0).
- M17.2: monsters and NPC allies may act before the player's first turn (Agility order), so a count of
  foes right after a stage starts can be one short; count `gs.combat.fight["foes"]` instead.
- Commits and PRs: author Daddy-Ousen only. NO `Co-Authored-By: Claude` trailer, no Claude footer.
- **Never use `sed -i` in Git Bash on repo files** - it strips CRLF. All working-copy text files are CRLF (autocrlf=true). Patch with Python on bytes (keep CRLF) or with the Edit tool. Do NOT normalise whole folders.
- `Commands.wait(gs, db, seconds)` takes SECONDS. The clock does pass midnight while awake, but the director only runs on sleep (`Commands.sleep(gs, db, Rest.ANYWHERE)`). Wake time is 6:00, so a stage before 6 is only reachable by staying up.
- A GUT test helper named `_set` clashes with `Object._set` (parse error).
- A stage starts only while its event is pending, the player is on the stage area, inside its hours and its `when_flags` hold (`Stage.is_open`).
- Scene stages place NPCs even off their schedule, but every placed NPC needs an `npc_behaviour` entry.
- Clearing an old "away" flag can wake an old schedule: 3.24 clears `horns_of_hammerad.gone_to_albez`, which put Pisces back on the Floodplains at night; fixed with `unless_flags` in_celum / left_celum.
- Talking to an NPC next to you gives `talk_with_guest` / `persuade` / `comfort_someone` (rules.npc.talk_actions) with the map's location as context; talking adds +1 relationship.
- Screenshots: a throwaway scene in `game/_scratch/` that adds `world/main.tscn` as a child (`add_child.call_deferred`), run with `godot --path game res://_scratch/shot.tscn`. Delete `game/_scratch` before committing.
- New `class_name` scripts need `godot --headless --path game --import` once.
- `-gtest=` is ignored; use `-gselect=<script name> -gdir=res://tests`.
- GUT exits 0 even on a parse error - grep for `Parse Error` and check the script count (92 on the M13.1 branch).
- Validator: `python tools/validate_data.py game/data/canon --all` (the folder with book<N> in it, not a book folder).
- Toy dbs erase `rules.economy`; real-db tests have hunger on.
- Rhir is real; Calruz stays missing; never link two canon entities unless the text says so (Ylawes is Yvlon's brother: 3.24 says so).
- Book 3 "E" chapters are Laken, not Erin. Laken, Geneva, Niers (3.22L) and Venitra use placeholder days.
- Save is v14 (M13.T traps; v13 = M10.0 portal trips). `MapDb` holds maps in `areas`; use `objects_on(area)` or `objects_near`, not `areas[a]['objects']`, so flag-hidden objects stay hidden. Enemy `danger` must be 0.0–1.0.
- Same-day canon order: chain with `depends_on`. Siblings that share one dependency run in id order, so a sibling can clear a flag another still `requires` (M10.1: the rescue cleared `mrsha.fell_into_the_dungeon` before Toren's event). Debug with a throwaway `extends SceneTree` script that prints `gs.world.history` reasons. Helper-only waves come at once when no foe is left; put helper waves before the last foe wave.

- Octavia matters to Book 3: killing her before day 87 cancels 3.25's goodbye and the wagon leaving, which cascades. Kill tests for her must run after day 87.
- Scene stages: `Stage.place_npc` skips an NPC who is already in the stage area, so that NPC stays at their own post (M10.3: Lyonette, Mrsha in the inn). Only NPCs brought in from elsewhere take the stage tile. Hooks that need an NPC next to the player must name NPCs that really are placed.
- Scene `when_flags` are read during the day, before the night's events run: use a flag that is set by an earlier night.
- Python patching: converting line ends twice (LF to CRLF on a string that already has CRLF) leaves a stray CR, and git then shows the file as `-text` and changed in full. Check `git ls-files --eol` after patching.
- Never write a bash `cat > "$UNSET_VAR/..."` line without a heredoc: it waits on stdin and hangs the shell.

- Director dependencies are hard: an event whose `depends_on` was cancelled is cancelled too. Chain events only to events that always happen, or one dead NPC cancels a whole day (M10.4 cut the chains this way). Siblings run in id order, so name ids to sort in story order.
- Effects and scene flags: a flag set by an event on day N is visible on day N+1. An event set and cleared in the same night never shows in a schedule (`erin.at_esthelm`).
- Fight-stage tests: a helper that walks to `Pathfind.around(at)` can stop on a diagonal square and never attack. Walk to the four side squares instead (`sim_book4_christmas._fight_turn`). Strong allies that arrive at once can kill weak foes before the player strikes; delay the ally wave.
- A throwaway `extends SceneTree` script that errors before `quit()` hangs Godot headless forever. Use `_initialize()`, and run with `timeout 300`.

## Graphics notes (M11)
- Core must not change for art. The view compares old and new state after each command and plays tweens; tweens never block input.
- Missing art must fall back to today's squares, so headless tests and new data never break.
- `.import` and `.uid` files are kept in git (ADR 0001). Run `godot --headless --path game --import` after adding art or scripts.
- The player marker moves at once; only the `CharacterSprite` child glides (tests read `player.position`).
- Monster markers: toy enemy types (`goblin`, `crab`) have no sheet and stay squares; `unit_world_view` checks their
  child order (edge, ring, body, label, bar). A sprite monster is (Ring, CharacterSprite, label, bar back, fill).
- A test that needs a sprite monster copies the toy goblin def to a real look id (`unit_monster_art.ART_GOBLIN`).
- Screenshot scenes: monsters added by hand with `Combat.add_monster` (no spawn entry) are removed by the first
  command (`Commands.attack`), and the view plays a fall for each. Change state by hand instead
  (`gs.combat.monsters.erase(id)`, `Combat.set_hp`).
- Part colours: a variant-folder part takes the file name as its colour (`kite_gray`, not `kite gray`).
  `body_zombie` needs a colour it cannot get: use body `male` with skin `zombie` / `zombie_green` and `heads_zombie`.
  `torso_clothes_tunic` has no male body.
- LPC tile packs: `lpc_terrains` fills: grass (1,10) + tufts (0..2,12), light grass tufts (3..4,12), dirt (1,3)/(1,5), grey cobble (13,3), snow (22,10)/(21..22,12), water (1,17), frozen dirt (25,12). `lpc_atlas`: pine (30,0,2,5), round tree (29,28,3,4), grey rock (28,26,1,1), stone wall face (17,24).
- Screenshots: `godot --path game --write-movie <file>.png --fixed-fps 10 --quit-after 12 res://_scratch/shot.tscn` (window is 1152x648; `--resolution` is ignored).
- M11.5 shot scene: `_scratch/shot.gd` reads AREA, X, Y, MINUTE, ZOOM (0 = keep 2), WINTER=1 from env vars;
  use `--quit-after 30` so snow has fallen. Stitch frames with PIL.
- M11.1 shot scene: a `_scratch/shot.gd` that makes a WorldView, a `GameState.new(1)`, `gs.player.place(AREA, pos)`, `v.refresh(gs)`, and sets `v.camera.zoom` (0.8 shows a whole 32x24 map). Read AREA/X/Y/ZOOM/WINTER from env vars. Winter: pass "winter" as the winter flag to `setup` and set `gs.flags["winter"]`.
- Terrain block layout (`lpc_terrains`, 3x6): rows 0-1 inner corners (SE gap (1,0), SW (2,0), NE (1,1), NW (2,1)), rows 2-4 ring, row 5 fills. Blocks used: dirt (0,0), cave (15,0), chasm (24,0), grass (0,7), light grass (3,7), snow wall (18,7), snow (21,7), frozen dirt (24,7), shallows water (0,14), light sea (24,14).
- Object regions are PIXELS in objects.json (tile props in tiles.json are CELLS).
- Picking art: a scratch `zoom.py` (crop + 16 px grid + px labels) was the fastest way to read exact pixel rects.

- M11.3: a fight screenshot is a `--write-movie` run (`--fixed-fps 20 --quit-after 30`) of a `_scratch` scene whose
  `_process` sends commands at set times (attack at 0.25 s, then `Combat.set_hp` to hurt the player); stitch frames with
  PIL. Freeze monsters (`act_seconds` huge) and set `rules.combat.hit` min/max 1.0. A hand-made NPC entry needs every
  field of `NpcSim` (`carry`, `route_i`, ...) or the sim errors.
- AnimDiff guesses swings from state (core has no hit log): a monster miss shows nothing; NPCs never swing.
- Weapon parts keep one file per colour (walk/<colour>.png): they need a `color` (sword "steel", spear "iron", waraxe "waraxe", dagger "dagger", staff "simple"). The `muscular` body has almost no clothes: use `male`.
- A look preview is fastest with a scratch `preview.py` that imports `build_sprites` and pastes the standing frames of each look into one image.
- Screenshots of NPCs: `_scratch/shot.gd` must be the script of a `_scratch/shot.tscn` (running the .gd alone opens the title menu). Fill `gs.npcs.npcs[id] = {"area", "x", "y", "facing"}` by hand to line up many NPCs.
- Godot `--import` rewrites some old `.import` files with LF; they show as changed with no content diff. `git checkout -- game/assets/objects game/assets/tiles` before committing.

## Book 5 canon notes (M13.6)
- Test trap: a test that waits on `inn_hill` on the morning of day 110 is attacked by the Razorbeak stage and
  knocked out; `Commands.wait` then returns -1 forever. An unbounded `while _hour(gs) < N` loop spews 800k lines.
  Wait indoors and bound every wait loop (`sim_book5_creler_nest._wait_indoors_until`).
- "Regrika" at Liscor is Venitra (4.27 H): no NPC for Regrika; never place Venitra in a scene before 4.27 H (the name
  would spoil it). Imenet is its own NPC (not linked to Ijvani).
- The LPC clone for M13.6 is in this session's scratchpad (`.../854c7124-.../scratchpad/ulpc`; gone next session).
- The Bash tool's safety check sometimes stalls on long Godot runs in subagents; PowerShell works.

## Active files
- M13.7: `game/data/canon/book5/chapters/4.28.json` ... `4.31.json`, `4.24.json`, `4.27H.json`, `book5/npcs.json`,
  `book3/npcs.json` (Ijvani), `game/data/enemies.json`, `appearance.json`, `audio.json`, `npc_behaviour.json`,
  `game/assets/characters/regrika_blackpaw.png`, `game/tests/sim_book5_last_light.gd`, `sim_canon_book5.gd`,
  `docs/adr/0020-m13-book5.md`.
- M13.6: `game/data/canon/book5/chapters/4.24.json` ... `4.27H.json`, `game/data/maps/esthelm_creler_cave.json`,
  `game/data/maps/esthelm_ruins.json`, `game/data/enemies.json`, `game/data/appearance.json`, `game/data/audio.json`,
  `game/data/rules.json`, `game/data/npc_behaviour.json`, `game/tests/sim_book5_creler_nest.gd`,
  `game/tests/sim_canon_book5.gd`, `docs/adr/0020-m13-book5.md`.
- M13.5: `game/data/canon/book5/chapters/4.18.json` ... `4.23E.json`, `game/data/canon/book5/npcs.json`,
  `locations.json`, `game/data/npc_behaviour.json`, `game/data/appearance.json`, `game/tests/sim_book5_rift_undead.gd`,
  `game/tests/sim_canon_book5.gd`, `docs/adr/0020-m13-book5.md`.
- M13.4: `game/data/canon/book5/chapters/1.02D.json` ... `1.06D.json`, `game/data/canon/book5/npcs.json`,
  `game/tests/sim_book5_geneva.gd`, `game/tests/sim_canon_book5.gd`, `docs/adr/0020-m13-book5.md`.
- M13.3: `game/data/canon/book5/chapters/4.13L.json` ... `4.17.json`, `game/data/canon/book5/npcs.json`,
  `locations.json`, `game/data/npc_behaviour.json`, `game/data/appearance.json`, `game/tests/sim_book5_pawns_faith.gd`,
  `game/tests/sim_canon_book5.gd`, `docs/adr/0020-m13-book5.md`.
- M13.0: `game/core/map_db.gd`, `game/data/maps/liscor_depths.json`, `game/data/maps/liscor_crypt.json`,
  `game/data/maps/inn_upper_floor.json`, `game/data/maps/inn_watchtower.json`, `game/data/enemies.json`,
  `game/tests/unit_gated_exits.gd`, `game/tests/sim_liscor_depths.gd`, `game/tests/sim_inn_third_floor.gd`, `docs/adr/0020-m13-book5.md`.

## Book 5 canon notes (M13.1)
- Event ids carry a letter after `b5.` (`b5.a_...`) so same-day siblings sort in story order.
- Scene NPC talks: `ToyMaps.walk_next_to` works on objects only. For an NPC, walk to its four side squares with
  `ToyMaps.walk_to(gs, db, sides)` (`sim_book5_soups._do_with`).
- Canon notes and summaries are capped at 300 characters by the validator; put long reasoning in the ADR.
- Every chapter file needs `"system": []` even with no level-ups.
- Every NPC in `npc_behaviour.json` needs its OWN look in `appearance.json` (`unit_art`), so placing a new NPC in a
  scene means a new sheet: `python tools/build_sprites.py --ulpc <clone> --only <id>`, then `--import` and
  `git checkout -- game/assets/characters` (import noise; the new png/import are untracked so they stay).
- Chapter data for M13.2 came from a generator script (scratchpad, gone next session). New NPCs appended to
  `book5/npcs.json` by `json.dumps(indent="	")` keep the file format.

## Book 5 canon notes (M13.3)
- 4.12's `ryoka.plans_to_visit_garias_farm` is set by an event that needs Pawn AND Bird alive; do not require it.
  The farm trip requires `ryoka.home_at_the_wandering_inn` instead.
- `--import` also rewrites every audio/character `.import` with LF: `git checkout -- game/assets/audio game/assets/objects game/assets/tiles`
  and `git ls-files -m game/assets/characters | xargs -r git checkout --` (keeps new untracked sheets).
- The LPC clone for M13.3 is in this session's scratchpad (`.../5c0f7f5b-.../scratchpad/ulpc`; gone next session).

## Book 5 canon notes (M13.4)
- Off-map arcs on days before Book 5's FIRST_DAY (97) still count in `sim_canon_book5` (it sleeps to 96 in
  before_all and checks every b5 event up to LAST_DAY). Kill tests for them need their own file that starts earlier
  (`sim_book5_geneva` sleeps to day 76).
- A chapter generator script was in the scratchpad (gone next session).

## Book 5 canon notes (M13.5)
- The LPC clone for M13.5 is in this session's scratchpad (`.../c8921a2b-.../scratchpad/ulpc`; gone next session).
- The chapter generator was `scratchpad/gen_m135.py` (gone next session). DataDb checks that stage foe tiles are
  walkable; the Python validator does not, so run the new sim test once before the full suite.
- `sim_book5_geneva.gd.uid` was missing from the M13.4 commit; added in M13.5.
- Laken's events need only Laken alive and chain on flags. The Laken kill test is in `sim_canon_book5`.
- Never pass text with backticks through an unquoted bash heredoc (`<<EOF`): bash runs them as commands. Write
  Python patch scripts to the scratchpad with the Write tool.

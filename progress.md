# Progress

M0–M16 detail (roadmap bullets, decisions, ADR 0001–0026) lives in
`docs/PROGRESS_ARCHIVE.md`. Read the archive only when you need that old detail.

## Context discipline (all sessions)
- Redirect GUT / validator runs to a file (scratchpad). Read only the pass/fail summary line and any FAIL/Error/Parse Error lines — never the full run.
- Delegate chapter-text reading (for canon extraction) and full test-suite runs to a subagent. Only its short summary should land in the main session's context, not raw book text or raw test logs.
- Don't re-read a file right after Edit/Write — the tool already confirms the change.
- Test scope (user, 2026-09-30): run the absolute minimum tests per task; no full suite unless the user asks. Detail in `CLAUDE.md` "Test scope".
- See `handoff.md` "Gotchas" for the GUT-exits-0-on-parse-error trap and other run-output pitfalls.

## Roadmap status
- [x] M0–M7 — Book 1 and the engine. Tags `m0-done` … `m7-done`, `m7.4-done`, `m7b-done`.
- [x] M8 — Book 2 (Fae and Fare) + Celum. M8.0–M8.6 merged and tagged; M8.7 merged ([PR #34](https://github.com/Daddy-Ousen/innworld-rpg/pull/34), tags `m8.7-done` and `m8-done` on merge commit ad436eb). Detail in the archive and ADR 0014 / 0015.
- [x] M9 — Book 3 (Flowers of Esthelm). M9.1–M9.4 merged; tags `m9.1-done` … `m9.4-done` and `m9-done` on merge commit 9e8f179 ([PR #39](https://github.com/Daddy-Ousen/innworld-rpg/pull/39)). Detail in the archive and ADR 0016.
- [x] M10 — Book 4 (Winter Solstice). M10.0–M10.5 merged; tags `m10.0-done` … `m10.5-done` and `m10-done` on merge commit 25b8d94 ([PR #45](https://github.com/Daddy-Ousen/innworld-rpg/pull/45)). Detail in the archive and ADR 0017.
- [x] M11 — Graphics, characters and animation. M11.0–M11.5 merged; tags `m11.0-done` … `m11.5-done` and `m11-done` on merge commit 7bb4656 ([PR #51](https://github.com/Daddy-Ousen/innworld-rpg/pull/51)). Detail in the archive and ADR 0018.
- [x] M12 — Audio: music, sound effects, ambience. M12.0–M12.5 merged; tags `m12.0-done` … `m12.5-done` and `m12-done` on merge commit 95fb6c4 ([PR #57](https://github.com/Daddy-Ousen/innworld-rpg/pull/57)). Detail in the archive and ADR 0019.
- [x] M13 — Book 5 (The Last Light). M13.0, M13.T, M13.1–M13.7 merged; tags `m13.0-done` … `m13.7-done` and `m13-done` on merge commit 17b6bab ([PR #66](https://github.com/Daddy-Ousen/innworld-rpg/pull/66)). Detail in the archive and ADR 0020.
- [x] M14 — Engine works: bag, cooking, guests, standing, NPC schedules, attack NPCs, UI skin, portraits, balance. M14.0–M14.8 merged; tags `m14.0-done` … `m14.8-done` and `m14-done` on merge commit a08c23a ([PR #75](https://github.com/Daddy-Ousen/innworld-rpg/pull/75)). Detail in the archive and ADR 0021. The user still has to play it (`godot --path game`).

- [x] M15 — Readability and lore fixes (font, player day, small HUD log, no XP numbers). M15.0–M15.3 merged as one PR ([PR #77](https://github.com/Daddy-Ousen/innworld-rpg/pull/77), merge commit b93e2df). Detail in the archive and ADR 0022.
- [x] M16 — Maps, art and cities. M16.0-M16.6 merged as one PR ([PR #78](https://github.com/Daddy-Ousen/innworld-rpg/pull/78), merge commit 98a3b08). Detail in the archive and ADR 0023-0026. The user still has to walk the maps (`godot --path game`).
- [x] M17 — Tactical combat, XCOM-style. M17.0–M17.8 merged ([PR #79](https://github.com/Daddy-Ousen/innworld-rpg/pull/79) … [PR #87](https://github.com/Daddy-Ousen/innworld-rpg/pull/87), last merge commit a7a5e37). Detail in the archive and ADR 0027.
  Tags `m17.0-done` … `m17.8-done` and `m17-done` are on GitHub (checked 2026-10-01).
  - [ ] The user plays fights with Skills, spells and cover (`godot --path game`). Needs the user at home.
- [ ] M18 — Book 6 (The General of Izril). M18.P – M18.7 merged; detail in `docs/PROGRESS_ARCHIVE.md`.
  - [ ] The user plays Book 6 (`godot --path game`).
- [x] itch.io page kit (2026-10-02, branch `docs/itch-page`): `docs/ITCH.md` (tagline, description, settings, tags,
  Comments on). Cover 630 × 500 (two choices) and 6 screenshots in `export/itch/` (local, gitignored), made from the
  real game. Checked by eye.
  - [x] The user made the itch.io page: https://rhasasn229.itch.io/innworld-rpg (public, browser play, comments on).
  - [x] README links the itch.io page (top links and "In your browser").
- [ ] Class tree from the wiki (branch `feat/class-tree-wiki`, 2026-10-07, local). Step 1 done: 6 advancement classes on today's tags
  (`veteran_warrior`, `exemplar_warrior`, `scout`, `veteran_scout`, `elementalist`, `cryomancer`) + 7 passive Skills. Advancements use
  `prereqs.classes` (no schema change; the base class stays). Tests run: `unit_data_db`, `unit_class_system`, `unit_skill_system`,
  `unit_levels`, `unit_journal`, `unit_system_messages`, `sim_decline`, validator, Python tool tests (105). All pass. Full suite not run.
  - [x] Step 2 (2026-10-07, local): tags `riding`, `animals`, `gardening`, `faith`; actions `ride_horse`, `tend_animals`, `tend_garden`, `pray`
    (sounds reuse `creak`, `pick_up`, `chime`); map objects on existing art: `garden_bed` (inn_hill), `hitching_post` and `stable_yard` (celum_gate),
    `wayside_shrine` (celum_square); classes `rider`, `gardener`, `beast_tamer`, `acolyte`, `priest`, `bishop`, consolidations `dragoon`
    (warrior+rider, cost 2) and `druid` (gardener+beast_tamer+mage, cost 3); 8 passive Skills. Tests run: `unit_class_tree_step2` (new, 4),
    `unit_data_db`, `unit_tags`, `unit_actions`, `unit_audio_data`, `unit_sound_cues`, `unit_map_db`, `unit_ground_art`, `unit_class_system`,
    `unit_skill_system`, `unit_world_view`, `sim_winter`, validator, Python tool tests (105). All pass. Full suite not run.
  - [x] Step 3 (2026-10-08, local; branch `feat/class-tree-step3`): classes `hunter`, `archer`, `alchemist`, `blacksmith`, `teacher`, advancements `knight` (after `exemplar_warrior`) and `assassin` (after `rogue`); 8 passive Skills. Existing tags only, no new actions or objects. Tests run: `unit_class_tree_step3` (new, 3), `unit_class_tree_step2`, `unit_data_db`, `unit_class_system`, `unit_skill_system`, `unit_levels`, `unit_journal`, validator. All pass. Full suite not run.
  - [ ] The user plays: do the new objects feel right? Later steps could add NPC users of these classes.
  - Skipped on purpose: Erin/NPC-unique classes (Rocksoup Cook, Wandering Innkeeper, Goblinfriend Innkeeper), Skeleton, Bandit, Necromancer lines.
- [x] North road (2026-10-08, local; branch `feat/invrisil-road`): maps `celum_north_gate`, `road_to_invrisil` (camp), `invrisil_gate`, `invrisil_square`; `celum_main_street` got a north exit; `riverfarm` got its road to the Invrisil gate (west edge). Times 1500 / 3100 / 900 min (guess). Data only. Tests run: `unit_north_road` (new, 5), `unit_map_db`, `unit_audio_data`, `unit_ambience`, `unit_ground_art`, `unit_world_view`, `unit_gated_exits`, `unit_other_maps`, `unit_travel`, `unit_travel_prompt`, `sim_book7_riverfarm` (updated), validator, Python tool tests (105). All pass. Full suite not run. The user walks it (`godot --path game`, Celum main street north).
- [x] Invrisil city (2026-10-08, local; branch `feat/invrisil-city`): `invrisil_main_street` (north of the square) with `invrisil_runners_guild` (parcel board), `invrisil_crag_pig` (inn, bed 10, shop `crag_pig`), `invrisil_merchants_guild` (shop `invrisil_merchants`, truth-stone plaque); square stall `invrisil_stall`. Hedault's house is a closed plaque. Data only; layouts, prices and stock are guesses. Tests run: `unit_north_road` (now 7), `unit_map_db`, `unit_economy`, `unit_audio_data`, `unit_ambience`, `unit_ground_art`, `unit_world_view`, `unit_other_maps`, `unit_data_db`, `sim_celum_trip`, validator, Python tool tests (105). All pass. Full suite not run. The user walks it.
- [x] Invrisil staff (2026-10-08, local; branch `feat/invrisil-staff`): behaviour for canon NPCs `merec` (Merchants' Guild, 8-18) and `raisha` (gnoll guard, `invrisil_gate`, 6-20); off-map place `invrisil`. Posts are guesses; no art (square markers). The Invrisil Runners' board already had `deliver_parcel`. Tests run: `unit_north_road` (now 8), `unit_behaviour_db`, `unit_npc_sim`, validator. All pass. Full suite not run.
- [x] Magnolia's estate (2026-10-08, local; branch `feat/magnolia-estate`): maps `magnolia_estate_grounds` and `magnolia_estate_hall` (chess table, hearth); `invrisil_gate` got an east exit (20 min, guess). Layout and direction are guesses; no golems, no NPCs, no events. Tests run: `unit_north_road` (9), `unit_map_db`, `unit_audio_data`, `unit_ambience`, `unit_ground_art`, `unit_world_view`, `unit_other_maps`, `unit_gated_exits`, `unit_data_db`, `unit_travel`, validator, Python tool tests (105). All pass. Full suite not run.
- [x] Estate NPCs (2026-10-08, local; branch `feat/magnolia-npcs`): behaviour for `magnolia_reinhart` (hall 10-20), `ressa`, `reynold` (hall 6-22), new canon records `reinhart_golem_west` / `_east` (book2, confidence likely; guard posts on the grounds, always). Off-map place `magnolia_estate`. Magnolia's whereabouts in other books (Celum, road) are not tracked: the sim shows her at the estate by day, a guess. No art (square markers). Tests run: `unit_north_road` (10), `unit_behaviour_db`, `unit_npc_sim`, `unit_canon_db`, `sim_canon_book1` - `3`, `sim_book6_world`, validator, Python tool tests (105). All pass. Full suite not run.
- [ ] Later (user, 2026-10-08): (1) Runners' Guild staff in Invrisil: no canon NPC found, so none added. (2) Character sheets for Merec, Raisha and the estate NPCs. (3) Track Magnolia's real whereabouts by flags; the Earth-transplants' stay (2.37).
- [x] Release keystore + icon check (2026-10-08): already done in M20.2 / v0.1.3 (keystore `%USERPROFILE%\.android\innworld-release.keystore`, password file next to it, outside git; icon `game/icon.png` 512 x 512 looked at: house at night, fine). v0.1.3-alpha is released with the signed apk.
  - [ ] The user backs up the keystore and its password file (a lost key means no updates to an installed app). Only the user can do this.
- [x] World wireframe (branch `docs/world-wireframe`, 2026-10-08, local): `docs/WORLD_WIREFRAME.md` + `docs/world_wireframe.svg`. Compass and order rules for continents and the Izril corridor (Liscor – Esthelm – Celum – Invrisil – Riverfarm SW of Invrisil; Pallass 400 mi S), with confidence marks and open questions. Docs only. No tests run. PR waits for the user to merge.
- [ ] M20 — Touch controls (ADR 0032, plan `docs/plans/m20.md`). User answers 2026-10-05: InputMap actions, 4-way D-pad,
  fight tap = plan then act, M20.0 + M20.1 in one PR.
  - [x] M20.0 input actions + M20.1 touch layer (branch `claude/whats-next-xpoe4w`, 2026-10-05, cloud). Checked on Xvfb renders
    (walk, More, panel + Back, fight + Cancel, bag). Also fixed `sim_player_hooks` (stale hook count 48 → 56, red on main since M18).
    Tests run: `unit_touch_controls` (new, 15), `unit_input_actions` (new, 6), `unit_play_loop`, `unit_hud_log`, `unit_bag`,
    `unit_combat_screen`, `unit_skill_bar`, `unit_spell_ui`, `unit_world_view`, `unit_journal`, `unit_console`, `unit_cover_ui`,
    `unit_audio_settings`, `unit_ui_theme`, `unit_system_messages`, `unit_no_xp_shown`, `unit_standing`, `sim_player_hooks`.
    All pass (200). Full suite not run. PR waits for the user to merge.
  - [x] Merged ([PR #105](https://github.com/Daddy-Ousen/innworld-rpg/pull/105), merge commit cd27adf).
  - [x] M20.3 UI scale (branch `claude/whats-next-xpoe4w`, 2026-10-05, cloud; ADR 0033, plan `docs/plans/m20.3.md`). User answers:
    the map and the touch pad keep their size. Checked on Xvfb renders (phone 2400 × 1080 at 100 % / 200 %, desktop at 150 %).
    Also: CLAUDE.md "No screen, but renders work". Tests run: `unit_ui_scale` (new, 8), `unit_touch_controls`, `unit_input_actions`,
    `unit_audio_settings`, `unit_ui_theme`, `unit_journal`, `unit_bag`, `unit_world_view`, `unit_play_loop`, `unit_hud_log`,
    `unit_combat_screen`, `unit_skill_bar`, `unit_spell_ui`, `unit_console`, `unit_cover_ui`, `unit_system_messages`, `unit_standing`,
    `unit_no_xp_shown`. All pass (202). Full suite not run. PR waits for the user to merge.
  - [x] Merged ([PR #106](https://github.com/Daddy-Ousen/innworld-rpg/pull/106), merge commit 6a79b46).
  - [ ] The user plays with touch and Menu size on a phone (browser build after the next release) and on a touch-screen PC.
  - [x] M20.2 Android build (branch `feat/m20.2-android-build`, 2026-10-08, local; ADR 0034): preset `Android`, sensor landscape, ETC2/ASTC on. Debug APK exported (89 MB), signed, checked with apksigner and aapt. Not run on a phone (none plugged in). Icon (`game/icon.png`) and signed release APK added later the same day; keystore kept outside git (ADR 0034). Open: user installs and plays it; back up the keystore.
- [x] M17.9 Work duress for non-fighters (branch `claude/whats-next-xpoe4w`, 2026-10-05, cloud; ADR 0027 "M17.9", plan `docs/plans/m17.9.md`).
  User answers: work duress in data, level 5 by night 9 – 10, crowd and cold. Inn worker: level 5 on night 10 (was 14); fighter unchanged.
  Also fixed `sim_winter` (red on main since M18.2: Bird on a snow wall tile in the 4.32 G stage). Tests run: see ADR 0027 "M17.9".
  All pass. Full suite not run. Merged ([PR #107](https://github.com/Daddy-Ousen/innworld-rpg/pull/107), merge commit 01d1863).
  - [ ] The user plays a busy inn day and a winter walk to feel the pace (`godot --path game`).
- [x] XP windows for Books 1 – 5 (branch `data/xp-windows-books1-6`, 2026-10-06, local). User chose the table: 9 events got `xp_window` on the stage hours.
  Tier 3 (x3): 3.20T Esthelm. Tier 2 (x2): 1.29, 2.26, 4.19, 4.29. Tier 1 (x1.5): 1.42, 2.05, 3.21L, 4.27H. Book 6 stays without windows (user, M18 batches).
  Tests run: `unit_xp_window`, `sim_canon_book1` – `sim_canon_book6`, `sim_skinner_night`, `sim_book6_eater_goats`, validator (0 errors), Python tool tests (102). All pass. Full suite not run.

  Merged ([PR #110](https://github.com/Daddy-Ousen/innworld-rpg/pull/110), merge commit 01f1adb).

- [ ] M19 — Book 7 (The Rains of Liscor). Plan: ADR 0030. M19.P – M19.9 merged; detail in `docs/PROGRESS_ARCHIVE.md`.
  - [ ] The user looks at the rain (`flag izril.rains` in the console, then walk outside) and hears it.

- [x] Floating touch stick (2026-10-08, user request): replaces the D-pad; `ui/touch_controls.gd`, `unit_touch_controls` (18 pass), ADR 0032 note. The user still has to try it on a phone. PR open (branch `feat/touch-stick`).

- [x] Phone UI bigger and see-through (2026-10-08, user request, branch `feat/mobile-ui-bigger`): on a phone OS (Android, iOS, or a browser on them) Auto menu size is 250 % (`UiScale.MOBILE`) whatever the dpi says; panel, button and list boxes are 78 % opaque (`UiScale.MOBILE_ALPHA`, theme edited at run time). Desktop unchanged. Tests run: `unit_ui_scale` (9), `unit_ui_theme`, `unit_touch_controls`, `unit_audio_settings`. All pass. Full suite not run. The user still has to look at it on a phone.

- [x] Long road confirm + walk scene (2026-10-08, user request, branch `feat/long-road-confirm`): an exit of 300 min or more (Celum <-> camp <-> Liscor, 10 h) asks "Travel to X?" first, then plays a 1.8 s walker-on-a-track scene; the move happens at its end. Stay or Esc cancels. `ui/travel_prompt.gd` (new), `world/main.gd`. Off headless-only (`confirm_travel`). Wagon rides and the 180 min Esthelm roads do not ask. Tests run: `unit_travel_prompt` (new, 6), `unit_travel`, `unit_input_actions`, `unit_touch_controls`, `sim_celum_trip`, `unit_hud_log`. All pass. Full suite not run. The user still has to look at it (`godot --path game`, walk onto the Celum south exit).

## Audit (2026-10-08, local, read-only; no code changed)
- [x] Findings split into modules M21 – M26 in `docs/ROADMAP.md` "Audit work" (2026-10-09). Work them from there; the list below is the source.
- [x] Each M21 – M26 step has a model tag `[Model · effort]` (2026-10-09, branch `docs/roadmap-model-tags`). Default Sonnet · medium.
- [x] `docs/ROADMAP.md` shows open work first and done milestones at the bottom, newest first (2026-10-09, branch `docs/roadmap-open-first`).
- [ ] M21 Housekeeping (M21.0 – M21.3 and M21.5 done 2026-10-09) · [ ] M22 Breakthroughs · [ ] M23 Canon bends · [ ] M24 Level by living · [ ] M25 NPC life · [ ] M26 Code health
- Healthy: hard rules hold (all RNG via `gs.rng`, core is 58 `RefCounted` files, UI does not write state), validator 0 errors, Python tool tests 105 OK.
- [ ] BUG: no class can pass level 9. Capstones 10/20/30 need a breakthrough, and only the debug console grants one (`ClassSystem.grant_breakthrough`; no event effect, no data). Needs a design pick (user).
- [ ] Divergence is thin: Books 2–7 have 0 `substitute` / `delay` / `mutate` fallbacks (all 838 events are `cancel` only); 67 of 1089 events have hooks (Book 2: 3 of 207).
- [x] Commit 565bc9b on `feat/class-tree-wiki`: not merged; redo in M22.3 (M21.1).
- [ ] New classes `hunter`, `archer`, `alchemist`, `blacksmith`, `teacher` have no own action (no hunt, shoot, brew, forge, teach). Thin pools: 4 spells, 4 recipes, 5 items.
- [ ] Cleanup: 36 merged local branches; README counts stale (898 events / 38 maps → 1089 / 50); this file and `handoff.md` are long (archive done items).
- [ ] Full GUT suite last run at M17.6. Two sims were found red later. One full run (subagent) when the user asks.
- [ ] Legal: policy read 2026-10-09 (DESIGN §7). Games not named; book titles in marketing are forbidden. Page text reworded 2026-10-09 (no title in marketing). Asking pirateaba is still optional (user).
- [ ] About 9 "the user plays …" checks are open (M17, M18, M19 rain, M20 phone, touch stick, phone UI, long road, class objects, north road).

## Releases (ADR 0029)
- [x] v0.1.3-alpha (branch `release/v0.1.3`, 2026-10-08, local): version bump (code 2), `tools/release.ps1` now also builds the signed apk. Smoke tests pass (events=1089, maps=40, problems=0). Three zips + `InnworldRPG-v0.1.3-alpha-android.apk` built. Waits: user merges the PR, then tag + `gh release create` with all four files.
- Older releases v0.1.0 – v0.1.2, the README rewrite and the web build: see `docs/PROGRESS_ARCHIVE.md`.
- [ ] Web build: later, own subdomain (CNAME + Settings → Pages → Custom domain).

## Cloud setup
- Done; detail in the archive. Book text in a cloud session: attach `Daddy-Ousen/innworld-canon-raw` (add_repo), clone it
  to `/home/user/innworld-canon-raw`, then link `canon/raw/book6` and `canon/raw/book7` to it (or run `bash tools/cloud/setup.sh --force`).

## After M8
- [x] Ryoka never gains a level (user, 2026-09-26): merged ([PR #35](https://github.com/Daddy-Ousen/innworld-rpg/pull/35)).

## Completed (current engine state)
- Canon: Book 1 (1.00–1.63, days 1–41), Book 2 (Interlude – The Call to 2.48, days 41–71) are complete event data. Book 3 (3.00E–3.25 + 1.00D/1.01D, days 71–87; Laken's thread days 46–91) is complete event data. Book 4 (3.26G–Interlude – Winter Solstice, days 85–96) is complete event data. Book 5 (4.00 K – 4.31 + 1.02 D – 1.06 D, days 97–114, Laken 100–115; 4.00 K – 4.06 K are history notes in ADR 0020) is complete event data.
- Godot 4.7.2 project in `game/`, GUT 9.7.1 in `game/addons/gut`.
- Canon Book 6 (M18.7): all chapters are event data (days 114 – 130). The Depthless Doctor has no events (non-canon).
- Core: `xp_window` (M17.8), `monster_abilities` (M17.7), `cover` (M17.6), `economy`, `economy_state`, `economy_db`, `rest` (M8.6), `portal` (M10.0), `stage` (waves, M7.B), `npc_react`, `save_slots`, `rng`, `game_state` (SAVE_VERSION=20), `save_migrations` (1→…→20), `encounter` (M17.1–M17.2), `combat_skills` (M17.4), `mana`, `spells`, `spell_db` (M17.5), `inn_state`, `guests`, `standing`, `brawl`, `cooking`, `traps`, `combat_db`, `stats`, `combat_state`, `combat`, `monster_sim`, `save_codec`, `behaviour_db`, `utility_ai`, `npc_roster`, `npc_sim`, `map_db`, `player_state`, `movement`, `interact`, `pathfind`, `canon_db`, `world_state`, `director`, `clock`, `tags`, `data_db`, `action_log`, `xp`, `actions`, `progression`, `levels`, `skill_system`, `class_system`, `night`, `commands`.
- Audio (M12.0-M12.5): `world/music_pick.gd`, `world/ambience_pick.gd`, autoload `Audio` (`ui/audio.gd`), `ui/audio_db.gd`, `ui/audio_settings.gd`, `ui/options_menu.tscn`, `data/audio.json`, `world/sound_cues.gd`, `game/default_bus_layout.tres`, `game/assets/audio/`.
- UI: `ui/title_menu.tscn` (main scene), `ui/pause_menu.tscn`, `ui/slot_list.tscn`, `ui/journal.tscn`, `ui/session.gd` (autoload), `ui/hud.tscn` (HP line), `ui/interact_menu.tscn`, `ui/system_messages.gd`, `ui/system_dialog.tscn`, `ui/character_sheet.tscn`, `ui/console_commands.gd`, `ui/debug_console.tscn` (also the overlay). World: `world/main.tscn` (main scene), `world/world_view.tscn`.
- Data: `tiles.json`, `maps/` (liscor_gate, liscor_market, floodplains_south, inn_hill, inn_interior, ruins_entrance, celum_gate, celum_square, celum_runners_guild, road_camp, celum_frenzied_hare, esthelm_ruins, bee_cave, celum_stitchworks, dungeon_rift, and from M18.1 wirclaw_village, inn_basement, liscor_ruins_hall, liscor_ruins_ossuary), `npc_behaviour.json`, `enemies.json`, `items.json`, `economy.json`; rules `npc`, `combat`, `winter`, `economy`, `portal`.
- Tests: about 133 GUT scripts (last full suite at M17.6, all pass); M17.7 – M18.1 ran only the scripts they touch (user rule). Runner: `bash tools/run_tests.sh <script>... | --all`. Python tool tests: 102 pass (`python -m unittest discover -s tools/tests`).
- Tools: `tools/extract_epub.py`, `tools/validate_data.py`, `tools/build_sprites.py`, `tools/build_objects.py`, `tools/build_creatures.py` (all need Pillow: `pip install -r tools/requirements.txt`), `tools/build_sfx.py` (standard library only).

## Blockers
- None.

## Balance note
- M6.5: levels cost less (base_xp 40, growth 1.25). A hard inn worker: first class on night 1–3, level 5 by about day 18–21 (`sim_m6_done`: [Cook] level 6 by day 22). Canon Erin is level 9 by day 9; the player is not meant to match her.
- M17.7: cost by total level, hidden cap 100, gentler curve after level 10. M17.8: fighters (two Goblin fights a day) reach level 5 on night 6–7, the inn worker on night 14. The curve was not changed. M17.9: work duress (crowd, cold) brings the busy inn worker to level 5 on night 10.

## Repo
- Public: https://github.com/Daddy-Ousen/innworld-rpg, branch `main`.

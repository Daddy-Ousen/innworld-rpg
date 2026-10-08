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
- [ ] M18 — Book 6 (The General of Izril). Plan: ADR 0028, steps M18.0 – M18.7 in `docs/ROADMAP.md`. Text in the private repo.
  - [x] M18.P plan (branch `claude/kind-feynman-y4x1mm`, 2026-10-01, cloud): six reading agents (summaries only), ADR 0028, roadmap steps.
    User answers: chapter `order` number (M18.0 engine step), maps Wirclaw's village + crypt ossuary + inn basement, Esthelm attack as a
    night wave stage. Laken's calendar (changed the same day): game day = his journal day + 45 in every book, no squeeze; tying his
    first snow to Liscor's winter (day 42) breaks Book 4 and Zel's death (ADR 0028 "Laken's calendar"). Book 6 Liscor days move to
    115 – 130 (Zel dies on 130). PR waits for the user to merge (merging = plan approved).
  - [x] M18.0 canon timing (branch `claude/kind-feynman-y4x1mm`, 2026-10-01, cloud): optional chapter key `order` in
    `CanonDb` and the validator (same day: book, chapter order, place in the file; Books 1 – 5 order unchanged); Laken's
    Book 3 events on days 46 – 91 and Book 5 events on days 100 – 115 (his Day + 45). Tests run: `unit_event_order` (new),
    `unit_canon_db`, `sim_canon_book2` – `sim_canon_book5`, `sim_book4_christmas`, `sim_book4_homecoming`,
    `sim_book4_relief_home`, Python tool tests (100), validator. All pass. Full suite not run. PR waits for the user to merge.
  - [x] M18.0 merged ([PR #89](https://github.com/Daddy-Ousen/innworld-rpg/pull/89), merge commit 5d0930e).
  - [x] M18.1 world (branch `claude/nice-albattani-wj8hw6`, 2026-10-01, cloud): maps `wirclaw_village`, `inn_basement`
    (trapdoor opens with `wandering_inn.expansion_begun`), `liscor_ruins_hall` and `liscor_ruins_ossuary` (the text puts
    the ossuary in the Ruins of Liscor: illusion wall until `liscor_ruins.hidden_chute_found`, one-way chute, corridor
    with a trap to `liscor_crypt`); the Eater Goat (`leap`, drawn art); 10 looks; 38 Book 6 NPC records, no events.
    Tests run: `sim_book6_world` (new) and 18 scripts the change touches, Python tool tests (102), validator. All pass.
    Full suite not run. [PR #90](https://github.com/Daddy-Ousen/innworld-rpg/pull/90) waits for the user to merge.
  - [x] M18.1 merged ([PR #90](https://github.com/Daddy-Ousen/innworld-rpg/pull/90), merge commit 440a0dd).
  - [x] M18.2 canon 4.32 G, 1.02 C – 1.05 C (branch `claude/sleepy-feynman-txet0j`, 2026-10-01, cloud): 17 events (days 114 – 121),
    the march as a scene stage with a talk hook, Rags's raid as news, Tom's Paranfer weeks off-map, `paranfer` location.
    Tests run: `sim_canon_book6` (new), `sim_book6_goblin_march` (new), `sim_book6_world`, `unit_canon_db`,
    `unit_event_order`, `sim_canon_book5`, Python tool tests (102), validator. All pass. Full suite not run. PR waits for the user.
  - [x] M18.2 merged ([PR #91](https://github.com/Daddy-Ousen/innworld-rpg/pull/91), merge commit f5cc08b).
  - [x] M18.3 canon 4.33 – 4.34 (branch `claude/sleepy-feynman-txet0j`, 2026-10-01, cloud): 14 events (day 115; the goats' night is 114).
    The Eater Goat attack is a fight stage with waves at `wirclaw_village`; the feast is a scene stage in the inn; both have hooks.
    Bugear dies by event effect. New behaviour entries for Wirclaw and the five Redfang (basement from day 116). Bugear's tag is
    sword. Tests run: `sim_book6_eater_goats` (new, 7), `sim_canon_book6`, `sim_book6_goblin_march`, `sim_book6_world`,
    `unit_canon_db`, `unit_event_order`, `sim_canon_book3`, `unit_behaviour_db`, `unit_npc_sim`, `unit_map_db`, Python tool
    tests (102), validator. All pass. Full suite not run. PR waits for the user to merge.
  - [x] M18.3 merged ([PR #92](https://github.com/Daddy-Ousen/innworld-rpg/pull/92), merge commit 6120ef3).
  - [x] M18.4 canon 4.35 E – 4.38 B (branch `claude/sleepy-feynman-txet0j`, 2026-10-01, cloud): 28 events (days 117 – 127), Laken off-map,
    Olesm's day 126 with the crypt search as a scene stage and hook, Esthelm as news only, Zel leaves through the door, Magnolia.
    Tests run: `sim_canon_book6`, `sim_book6_crypt_search` (new), `sim_canon_book5` (fixed a stale M18.3 assert), the touched Book 6 sims,
    Zel and behaviour scripts, Python tool tests (102), validator. All pass. Full suite not run. PR waits for the user.
  - [x] M18.5 canon 4.39 G – 4.42 L (branch `claude/sleepy-feynman-txet0j`, 2026-10-01, cloud): 20 events (days 126 – 129). The party is a scene stage
    in the inn with a talk hook; the Rose Knights fights and the Hive front are events only. Greydath is a flag on `greybeard`; Purple Smile
    is [Sergeant] by flag on day 129. Tests run: `sim_book6_goblin_party` (new, 4), `sim_canon_book6`, the touched Book 6 sims, `sim_canon_book5`,
    `unit_canon_db`, `unit_event_order`, `unit_behaviour_db`, `unit_npc_sim`, `unit_map_db`, Python tool tests (102), validator. All pass.
    Full suite not run. PR waits for the user to merge.
  - [x] M18.5 merged ([PR #94](https://github.com/Daddy-Ousen/innworld-rpg/pull/94), merge commit c1f3904).
  - [x] M18.6 canon 4.43 – 4.47 (branch `claude/sleepy-feynman-txet0j`, 2026-10-01, cloud): 23 events (days 128 – 129). The Silver Swords arrive at
    the inn as a scene stage with a talk hook; Zel's speech is T1 news with an Ilvriss hook on the council; Erin is level 33. 4.44 M is day 128.
    Tests run: `sim_book6_silver_swords` (new, 6), `sim_canon_book6`, the touched Book 6 sims, `sim_canon_book5`, `unit_canon_db`, `unit_event_order`,
    `unit_behaviour_db`, `unit_npc_sim`, `unit_map_db`, Python tool tests (102), validator. All pass. Full suite not run. PR waits for the user to merge.
  - [x] M18.6 merged ([PR #95](https://github.com/Daddy-Ousen/innworld-rpg/pull/95), merge commit 639fd45).
  - [x] M18.7 canon Antinium Wars Pt. 3 – 5, 4.48, 4.49 (branch `claude/sleepy-feynman-txet0j`, 2026-10-01, cloud): 31 events (days 129 – 130).
    Zel dies on day 130 and names the Goblin Lord Reiss (`goblin_lord.named_reiss`). The mourning is a scene stage in the inn with a talk hook
    with Erin. Chosen records and the 4.31 scroll flag fixed. Tests run: `sim_book6_zel_dies` (new, 7), `sim_canon_book6`, `sim_canon_book5`, the
    touched Book 6 sims, `unit_canon_db`, `unit_event_order`, `unit_behaviour_db`, `unit_npc_sim`, `unit_map_db`, Python tool tests (102),
    validator. All pass. Full suite not run. PR waits for the user to merge. After the merge M18 is done except the user's play check.
  - [x] M18.7 merged ([PR #96](https://github.com/Daddy-Ousen/innworld-rpg/pull/96), merge commit 6a9e8b8).
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

- [ ] M19 — Book 7 (The Rains of Liscor). Plan: ADR 0030, steps M19.0 – M19.8 in `docs/ROADMAP.md`.
  - [x] M19.P plan (branch `docs/m19-plan`, 2026-10-07, local): Book 7 cut from the epub to `canon/raw/book7/` (gitignored);
    seven reading agents (summaries only); ADR 0030, roadmap steps, `docs/CLOUD.md` queue. User answers: rain + flood (door is
    the way to Liscor), door with several links + small Pallass map (portal schema change approved), moth attack = wave stage
    with `xp_window` x3, dungeon dive = events only. Days 133 – about 143. No code, no tests run. PR waits for the user to merge.

  - [x] M19.0 engine (branch `feat/m19.0-door-links-rains`, 2026-10-07, local): door `links` (pick the stone; flags, hours, power per
    link; one shared trip count), `rules.rains` (season and flood flags), rain on screen and in the sound (`amb_rain.ogg` made by
    `tools/build_rain.py`). User answers: no rain duress; rain sound by tool. No save change. Detail: ADR 0030 "M19.0 as built".
    Tests run: `unit_portal_links` (new), `unit_rains` (new), 16 touched scripts, Python tool tests (105), validator. All pass.
    Full suite not run. PR waits for the user to merge.
  - [x] M19.0 merged ([PR #112](https://github.com/Daddy-Ousen/innworld-rpg/pull/112), merge commit fef7f44).
  - [x] M19.1 world (branch `feat/m19.1-world`, 2026-10-07, local): door with 3 links (Celum, Pallass `pallass_door_street`, Liscor west wall on
    `liscor_watch`), flood overlays (flag `izril.flood`) on 4 maps and 3 gated exits, Grand Theatre and smashed-tower flags, moth enemies + sheets,
    Book 7 records (33 NPCs, 14 places, no events). Detail: ADR 0030 "M19.1 as built". Tests run: `sim_book7_world` (new, 11), `unit_portal_links`,
    `unit_map_db`, `unit_combat_db`, `unit_monster_art`, `unit_sound_cues`, `unit_gated_exits`, `unit_world_view`, `unit_canon_db`, `unit_liscor_map`,
    `unit_audio_data`, `unit_ambience`, `sim_winter` (narrowed to the snow-wall overlay), `sim_book4_homecoming`, `sim_book6_world`, Python tool tests (105),
    validator. All pass. Full suite not run. PR waits for the user to merge.
  - [x] M19.1 merged ([PR #113](https://github.com/Daddy-Ousen/innworld-rpg/pull/113), merge commit 00767ce).
  - [x] M19.2 canon 5.00 – 5.03 (branch `feat/m19.2-canon-5-00`, 2026-10-07, local): 23 events (days 133 – 135). Stages: the lunch (day 133) and the Venim
    deal (day 134, sets `izril.rains`), both scenes in the inn with a talk hook. No Pallass walk, no Riefel death. Venim has a behaviour entry.
    Tests run: `sim_book7_pallass_crisis` (new, 6), `sim_book7_world`, `sim_canon_book6`, `unit_canon_db`, `unit_event_order`, `unit_behaviour_db`,
    `unit_npc_sim`, Python tool tests (105), validator. All pass. Full suite not run. PR waits for the user to merge.
  - [x] M19.2 merged ([PR #114](https://github.com/Daddy-Ousen/innworld-rpg/pull/114), merge commit f9552eb).
  - [x] M19.3 canon 5.04 – 5.06 M (branch `feat/m19.3-canon-5-04`, 2026-10-07, local): 19 events (days 135 – 136). One scene stage: the Players' play night
    (day 135) with a Wesle hook. No dinner stage, no xp_window. Erin level 34 by `system` record. Records fixed: Toren, Wesle, Halrac, Mrsha.
    Tests run: `sim_book7_players_and_toren` (new, 5), `sim_book7_pallass_crisis`, `sim_book7_world`, `unit_canon_db`, `unit_event_order`, `unit_behaviour_db`,
    `unit_npc_sim`, `sim_canon_book2`, `sim_canon_book3`, `sim_canon_book6`, Python tool tests (105), validator. All pass. Full suite not run. PR waits for the user to merge.
  - [x] M19.4 canon 5.07, 5.08, Interlude - Flos (branch `feat/m19.4-canon-5-07`, 2026-10-07, local): 28 events (days 137 - 138). The moths are a 6-wave fight stage on
    `inn_hill` with `xp_window` x3 and a fight hook; a scene in the inn that night with a talk hook. Pallass lifts the embargo and the Pallass door link opens. Flos notes are tier 1.
    Tests run: `sim_book7_moths` (new, 6), `sim_winter`, `unit_canon_db`, `unit_event_order`, `unit_behaviour_db`, `unit_npc_sim`, `unit_xp_window`, `unit_map_db`, `sim_book7_world`,
    `sim_book7_pallass_crisis`, `sim_book7_players_and_toren`, `sim_canon_book6`, Python tool tests (105), validator. All pass. Full suite not run. PR waits for the user to merge.
  - [x] M19.5 canon 5.09 E - 5.11 E (branch `feat/m19.5-canon-5-09`, 2026-10-08, local): 26 events (days 130 - 142, Laken's Day + 45). New map `riverfarm`; the banquet (day 142) is a scene stage with two hooks (Ivolethe, the poisoned cup). No road: the first `celum_gate` link was removed (Riverfarm is SW of Invrisil); no exits until an Invrisil map exists. Detail: ADR 0030 "M19.5 as built".
    Tests run: `sim_book7_riverfarm` (new, 7), `unit_map_db`, `unit_behaviour_db`, `unit_npc_sim`, `unit_canon_db`, `unit_event_order`, `unit_gated_exits`, `unit_audio_data`, `unit_ambience`, `unit_world_view`, `unit_ground_art`, `sim_book7_world`, `sim_book7_moths`, `sim_book7_pallass_crisis`, `sim_book7_players_and_toren`, `sim_canon_book6`, `sim_winter`, `unit_liscor_map`, Python tool tests, validator. All pass (Python tool tests 105, validator 0 errors; first run of `unit_ground_art` failed on a tree hiding a wall, fixed). Full suite not run. PR waits for the user to merge.
  - [x] M19.6 canon 5.12 – 5.15 (branch `feat/m19.6-canon-5-12`, 2026-10-08, local): 44 events (days 137 – 140). The flood starts (`izril.flood`, set on day 137 so it shows on 138);
    the door gets its Liscor west-wall end on day 138 (Pallass and Celum ends stay). Three scene stages in the inn, each with one talk hook, no `xp_window`: the Soldiers' dinner
    (day 138, Klbkch), the victory party (day 139, Relc), the Vuliel Drae confession (day 140, Revi). Parade, play, Embria's fight, Tyrion and the whole dungeon dive are events.
    Olesm is [Strategist] 30 and Erin level 35 by `system` records. 8 NPCs got behaviour entries. Tests run: `sim_book7_flood_and_parade` (new, 6), `sim_book7_world`, `sim_book7_moths`,
    `sim_book7_pallass_crisis`, `sim_book7_players_and_toren`, `sim_winter`, `sim_canon_book6`, `unit_canon_db`, `unit_event_order`, `unit_behaviour_db`, `unit_npc_sim`, `unit_map_db`,
    `unit_data_db`, Python tool tests (105), validator (0 errors). All pass. Full suite not run. PR waits for the user to merge.
  - [x] M19.7 canon 5.16 S – 5.18 S (branch `feat/m19.7-canon-5-16`, 2026-10-08, local): 33 events (days 140 – 143). Two scene stages with one talk hook each, no `xp_window`: Zel's funeral in `liscor_plaza` (day 142, hook Zevara) and the lease haggle in the inn (day 143, hook Selys). Selys is [Heiress] 4 then 6, [Receptionist] 19. New places `liscor_city_hall`, `liscor_sewers`, `pallass_archive`; Seborn has a behaviour entry. Detail: ADR 0030 "M19.7 as built".
    Tests run: `sim_book7_zel_and_selys` (new, 4), `sim_book7_flood_and_parade`, `sim_book7_world`, `sim_book7_moths`, `sim_book7_riverfarm`, `sim_book7_pallass_crisis`, `sim_book7_players_and_toren`, `unit_canon_db`, `unit_event_order`, `unit_behaviour_db`, `unit_npc_sim`, `unit_map_db`, `unit_data_db`, `sim_winter`, `sim_canon_book6`, Python tool tests (105), validator (0 errors). All pass. Full suite not run. PR waits for the user to merge.
  - [x] M19.8 canon 5.19 G, 5.20 G (branch `feat/m19.8-canon-5-19`, 2026-10-08, local): 21 events (days 141 – 143), all off-map; no stage, no hook, no `xp_window`. Rags gets `system` records ([Chieftain] 20 on day 143). New places `northern_swamp`, `northern_high_road`. Detail: ADR 0030 "M19.8 as built".
    Tests run: `sim_book7_goblin_road` (new, 4), `sim_book7_zel_and_selys`, `sim_book7_flood_and_parade`, `sim_book7_world`, `sim_canon_book6`, `unit_canon_db`, `unit_event_order`, `unit_behaviour_db`, `unit_npc_sim`, `unit_map_db`, `sim_winter`, Python tool tests (105), validator (0 errors). All pass. Full suite not run. PR waits for the user to merge.
  - [x] M19.9 `sim_canon_book7` (branch `feat/m19.9-sim-canon-book7`, 2026-10-08, local): days 130 – 143, 191 events, drift 0, no named deaths, 11 stages, one `xp_window`. Test run: `sim_canon_book7` (new, 5). All pass. Full suite not run. After the merge M19 is done except the user's play check.
  - [ ] The user looks at the rain (`flag izril.rains` in the console, then walk outside) and hears it.

- [x] Floating touch stick (2026-10-08, user request): replaces the D-pad; `ui/touch_controls.gd`, `unit_touch_controls` (18 pass), ADR 0032 note. The user still has to try it on a phone. PR open (branch `feat/touch-stick`).

- [x] Phone UI bigger and see-through (2026-10-08, user request, branch `feat/mobile-ui-bigger`): on a phone OS (Android, iOS, or a browser on them) Auto menu size is 250 % (`UiScale.MOBILE`) whatever the dpi says; panel, button and list boxes are 78 % opaque (`UiScale.MOBILE_ALPHA`, theme edited at run time). Desktop unchanged. Tests run: `unit_ui_scale` (9), `unit_ui_theme`, `unit_touch_controls`, `unit_audio_settings`. All pass. Full suite not run. The user still has to look at it on a phone.

- [x] Long road confirm + walk scene (2026-10-08, user request, branch `feat/long-road-confirm`): an exit of 300 min or more (Celum <-> camp <-> Liscor, 10 h) asks "Travel to X?" first, then plays a 1.8 s walker-on-a-track scene; the move happens at its end. Stay or Esc cancels. `ui/travel_prompt.gd` (new), `world/main.gd`. Off headless-only (`confirm_travel`). Wagon rides and the 180 min Esthelm roads do not ask. Tests run: `unit_travel_prompt` (new, 6), `unit_travel`, `unit_input_actions`, `unit_touch_controls`, `sim_celum_trip`, `unit_hud_log`. All pass. Full suite not run. The user still has to look at it (`godot --path game`, walk onto the Celum south exit).

## Releases (ADR 0029)
- [x] v0.1.3-alpha (branch `release/v0.1.3`, 2026-10-08, local): version bump (code 2), `tools/release.ps1` now also builds the signed apk. Smoke tests pass (events=1089, maps=40, problems=0). Three zips + `InnworldRPG-v0.1.3-alpha-android.apk` built. Waits: user merges the PR, then tag + `gh release create` with all four files.
- [x] v0.1.2-alpha (branch `release/v0.1.2`, 2026-10-06, local): version bump, README and ITCH.md text (touch is no longer "next release"). Three zips built and
  smoke-tested (898 events, 38 maps, 0 problems). Tests run: smoke only. Full suite not run. PR waits for the user to merge.
  - [x] Merged ([PR #108](https://github.com/Daddy-Ousen/innworld-rpg/pull/108), merge commit e9ad2e2). Tag `v0.1.2-alpha` pushed. Pre-release published 2026-10-06 with three zips: https://github.com/Daddy-Ousen/innworld-rpg/releases/tag/v0.1.2-alpha. Pages deploy run succeeded.
  - [x] The user uploaded the v0.1.2 web zip to itch.io (said 2026-10-07).
- [x] v0.1.0-alpha (branch `release/v0.1.0`, 2026-10-01, local): `game/export_presets.cfg` (Windows, Linux; `*.json` packed; tests and GUT
  left out), `config/version` and a version label on the title screen, `tools/release.ps1` + `tools/release/smoke.gd` + player
  `README-PLAYERS.txt`. Built and smoke-tested both zips (898 events, 38 maps, 0 problems; 5 nights run from the pack). The Windows
  exe opens and closes clean. Tests run: `unit_play_loop` (16 pass). Full suite not run.
  - [x] Merged ([PR #97](https://github.com/Daddy-Ousen/innworld-rpg/pull/97), merge commit 548f0f5). Tag `v0.1.0-alpha` pushed.
    Pre-release published 2026-10-01: https://github.com/Daddy-Ousen/innworld-rpg/releases/tag/v0.1.0-alpha (two zips).
  - [ ] Android: skipped (user, 2026-10-01). Needs touch controls first (roadmap "Releases").
- [x] README rewrite for players first, developers second (branch `docs/readme-rewrite`, 2026-10-01, local). Counts checked:
  898 events, 261 NPCs, 103 places, 38 maps, 147 GUT scripts (~1,419 tests), 102 Python tests. Merged ([PR #99](https://github.com/Daddy-Ousen/innworld-rpg/pull/99)).
- [ ] Web build (ADR 0031; user, 2026-10-01: itch.io + GitHub Pages, GitHub URL first, own subdomain later).
  - [x] Branch `feat/web-build` (from `docs/readme-rewrite`): "Web" preset, web zip in `tools/release.ps1`, web-only
    stretch in `project.godot`, Quit hidden in a browser, `.github/workflows/pages.yml`, README "Play in your browser".
    All three zips built and smoke-tested (898 events, 38 maps, 0 problems). Checked in Chrome: play, save, reload, night 0.3 s.
    Tests run: `unit_play_loop` (17 pass). Full suite not run. Merged ([PR #100](https://github.com/Daddy-Ousen/innworld-rpg/pull/100), d565a3b).
  - [x] GitHub Pages on, source "GitHub Actions" (user, 2026-10-02).
  - [x] v0.1.1-alpha (user, 2026-10-02) on branch `release/v0.1.1`: version bump, README download link. Three zips built and
    smoke-tested (898 events, 38 maps, 0 problems). Tests run: `unit_play_loop` (17 pass). Full suite not run.
  - [x] Merged ([PR #101](https://github.com/Daddy-Ousen/innworld-rpg/pull/101), merge commit 429583e). Tag `v0.1.1-alpha` pushed.
    Pre-release published 2026-10-02 with three zips: https://github.com/Daddy-Ousen/innworld-rpg/releases/tag/v0.1.1-alpha
  - [x] Live: https://daddy-ousen.github.io/innworld-rpg/ (title screen v0.1.1-alpha, no errors; wasm served gzip, 10 MB).
    The release-event run failed: the `github-pages` environment allows only `main`, not tags. Deployed by hand with
    `gh workflow run pages.yml --ref main -f tag=v0.1.1-alpha` (success).
  - [x] Tag rule `v*` added to the `github-pages` environment (user, 2026-10-02). The re-run of the release-event run
    succeeded, so a published release now deploys by itself.
  - [x] itch.io: the page is live with the web zip (user, 2026-10-02).
  - [ ] Later: own subdomain (CNAME + Settings → Pages → Custom domain).

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

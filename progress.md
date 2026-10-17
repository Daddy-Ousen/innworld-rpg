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
- [ ] M28 — Book 8 (Blood of Liscor), plan `docs/plans/m28.md`, ADR 0043.
  - [x] M28.P plan (2026-10-16, branch `docs/m28-book8-plan`): user picks: 3 fight stages (5.34, 5.38, 5.44), moon by flags, dungeon dive events only, north thread events only. Docs only, no tests run. Waits: user merges the PR.
  - [x] M28.0 engine (2026-10-16, branch `feat/m28.0-boycott`): optional `rules.inn.race_boycott [{flag, race, factor}]`, `Guests.race_weights`. Tests: `unit_guests` (+4), `unit_standing`, `sim_inn_service` pass. Full suite not run.
  - [x] M28.1 world and records (2026-10-16, branch `feat/m28.1-world-records`): `raskghar_armoured`, `awakened_raskghar` (Gnoll art stand-in), map `raskghar_camp`, `canon/book8` records (20 NPCs, 4 places), Calruz note. Tests: `sim_book8_world` (new, 6) + 11 touched scripts pass; validator 0 errors; Python 116 OK. Full suite not run.
  - [x] M28.2 canon 5.21 E – 5.23 G (2026-10-16, branch `feat/m28.2-canon-5-21`): 38 events, days 143 – 148, off-map, no stages. Tests: `sim_book8_north_one` (new, 6), `sim_book7_goblin_road`, `sim_canon_book7`, `unit_canon_db` pass; validator 0 errors; Python 116 OK. Full suite not run.
  - [x] M28.3 canon 5.24 L – 5.26 L (2026-10-16, branch `feat/m28.3-canon-5-24`): 27 events, days 144 – 154, 15 Lyonette `system` records, repair events (windows, watchtower, Jelaqua body). No stage, no hook (user pick). Tests: `sim_book8_liscor_one` (new, 7), `sim_book8_north_one`, `sim_canon_book7`, `unit_canon_db` pass; validator 0 errors. Full suite not run.
  - [x] M28.4 canon 5.27 – 5.29 (2026-10-16, branch `feat/m28.4-canon-5-27`): 27 events, days 155 – 156, Drake boycott flag + `rules.inn.race_boycott` entry (factor 0.15, guess). No stage, no hook. Tests: `sim_book8_liscor_two` (new, 6), liscor_one, north_one, `sim_canon_book7`, `unit_canon_db`, `unit_guests`, `unit_standing`, `sim_inn_service`, `unit_data_db` pass; validator 0 errors. Full suite not run.
  - [x] M28.5 canon 5.30 G – 5.32 G (2026-10-16, branch `feat/m28.5-canon-5-30`): 32 events, days 149 – 150 (one Liscor scene day 157, guess), off-map, no stage, no hook, no system records. Tests: `sim_book8_north_two` (new, 6), north_one, liscor_one, liscor_two, `sim_canon_book7`, `unit_canon_db` pass; validator 0 errors. Full suite not run.
  - [x] M28.6 canon 5.33 B, Interlude - Blackmage, 5.34, 5.35 H (2026-10-16, branch `feat/m28.6-canon-5-33`): 37 events, days 157 - 159, fight stage `b8.raskghar_raid_the_wandering_inn` (`inn_hill`, 21 - 24 h, `xp_window` x3), one talk hook (Headscratcher / Bird), moon flags, 21 system records. Tests: `sim_book8_raid_one` (new, 8), north_two, liscor_two, `sim_book8_world`, `sim_canon_book7`, `unit_canon_db`, `unit_xp_window`, `sim_winter`, `unit_player_hooks`, `sim_player_hooks` (hook count 128 -> 129) pass; validator 0 errors. Full suite not run. Not committed.
    - [ ] The user plays the raid stage (`godot --path game`).
  - [x] M28.7 canon 5.36, 5.37 G, 5.38 (2026-10-16, branch `feat/m28.7-canon-5-36`): 41 events, days 151 – 161. Stage `b8.raskghar_raid_the_inn_by_daylight` (`inn_hill`, day 161, 15 – 18 h, xp x3). No hook. Fess dies. Records: Rags [Chieftain] 24, Redscar, Garen, Halrac; Pebblesnatch record fixed to female. Tests: `sim_book8_raid_two` (new, 8), raid_one, north_two, `sim_canon_book7`, `unit_canon_db`, `unit_xp_window`, `sim_winter`, `sim_player_hooks` pass; validator 0 errors. Full suite not run.
  - [x] M28.8 canon 5.39 – 5.42 (2026-10-17, branch `feat/m28.8-canon-5-39`): 41 events, days 161 – 162, events only (no stage, no hook). One kill (Rebat). System records: Shorthilt, Badarrow, Rabbiteater, Drassi, Ksmvr, Calruz. Tests: `sim_book8_dive_one` (new, 6), raid_two, north_two, `sim_canon_book7`, `unit_canon_db` pass; validator 0 errors; Python 116 OK. Full suite not run.
  - [x] M28.9 canon 5.43, Interlude – Niers, 5.44 (2026-10-17, branch `feat/m28.9-canon-5-43`): 26 events, days 162 – 163. Stage `b8.three_doors_open_on_the_raskghar_camp` (`raskghar_camp`, day 163, 18 – 23 h, xp x3). No hook. Way in: Erin's magic door in `inn_interior` links to the camp on day 163 only (user pick: flag-gated exit); knock-out wakes at the inn. Kills: Cassa, Vakk. Calruz in the Watch prison; captives freed; Erin [Magical Innkeeper] 36. Tests: `sim_book8_battle_one` (new, 9), `sim_kill_book8` (new, 6), `sim_book8_world` (changed), `unit_map_db`, `unit_other_maps`, `unit_ground_art`, `sim_liscor_depths`, `unit_data_db` pass; validator books 1 – 8: 0 errors. Full suite not run.
  - [x] M28 all canon batches done. Merged (PR #200, 2026-10-17).
  - [ ] `sim_canon_book8` (named in the M28 "Done when"; not written yet).
  - [ ] The user plays Book 8 (`godot --path game`): the raid stages, the camp door on day 163, the boycott.
- [x] Class tree from the wiki, steps 1 – 3 (2026-10-07/08): advancement classes, riding / animals / gardening / faith tags, hunter, archer, alchemist, blacksmith, teacher, knight, assassin. Test lists in the archive.
- [x] Class tree step 4 (2026-10-13, branch `feat/class-tree-step4`): 15 classes (4 base: tailor, glassblower, tinkerer, bard; 7 advancements: pyromancer, necromancer, illusionist, armorer, weaponsmith, trader, diplomat; 4 consolidations: battlemage, paladin, spymaster, apothecary) + 15 passive Skills. Data only, existing tags. All `confidence: guess`. Tests: `unit_class_tree_step4` (new, 5), step2, step3, `unit_class_system`, `unit_class_actions` pass. Full suite not run.
  - [ ] The user plays: do the new classes get offered at sensible times?
  - [ ] The user plays: do the new objects feel right?
- [ ] M27 — Balance from player feedback (2026-10-15, merged [PR #188](https://github.com/Daddy-Ousen/innworld-rpg/pull/188), merge commit 0812d6d, plan `docs/plans/m27.md`, ADR 0042).
  - [x] M27.0 leveling: `base_xp` 40 -> 30, `growth` 1.25 -> 1.2; novelty `k` 0.35 -> 0.2, `floor` 0.1 -> 0.3. Sims: inn worker level 5 on night 7 (was 9 - 10); fighter 14 - 15 on day 22.
  - [x] M27.1 `consolidation_min_level` 10 -> 5.
  - [x] M27.2 buy / sell many in one trade (`trade_extra_minutes` 1, `bulk_buy` 5; picks `sell:<good>#<n>`).
  - [x] M27.3 `decay_after_days` 7 -> 30, `reputation_decay_every` 3 -> 10.
  - Tests run (all pass): unit_xp, unit_levels, unit_actions, sim_balance_progress, sim_balance_fighter, sim_30_days, sim_breakthrough_probe, unit_class_system, unit_class_tree_step2/3/4, unit_breakthrough, unit_night, unit_system_messages, unit_economy, unit_interact, unit_console, unit_sound_cues, sim_celum_trip, unit_cooking, unit_data_db, unit_standing, sim_balance_money, sim_inn_service, unit_brawl, unit_guests. Validator books 1-7: 0 errors. Python 116 OK. Full suite not run.
  - [ ] The user plays: level pace, trading, friends after a trip.
- [x] North road, Invrisil city and staff, Magnolia's estate and NPCs (2026-10-08): data only; maps `celum_north_gate`, `road_to_invrisil`, `invrisil_*`, `magnolia_estate_*`. Layouts and times are guesses. The user walks them. Test lists in the archive.
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

## Player audit (2026-10-17, local, read-only; no code changed)
- [x] Audit from a player's and a book reader's view: `docs/AUDIT_PLAYER_2026-10-17.md` (not committed). Played the
  v0.1.5 web build (title, gate, inn, Erin, a night, the day-9 Chieftain fight) and two headless runs (do nothing to
  day 166; inn worker two weeks). No tests run (no code or data changed).
- Top findings: NPCs have no voice (Erin says nothing; one generic talk menu); big moments reach the player as next-day
  news, scenes are one line, no signposts before fight stages; nobody reacts to an Earther; Book 6 – 8 climaxes off
  screen (Zel) or without hooks (Book 8: 1 hook in 269 events, Calruz not in the three-door fight); System lines not
  in book style; lore slips (inn stays "abandoned", signs before day 14, Magnolia not pink, no Human distrust in Liscor).
- [x] The user said "we will do all" (2026-10-17). Plan: ADR 0044 + `docs/plans/m29.md` – `m33.md`; ROADMAP has
  M29 Lore polish, M30 Voices and the Earther, M31 Signposts and scene beats, M32 Climaxes of Books 6 – 8,
  M33 Depth (branch `docs/player-audit-plan`). Docs only, no tests run. Waits: user merges the PR, then M29.0.
- [x] ROADMAP "At a glance" has a "Model · effort per step" column for every open phase and sub-step (user ask,
  2026-10-17); reading agents run on Sonnet · medium. Same PR.
- [x] Plan merged ([PR #201](https://github.com/Daddy-Ousen/innworld-rpg/pull/201)).

## M29 Lore polish (plan `docs/plans/m29.md`, ADR 0044)
- [x] M29.0 The System speaks like the books (2026-10-17, branch `feat/m29.0-system-voice`): new `core/system_voice.gd`
  (`SystemVoice`); level, Skill, class obtained / offered / lost, neglect, consolidation ("[Conditions Met: …]") and
  breakthrough lines in book style; offer page title "[Class Offered]"; action `talk_with_guest` shows "Talk" (id
  unchanged). No schema or save change. Tests: `unit_system_voice` (new, 5), `unit_system_messages`,
  `unit_class_system`, `unit_breakthrough`, `unit_console`, `unit_night`, `unit_journal`, `unit_no_xp_shown`,
  `unit_interact` pass; validator books 1 – 8: 0 errors. Full suite not run.
  - [ ] The user looks at the first night's System page (`godot --path game`).
- [x] M29.0 merged ([PR #202](https://github.com/Daddy-Ousen/innworld-rpg/pull/202)).
- [x] M29.1 inn name, signs, first guests (2026-10-17, branch `feat/m29.1-inn-name`). User picks: location
  `names [{flag, name}]` + `CanonDb.location_name`; `rules.inn.patron_flags` (any of) + `rules.inn.race_flags`;
  save v22 migration (sets `wandering_inn.has_regulars` if `b1.inn_first_regulars` ran). Signs by flag (data).
  Goblin patrons weight 2 (guess). Detail in ADR 0044 "M29.1". Tests: `unit_inn_name` (new, 5), `unit_guests`
  (+4), `sim_inn_service`, `unit_map_db`, `unit_ground_art`, `unit_sign_art`, `unit_other_maps`, `unit_hud_log`,
  `unit_system_messages`, `unit_console`, `unit_canon_db`, `unit_standing`, `sim_canon_book1`, `unit_game_state`,
  `unit_npc_levels` pass; validator books 1 – 8: 0 errors; Python 117 OK. Full suite not run.
  - [ ] The user looks at the inn on day 1 and day 14, and sees no patrons before day 15 (`godot --path game`).
- [ ] M29.2 Liscor is wary of Humans (schema ask first).

- [ ] M28 leftover found: `sim_canon_book8` (in M28 "Done when") does not exist. Roadmap item added under M28.

## Audit (2026-10-08, local, read-only; no code changed)
- [x] Findings split into modules M21 – M26 in `docs/ROADMAP.md` "Audit work" (2026-10-09). Work them from there; the list below is the source.
- [x] Each M21 – M26 step has a model tag `[Model · effort]` (2026-10-09, branch `docs/roadmap-model-tags`). Default Sonnet · medium.
- [x] `docs/ROADMAP.md` shows open work first and done milestones at the bottom, newest first (2026-10-09, branch `docs/roadmap-open-first`).
- [x] `docs/ROADMAP.md` reorganised again (2026-10-11, branch `docs/roadmap-reorg`): M21 moved to Done; M20 phone check ticked (M21.6), touch-screen PC still open; "Waits on the user" has user to-dos (keystore backup, ask pirateaba); Later has the small asks; Releases lists v0.1.0 – v0.1.4. Docs only, no tests run.
- [x] M21 Housekeeping · M22 Breakthroughs · M23 Canon bends (Books 2 – 7, ADR 0036) · M24 Level by living · M25 NPC life (ADR 0038, 0039) · M26 Code health (ADR 0040, 0041; `main.gd` and `world_view.gd` split). All done 2026-10-09 – 10-13. Per-step test lists are in the archive; `docs/ROADMAP.md` Done has the step lines. Full suite not run after them.
  - M26.2 (2026-10-13): own looks for Rose, Imani, Joseph (`appearance.json` + sheets); `unit_art` 11/11.
- Healthy: hard rules hold (all RNG via `gs.rng`, core is 58 `RefCounted` files, UI does not write state), validator 0 errors, Python tool tests 105 OK.
- [ ] BUG: no class can pass level 9. Capstones 10/20/30 need a breakthrough, and only the debug console grants one (`ClassSystem.grant_breakthrough`; no event effect, no data).
  - [x] M22.0 design (2026-10-09, branch `docs/m22.0-breakthrough-design`): ADR 0035. User picks: hard moment + class trial + canon `boon` hook; a moment counts from level 9 / 19 / 29; a vague hint. Docs only, no tests run.
  - [x] M22.1 engine (2026-10-10, branch `feat/m22.1-breakthrough-engine`): `core/breakthrough.gd`, night steps 2 + 5b, hook `boon`, effect `breakthrough`, `rules.levels.breakthrough`, checks in `DataDb` + validator. No save change. Tests: `unit_breakthrough` (16), `unit_levels`, `unit_class_system`, `unit_night`, `unit_director`, `unit_canon_db`, `unit_player_hooks`, `unit_data_db`, `sim_canon_book1` all pass; Python 107 OK; validator 0 errors. Full suite not run.
  - [x] M22.2 data (2026-10-10, branch `feat/m22.2-breakthrough-data`): trials + hints on 8 classes, 6 `boon` hooks (Books 1 – 3). Tests: `unit_breakthrough` (17), `unit_data_db`, `unit_canon_db`, `unit_director`, `unit_player_hooks`, `sim_player_hooks` (count 74), `sim_canon_book1..3` pass; Python 107 OK; validator 0 errors. Full suite not run.
  - [x] M22.3 consolidation (2026-10-10, branch `feat/m22.3-consolidation`): 565bc9b redone on main. Automatic at night, no offer; needs every source class, one at level 10 (after its breakthrough), and a full pool. Tests: `unit_class_system`, `unit_class_tree_step2` (+1), `unit_class_tree_step3`, `unit_night`, `unit_system_messages`, `unit_journal`, `unit_game_state`, `unit_data_db`, `unit_breakthrough`, `sim_decline` pass; Python 107 OK; validator 0 errors. Full suite not run.
  - [x] M22.4 probe sim (2026-10-10, branch `feat/m22.4-probe-sim`): `sim_breakthrough_probe` (2 tests, days 1 – 87, 3 seeds). Busy inn level 10 on night 31 – 32, quiet inn on night 73 (gate holds), fighter on night 17 – 22. Bar numbers kept (ADR 0035 "Probe result"). Tests run: `sim_breakthrough_probe` only (no code or data changed). Full suite not run. M22 is done.
- [x] M22 breakthroughs done (ADR 0035; bug "no class passes level 9" fixed). Probe: busy inn level 10 on night 31 – 32.
- [x] M23 divergence done for Books 2 – 7 (substitutes, alt events, hooks, kill sims `sim_kill_book2` – `7`). Report: `docs/divergence/report.md`.
- [x] Commit 565bc9b on `feat/class-tree-wiki`: redone in M22.3 ([PR #152](https://github.com/Daddy-Ousen/innworld-rpg/pull/152), merged 2026-10-10). Local branch `feat/class-tree-wiki` deleted; the remote branch still exists.
- [x] New classes `hunter`, `archer`, `alchemist`, `blacksmith`, `teacher` now have their own action (M24.0). Done in M24.1 – M24.3.
- [x] Cleanup of this file and `handoff.md` (2026-10-13). Open: merged local branches; README counts may be stale.
- [x] Full GUT suite run 2026-10-09 (M21.4): 166 scripts, 6 red, all fixed. Not re-run in full after the fixes.
- [ ] Legal: policy read 2026-10-09 (DESIGN §7). Games not named; book titles in marketing are forbidden. Page text reworded 2026-10-09 (no title in marketing). Asking pirateaba is still optional (user).
- [ ] About 9 "the user plays …" checks are open (M17, M18, M19 rain, M20 phone, touch stick, phone UI, long road, class objects, north road).

## Outside PRs
- [ ] PR #164 (DKemp98, classes/skills/sundry): reviewed 2026-10-12. Cannot merge as is (flat JSON breaks the loader,
  number ranges break `int()`, conflicts with M24, no tests). User chose "ask for changes"; reply drafted for the user to post. Detail in `handoff.md`.

## Google Play (ADR 0037, `docs/PLAY_STORE.md`)
- [x] Prep (2026-10-11, branch `feat/play-store-prep`, local): preset `Android Play` (Gradle, AAB, target API 36, min 29); `tools/release.ps1` builds `export/InnworldRPG-v<version>-play.aab` (`-PlayOnly` for only that); Gradle template in `game/android/` (gitignored); store graphics tool `tools/build_store_art.py`; `PRIVACY.md`; listing text and form answers. Built and checked: AAB 88 MB, signed with the release key (jarsigner ok), no permissions. Python tool tests 116 OK. No game code changed, so no GUT run. Full suite not run.
- [ ] pirateaba says yes in writing (user). **No upload before this** (user pick 2026-10-11).
- [ ] Play developer account, internal test on a phone, closed test (12 testers, 14 days), tablet check, production.

## Releases (ADR 0029)
- [x] v0.1.5-alpha (branch `release/v0.1.5`, 2026-10-15, local): version bump (Android code 4). Smoke tests pass (events=1134, maps=50, problems=0). Windows, Linux, Web zips + signed apk + play aab built in `export/`. Waits: user merges the PR, then tag `v0.1.5-alpha` + `gh release create` with the four files (zips + apk; the aab stays out, no Play upload yet).
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

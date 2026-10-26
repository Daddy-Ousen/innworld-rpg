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
  - [x] `sim_canon_book8` (2026-10-25, branch `test/sim-canon-book8`): 6 tests, 269 events, days 143 - 163, drift 0, 3 stages, 4 kills, flags, order. Pass. Full suite not run.
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
  - [ ] M34 — Phone controls, second pass (user ask 2026-10-21: menus hard to pick from, Use button not ideal).
  - [x] M34.P research + plan (2026-10-21, branch `docs/m34-phone-controls`): `docs/plans/m34.md`, ADR 0045, ROADMAP
    M34 section (placed before M31). User took the picks: menus and button first (M34.0 – M34.2), tap the world
    later (M34.3); same card on desktop; hold to attack on touch, Yes / No with keys. Docs only, no tests run.
  - [x] Plan merged ([PR #216](https://github.com/Daddy-Ousen/innworld-rpg/pull/216)).
  - [x] M34.0 action card (2026-10-21, branch `feat/m34.0-action-card`): `ui/interact_menu.gd` / `.tscn` rewritten
    in place: target page, one card per target, drag-safe buttons (fire on release, a 12 px move scrolls), Attack
    = hold 0.6 s on touch, Yes / No with keys. No core, schema or save change. Checked on a 250 % render
    (1200 × 540). Tests: `unit_action_card` (new, 11), `unit_world_view` (20, the old stove red is fixed),
    `unit_brawl`, `unit_economy`, `unit_spell_ui`, `unit_portrait`, `unit_input_actions`, `unit_touch_controls`,
    `unit_play_loop`, `unit_interact`, `unit_ui_scale`, `unit_ui_theme` pass. Full suite not run.
    - [ ] The user tries it on the phone (shop rows, talk to Erin, hold to attack).
  - [x] M34.0 merged ([PR #217](https://github.com/Daddy-Ousen/innworld-rpg/pull/217)).
  - [x] M34.1 shop screen (2026-10-21, branch `feat/m34.1-shop-screen`): new `ui/shop_panel.gd` / `.tscn`
    (`ShopPanel`); a shop's card has one "Shop" button; Buy / Sell tabs, cards, count strip (- / + hold to repeat,
    Max, "Buy 3 for 9c"), "Sell all"; stays open after a deal; Back shows the card again. Core: `Economy.is_single`
    (was private `_single`). No schema or save change. Checked on a 250 % render (1200 × 540). Tests:
    `unit_shop_panel` (new, 13), `unit_action_card` (1 test changed), `unit_economy` (1 test changed),
    `unit_world_view`, `unit_brawl`, `unit_spell_ui`, `unit_portrait`, `unit_touch_controls`, `unit_play_loop`,
    `unit_ui_scale`, `unit_interact` pass. Full suite not run.
    - [ ] The user buys and sells on the phone (count strip, hold +, Sell all).
  - [x] M34.1 merged ([PR #218](https://github.com/Daddy-Ousen/innworld-rpg/pull/218)).
  - [x] M34.2 context button (2026-10-21, branch `feat/m34.2-context-button`): `ui/touch_controls.gd` context button
    ("Talk / Erin") replaces Use, chips left of it ("All" past 4 targets), More / Bag / context bottom right, Menu and
    Back top right under the HUD bar. `InteractMenu.targets` / `verb_of`; Shop before Haggle on a card. No core,
    schema or save change. Checked on a 250 % render with touch on. Tests: `unit_context_button` (new, 9),
    `unit_touch_controls`, `unit_input_actions`, `unit_ui_scale`, `unit_hud_log`, `unit_action_card`,
    `unit_shop_panel`, `unit_world_view`, `unit_play_loop`, `unit_economy`, `unit_brawl`, `unit_spell_ui`,
    `unit_portrait`, `unit_interact` pass. Full suite not run.
    - [ ] The user tries the context button and chips on the phone.
  - [x] M34.2 merged ([PR #219](https://github.com/Daddy-Ousen/innworld-rpg/pull/219)).
  - [x] M34.3 tap the world (2026-10-21, branch `feat/m34.3-tap-world`): new `world/main_tap.gd` (`MainTap`): a touch
    tap walks next to a person or a thing (normal moves, path found again each step) and opens its card; a tap on the
    floor walks there. Stick, key, Cancel, a panel, a fight or a new map stops it. Options "Controls: Tap + stick /
    Stick only" (`TouchSettings.controls`, settings file). No core, schema or save change. Tests: `unit_tap_walk`
    (new, 10), `unit_touch_controls`, `unit_travel_prompt`, `unit_context_button`, `unit_input_actions`,
    `unit_ui_scale`, `unit_audio_settings`, `unit_play_loop`, `unit_world_view`, `unit_combat_screen`,
    `unit_cover_ui`, `unit_spell_ui`, `unit_skill_bar` pass. Full suite not run.
    - [ ] The user taps people and things on the phone (walk, card, stick still works, Stick only).
  - [x] M34.3 merged ([PR #220](https://github.com/Daddy-Ousen/innworld-rpg/pull/220)).
  - [x] M34.4 phone render check (2026-10-21, branch `feat/m34.4-phone-sizes`): renders at 2400 × 1080 / 250 %
    showed 64 px touch buttons and tiles (about 25 dp) and 30 dp card buttons. User pick: size by dpi on a phone.
    `UiScale.px_per_dp`, `touch_grow` (48 dp pad buttons), `map_grow` (40 dp tiles), `touch_ui_px` +
    `InteractMenu.row_h()` (48 dp card and shop buttons). Desktop unchanged. Rendered again as a 405 dpi phone: OK.
    Tests: `unit_ui_scale` (+2), `unit_action_card`, `unit_shop_panel`, `unit_touch_controls`, `unit_context_button`,
    `unit_tap_walk`, `unit_world_view`, `unit_combat_screen`, `unit_play_loop`, `unit_input_actions`, `unit_hud_log`,
    `unit_portrait`, `unit_spell_ui`, `unit_brawl`, `unit_economy`, `unit_audio_settings`, `unit_ui_theme` pass.
    Full suite not run.
    - [ ] The user plays M34 on a phone (needs a new release build): sizes, card, shop, context button, tap walk.
    - [ ] Later: the bag screen is still the old list with key hints; "H: help" shows on a phone.
  - [x] M34.4 merged ([PR #221](https://github.com/Daddy-Ousen/innworld-rpg/pull/221)).
  - [x] M34.5 phone fixes (2026-10-22, branch `fix/m34.5-fight-column`, from the user's v0.1.7 play, phone upright):
    the empty context button hid End turn in a fight -> it hides when nothing is near and in fights, and More /
    Bag sit above the combat bar; the shop's Buy button shrank to a sliver upright -> the strip wraps, Buy at least
    4 button heights wide. Rendered upright and sideways. Tests: `unit_context_button` (+1, changed 2),
    `unit_shop_panel` (+1), `unit_touch_controls`, `unit_combat_screen`, `unit_tap_walk`, `unit_ui_scale`,
    `unit_economy`, `unit_world_view`, `unit_play_loop`, `unit_action_card`, `unit_input_actions`,
    `unit_skill_bar`, `unit_spell_ui` pass. Full suite not run.
    - [x] M34.5 merged ([PR #224](https://github.com/Daddy-Ousen/innworld-rpg/pull/224)).
    - [ ] The user checks the fixes on the phone with v0.1.8-alpha.
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
- [x] M29.1 merged ([PR #203](https://github.com/Daddy-Ousen/innworld-rpg/pull/203)).
- [x] M29.2 Liscor is wary of Humans (2026-10-18, branch `feat/m29.2-wary-liscor`). User pick: regard and shop price.
  New optional `rules.standing.race_regard [{town, race, start, fade, price?, shops?, except?}]`; `Standing.race_start`,
  `Standing.shop_markup`. Liscor Drakes start at -3 (wary), Lism +15%, both gone at Liscor reputation 10; Relc, Olesm,
  Selys excepted. No save change. Also fixed `sim_balance_money` (broken by M29.1: no patrons before day 15; the sim now
  sets `wandering_inn.has_regulars`). Tests: `unit_race_regard` (new, 6), `unit_standing` (Lism band changed), `unit_economy`,
  `unit_interact`, `unit_npc_react`, `unit_data_db`, `sim_balance_money`, `sim_30_days`, `sim_balance_progress`,
  `sim_breakthrough_probe`, `unit_work_duress`, `unit_actions`, `sim_book8_liscor_two`, `unit_portrait` pass; validator books 1 – 8:
  0 errors. Full suite not run.
  - [ ] The user talks to Lism and buys at his stall on day 1, then after some talks and serving (`godot --path game`).

- [x] M29.3 – M29.5 (2026-10-18, branch `feat/m29.3-looks`, stacked on the M29.2 branch; three commits). Looks: Magnolia
  pink, Erin green shirt, Moore `scale` 1.35 (new optional look key, user pick; Antinium art later). M29.4: one
  "The Story So Far" page after the last canon day (flag `story.end_shown`, no save change). M29.5: camera offset
  lifts the fight above the log strip. Tests: `unit_art` (+1), `unit_story_end` (new, 4), `unit_system_messages`,
  `unit_night`, `unit_canon_db`, `unit_journal`, `unit_no_xp_shown`, `sim_decline`, `sim_30_days`, `unit_play_loop`,
  `unit_game_state`, `unit_combat_screen` (+1), `unit_hud_log`, `unit_touch_controls`, `unit_ui_scale`, `unit_monster_art`,
  `unit_portrait` pass. `unit_world_view` has 1 red (`test_use_menu_lists_and_uses`: stove actions, from the Blue Pastry
  PR, not from this work). Full suite not run.
  - [ ] The user looks at Erin, Magnolia and Moore, a fight at the bottom of a map, and the end page after day 163.

## M30 Voices and the Earther (plan `docs/plans/m30.md`, ADR 0044)
- [x] M29.3 – M29.5 merged ([PR #206](https://github.com/Daddy-Ousen/innworld-rpg/pull/206)).
- [x] M30.0 design (2026-10-18, branch `docs/m30.0-voice-design`). User picks: plan schema with talk options, 15-NPC
  Book 1 cast, short lines in own words (max 20 words), barks as planned (4 tiles, 20 min, stable hash). ADR 0044
  "M30.0" has `data/voices.json`, `rules.voice`, talk order, `voice:<id>` picks, validator list. Picks use a stable
  hash, not `gs.rng`. M30.5 save is now v23 (v22 went to M29.1). Docs only, no tests run.
- [x] M30.1 engine (2026-10-18, branch `feat/m30.1-voice-engine`): `core/voice.gd`, `data/voices.json` (empty),
  `rules.voice`, `Interact.VOICE` rows + `action_of`, use menu and console rows, `world/view_bubbles.gd` barks,
  Python `check_voices`. No save change. Tests: `unit_voice` (new, 12), `unit_interact`, `unit_standing`,
  `unit_talk_topics`, `unit_play_loop`, `unit_console`, `unit_data_db`, `unit_race_regard` pass; `unit_world_view`
  19 pass, 1 red (`test_use_menu_lists_and_uses`, old Blue Pastry stove count, not from this work). Validator books
  1 - 8 + voices: 0 errors. Python 120 OK. Full suite not run.
- [x] M30.1 merged ([PR #208](https://github.com/Daddy-Ousen/innworld-rpg/pull/208)).
- [x] M30.2 voices for the Book 1 cast (2026-10-18, branch `feat/m30.2-voices-book1`): 15 entries in `data/voices.json`
  (Erin, Relc, Klbkch, Zevara, Beilmark, Pisces, Olesm, Selys, Krshia, Lism, Ryoka, Ceria, Pawn, Rags, Toren). Own
  options: Erin (work, chess, inn), Relc (spar), Pisces (magic), Olesm (chess), Krshia (haggle), Toren (chess). A reading
  agent fixed 11 lines. Tests: `unit_voice` (+5, now 21), `unit_talk_topics` and `unit_standing` (changed: a voiced NPC's
  first talk gives a greeting AND a line), `unit_interact`, `unit_play_loop`, `unit_console`, `unit_race_regard`,
  `unit_data_db`, `sim_canon_book1`, `unit_hud_log`, `unit_npc_react`, `unit_game_state` pass; validator: 0 errors;
  Python 120 OK. `unit_world_view` still has the old red (`test_use_menu_lists_and_uses`). Full suite not run.
- [x] M30.3 voices for the Books 2 – 8 cast (2026-10-18, branch `feat/m30.3-voices-books2-8`, stacked on M30.2): 20
  entries (35 in all): Lyonette, Mrsha (brackets), Bird, Ksmvr, Yvlon, Numbtongue, Headscratcher, Badarrow, Rabbiteater,
  Shorthilt, Zel, Ilvriss, Jelaqua, Moore, Halrac, Wesle, Octavia, Magnolia, Laken, Calruz. Every line waits for a story
  flag. Options: Bird (archery), Yvlon (spar), Zel (stance), Octavia (haggle). Two reading agents fixed 33 lines; Book 6
  flags (Zel's death) were checked against canon summaries only (no Book 6 text here). Tests: `unit_voice` (+4, now 21),
  `unit_interact`, `unit_standing`, `unit_talk_topics`, `unit_data_db`, `unit_play_loop` pass; validator 0 errors; Python 120 OK.
  Full suite not run.
  - [ ] The user talks to Erin, Relc, Krshia and Toren on day 8 and walks past them (barks), then later to Zel and Mrsha (`godot --path game`).
- [x] M30.4 the Earther meeting (2026-10-19, branch `feat/m30.4-earther-meeting`). User picks: three optional voice
  option fields (`set_flags`, `relationship`, `page`), all six Earthers react. Erin's talk: page "From Earth" (6 lines,
  her face), +3, flag `erin.knows_player_is_earther`, 4 Earth lines after. Ryoka, Laken (+2) and new small entries for
  Rose, Imani, Joseph. No save change. Tests: `sim_earther_meeting` (new, 5: once, lines, save, Ryoka, same canon
  history and RNG with and without the talk), `unit_voice` (+3, now 24), `unit_interact`, `unit_talk_topics`,
  `unit_standing`, `unit_console`, `unit_data_db`, `unit_system_messages`, `sim_canon_book1` pass; validator 0 errors;
  Python 121 OK. Full suite not run.
  - [ ] The user tells Erin, then sees the page with her face (`godot --path game`, talk to Erin, "Tell Erin you are from Earth").
- [x] M30.5 who you are (2026-10-19, branch `feat/m30.5-who-you-are`, stacked on M30.4). User picks: save v23,
  background pool 25 %, 6 look presets. `core/player_identity.gd`, `data/backgrounds.json` (6 backgrounds, flag
  `background.<id>`, one Erin line each), `player_2` – `player_6` looks + sheets, `ui/create_player.gd` ("Who are
  you?" after the start pick, in a scroll box), welcome page and character sheet name the player, view and fight bar
  use the look. Save v22 -> v23 migration. Checked on renders at 100 % and 200 % menu size. Tests:
  `unit_player_identity` (new, 12), `unit_play_loop` (changed title flow, +1), `unit_game_state`, `unit_voice`,
  `unit_save_slots`, `unit_touch_controls`, `unit_ui_scale`, `unit_art`, `unit_class_system`, `unit_combat_screen`,
  `unit_system_messages`, `unit_no_xp_shown`, `unit_console`, `unit_data_db`, `unit_standing`, `unit_spell_ui` pass;
  `unit_world_view` 19 pass, 1 old red (stove count). Validator 0 errors; Python 124 OK. Full suite not run.
  - [ ] The user makes a new game (name, look, background), then tells Erin about Earth (`godot --path game`).
  - [ ] The user tries the "Who are you?" screen on a phone (touch, big menu size, the on-screen keyboard).
- [x] M30.4 and M30.5 merged ([PR #211](https://github.com/Daddy-Ousen/innworld-rpg/pull/211), [PR #212](https://github.com/Daddy-Ousen/innworld-rpg/pull/212), merge commit bad8b49).
- [x] ROADMAP updated (2026-10-19, branch `docs/roadmap-update`): M29 and M30 marked merged, phone check for M30.5 added,
  next step M31.0, outside PR #210 in Later. Docs only, no tests run.

- [x] M28 leftover `sim_canon_book8` written (see M28 above).

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
- [x] Permission (user decision 2026-10-19): a mod on the author's Discord said fan games are fine while they keep the
  author's fan-work rules. Store text reworded to keep them (`docs/PLAY_STORE.md` section 0). Keep the Discord screenshot.
- [x] Play Console (2026-10-19, account "Thrive IT Solutions", Personal): app "Innworld RPG" created
  (`org.daddyousen.innworldrpg`, Game, Free). App content all saved: privacy policy, no ads, no sign-in, no ad ID,
  not government / financial / health, target 16-17 + 18+, data safety "no data". Content rating saved: ESRB Teen,
  PEGI 16, USK 16; Taiwan refused a rating (not sold there). Store listing saved (text, icon, banner, 6 screenshots;
  icon and banner labelled AI-assisted, user pick). Category Role Playing, email rhasan229@gmail.com, website GitHub.
  Closed track "Alpha": 178 countries; release 1 draft has release notes.
- [x] AAB uploaded (user dragged it in; version code 5, API 29+, target 36, arm64). Taiwan removed from the track
  (rating refused there: 177 countries). Release saved and 14 changes sent to Google for review (2026-10-19; managed
  publishing off, so the closed test goes live when approved; review takes up to 7 days).
- [x] Release 5 (v0.1.6) was approved and is live on the Alpha track (seen 2026-10-24; testers managed by a Google Group).
- [x] v0.1.8 sent (2026-10-24): release "7 (0.1.8-alpha)" on Closed testing - Alpha, full rollout, notes in en-US.
  The user dragged in the aab; I filled the notes, saved and sent 1 change for review (quick checks first, then up to
  7 days). Two warnings only: no deobfuscation file, no native debug symbols (same as before; not blocking).
  - [ ] Google approves the v0.1.8 release.
- [ ] The user adds 12+ testers (emails or a Google Group) to the closed track; 14 days; then apply for production.
- [ ] Tablet check (API 36 cannot lock landscape on large screens). Store tags (optional).

## Releases (ADR 0029)
- [x] v0.1.8-alpha (2026-10-24, [PR #225](https://github.com/Daddy-Ousen/innworld-rpg/pull/225), merge commit c331307,
  tag `v0.1.8-alpha`): the M34.5 phone fixes. Android code 7. Smoke tests pass (events=1403, maps=51, problems=0).
  GitHub release (pre-release) has the 3 zips + signed apk (sizes checked); Pages deploy started from the release.
  The aab stays local (`export/`) for Play. No GUT run (no game code changed).
  - [ ] The user installs the apk from the release page and checks the fight and shop fixes on the phone.
- [x] v0.1.7-alpha (2026-10-22, [PR #222](https://github.com/Daddy-Ousen/innworld-rpg/pull/222), merge commit e42ae14,
  tag `v0.1.7-alpha`): the M34 phone controls. Android code 6. Smoke tests pass (events=1403, maps=51, problems=0).
  GitHub release (pre-release) has the 3 zips + signed apk (sizes checked); Pages deploy started from the release.
  The aab stays local (`export/`) for Play. No GUT run (no game code changed).
  - [ ] The user installs the apk from the release page on the phone and plays M34.
  - [ ] Optional: the user drags `export/InnworldRPG-v0.1.7-alpha-play.aab` into the Play closed track.
- [x] v0.1.6-alpha (2026-10-19, [PR #214](https://github.com/Daddy-Ousen/innworld-rpg/pull/214), merge commit a366c24,
  tag `v0.1.6-alpha`): version code 5. Smoke tests pass (events=1403, maps=51, problems=0). GitHub release has the 3 zips
  + signed apk; Pages deploy started from the release. The aab goes to Play only. No GUT run (no game code changed).
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

## M31 — Signposts and scene beats (plan `docs/plans/m31.md`, ADR 0044)
- [x] M31.0 engine (2026-10-24, branch `feat/m31.0-foreshadow-beats`). User picks: foreshadow `where` / `hours`
  optional (from the stage), morning "Talk in Town" page + journal "Coming up", beats as log line + bubble, no
  save bump ("beat" in `combat.stage_run`, tolerant read). New `core/foreshadow.gd`; `core/stage.gd` beats and
  `last_beat`; `CanonDb` / `CombatDb` / Python validator checks. No canon data uses the fields yet.
  Tests (all pass): `unit_foreshadow` (new, 13), `unit_stage` (27, +9), `unit_journal`, `unit_system_messages`,
  `unit_voice`, `unit_battle`, `unit_music_pick`, `unit_canon_moments`, `unit_world_view`, `unit_canon_db`,
  `sim_canon_book1`. Validator books 1 – 8: 0 errors. Python 128 OK. Full suite not run.
- [x] M31.1 signposts (2026-10-24, branch `data/m31.1-signposts`): a `foreshadow` on all 25 fight stages and on 10
  key scenes (list in ADR 0044 "M31.1" and `KEY_SCENES` in `unit_foreshadow`). `days_before` 1; burning of Brunkr
  and Ulrien 0; Zel's funeral 2. New Python check: given foreshadow hours must fit the stage hours.
  Tests (all pass): `unit_foreshadow` (15, +2 real-data tests), `unit_canon_db`, `sim_canon_book1`,
  `sim_canon_book7`. Validator books 1 – 8: 0 errors (book 6 copy check skipped: no raw text here). Python 129 OK.
  Full suite not run.
- [x] M31.2 beats (2026-10-24, branch `data/m31.2-beats-books-1-4`): 5 – 6 beats on all 17 Books 1 – 4 scenes
  (Book 1 has none). Speakers only placed NPCs; Toren and Mrsha get unspoken lines. Summaries from a reading agent.
  New `unit_scene_beats` (count 3 – 6, speakers, at most 20 words, inside the scene hours).
  Tests (all pass): `unit_scene_beats` (5, new), `unit_canon_db`, `sim_canon_book2`, `sim_canon_book3`,
  `sim_canon_book4`. Validator books 1 – 4: 0 errors (copy check on). Python 129 OK. Full suite not run.
- [x] M31.3 beats (2026-10-24, branch `data/m31.3-beats-books-5-8`): 5 – 6 beats on all 30 Books 5 – 8 scenes,
  2 – 3 ally shouts on all 25 fight stages (a shout only after its speaker's wave arrives). Book 6 (no raw text
  here) written from the canon summaries only. 3 lines reworded after the copy check. `unit_scene_beats` now
  covers 47 scenes and 25 fights.
  Tests: `unit_scene_beats` (6), `unit_canon_db`, `sim_canon_fights`, `sim_book8_raid_one`, `sim_book8_raid_two`,
  `sim_book8_battle_one`, `sim_canon_book5`, `sim_canon_book7` pass. `sim_canon_book6` 12/13: the failing test
  (`test_greydath_is_a_flag_not_a_merge`, line 185) also fails on main without this change (old failure).
  Validator books 1 – 8: 0 errors. Python 129 OK. Full suite not run.
- [ ] M31 play check: the user plays a signposted day and a scene.
- [x] Old failure: `sim_canon_book6` `test_greydath_is_a_flag_not_a_merge`. Fixed: see "Fixes" (Greydath one id).

## M32 — Climaxes of Books 6 – 8 (plan `docs/plans/m32.md`, ADR 0044)
- [x] `sim_canon_book8` merged (PR #235).
- [x] M32.0 choices and reading (2026-10-25, branch `docs/m32.0-choices`). User picks: Zel can be saved (drive off
  Bea and Ijvani before the last wave, Zel standing); a new battlefield map; Tremborag's hall stays news; Klbkch
  always dies; a living Zel gives Selys the Heartflame himself. Reading agents (Sonnet) read 5.44 and 4.47 – 4.49:
  no Drakes beside Zel (Human levy, Rose Knights, Thomast); five Chosen; Nokha is a swordswoman. Book 6 text was
  extracted locally to `canon/raw/book6/` (gitignored). M32.4 is now the "Zel lives" bend. Docs only, no tests run.
- [x] M32.1 three-door battle (2026-10-25, branch `feat/m32.1-three-doors`, ADR 0044 "M32.1"). Enemies `calruz`
  (yields) and `nokha_awakened` (flees) use `escape` (no new field); awakened Raskghar danger 0.95; cage object
  `raskghar_cages`; the Horns wave and Calruz last; 4 `change` hooks (Calruz, cages, night raid, daylight raid).
  Tests (all pass): `sim_book8_battle_one` (11), `sim_book8_raid_one` (8), `sim_book8_raid_two` (8),
  `sim_kill_book8` (6), `sim_canon_book8` (6), `sim_player_hooks` (6), `unit_combat_db`, `unit_monster_art`,
  `unit_sound_cues`, `unit_ground_art`. Validator books 1 - 8: 0 errors. Python 129 OK. Full suite not run.
- [x] M32.2 Zel's stage (2026-10-25, branch `feat/m32.2-zel-stage`, ADR 0044 "M32.2"). User pick: the full save
  rule. Engine: `drive_off_foe` records (context `waves_left`, `protect_standing`), stage key `protect`, hook key
  `all` (CanonDb and the Python validator check both). New map `invrisil_battlefield` (exit from `invrisil_gate`),
  enemies `rose_knight`, `bea`, `ijvani`, `oom`, `venitra`, `kerash` (all escape). Stage on
  `b6.the_battle_of_invrisil_opens`, signpost 3 days before; hooks `player_fought_beside_zel`,
  `player_broke_bea_and_ijvani` (sets `zel.saved_by_the_player`; Zel still dies). Tests (all pass): new
  `sim_book6_zel_stage` (9), `unit_stage` (33), `unit_director` (27), `unit_combat` (93), `unit_player_hooks` (16),
  `unit_canon_db` (7), `unit_combat_db`, `unit_monster_art`, `unit_sound_cues`, `unit_map_db`, `unit_other_maps`,
  `unit_ground_art`, `sim_canon_book6` (13), `sim_book6_zel_dies` (7), `sim_kill_book6` (9), `sim_book6_world` (9),
  `sim_gazi_attack` (5), `sim_book3_stages` (10), `sim_book8_battle_one` (11). Validator: 0 errors. Python 131 OK.
  `sim_book5_last_light` 7/9: the 2 failures (`standing.gd:100` String error) fail on main too (old). Full suite not run.
- [x] M32.3 boss feel (2026-10-26, branch `feat/m32.3-boss-feel`, ADR 0044 "M32.3"). User picks: 3 new ability
  kinds, fear takes AP, the Goblin Lord is a new foe. `MonsterAbilities`: `fear` (Skinner "Red eyes", 2 AP when in
  sight within 6), `bile` (Crypt Lord, poison 3 rounds; replaces its `ranged`), `command` (+accuracy, no flee for
  tagged foes near). Regrika: agility 8 and a "Charge" leap (data only). New enemy `goblin_lord` (escape, command,
  Shaman look, voice) in the wave before the Chosen on Zel's stage; `player_fought_beside_zel` counts him. No save
  change (state in `encounter`). Tests (all pass): `unit_monster_abilities` (18), `unit_combat_db` (14),
  `unit_monster_art` (6), `unit_sound_cues` (9), `sim_book6_zel_stage` (9), `sim_skinner_night` (7),
  `sim_esthelm_siege` (6), `unit_cover_position` (10), `unit_encounter` (25), `unit_monster_sim` (32),
  `unit_combat` (31), `unit_combat_preview` (15), `unit_combat_skills` (21), `sim_canon_fights` (6),
  `sim_canon_book1` (15), `sim_canon_book5` (19), `sim_kill_book5` (10), `sim_canon_book6` (13),
  `sim_book6_zel_dies` (7). Validator books 1, 5, 6: 0 errors. Python 131 OK. Full suite not run.
- [x] M32.4 Zel lives (2026-10-26, branch `feat/m32.4-zel-lives`, ADR 0044 "M32.4"). No engine, schema or save
  change. Death `not_flags: zel.saved_by_the_player` + mutate to `b6.zel_spares_reiss_and_lives` (sets
  `zel.survived_invrisil` and the Goblin flags). Alts: Magnolia's bounty, Az'kerash's anger, Liscor hears he lived;
  Reiss guarding the body and Klbkch's mirror cancel. Book 7 mourning needs `zel.dead_at_invrisil`; funeral stage
  `when_flags`. `b7.zel_gives_selys_the_heartflame` (needs a living Zel with the armour). Zel goes back to Liscor
  (behaviour `unless_flags`). Save hook clears the "Az'kerash came" flags. Cost: 25 events lost, drift 15.
  Tests (all pass): new `sim_book6_zel_lives` (8), `sim_book6_zel_stage` (9, Zel now lives when saved),
  `sim_canon_book6` (13), `sim_canon_book7` (5), `sim_kill_book6` (9), `sim_book6_zel_dies` (7),
  `sim_book7_zel_and_selys` (4), `unit_canon_db` (7). `sim_kill_book7` 9/10: Magnolia ceiling raised 12 / 18 ->
  31 / 30 (no battle, so Zel lives and is not mourned); the Laken drift failure (50 > 13) is old (also on main).
  Validator books 6, 7: 0 errors. Python 131 OK. Full suite not run.
- [x] M32.4 merged ([PR #241](https://github.com/Daddy-Ousen/innworld-rpg/pull/241)). All M32 build steps are merged.
- [ ] The user plays the three doors and Zel's last stand.

## M33 — Depth: spells, dishes, quests, friends (plan `docs/plans/m33.md`, ADR 0044)
- [x] M33.0 canon spells (2026-10-26, branch `feat/m33.0-canon-spells`, ADR 0044 "M33.0"). User picks: 8 damage
  spells, all 4 new kinds, friend gate. Reading: 2 Sonnet agents, Books 1 – 8. New `core/spell_effects.gd`: `hold`
  ([Astral Binding]), `blink` ([Flash Step]), `hide` ([Invisibility]), `wall` ([Ice Wall]); shapes `self`, `tile`;
  state in `combat.encounter`. `learn.band` ("friend" on every teacher). 17 spells, each with a spellbook on the
  Liscor shelf. No save change. Tests (all pass): new `unit_spell_effects` (12), `unit_spells` (31),
  `unit_spell_learning` (19), `unit_spell_ui` (13), `unit_m24_spells` (4), `unit_economy` (25), `unit_encounter` (25),
  `unit_monster_sim` (32), `unit_cover_position` (10), `unit_combat.gd` (31), `unit_combat_preview` (15),
  `unit_combat_skills` (21), `unit_monster_abilities` (18), `unit_movement` (13). Validator books 1 – 8: 0 errors.
  Python 131 OK. Full suite not run.
- [x] M33.1 Erin's food and drink (2026-10-26, branch `feat/m33.1-erin-food`, ADR 0044 "M33.1"). 5 recipes, 5 actions, 5 dishes, 5
  ingredients; ingredient `from_flag` is the story gate. Also fixed: `make_pastry` had no sound (`unit_m24_goods` red on main).
  Tests: `unit_m33_food` (new, 3), `unit_m24_goods`, `unit_cooking` (8 -> 13 recipes), `unit_economy`, `unit_guests`,
  `sim_inn_service`, `unit_data_db`, `unit_sound_cues` pass; validator books 1 – 8: 0 errors; Python 131 OK. Full suite not run.
  - [ ] The user plays: buy honey after 2.42, cook at the inn stove, serve the new dishes.
- [ ] The user learns a spell from a friend and casts the new kinds in a fight.

## Docs
- [x] ROADMAP update (2026-10-26, branch `docs/roadmap-update-3`): M31 and M32 moved to Done, their play checks to
  "Waits on the user", the Rags / Laken alt to Later, next step M33.0. Docs only, no tests run.
- [x] ROADMAP update (2026-10-25, branch `docs/roadmap-update-2`): M31 marked merged (PR #230 - #232), next step `sim_canon_book8` then M32.0. `sim_canon_book6` 13/13 pass on main. Docs only.
- [x] ROADMAP cleanup (2026-10-24, branch `docs/roadmap-cleanup`): open work first, done milestones as a one-line
  table at the bottom, ticked steps removed, stale lines fixed. Docs only, no tests run.

## Fixes
- [x] Laken drift ceiling (2026-10-26, branch `fix/laken-drift-ceiling`): `sim_kill_book7`
  `test_laken_dies_and_riverfarm_holds_together` failed, drift 50 > 13 (also on main before M32.4). Cause: the M28
  Book 8 data. Book 7 still adds exactly 13.0. On day 143, `b8.riverfarm_shows_its_trebuchets_to_the_nobles` needs
  Laken, and its whole chain (5.21 E - 5.32 G: gathering, night raid, Rags and Pyrite, Bethal, Lancrel) cancels at
  once. Real causes, so a fair cost. One link was story order only (ADR 0036 rule 1): Elia's mountain siege waited on
  Tyrion saving Laken; now `tyrion_offers_laken_his_hand` waits on that instead. Laken ceiling 26 / 49.5.
  Tests (all pass): `sim_kill_book7` 10/10, `sim_canon_book7` 5/5, `sim_canon_book8` 6/6, `sim_kill_book8` 6/6,
  `sim_book8_north_two` 6/6. Validator book 8: 0 errors. Full suite not run.
  - [ ] Follow-up (design, user pick): Rags's Book 8 thread (Pyrite, Bethal, Lancrel) has no alt when Laken dies.
- [x] Race start null home (2026-10-26, branch `fix/race-start-null-home`): `sim_book5_last_light` (2 tests) errored
  at `core/standing.gd:100` (`Invalid call 'String' constructor: Drake`). Cause: Zel's canon `"home"` is `null`;
  `get("home", "")` returns that `null` (the default is only for a missing key), and `String(null)` fails. Only a
  Drake reaches that call, so Zel trips it once he is on the roster. `race_start` now returns 0 when race or home
  is not a String. Also fixed two broken line breaks in `standing.gd` (tabs where `\` was). Guard test in
  `unit_race_regard` (+1, now 7). Tests (all pass): `unit_race_regard` 7/7, `sim_book5_last_light` 9/9,
  `unit_standing` 21/21. Full suite not run.
  - [ ] Follow-up: the same broken line breaks (tabs, no `\`) sit in `canon_db.gd:194`, `data_db.gd:365`,
    `map_db.gd:675` and `:704`, `npc_react.gd:109`, `npc_sim.gd:91`, `stage.gd:115`, `ui/skill_bar.gd:51`,
    `world/ground_art.gd:199`. They still parse (one long line). Cosmetic only.
- [x] Greydath one id (2026-10-24, branch `fix/greydath-one-id`): `sim_canon_book6` failed at line 185 because M28.1
  added a second record `greydath` for the same Goblin (4.39 G: Greybeard is Greydath; the Book 6 note says keep the id
  `greybeard`). Removed the `greydath` record from `canon/book8/npcs.json`; the two 5.37 G events now use `greybeard`.
  Event ids and `greydath.*` flags kept (saves still load). Tests (all pass): `sim_canon_book6` (13/13),
  `sim_book8_world` (7, +1 guard), `sim_book8_raid_two` (8), `unit_canon_db`. Validator books 6 and 8: 0 errors.
  Python 129 OK. Full suite not run.

## Blockers
- None.

## Balance note
- M6.5: levels cost less (base_xp 40, growth 1.25). A hard inn worker: first class on night 1–3, level 5 by about day 18–21 (`sim_m6_done`: [Cook] level 6 by day 22). Canon Erin is level 9 by day 9; the player is not meant to match her.
- M17.7: cost by total level, hidden cap 100, gentler curve after level 10. M17.8: fighters (two Goblin fights a day) reach level 5 on night 6–7, the inn worker on night 14. The curve was not changed. M17.9: work duress (crowd, cold) brings the busy inn worker to level 5 on night 10.

## Repo
- Public: https://github.com/Daddy-Ousen/innworld-rpg, branch `main`.

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
- [ ] M19 — Book 7 (The Rains of Liscor). Not planned: M19.P first (ADR 0030). Text in the private repo.

## Releases (ADR 0029)
- [x] v0.1.0-alpha (branch `release/v0.1.0`, 2026-10-01, local): `game/export_presets.cfg` (Windows, Linux; `*.json` packed; tests and GUT
  left out), `config/version` and a version label on the title screen, `tools/release.ps1` + `tools/release/smoke.gd` + player
  `README-PLAYERS.txt`. Built and smoke-tested both zips (898 events, 38 maps, 0 problems; 5 nights run from the pack). The Windows
  exe opens and closes clean. Tests run: `unit_play_loop` (16 pass). Full suite not run.
  - [x] Merged ([PR #97](https://github.com/Daddy-Ousen/innworld-rpg/pull/97), merge commit 548f0f5). Tag `v0.1.0-alpha` pushed.
    Pre-release published 2026-10-01: https://github.com/Daddy-Ousen/innworld-rpg/releases/tag/v0.1.0-alpha (two zips).
  - [ ] Android: skipped (user, 2026-10-01). Needs touch controls first (roadmap "Releases").
- [x] README rewrite for players first, developers second (branch `docs/readme-rewrite`, 2026-10-01, local). Counts checked:
  898 events, 261 NPCs, 103 places, 38 maps, 147 GUT scripts (~1,419 tests), 102 Python tests. PR waits for the user.
- [ ] Web build (ADR 0031; user, 2026-10-01: itch.io + GitHub Pages, GitHub URL first, own subdomain later).
  - [x] Branch `feat/web-build` (from `docs/readme-rewrite`): "Web" preset, web zip in `tools/release.ps1`, web-only
    stretch in `project.godot`, Quit hidden in a browser, `.github/workflows/pages.yml`, README "Play in your browser".
    All three zips built and smoke-tested (898 events, 38 maps, 0 problems). Checked in Chrome: play, save, reload, night 0.3 s.
    Tests run: `unit_play_loop` (17 pass). Full suite not run. PR waits for the user.
  - [ ] Merge, then a release with the web zip (user picks: new v0.1.1-alpha or add to v0.1.0-alpha).
  - [ ] Turn on GitHub Pages (Settings → Pages → Source "GitHub Actions"), run the workflow, open the page.
  - [ ] itch.io: the user makes the page and uploads the web zip (steps in `handoff.md`).
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
- M17.7: cost by total level, hidden cap 100, gentler curve after level 10. M17.8: fighters (two Goblin fights a day) reach level 5 on night 6–7, the inn worker on night 14. The curve was not changed; the planned fix is XP sources for non-fighters (optional M17.9).

## Repo
- Public: https://github.com/Daddy-Ousen/innworld-rpg, branch `main`.

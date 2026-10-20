# Handoff

## Just done (2026-10-21, local): M34.P phone controls plan (branch `docs/m34-phone-controls`)
- User: phone menus (shop, NPC talk) are hard to pick from; the Use button is not ideal. Asked for research + a proposal.
- Wrote `docs/plans/m34.md` (root causes, what other phone RPGs do, steps M34.0 – M34.4), ADR 0045, ROADMAP M34
  section (before M31). Root causes: flat `ItemList` in `ui/interact_menu.gd`, one tap fires via
  `TouchControls.activate_on_tap`, no finger-drag scroll on `ItemList`, rows under 48 dp, no map tap outside fights
  in `world/main_input.gd`. User picks: B – D first, same card on desktop (old list goes), hold to attack on touch.
- Next: user merges the PR. Then M34.0 action card **[Opus · medium]**: new `ui/action_card.gd/.tscn`, wire it in
  `world/main_panels.gd`, move the tests that drive the old list (`unit_world_view`, `unit_play_loop`, ...).
- Gotchas: an unrelated `.gitignore` change and `web/` sit in the tree; not committed. Keep core
  untouched: rows still come from `Interact.options`; trade picks use `Interact.trade_action(prefix, good, count)`.
  Tap-walk must send normal move commands (determinism). Check layout on a phone render (Touch notes below).

## Just done (2026-10-19, local): release v0.1.6-alpha + Google Play closed test setup
- Release: PR #214 merged (a366c24), tag `v0.1.6-alpha`, GitHub release with 3 zips + apk. Pages deploy ran from it.
- `docs/PLAY_STORE.md`: section 0 now lists the author's fan-work rules and how we keep them (no book or series name in
  marketing, "unofficial", credit to pirateaba, no crowdfunding). Description counts updated.
- Play Console (Chrome, account "Thrive IT Solutions", app id 4974346913680933873): app made, all App content forms,
  content rating, store listing, store settings and closed track "Alpha" countries done. Detail in `progress.md`.
- The user dragged the AAB in. Taiwan removed from the closed track (IARC refused a rating there; Play blocks the
  release otherwise). Release saved; 14 changes sent to Google for review (2026-10-19, up to 7 days).
- Next: the user adds 12+ testers (Closed testing > Alpha > Testers) and keeps them opted in for 14 days, then applies
  for production. Then M31.0 (see the older entry below).
- Gotchas: the Chrome tool cannot upload files over 10 MB (the AAB is 88 MB): the user must drag it in. The asset
  library upload took only the first file of a multi-file batch once; upload one at a time. The IARC form needs Save
  before Next turns on. Store text must never name a book or the series (author's rule). A new rating refusal for a country means that country must leave every track.

## Just done (2026-10-19, local): ROADMAP update (branch `docs/roadmap-update`)
- PR #211 (M30.4) and PR #212 (M30.5) are merged (main at bad8b49). `docs/ROADMAP.md`: M29 and M30 rows say merged,
  "All steps merged" lines, a phone check for "Who are you?", next step M31.0, outside PR #210 (DKemp98) in Later.
  Docs only, no tests run.
- Next: user merges this PR. Then M31.0 signposts and scene beats engine **[Opus · medium]**: ask the `foreshadow` /
  `beats` schema first (rule 11). Plan `docs/plans/m31.md`. User play checks for M29 / M30 stay open.
- Gotchas: local `main` was stale (behind origin); branch from `origin/main`. Untracked `.uid` files and `web/` are
  still in the tree: not committed here.

## Just done (2026-10-19, local): M30.4 Earther meeting + M30.5 who you are
- M30.4 (branch `feat/m30.4-earther-meeting`, [PR #211](https://github.com/Daddy-Ousen/innworld-rpg/pull/211)):
  voice options may have `set_flags`, `relationship`, `page` (`Voice.apply`; `Interact.perform` returns `page`;
  `SystemMessages.talk_page` shows it with the NPC's face). One-time "earth" talks on Erin (+3), Ryoka, Laken, Rose,
  Imani, Joseph (+2). Flags `<name>.knows_player_is_earther`. Test `sim_earther_meeting`.
- M30.5 (branch `feat/m30.5-who-you-are`, stacked on M30.4, PR to main): save v23 (`player.name/look/background`),
  `core/player_identity.gd`, `data/backgrounds.json`, looks `player_2` – `player_6` (sheets built), `ui/create_player.gd`
  inside a scroll box in `ui/title_menu.gd`. Test `unit_player_identity`. Detail in ADR 0044 "M30.4" / "M30.5";
  test lists in `progress.md`.
- Merged (PR #211, #212). Then the user plays M30 (`godot --path game`: New game ->
  "Who are you?", talk to Erin -> "Tell Erin you are from Earth"). Then M31.0 design **[Opus · high]** (ask the
  `foreshadow` / `beats` schema first, rule 11).
- Gotchas: `Commands.sleep(..., Rest.ANYWHERE)` is refused inside the inn (`inn_interior`): a sleep loop there never
  ends. Sleep at `liscor_gate` like `sim_canon_book1`, and cap the loop. A command moves NPCs on, so look up a voice
  option with `Voice.options`, not the `Interact` row, after a command. `title.new_game()` still starts at once
  (tests use it); the buttons go through `open_create`. Save is v23 now. The LPC clone is in this session's
  scratchpad (`ulpc`, gone next session). `build_sprites` rewrites the CREDITS.md commit line: `git checkout CREDITS.md`.

## Just done (2026-10-18, local): M30.2 + M30.3 voices (branches `feat/m30.2-voices-book1`, `feat/m30.3-voices-books2-8`)
- `game/data/voices.json` now has 35 NPC voices (15 Book 1 + 20 Books 2 - 8). No engine or schema change. Tests added to
  `game/tests/unit_voice.gd` (cast present, every gate flag is set by a real canon event, Mrsha mute, Book 1 options).
  Detail in ADR 0044 "M30.2" and "M30.3"; test list in `progress.md`.
- Two small test edits: `unit_talk_topics` (a first talk with a voiced NPC now logs 2 lines) and `unit_standing`
  (clears `_db.voices` for the generic band line).
- Next: user merges the two PRs (M30.2 first). Then M30.4 the Earther meeting **[Opus · medium]**: a one-time option
  "Tell Erin you are from Earth" on Erin's voice (flag-gated, sets `erin.knows_player_is_earther` through an action
  effect), a 4 - 6 line text page, Ryoka and other Earthers react once. Check `sim_canon_book1` drift 0.
- Gotchas: a new game starts on DAY 8 with the inn open, so lines for days 1 - 7 never show. Voices use flag names from
  canon `set_flags`; the test `test_book1_voice_flags_are_real` catches typos. Book 6 text is not on this machine.
  Write voice data as scratchpad JSON and merge with a script (tabs + CRLF). `git add game` sweeps in the untracked
  `.uid` files: add paths by name. Reading agents (Sonnet) found about one wrong line in five: always fact-check.

## Just done (2026-10-18, local): M30.1 voice engine (branch `feat/m30.1-voice-engine`)
- Built ADR 0044 "M30.0" as designed; detail in ADR 0044 "M30.1". Files: `game/core/voice.gd` (new),
  `game/world/view_bubbles.gd` (new), `game/data/voices.json` (new, empty), `game/data/rules.json` (`voice`),
  `game/core/data_db.gd`, `game/core/interact.gd`, `game/world/main.gd`, `game/world/world_view.gd`,
  `game/ui/interact_menu.gd`, `game/ui/console_commands.gd`, `game/test_support/toy_data.gd` (erases `voice`),
  `tools/validate_data.py`, `tools/tests/test_validate_data.py`, `game/tests/unit_voice.gd` (new).
- Tests: list in `progress.md` M30.1 line. Full suite not run.
- Next: user merges the PR. Then M30.2 Book 1 cast **[Sonnet · high]**: write `voices.json` entries for the 15
  ids in ADR 0044 "M30.0" (own words, max 20 words, 2 – 3 lines per band, 3 – 5 idle). A reading agent checks
  traits against Book 1 (summaries only). Options need existing actions; check each action's `context` rules
  (for example `play_chess` reads `opponent_skill`).
- Gotchas: action tags are normalised, so a context bonus shows as a ratio, not a sum. An own line replaces the
  talk topic for that talk (no gs.rng used then). The Git Bash heredoc ate `
` in a Python string again: use
  the Write/Edit tools for test code. `unit_world_view` `test_use_menu_lists_and_uses` is still red (old).

## Just done (2026-10-18, local): M30.0 voice design (branch `docs/m30.0-voice-design`)
- User took every recommended pick: plan schema with own talk options, 15-NPC Book 1 cast, short own-words lines,
  barks as planned. Written into ADR 0044 "M30.0" (schema, `rules.voice`, talk order, barks, tone, validator,
  checked NPC ids). Plan and ROADMAP: M30.0 ticked; M30.5 save is v23. Docs only, no tests run.
- Next: user merges the PR. Then M30.1 engine **[Opus · medium]**: `core/voice.gd` (greet, line, options,
  bark, FNV-1a hash), `DataDb` loads `voices.json` + validate, `Interact.VOICE` rows and perform, bubbles in
  `world/view_markers.gd`, `tools/validate_data.py` + Python test. Tests per plan M30.1. The schema is approved:
  no need to ask again, unless the engine needs a field the ADR does not list.
- Gotchas: canon ids are long for some (`erin_solstice`, `ryoka_griffin`, `ceria_springwalker`). Confidence words
  are `confirmed | likely | guess`. Voice picks must not use `gs.rng` (keeps canon sims at drift 0).

## Just done (2026-10-18, local): M29.3 – M29.5 (branch `feat/m29.3-looks`, on top of the M29.2 branch)
- M29.3 looks (Magnolia pink, Erin green shirt, Moore `scale` 1.35 via `CharacterSprite.scale_for`), M29.4 end page
  (`Night.STORY_END_FLAG`, `CanonDb.last_day`, `SystemMessages.STORY_END`), M29.5 `WorldView.FIGHT_LIFT`. Three
  commits. Test list in `progress.md`. ADR 0044 "M29.3 – M29.5". Full suite not run.
- Next: user merges (M29.2 first, then this branch). Then M30 voices and the Earther **[Opus · high]**: ask the
  NPC-voice schema question first. Antinium art is a later art step.
- Gotchas: `unit_world_view` `test_use_menu_lists_and_uses` is red on this branch and was red before (Blue Pastry
  stove actions: 9, not 8). LPC clone for sheets is in the old scratchpad `ulpc` (gone next session). `build_sprites`
  rewrites the CREDITS.md commit line: `git checkout CREDITS.md` after. `sed -i` on a new file turned CRLF to LF
  (harmless with autocrlf).

## Just done (2026-10-18, local): M29.2 Liscor is wary of Humans (branch `feat/m29.2-wary-liscor`)
- `rules.standing.race_regard` (optional): `Standing.race_start` feeds `regard`; `Standing.shop_markup` feeds `Economy.price`
  (BUY only). Weight = clamp(1 - town reputation / fade, 0, 1). Data in `rules.json`; ADR 0044 "M29.2".
- Fixed `sim_balance_money` (M29.1 left it red: it plays days 8 – 21 and needs `wandering_inn.has_regulars`). Other
  patron sims checked and pass. Test list in `progress.md`. Full suite not run.
- Next: user merges the PR. Then M29.3 looks **[Sonnet · medium]**: ask about Antinium art (now or later) and Moore's size
  (needs a schema field?). Needs the LPC clone (see "How to rebuild art").
- Gotchas: any Drake NPC whose `home` is in Liscor now starts wary, so a test that wants a neutral Drake greeting must
  use an excepted NPC (relc, olesm, selys) or add relationship. The gate-guard stranger line waits for M30.

## Just done (2026-10-17, local): M29.1 inn name, signs, first guests (branch `feat/m29.1-inn-name`)
- Schema (user picks): canon location `names [{flag, name}]` -> `CanonDb.location_name(flags, id)` (used by
  `ui/hud.gd`, `ui/system_messages.gd` knock-out page, `ui/console_commands.gd` `where`); validator + Python test.
  `rules.inn.patron_flags` (ANY of) and `rules.inn.race_flags {race: flag}` in `core/guests.gd` (`patrons_come`,
  `race_weights`, `validate`). Save v22: `_migrate_21_to_22` sets `wandering_inn.has_regulars` when
  `b1.inn_first_regulars` ran.
- Data: `canon/book1/locations.json` (inn names), `chapters/1.21.json` (+flag `wandering_inn.has_regulars`),
  `rules.json` (goblin patrons 2, gates), `maps/inn_hill.json` (door sign "Inn", plaque `inn_name_sign`, board by flag).
- Tests: list in `progress.md` M29.1 line. All pass. Full suite not run.
- Next: user merges the PR. Then M29.2 Liscor is wary of Humans **[Opus · medium]**: ask the
  `rules.standing.race_regard` schema question first.
- Gotchas: a test that wants patrons with real data must set `wandering_inn.has_regulars` (see `unit_guests._game`).
  `sim_inn_service` plays days 8 – 14 and sets the flag by hand. Goblins stay a patron race after day 19 (no end
  flag yet). In a loop of several Godot runs in one Bash call, some runs died with no output once; rerunning them
  alone worked. The Bash heredoc ate a `\` line end again: write patch scripts with the Write tool.

## Just done (2026-10-17, local): M29.0 the System speaks like the books (branch `feat/m29.0-system-voice`)
- New `game/core/system_voice.gd` (`SystemVoice`): every System line goes through it. Changed callers:
  `core/night.gd` (level, Skill, offer log line), `core/class_system.gd` (accept, consolidation, neglect, loss),
  `core/breakthrough.gd` (`KEY_LINE` const removed; `key_line` calls the helper), `ui/system_messages.gd` (offer page).
  `data/actions.json`: `talk_with_guest` name "Talk". Line list in ADR 0044 "M29.0".
- Tests: list in `progress.md` M29.0 line. All pass. Full suite not run.
- Next: user merges the PR. Then M29.1 **[Opus · medium]**: ask the two schema questions first (location `names`
  by flag; maybe `rules.inn.patron_races_by_flag`).
- Gotchas: all toy classes in `ToyData` are named "[X]" and toy Skills "[S]", so tests expect "[X Level 2!]".
  Accept now gives two lines first ("[X Class Obtained!]", "[X Level 1!]"); consolidation gives "[Conditions Met: …]"
  then the level line. The hint line "X needs a breakthrough to reach level N." stays prose (on purpose).
  Ten untracked `sim_book8_*.gd.uid` / `sim_kill_book8.gd.uid` files came from the import; not committed here.

## Just done (2026-10-17, local): audit plan M29 – M33 (branch `docs/player-audit-plan`)
- The user said "we will do all". Wrote ADR 0044 and `docs/plans/m29.md` … `m33.md`; ROADMAP "At a glance" and
  "Next up" now list M29 – M33 with model tags; a missing `sim_canon_book8` is a new M28 item. Docs only, no tests run.
- ROADMAP "At a glance" now has a "Model · effort per step" column (user ask). It copies the step tags; when a tag
  changes, change both. Reading agents: Sonnet · medium.
- Next: user merges the PR. Then M29.0 (book-style System lines + "Talk" label) **[Opus · medium]**. Each schema or
  save change in ADR 0044's table is asked at the start of its step (rule 11).
- Gotchas: test names in the plans were checked against `game/tests/` (there is no `unit_save_migrations` or
  `unit_title_menu`; migrations are tested in the feature's own unit test, the title flow in `unit_play_loop`).

## Just done (2026-10-17, local): player audit (read-only)
- Wrote `docs/AUDIT_PLAYER_2026-10-17.md` (committed with the plan above). No code or data changed, no tests run.
- Method: v0.1.5 web build served from `export/InnworldRPG-v0.1.5-alpha-web` (`python -m http.server`), driven
  with Playwright; headless `extends SceneTree` scripts (scratchpad) that sleep through all books and print
  `SystemMessages.pages`.
- Next: the user picks the order of work from the audit. Option 1 (NPC voices) needs a schema change: ask first.
- Gotchas: Playwright screenshots of the Godot canvas time out with the default tool; use
  `page.screenshot({timeout: 60000})` in run_code. Godot needs a key held ~120 ms (`keyboard.down`/`up`), a bare
  `press` is lost. In the debug console every second command is often dropped after a walk; send one per call and
  check with `where`. `go n` from the Liscor gate walks into the 10 h road to the camp. Playwright writes
  `.playwright-mcp/` in the repo root: delete it after.

## Just done (2026-10-17, local): M28.9 canon 5.43 - 5.44, M28 complete (branch `feat/m28.9-canon-5-43`)
- 26 events, stage `b8.three_doors_open_on_the_raskghar_camp` (day 163, 18 - 23 h, xp x3), tests `sim_book8_battle_one`, `sim_kill_book8`. The player enters by Erin's magic door in `inn_interior` (open day 163 only, user pick); the camp north door leads back; a knock-out wakes at the inn (rules.json). ADR 0043 has doubts.
- Next: user merges the PR. Then the user plays Book 8. Optional later: own art for the Raskghar (they wear the Gnoll look); the text puts the battle on day 163, not 163 - 164; battle hours are a guess.
- Gotchas: the camp still has no map exits; the door counts against the 4 door trips a day.

## Just done (2026-10-17, local): M28.8 canon 5.39 - 5.42 (branch `feat/m28.8-canon-5-39`)
- 41 events, test `sim_book8_dive_one`. Captive flags (Mrsha, Ceria) stay on. ADR 0043 has flags and doubts.
- Next: user merges the PR. Then M28.9 (5.43, Interlude - Niers, 5.44): the three-door battle STAGE on `raskghar_camp` with xp_window (ask tier, stage details, hooks). Put the 5.43 raid on day 162 night (5.42 ends as it begins), not 163. Erin [Magical Innkeeper] 36 as a `system` record; Calruz taken to the Watch prison; Vakk sacrificed; Fess dies; also a kill sim for the six named dead and validator books 1 - 8.
- Gotchas: Fleetfur and Beetlestare die in 5.30 G (no records, no kill). The Celum scene is in 5.41. Nokha is the ritual woman (same entity as in 5.43).

## Just done (2026-10-16, local): M28.7 canon 5.36, 5.37 G, 5.38 (branch `feat/m28.7-canon-5-36`)
- 41 events, stage `b8.raskghar_raid_the_inn_by_daylight` (day 161, 15 - 18 h, xp x3), test `sim_book8_raid_two`. 5.38 clears `izril.moons_nearly_full`, sets `izril.moons_full`. Flags `mrsha.taken_by_the_raskghar`, `ceria.taken_by_the_raskghar`, `calruz.revealed_as_the_raskghar_great_chieftain`. ADR 0043 has doubts.
- Next: user merges the PR. Then M28.8 (5.39 - 5.42, days 161 - 162): Antinium offensive, Calruz and Ceria, Redfang trek. Ask stage and hook choices first (plan: events only).
- Gotchas: 5.37 G may be day 150 (put on 151). The text never shows the inn fight; the stage is on the hill. Fess dies in 5.3x (kill event).

## Just done (2026-10-16, local): M28.6 canon 5.33 B - 5.35 H (branch `feat/m28.6-canon-5-33`)
- 37 events in `canon/book8/chapters/5.33B|interlude_blackmage|5.34|5.35H.json` (orders 64 - 67), test `sim_book8_raid_one`. A delegated agent wrote it. Not committed. ADR 0043 M28.6 has stage, flags, doubts.
- Stage `b8.raskghar_raid_the_wandering_inn` on `inn_hill` 21 - 24 h, xp x3; hook `player_stood_with_headscratcher_after_the_raid` (5.35 H). `sim_player_hooks` count now 129.
- Next: commit, PR, user merges. Then M28.7 (5.36, 5.37 G): ask stage and hook choices first. The 5.38 raid (day 161) should use or clear `izril.moons_nearly_full` / `raskghar.awakened_by_the_moons`.
- Gotchas: the stage uses `cave_goblin` too (canon). `wandering_inn.drake_boycott` is still set (the text does not end it). Montressa id is `montressa_du_valeross`. The stage test waits ~15 h from 6:00 to reach 21 h; it passes.

## Just done (2026-10-16, local): M28.5 canon 5.30 G - 5.32 G (branch `feat/m28.5-canon-5-30`)
- 32 events, test `sim_book8_north_two`. ADR 0043 has flags and doubts.
- Next: user merges the PR. Then M28.6 (5.33 B, Interlude - Blackmage, 5.34, 5.35 H, days 157 - 160). 5.34 is a FIGHT STAGE (raid on Liscor and the inn, day 159) with an `xp_window`: ask the xp tier and stage details first. Enemies `raskghar_armoured` / `awakened_raskghar` exist.
- Gotchas: the director runs by earliest day first, chapter order only breaks ties. Fleetfur and Beetlestare have no records, so the kill sim skips them. Tyrion's guest is probably Welca (unnamed in text).

## Just done (2026-10-16, local): M28.4 canon 5.27 - 5.29 (branch `feat/m28.4-canon-5-27`)
- 27 events, test `sim_book8_liscor_two`, boycott flag and rule entry (factor 0.15 guess). ADR 0043 has doubts.
- Next: user merges the PR. Then M28.5 (5.30 G - 5.32 G, days 149 - 150, off-map). Ask stage and hook choices first.
- Gotchas: the plan's Griffon Hunt note was wrong: the lost member is Ulrien (Book 5), no Corry. The dive may be day 157.

## Just done (2026-10-16, local): M28.3 canon 5.24 L - 5.26 L (branch `feat/m28.3-canon-5-24`)
- 27 events in `canon/book8/chapters/5.24L|5.25L|5.26L.json`, test `sim_book8_liscor_one`. A delegated agent wrote it; I ran validator and the new test. ADR 0043 has flags and doubts.
- Next: user merges the PR. Then M28.4 (5.27 - 5.29, days 155 - 157): Goblin team, play brawl, Drake boycott (set `wandering_inn.drake_boycott`, add the `rules.inn.race_boycott` entry), dive, spider nest. Ask stage and hook choices first.
- Gotchas: the text never says "rope" for the bridge. The Lyonette class merge also removes [Tactician]. Visits of the "week" sit on days 148 - 151.

## Just done (2026-10-16, local): M28.2 canon 5.21 E - 5.23 G (branch `feat/m28.2-canon-5-21`)
- 38 events in `canon/book8/chapters/5.21E|5.22G|5.23G.json`, test `sim_book8_north_one`. A delegated agent wrote it; I checked validator and tests. ADR 0043 has the flags and doubts.
- Next: user merges the PR. Then M28.3 (5.24 L - 5.26 L, days 144 - 154): ask stage and hook choices at its start (the plan has none; ask if the ball or Pawn scenes want a hook). Put the repair events there (clear `wandering_inn.windows_broken`, Jelaqua's body, Lyonette [Princess] lost then back as [Worldly Princess] 11 as `system` records).
- Gotchas: Book 7 road battle day 142 vs 5.22 G (143 - 144): left as is. Delegating canon writing to one agent worked: brief it with the Book 7 templates, ADR 0030 sections, and the validator docstring.

## Just done (2026-10-16, local): M28.1 world and records (branch `feat/m28.1-world-records`)
- Data only: 2 enemies, map `raskghar_camp`, `canon/book8/{npcs,locations}.json`, Calruz note. ADR 0043 has the list. Plain Raskghar id is `not_gnoll`.
- Next: user merges the PR. Then M28.2 (canon 5.21 E - 5.23 G, off-map, days 143 - 148): ask the stage and hook choices first (none planned). Repair events (clear `wandering_inn.windows_broken`, Jelaqua's body) go into M28.3 (5.24 L).
- Gotchas: Book 8 raw text is in `canon/raw/book8/` (local). Chapter ids: 5.21E ... 5.44, `interlude_blackmage`, `interlude_niers`; `order` 52 - 77. Awakened and armoured Raskghar wear the Gnoll look until the user wants own art.

## Just done (2026-10-16, local): M28.0 boycott rule (branch `feat/m28.0-boycott`)
- `rules.inn.race_boycott` (optional) + `Guests.race_weights`. No data uses it yet: M28.4 adds the Drake entry and the event that sets `wandering_inn.drake_boycott`.
- Tests: `unit_guests` 23, `unit_standing`, `sim_inn_service` pass. Full suite not run.
- Next: user merges the PR. Then M28.1 (enemies, `raskghar_camp`, NPC records, Calruz alive, repair events).

## Just done (2026-10-16, local): M28.P Book 8 plan (branch `docs/m28-book8-plan`)
- Extracted Book 8 to `canon/raw/book8/` (26 chapters, local, gitignored). Seven agents read it; summaries only. Wrote `docs/plans/m28.md` + ADR 0043. Docs only, no tests run.
- User picks: 3 fight stages (5.34 raid, 5.38 raid, 5.44 battle), moon by flags, dungeon dive events only, north thread events only.
- Next: user merges the PR. Then M28.0 (boycott rule; ask before a schema change) and M28.1 (enemies, `raskghar_camp`, records). Canon batches M28.2 – M28.9 after.
- Gotchas: Calruz was "missing" in our data; Book 8 makes him alive (fix in M28.1). Liscor-chapter day numbers are guesses; only Laken's Day N + 45 is firm. Book 8 `order` starts at 52. The ROADMAP row for M28 is not added yet (older uncommitted ROADMAP edits sit in `git stash` "m28-plan-wip" on `feat/website`; do not lose them).

## Just done (2026-10-15, local): release v0.1.5-alpha (branch `release/v0.1.5`)
- Bumped `game/project.godot` and both Android presets (code 4). `tools/release.ps1` ran OK from the PowerShell tool with `C:\Windows\System32` first in PATH (Git Bash tar fails on `D:` paths).
- Next: user merges the PR; then tag `v0.1.5-alpha` on main and `gh release create` with 3 zips + apk. Web Pages publishes from the release.

## Just done (2026-10-15, local): M27 balance from player feedback (branch `feat/m27-balance-feedback`)
- Feedback from a contributor: slow levels, level-10 consolidation, slow selling, fast forgetting. User picked all 4 fixes.
- Plan `docs/plans/m27.md`, ADR 0042. Four commits: M27.0 XP curve + repeat penalty, M27.1 consolidation at 5,
  M27.2 buy/sell many (`Economy.buy/sell(..., count)`, `Interact.trade_action/trade_parts`, menu rows, console `[n]`),
  M27.3 slower decay. Test list in `progress.md` M27 line. Full suite not run.
- Merged: PR #188, merge commit 0812d6d (2026-10-15). Next: user plays (`godot --path game`). If level 10+ is now too fast, raise `base_xp` first.
- Gotchas: menu trade picks may carry `#<count>`; read them with `Interact.trade_parts`, not `substr`.
  A heredoc with many quotes broke Git Bash once: put long patch scripts in a scratchpad .py file.
  The PR #185 entry below is from another session; it is not part of M27.

## Just done (2026-10-15, local): review and fix of PR #185 (Blue Pastry, by DKemp98)
- Worktree `D:\ClaudeC\innworld-pr185`, branch `fix/pr185-blue-pastry` (fetched as `pr-185`). One fix commit a38c6e9..
- Fixed: trailing comma in `recipes.json`; `"bake_"` typo -> `make_pastry` on `pig_stove`; added `sell_goods` to `pig_bar`; 3 tests updated (`unit_actions`, `unit_cooking`, `unit_economy`).
- Tests run (all pass): unit_cooking, unit_actions, unit_economy, unit_guests, unit_map_db, unit_other_maps, unit_celum_map, sim_inn_service, unit_tags. Validator: 0 errors. Full suite not run.
- Open: user says stew and pasta are canon (no `canon_ref` yet). Blue pastry price (17 each, 3 per batch) may be too rich. `roast_meat` rebalanced (30 min, 3 xp).
- Done: merged as PR #187, #185 closed, worktree removed.

## Just done (2026-10-13, local): class tree step 4 (branch `feat/class-tree-step4`)
- Added 15 classes to `game/data/classes.json` and 15 passive Skills to `game/data/skills.json`. Data only. All `confidence: guess`.
- Test: `game/tests/unit_class_tree_step4.gd` (new).
- Next: user reviews names and thresholds, then merge. Not committed yet.
- Gotcha: skill id `measured_dose` already existed (alchemist). The new one is `careful_dose`. Check ids before you add Skills.

## Just done (2026-10-13, local): cleanup of state files
- Moved old entries from `handoff.md`, `progress.md` and `docs/ROADMAP.md` to `docs/PROGRESS_ARCHIVE.md` (section "Archived 2026-10-13"). Nothing deleted. Docs only, no tests run.
- Next: user merges the cleanup PR (PR #183, earther looks, is already merged). Then the Book 8 plan (ROADMAP "Later").

## Just done (2026-10-13, local): own looks for Rose, Imani, Joseph (branch `data/m25.4-earther-looks`)
- User pick A (fix the old `unit_art` fail with sprites). Data + art only, no engine change.
- `game/data/appearance.json`: looks `rose`, `imani`, `joseph` (all `confidence: guess`; modern clothes).
- Built `game/assets/characters/{rose,imani,joseph}.png` with `tools/build_sprites.py --only rose,imani,joseph`.
  CREDITS.md did not change (the parts were already credited).
- Tests: `unit_art` 11/11 (was 1 fail), `unit_m25_whereabouts`, Python 116 OK. Full suite not run.
- Next: user merges the PR. Then the Book 8 plan (ROADMAP "Later").
- Gotchas: after `git sparse-checkout add` the LPC files may not be there at once; run
  `git -C ulpc sparse-checkout reapply` before the build, else the sheets come out empty (3 KB).

## Just done (2026-10-13, local): M26.1 split `world_view.gd` (branch `refactor/m26.1-split-world-view`)
- No behaviour change. `game/world/world_view.gd` 1285 -> 335 lines. It keeps nodes, state, `setup`, `refresh`, `_process`.
- New in `game/world/`: `view_art.gd` `ViewArt` (static only: TILE, sheet paths, tile sets, object art, `square`,
  `rect`, `poly`, `add_label`, `region_sprite`, `tile_prop`), `view_map.gd` `ViewMap` (ground, objects, props, signs,
  crowd, animated objects), `view_markers.gd` `ViewMarkers` (NPCs, patrons, monsters, fairies, traps, bars, `labelled`),
  `view_effects.gd` `ViewEffects` (AnimDiff `play`, turn replay). ADR 0041.
- Public names stay on WorldView (constants copied from helpers, statics and `play`/`replay`/`skip_replay`/`is_replaying`
  pass on). No test changed.
- `GroundArt`, `SignArt`, `CombatOverlay` now name `ViewArt` instead of `WorldView` (else a script cycle: "resources
  still in use at exit" in every view test).
- M26 is all ticked: moved to Done in `docs/ROADMAP.md`. Next: user merges the PR. Then the Book 8 plan (see ROADMAP "Later").
- Tests: list in `progress.md` M26 line. All pass. Full suite not run.
- Gotchas: `unit_art` fails on main too (Imani, Joseph, Rose from M25.4 have no own look; the test wants one for every
  canon NPC). Fix = sprites via `tools/build_sprites.py` or a test exception: ask the user.
  Scripts that load the main scene sometimes print "8 ObjectDB instances leaked" + "4 resources still in use" at exit,
  not every run. main shows the same (checked 2026-10-13), so it is not from the split. Helpers keep the view in an UNTYPED `_v` (ADR 0040 rule).
  New `class_name` needs `godot --headless --path game --import`.

## Just done (2026-10-13, local): M26.0 split `main.gd` (branch `refactor/m26.0-split-main`)
- No behaviour change. `game/world/main.gd` 967 -> 499 lines, now `class_name MainScreen`: commands + turn replay.
- New RefCounted helpers (made in `MainScreen._ready`): `main_input.gd` `MainInput` (keys, held direction, mouse),
  `main_aim.gd` `MainAim` (armed Skill/spell, click walk, tap, turn overlay + plan), `main_travel.gd` `MainTravel`
  (long-road prompt; `main.travel` = `road.prompt`), `main_panels.gd` `MainPanels` (is_busy, console, use menu, bag,
  touch pad, UI scale, history, night pages, morning autosave). ADR 0040.
- Public members tests use stay on MainScreen as pass-on calls (`step`, `click`, `tap`, `hover`, `cancel`, `is_busy`,
  `armed_skill`, `_walking`, `toggle_console`, `open_use_menu`, ...). No test changed.
- Tests: the 20 scripts listed in `progress.md` M26 line, all pass. Full suite not run.
- Next: user merges the PR. Then M26.1 split `world_view.gd` (1285 lines) **[Opus · medium]**.
- Gotchas: helpers keep the screen in an UNTYPED `_m`. A typed `_m: MainScreen` makes a script cycle and Godot
  reports "N resources still in use at exit". Values read from `_m` need explicit types (`:=` cannot infer).
  "ObjectDB instances leaked" warnings at exit come and go between runs: audio streams still playing (not ours).
  New `class_name` needs `godot --headless --path game --import`.

## Waiting on the user
- Merge the cleanup PR (branch `docs/state-cleanup`).
- Ask pirateaba; back up the keystore (see `docs/ROADMAP.md` "Waits on the user").
- Play a busy inn day and a winter walk to feel the new pace.
- Play fights with Skills, spells and cover; look at M14.6 / M14.7 colours and M16 maps; play Book 6 (`godot --path game`).
- Play with touch controls and Menu size (PC with touch screen; phone with the v0.1.2 browser build).

## Gotchas (XP)
- Work duress (M17.9) is computed only when the caller passes no `opts.duress`. A test that wants plain XP from a
  crowd action passes `{"duress": 1.0}`. `sim_balance_*` tables: run with `BALANCE_LOG=<file>`.
- A stage unit on `inn_hill` must not stand on the snow wall rects (`sim_winter` checks every stage).

## Touch notes (M20)
- A touch button sends `InputEventAction` press/release with `Input.parse_input_event` (buffered: tests call
  `Input.flush_buffered_events()`). Use parse_input_event for both press and release, never `Input.action_release`
  for one side only: a buffered press after a direct release leaves the action stuck down.
- `TouchControls.sync` runs every frame from `main._process`. When the pad hides it calls `release_all()`.
- A tap is an emulated mouse click with `device == InputEvent.DEVICE_ID_EMULATION`; the fight cell comes from
  `event.position` through `view.get_canvas_transform()`, not from the mouse pointer.
- Headless test windows are tiny (64 px): layout asserts about screen fit fail there. Check layout on a render.
- Renders in the cloud work (Mesa + Xvfb): write a throwaway `extends SceneTree` script, `await process_frame` once
  before loading scenes (autoloads), then
  `xvfb-run -a -s "-screen 0 1280x720x24" godot --path game --audio-driver Dummy --rendering-driver opengl3 --resolution 1152x648 -s res://_shot.gd -- <out dir>`
  and save `root.get_texture().get_image()` after `RenderingServer.frame_post_draw`. Delete the script after.
- Phone renders: `-screen 0 2400x1080x24 --resolution 2400x1080`, and in the script set the web stretch by hand
  (`root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS`, aspect EXPAND, size 1152 × 648): `.web`
  overrides do not apply under Xvfb. Set the scale with `Session.set_ui_scale_mode`, not `content_scale_factor`
  (Session re-applies its own factor on a resize). Point `ui_scale_path` / `touch_settings_path` at the out dir.
- UI scale (M20.3): a faked screen touch in a test makes Auto pick 200 % (the headless window is tiny). Reset with
  `Session.apply_ui_scale()` after `touch_seen = false`.

## Web build notes (ADR 0031, merged)
- Branch `feat/web-build` (from `docs/readme-rewrite`, so it holds the README PR #99 commits too).
- All export templates 4.7.2 are now installed in `%APPDATA%\Godot\export_templates\4.7.2.stable` (all platforms).
- `tools/release.ps1` makes `export/InnworldRPG-v<version>-web.zip` (index.html at the zip root, 70 MB).
- `.github/workflows/pages.yml`: on a published release (or by hand with a tag) it downloads the `*-web.zip`
  from the release and publishes it to Pages. It does not build. Pages must be set to "GitHub Actions" once.
- itch.io steps for the user: itch.io → Upload new project → Kind of project "HTML" → upload the web zip →
  tick "This file will be played in the browser" → Viewport 1152 x 648, tick "Fullscreen button" →
  Classification "Games", pricing "No payments" (non-commercial) → Save → set Visibility "Public".
- Own subdomain later: DNS CNAME `play.<domain>` → `daddy-ousen.github.io`; Settings → Pages → Custom domain;
  Enforce HTTPS. Nothing in the repo changes.
- Gotchas: the web build only scales with the `.web` stretch settings in `project.godot`. Browser saves are per site.
  `git checkout -- game/assets` before an export makes Godot reimport and can crash the export (known segfault):
  run `--import` once (twice if it crashes) before `tools/release.ps1`. The in-app browser `type` action does not
  reach Godot's input; Playwright `keyboard.type` works (open the console with `Backquote`, `sleep *` sleeps anywhere).


## Gotchas (release)
- Every export and `--import` rewrites many `.import` files (line ends). Run `git checkout -- game/assets` after.
- A release template ignores `-s`. Smoke-test a build with the editor console exe: `--headless --main-pack <exe> -s <script>`.
- The local class cache can be stale after cloud merges ("Identifier X not declared"): run `--import` once.
- Two untracked test `.uid` files came from cloud merges (`sim_book6_silver_swords`, `sim_book6_zel_dies`); committed on this branch.

## Gotchas (cloud)
- Chapter ids for non-numbered chapters follow the raw `index.json` id (for example `interlude_the_antinium_wars_pt_3`); the file name must match.
- A dead NPC is removed from `gs.npcs.npcs`: tests that read an NPC after its death use `gs.world.is_alive`.
- Character sheets in the cloud: sparse-clone the LPC generator into the scratchpad (about 240 MB, 1 – 2 min):
  `git clone --depth 1 --filter=blob:none --sparse <ULPC url> ulpc`, then `git -C ulpc sparse-checkout set --no-cone
  /CREDITS.csv /LICENSE /palette_definitions/ /sheet_definitions/ '/spritesheets/**/walk.png' ... '/spritesheets/weapon/'
  '/spritesheets/shield/'` (the list in "How to rebuild art"). No `MSYS_NO_PATHCONV` on Linux.
- `unit_map_db.test_real_exits_lead_back` has a `ONE_WAY` list (the Ruins chute). A new one-way exit goes there.
- The SessionStart hook works in a real cloud VM, but it cannot clone the private book repo. Fix: attach
  `Daddy-Ousen/innworld-canon-raw` (add_repo), `git clone --depth 1` it to `/home/user/innworld-canon-raw`, then
  `mkdir -p canon/raw; ln -s /home/user/innworld-canon-raw/book6 canon/raw/book6` (same for book7). `canon/raw/` is gitignored.
- Tag pushes are refused (HTTP 403). Write "tag pending: <tag> on <commit>" in progress.md; the user pushes tags locally.
- A cloud session can push only its own working branch: one sub-milestone per session, one PR.
- No screen in the cloud: "the user plays" checks wait. Renders under Xvfb work (CLAUDE.md, "Touch notes"). Plans live in `docs/plans/`, not `~/.claude/plans/`.
- Books 1–5 text is not in the cloud.
- A fresh `--import` takes about 100 s. `setup.sh` reverts `.import` files the import rewrites.
- On Windows `python3` is the Store alias (fails); use `python` locally. Linux uses `python3`.

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
- Book 3 "E" chapters are Laken, not Erin. Laken's days: game day = his journal day + 45 in every book (ADR 0028).
  Geneva, Niers (3.22L) and Venitra use placeholder days.
- Save is v23 (see `core/game_state.gd`). `MapDb` holds maps in `areas`; use `objects_on(area)` or `objects_near`, not `areas[a]['objects']`, so flag-hidden objects stay hidden. Enemy `danger` must be 0.0–1.0.
- Same-day canon order: Book 6+ chapter files carry `"order"`; events then run in chapter order and file order
  (M18.0). Books 1 – 5 still run in id order. Use `depends_on` only for a real dependency (a cancel spreads).
  Siblings that share one dependency run in that order too, so a sibling can clear a flag another still `requires` (M10.1: the rescue cleared `mrsha.fell_into_the_dungeon` before Toren's event). Debug with a throwaway `extends SceneTree` script that prints `gs.world.history` reasons. Helper-only waves come at once when no foe is left; put helper waves before the last foe wave.

- Octavia matters to Book 3: killing her before day 87 cancels 3.25's goodbye and the wagon leaving, which cascades. Kill tests for her must run after day 87.
- Scene stages: `Stage.place_npc` skips an NPC who is already in the stage area, so that NPC stays at their own post (M10.3: Lyonette, Mrsha in the inn). Only NPCs brought in from elsewhere take the stage tile. Hooks that need an NPC next to the player must name NPCs that really are placed.
- Scene `when_flags` are read during the day, before the night's events run: use a flag that is set by an earlier night.
- Python patching: converting line ends twice (LF to CRLF on a string that already has CRLF) leaves a stray CR, and git then shows the file as `-text` and changed in full. Check `git ls-files --eol` after patching.
- Never write a bash `cat > "$UNSET_VAR/..."` line without a heredoc: it waits on stdin and hangs the shell.

- Director dependencies are hard: an event whose `depends_on` was cancelled is cancelled too. Chain events only to events that always happen, or one dead NPC cancels a whole day (M10.4 cut the chains this way). Siblings run in id order, so name ids to sort in story order.
- Effects and scene flags: a flag set by an event on day N is visible on day N+1. An event set and cleared in the same night never shows in a schedule (`erin.at_esthelm`).
- Fight-stage tests: a helper that walks to `Pathfind.around(at)` can stop on a diagonal square and never attack. Walk to the four side squares instead (`sim_book4_christmas._fight_turn`). Strong allies that arrive at once can kill weak foes before the player strikes; delay the ally wave.
- A throwaway `extends SceneTree` script that errors before `quit()` hangs Godot headless forever. Use `_initialize()`, and run with `timeout 300`.

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

## Screenshot recipe (M16.1)
- Scratch scene `game/_scratch/shot.tscn` + `shot.gd` (`extends Node`, `_ready` calls a deferred coroutine). For each map id in `db.maps.areas`:
  a `SubViewport` sized `MapDb.size * WorldView.TILE` (`UPDATE_ALWAYS`) holds a `WorldView` from `res://world/world_view.tscn`;
  `v.setup(db.maps, {}, db.combat.enemies, {}, "winter")`; `gs = GameState.new(1)`; `gs.flags["winter"] = true` for winter;
  `gs.player.place(id, Vector2i(0,0))`; `v.refresh(gs, db)`; hide `v.player` and `v.atmosphere`; camera zoom 1; wait 4 frames;
  `get_texture().get_image().save_png`. Run with the console exe (not `--headless`): `OUT=<dir> WINTER=1 ONLY=id1,id2 Godot..._console.exe --path game res://_scratch/shot.tscn`.
- `godot --headless --import` may segfault (known) but still imports; then `git checkout -- game/assets/audio game/assets/fonts`.

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


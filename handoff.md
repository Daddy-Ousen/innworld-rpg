# Handoff

## Just done (2026-11-01, cloud): M36.2 Book 9 canon 5.45, 5.46, 5.47 G (branch `claude/m35-1-stat-sheets-pt83je`, restarted from main after PR #261)
- Two Sonnet reading agents (summaries only, not in git). User picks: no fight stage; two talk hooks (the parade and
  the baseball game), each on a scene stage with beats and a signpost.
- Data: `game/data/canon/book9/chapters/5.45.json` (12), `5.46.json` (7), `5.47G.json` (12); Twofeather's note in
  `book9/npcs.json`. Generator script was in the session scratchpad (gone); edit the JSON by hand from now on.
- Tests: `game/tests/sim_book9_morning_after.gd` (new, 8). Counts: `unit_scene_beats` scenes 49 and fights 26,
  `unit_foreshadow` fights 26, `sim_player_hooks` 137. List and results in `progress.md` "M36". Full suite not run.
- PR: https://github.com/Daddy-Ousen/innworld-rpg/pull/262 (draft). Next: the user merges it. Then M36.3 canon
  5.48 G, 5.49, 5.50 G, Interlude – Bird (Sonnet · high). Ask the stage and hook choices first (the plan has none
  for M36.3). Quietstab's kill (5.50 G, by Tremborag) goes there; the boycott flag clears in the 5.49 batch.
- Waits on the user: `unit_scene_beats` fails on main too. `b6.the_battle_of_invrisil_opens` has 4 ally shouts and
  `b8.three_doors_open_on_the_raskghar_camp` has 5 (rule: 1 – 3, ADR 0044 M31). Fix the data or widen the rule.
- Gotchas:
  - Two counts were stale on main since M32.2 – M32.4 (26 fights, 135 hooks). Each new stage or hook moves them.
  - Hooks with no NPC near the player do not fire: put the hook on a scene stage that places the NPCs.
  - The Celum door went to the meadow in 5.45 (flag `albez_door.celum_side_in_the_meadow`), but the map link in
    `inn_interior` still goes to the Stitchworks. If a later batch needs the meadow link, add a link with
    `when_flags` (data only). The Celum stone is taken by Zevara (Krshia interlude) and the doors die in 5.57.
  - Gilam's level is null; one agent read Pellmia saying "Level 20" in 5.47 G. Not checked line by line.
  - Jelaqua (beheaded in 5.58), Moore and Seborn: still to check in M36.7 (see the M36.1 notes below).
  - `sim_book9_morning_after.gd.uid` is not made yet (no `--import` run); it comes with the next import.
- Active files: `game/data/canon/book9/chapters/`, `game/tests/sim_book9_morning_after.gd`, `docs/plans/m36.md`.

## Just done (2026-11-01, cloud): M36.1 Book 9 world and records (branch `claude/m35-1-stat-sheets-pt83je`, restarted from main after PR #260)
- Two Sonnet reading agents (summaries only, in the session scratchpad, not in git). User picks: `draug` with its own
  sprite; two thief enemies; 17 NPC records; keep `greybeard` as Greydath's one id.
- Data: `game/data/canon/book9/{npcs,locations}.json` (17 + 3), `book9/chapters/.gitkeep`; enemies `draug`,
  `brothers_thug`, `chell_sister` in `enemies.json` + `audio.json`; look `draug` in `appearance.json` and
  `game/assets/characters/draug.png` (+ `.import`). Notes on `goblin_lord`, `garen`, `osthia_blackwing`, `calruz`,
  `greybeard`. Test `game/tests/sim_book9_world.gd` (new); enemy count 58 → 61 in `unit_monster_art` and `unit_combat_db`.
- Tests: 8 scripts, 79 tests, all pass (list in `progress.md` "M36"). Validator 0 errors. Full suite not run.
- Next: the user merges the PR. Then M36.2 canon 5.45, 5.46, 5.47 G (Sonnet · high). Ask the stage and hook choices
  first (the plan has none for M36.2). Twofeather's kill (5.47 G, by `gilam`) goes there.
- Gotchas:
  - A book folder with no chapter files needs `chapters/.gitkeep`, or `CanonDb` logs "Couldn't open directory" and
    every GUT test that loads data fails with "Unexpected Errors".
  - A new enemy changes two counts: `unit_monster_art` and `unit_combat_db` (both now 61).
  - Sprite build in the cloud works: sparse clone of the LPC generator at the commit in `CREDITS.md`, then
    `git sparse-checkout add /spritesheets/<folders>/`. `build_sprites.py` builds every look, so other looks fail
    for missing art; use `--only <id> --out <scratch> --credits <scratch file>` and copy the png. Then run
    `godot --headless --path game --import` for the `.import` file.
  - Lord Erill's id is `erill_fienst`. Ieka is `ieka_imarris`, Gralton is `gralton_radivaek`. Gilam's level is null.
  - Watch cells: place `liscor_watch_cells` exists, but the `liscor_watch_barracks` map has no cells. M36.4 needs a
    spot for Erin and the four Hobs (Headscratcher, Badarrow, Rabbiteater, Shorthilt): ask the user.
  - Jelaqua is beheaded by Garen in 5.58, and Moore and Seborn are left dying. They seem to live (Jelaqua is a Selphid),
    but this is not checked against the text yet. No kills now; M36.7 checks it with a reading agent.
  - 17 old `.uid` files in `game/tests/` stay untracked on purpose.
- Active files: `game/data/canon/book9/`, `game/tests/sim_book9_world.gd`, `docs/plans/m36.md`.

## Just done (2026-11-01, cloud): M36.P Book 9 plan (branch `claude/m35-1-stat-sheets-pt83je`, restarted from main after PR #259)
- Eight Sonnet reading agents read all of `canon/raw/book9` (summaries only, in the session scratchpad, not in git).
  One more agent checked the 5.62 deaths line by line.
- Wrote `docs/plans/m36.md` (day map, deaths, 14 conflicts, steps M36.1 – M36.10, 4 open choices) and
  `docs/adr/0047-m36-book9.md`. ROADMAP, `docs/CLOUD.md` queue note and `progress.md` "M36" updated. Docs only, no tests run.
- User answers (in the plan "Answers" and ADR 0047): stages = east gate battle (5.62) + door thieves (5.54); hooks = jail
  visit, Gnoll gathering, cooking contest; day rule = march Day + 163; Erin and the Hobs in the Watch cells on the map.
- PR: https://github.com/Daddy-Ousen/innworld-rpg/pull/260 (draft). Next: the user merges it. Then M36.1 world and
  records (Sonnet · high).
- Gotchas:
  - Book 9's "Day N" is Tyrion's march count, NOT Laken's (+45 rule of ADR 0028 does not apply). Proposed: game day = Day + 163.
  - Numbtongue looks dead in 5.62 but lives in Book 10 (6.02 on): no kill. Purple Smile: never confirmed dead: no kill.
    Osthia Blackwing: [False Death], alive. Calruz: still in his cell, no verdict.
  - Reiss = the existing record `goblin_lord` (Book 6). Greydath vs Book 4 `greybeard`: not merged; M36.1 checks the text.
    Lord Erill is not `erille` (Princess Erille).
  - NPC records live in `data/canon/book*/npcs.json` as a dict under `npcs` (keys are the ids).
  - 5.51 G (Day 9) comes after its Liscor twin 5.53 (Day 8): order events by day, not by chapter.
  - 17 old `.uid` files in `game/tests/` stay untracked on purpose (the stop hook nags about them).
- Active files: `docs/plans/m36.md`, `docs/adr/0047-m36-book9.md`.

## Just done (2026-11-01, cloud): M35.3 Magnolia's whereabouts (branch `claude/m35-1-stat-sheets-pt83je`, restarted from main after PR #258)
- Two Sonnet reading agents (Books 5 - 6, 7 - 8; summaries only). User picks: camp days off map at Invrisil, battle on
  `invrisil_battlefield` [3, 10], then `invrisil_gate` [14, 3] by day until 5.02; Ressa mirrors her.
- Data: 4 goals each for `magnolia_reinhart` and `ressa` in `game/data/npc_behaviour.json`. Tests: `game/tests/unit_m25_whereabouts.gd` (+4).
  ADR 0046 "M35.3 note", plan "Answers", ROADMAP play check, `progress.md`. M35 is now built.
- Next: the user merges the PR. Then M36.P (Book 9 plan, Opus · high), `docs/CLOUD.md` "Task queue" item 2.
- Gotchas: `b6.magnolias_levy_waits_at_invrisil` is alt-only (runs only if Zel's speech fails), so the canon path uses
  `magnolia.recorded_the_speech` for the camp stay. `GameState.new` + `Director.run` skips events that need an NPC alive:
  use `GameState.new_game` + `ToyCanon.sleep_through` (about 25 s to day 135). `unit_npc_sim` `test_talk_to_an_npc` fails on
  main (an NPC dictionary has an extra key; old, not M35). 17 old `.uid` files in `game/tests/` stay untracked on purpose.

## Just done (2026-11-01, cloud): M35.2 Runners' Guild staff (branch `claude/m35-1-stat-sheets-pt83je`, restarted from main after PR #257)
- Two Sonnet reading agents (Books 2 - 4, 5 - 8). Result: none found. User pick: add nothing. Docs only (ADR 0046, plan, ROADMAP, progress). No tests run.
- Next: the user merges the PR. Then M35.3 Magnolia's whereabouts (Opus · high).
- Gotchas: Thasius Griff (4.35E, Book 6) is the only Invrisil City Runner named; add him later only if the user asks. Miss Bellia is Celum, not Invrisil.
  17 old `.uid` files in `game/tests/` stay untracked on purpose.

## Just done (2026-11-01, cloud): M35.1 stat sheets (branch `claude/m35-1-stat-sheets-pt83je`)
- Two Sonnet reading agents (Books 1 - 4, 5 - 8; summaries only). Result: no level is stated for any of the eight NPCs.
  User pick: add Reynold's past [Lieutenant] (level null) only. One data edit in `book2/npcs.json`; ADR 0046 note; plan answers.
- Tests: 6 scripts (41 pass) + validator books 2, 4. Full suite not run. Details in `progress.md` "M35".
- Next: the user merges the PR. Then M35.2 (Runners' Guild staff, Sonnet · high), then M35.3.
- Gotchas: the private text repo must be added first (`add_repo` Daddy-Ousen/innworld-canon-raw, clone, then `bash tools/cloud/setup.sh --force`).
  NpcLevels counts a null level as 1, so the extra class adds a tiny hidden total. No Skills field in NPC records (schema change needs the user).
  17 old `.uid` files in `game/tests/` stay untracked on purpose.

## Just done (2026-11-01, cloud): M35.0 Ceria's fire lesson (branch `claude/bold-ritchie-459a52`)
- Three Sonnet reading agents (Books 1 - 4, 7 - 8; summaries only). User picks: [Flashfire], start Book 1 day 36.
- Data only (ADR 0046, `docs/plans/m35.md` "Answers"): quest `ceria_teaches_flashfire` in `data/quests.json`; `flashfire`
  has `learn.flags: ["quest.ceria_fire_lesson"]` in `data/spells.json`. Tests changed: `unit_quest_lines` (+2),
  `unit_spell_learning` (Flashfire waits for the flag). Tests in `progress.md` "M35". Full suite not run.
- Next: the user merges the PR. Then M36.P (Book 9 plan, Opus · high), then M35.1 stat sheets (`docs/CLOUD.md` queue).
- Gotchas: the plan said Ceria is a [Pyromancer]; the canon record says [Elementalist] / [Cryomancer] (fixed in the plan).
  Ceria has no map goal between day 40 and Celum (day 85): in Book 2 she lodges at the inn (`ceria.staying_at_inn`) but
  is off the map. Not fixed (out of M35 scope); add a goal if the user asks. The cloud needs the private text repo
  cloned (`add_repo` Daddy-Ousen/innworld-canon-raw, then `bash tools/cloud/setup.sh --force`): the SessionStart hook
  did not find it this time. The validator wants `python3 tools/validate_data.py game/data/canon --all` for
  quests.json. 17 old `.uid` files are untracked in `game/tests/`: not part of any branch, the stop hook nags about them.

## Just done (2026-11-01, local): model · effort tags in `docs/CLOUD.md` (branch `docs/cloud-model-tags`)
- Task queue items 1 – 4 each say which model and effort to pick (M35.0 Sonnet · high, M35.1 Sonnet · medium, M35.2 Sonnet · high,
  M35.3 Opus · high, M36.P / M37.P Opus · high, later steps by type). PR #254 (cloud prep) is merged. Docs only, no tests run.
- Next: the user merges this PR, then starts the cloud sessions (M35.0 and M36.P first).

## Just done (2026-11-01, local): cloud prep for M35 – M37 (branch `docs/cloud-prep-m35-m37`)
- Pushed the extracted text of Books 1 – 5 and 8 – 10 to the PRIVATE repo `Daddy-Ousen/innworld-canon-raw` (user said
  yes; commit bd0c137). Books 6 – 7 were there already. Book 9 = 5.45 – 5.62 + 4 interludes (22 chapters); Book 10 =
  6.00 – 6.16 (17 chapters). `canon/raw/book9` and `book10` are local and gitignored.
- Wrote `docs/plans/m35.md` (Ceria's magic line, stat sheets, Runners' Guild staff in Invrisil, Magnolia's whereabouts),
  `m36.md` (Book 9) and `m37.md` (Book 10). Updated `docs/CLOUD.md` (queue items 1 – 4, checklist, schedule),
  `CLAUDE.md` (cloud book text: Books 1 – 10) and ROADMAP. Docs only, no tests run.
- Next: the user merges the PR. Then, in the cloud: M35.0 and M36.P first (they may run together), then M35.1 –
  M35.3 one at a time, then M36.0 … M36.n, then M37 (`docs/CLOUD.md`, "Task queue" 1 – 4 has the prompts).
- Gotchas: "character sheets" = NPC stat sheets, not art (art exists). Book 10 chapter ids start with `6.`: M37.P must
  check `tools/validate_data.py` and `core/canon_db.gd` for chapter-id checks first (none found by search). The next
  ADR numbers are reserved: 0046 (M35), 0047 (Book 9), 0048 (Book 10). The old branch `docs/changelog-v0.2.0` is
  pushed with a changelog commit and has no PR yet.

## Just done (2026-11-01, local): release build v0.2.0-alpha (branch `release/v0.2.0`)
- Bumped `game/project.godot` and both Android presets (`version/code=9`, name `0.2.0-alpha`). `--import` twice, then
  `tools/release.ps1` (PowerShell tool, System32 first in PATH, `$env:GODOT` = console exe). Smoke tests pass for all
  three. Apk verifies (v2 + v3), versionCode 9. Files in `export/`: 3 zips, apk, aab. PR #251 (bag) is merged.
- Next: user merges the release PR. Then tag `v0.2.0-alpha` on the merge commit and `gh release create --prerelease`
  with the 3 zips + apk (Pages deploys from the release). Optional: the aab to the Play track (user drags it in).
  Then the user plays M31 - M34 and the bag on the phone.
- Gotchas: after the build `git checkout -- game/assets game/icon.png.import game/addons` (line-end noise). The
  `.gitignore` change, `.uid` files and `web/` are not part of the release.

## Update (2026-11-01): the bag branch is pushed and PR #251 is open (not merged). Next: the user merges it.
The steps below are done except the merge.

## Just done (2026-10-31, local): bag screen card look (branch `feat/bag-card-look`)
- Built and checked: `game/ui/bag.gd` + `bag.tscn` rewritten (cards, "Leave 1", Close, `_fit`), tests in
  `game/tests/unit_bag.gd` (+6). ADR 0045 "Bag screen" note, ROADMAP play check, `progress.md` entry. Committed
  locally on the branch. NOT pushed. NO PR yet.
- Next: `git push -u origin feat/bag-card-look`, `gh pr create` (body: what changed, tests run, full suite not run),
  bind the PR, ask the user to merge. Then the user checks the bag on the phone after a new release build.
- Gotchas: PowerShell splits `-gselect=unit_bag.gd` at the dot: quote it. The `godot` winget link prints nothing:
  use the `Godot_v4.7.2-stable_win64_console.exe` in `%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_*`.
  A wrapped `Label` has no height until one frame after `show()`: `Bag._fit` runs again on the next frame.
  A CardButton sets `text_overrun_behavior` to trim: set `OVERRUN_NO_TRIMMING` on a button that must show all its text.
  `.gitignore` change, `.import` line ends, `.uid` files and `web/` are not part of this branch.

## Earlier (2026-10-31, local): ROADMAP update (branch `docs/roadmap-update-4`, merged as PR #250)
- PR #249 (v0.1.9-alpha) is merged. Tag and GitHub pre-release exist. `docs/ROADMAP.md` "Next step" and `progress.md`
  Releases now say so. Docs only, no tests run.
- Next: user merges the PR. Nothing is queued to build. The user plays M31 - M33 (apk on the v0.1.9-alpha release page).
  Optional picks: bag screen in the card look; Rags alt when Laken dies; console `skip <days>`; Play aab for v0.1.9.
- Gotchas: local `.import` line-end changes, `.gitignore` and `.uid` files are not part of this branch. No `python3`
  in this shell: use Edit for doc changes.

## Earlier (2026-10-31, local): release v0.1.9-alpha (branch `release/v0.1.9`)
- Bumped `game/project.godot` and both Android presets (`version/code=8`). `--import` twice, then `tools/release.ps1`
  from the PowerShell tool (System32 first in PATH, `$env:GODOT` = the console exe). Smoke tests pass for all three.
  Apk verifies (v2 + v3), versionCode 8. Files in `export/`: 3 zips, apk, aab.
- Next: PR merged, then tag `v0.1.9-alpha` on the merge commit and `gh release create --prerelease` with the 3 zips +
  apk (Pages deploys from the release). The user installs the apk and plays M31 – M33. Optional: the aab to the Play track.
- Gotchas: `--import` rewrites many `.import` files (line ends only): do not commit them. The `.gitignore` change and
  `web/` are not part of the release.

## Just done (2026-10-26, local): M33.4 friend perks (branch `feat/m33.4-friend-perks`)
- User picks: passive perks only; a perk at friend and one at close friend. M33.3 is merged (PR #247).
- Code: `rules.standing.perks` read by `core/standing.gd` (`perk_discount`, `talk_xp_mult`, `is_friend`, `perk_news`,
  `_validate_perks`); hooks in `Economy` (through `shop_markup`), `Actions.perform` (XP x), `Night.run` (a line once).
  Data: 32 perks in `data/rules.json`. ADR 0044 "M33.4".
- Tests: new `game/tests/unit_friend_perks.gd` (11). See `progress.md` M33.4. Full suite not run.
- Next: user merges the PR. M33 is then built. Open: the play checks, and a v0.1.9 release build (M31 – M33 are in no
  apk yet, `tools/release.ps1`). Optional: Python validator check for `perks` (only the GDScript check exists).
- Gotchas: a close-friend NPC already fought beside the player (`friend_fight` 10); `fight_help` perks add the friend
  band. `Standing.regard` of a Drake in Liscor starts wary, so a Lism discount needs a few points more. Perk flags use
  an underscore for the band (`perk.lism.close_friend`).

## Just done (2026-10-26, local): M33.3 three quest lines (branch `feat/m33.3-quest-lines`)
- User pick: Pisces for the magic line. Data only (ADR 0044 "M33.3"): `data/quests.json` has `erin_gets_the_inn_going`
  (Erin, offered on day 8), `pawn_and_the_painted_soldiers` (Pawn, from day 82), `pisces_teaches_mana` (Pisces, from
  day 17). `spells.json`: `flash_step` has `learn.flags: ["quest.pisces_mana_lesson"]` (Pisces teaches it only after).
- Tests: new `game/tests/unit_quest_lines.gd` (7). See `progress.md` M33.3. Full suite not run.
- Next: user merges the PR. Then M33.4 friendship perks **[Sonnet · medium]** (one perk per main NPC at friend and
  close-friend level; ask first if a new field is needed). Play check: take a line and learn [Flash Step].
- Gotchas: steps can use only actions the player can do: `pray` has no object near Liscor, `study_spell` is logged
  only when a spell is learned, `serve_guests` comes from the inn service. Cooking, repairs, washing and talking work.
  Data files use CRLF and tabs: write them from Python with `newline=''`. The Ceria magic line is not built (add as data).

## Just done (2026-10-26, local): M33.2 quest engine (branch `feat/m33.2-quest-engine`)
- User picks: a quest starts from an auto talk row on its giver ("Ask about: <title>"); a spell reward unlocks the
  teacher (spell `learn.flags`, set by a reward flag). Plan: `docs/plans/m33.md` "M33.2 build plan". ADR 0044 "M33.2".
- Code: new `core/quests.gd` (offers, start, after_action, update, journal_lines, validate) and `core/quest_state.gd`
  (`gs.quests`, save v24 + `_migrate_23_to_24`). Hooks: `Actions.perform`, `Commands._after`, `Night.run` (step 5d),
  `Interact` (`QUEST`, NPC option `quests`), `ui/interact_menu.gd`, `ui/console_commands.gd`, `ui/journal.gd`
  ("Tasks" at the top), `Spells.teach_error` + `SpellDb` (`learn.flags`). `tools/validate_data.py` checks quests.json.
- Data: `data/quests.json` has no quests yet.
- Next: user merges the PR. Then M33.3 three quest lines **[Sonnet · high]**: ask the user to pick the lines first
  (plan: Erin's inn, Pawn, magic from Pisces or Ceria). Each line is quests.json data; a magic line can end with a
  reward flag that a spell's `learn.flags` waits on.
- Gotchas: a "go back to the giver" step is a `did` step on `talk_with_guest` with context `{"npc": giver}`. The
  "Ask about" talk record itself never counts (the quest starts after it). Quest lines go to `gs.combat.lines`
  (during the day) or the night lines. The Bash tool turns a backslash line break inside a heredoc into tabs: write
  long patch scripts to the scratchpad with the Write tool, or use Edit.

## Just done (2026-10-26, local): M33.1 Erin's food and drink (branch `feat/m33.1-erin-food`)
- Data only (ADR 0044 "M33.1"): 5 recipes, 5 actions (`make_juice`, `fry_burgers`, `warm_honey_milk`, `mix_milkshake`,
  `mix_faerie_drink`), 5 dishes, 5 ingredients; stove lists in `inn_interior` and `invrisil_crag_pig`; `rules.inn.dishes`;
  `audio.json` sounds (also `make_pastry`). Krshia's stall sells the ingredients; `from_flag` on potatoes, honey, nectar.
- Tests: `unit_m33_food` (new). `unit_cooking` recipe count is now 13. See `progress.md` M33.1.
- Next: user merges the PR. Then M33.2 quest engine **[Opus · high]** (schema ask first, save bump + migration).
- Gotchas: data files here use CRLF (some tools hide it): edit in Python with `newline=''`. A recipe has no flag gate: gate by
  the ingredient's `from_flag`. Shop `sells` order is tested in `unit_economy` (Celum stall); new goods went to Krshia only.

## Just done (2026-10-26, local): M33.0 canon spells (branch `feat/m33.0-canon-spells`)
- User picks: 8 damage spells, all 4 new kinds, friend gate (ADR 0044 "M33.0", plan `docs/plans/m33.md`).
- Code: new `core/spell_effects.gd` (hold, blink, hide, wall; state in `combat.encounter`: `held`, `hidden`,
  `walls`). Hooks: `Spells.cells/use/why_not/aim_for_dir/npc_pick`, `SpellDb` (field `effect`, shapes `self` and
  `tile`, `learn.band`), `Encounter._run_until_player` (hold skip, rounds tick), `Combat.monster_target` (hide),
  `MonsterSim._taken` and `Movement` (ice blocks), `Cover.details` (ice = full cover), `Commands._encounter_act_q`
  (a strike ends hide), `world/main_aim.gd` and `ui/skill_bar.gd` (cast "self" at once, tips).
- Data: 12 new spells in `data/spells.json`, 12 spellbooks in `data/economy.json` and on the Liscor shelf. Every
  teacher lesson has `"band": "friend"`.
- Next: user merges the PR. Then M33.1 Erin's food and drink **[Sonnet · medium]**. Play check: learn a spell from
  a friend, cast the new kinds.
- Gotchas: `unit_spells` takes about 7 minutes (each test loads all data): give it a long timeout or run it in the
  background; it is not stuck. A new `class_name` needs `godot --headless --path game --import` (it can segfault
  once: run it twice), then `git checkout -- addons assets icon.png.import`. Only monsters can be held or fooled by
  [Invisibility]; hostile NPCs still see you. Ice does not block sight.

## Just done (2026-10-26, local): ROADMAP update (branch `docs/roadmap-update-3`)
- PR #241 (M32.4) and PR #242 (Laken drift) are merged. M31 and M32 now sit in the Done table. Their play checks
  are under "Waits on the user". The Rags / Laken alt idea is under "Later". Docs only, no tests run.
- Next: user merges the PR. Then M33.0 canon spells **[Opus · medium]**: a reading agent (Sonnet) lists spells in
  Books 1 – 8 with casters; the user picks 10 – 15 and which new effect kinds (schema ask, rule 11). Plan:
  `docs/plans/m33.md`.
- Also open: no release since v0.1.8 (M31 and M32 are not in an apk yet). A v0.1.9 build lets the user play them on
  the phone (`tools/release.ps1`, and upload the apk).
- Gotcha: `.gitignore` has a local change (signing key lines) and `web/` plus stray `.uid` files are untracked. They
  are not part of this branch.

## Just done (2026-10-26, local): Laken drift ceiling (branch `fix/laken-drift-ceiling`)
- `sim_kill_book7` Laken test is green (10/10). The extra drift (37) came from Book 8 day 143: the whole Riverfarm
  and Goblin war chain cancels when Laken is dead. Real causes, so the ceiling is now 26 / 49.5 (comment in the test).
- Data fix (ADR 0036 rule 1): `b8.elia_arcsinger_breaks_the_mountain_siege` no longer `depends_on`
  `b8.tyrion_lances_redscar_and_saves_laken`; `b8.tyrion_offers_laken_his_hand` depends on it instead (5.32G).
- Next: user merges the PR. Optional design pick: an alt for Rags's Book 8 thread when Laken dies.
- Gotcha: a kill sim's drift counts all books. New book data with windows inside the sim's days (here Book 8 day 143)
  can push an old ceiling. To see which events add drift, read `gs.world.history` entries (skip non-canon ids like
  `player.kill`) and weigh them with `rules.director.drift` x `tier_weight`.

## Just done (2026-10-26, local): M32.4 Zel lives (branch `feat/m32.4-zel-lives`)
- Data only (ADR 0044 "M32.4"): the death event has `not_flags: ["zel.saved_by_the_player"]` and mutates to
  `b6.zel_spares_reiss_and_lives`. New alts: `b6.magnolia_offers_a_bounty_for_the_trap`, `b6.azkerash_rages_that_zel_lived`,
  `b6.liscor_hears_zel_lived` (4.49), `b7.zel_gives_selys_the_heartflame` (5.16S, first mutate of the bequest; needs a
  living Zel with `zel.wears_the_heartflame_breastplate`). Book 7 mourning needs `zel.dead_at_invrisil`; the funeral stage
  has `when_flags: ["zel.body_in_liscor"]`. Zel's Celum goal has `unless_flags: ["zel.survived_invrisil"]`.
- Tests: new `sim_book6_zel_lives` (8). `sim_book6_zel_stage` and `sim_kill_book7` (Magnolia ceiling) changed. See
  `progress.md` M32.4. Full suite not run.
- Next: user merges the PR. Then the user plays the three doors and Zel's last stand. Optional: the old
  `sim_kill_book7` Laken drift failure (50 > 13, also on main).
- Gotchas: a stage does not read `requires.flags`: a scene that must not show needs stage `when_flags`. JSON chapter
  files mix inline and expanded blocks (CRLF, tabs): edit by hand or by raw text, never `json.dump`. An alt event stays
  `pending` for ever (it is `alt_only`): do not assert it is resolved. Stash test: `git stash push -- game/data <files>`
  runs a sim on main data without a second checkout. Do not `taskkill` Godot: the auto-mode check blocks it, and the
  open Godot may be the user's editor.

## Just done (2026-10-26, local): M32.3 boss feel (branch `feat/m32.3-boss-feel`)
- User picks (ADR 0044 "M32.3"): three new ability kinds; fear takes AP; the Goblin Lord is a new foe.
- Code: `core/monster_abilities.gd` (kinds `fear`, `bile`, `command`; `ready`, `apply_fear`, `spit`,
  `poison_tick`, `command_over`, `command_bonus`), `core/encounter.gd` (poison tick at each turn start, fear at the
  player's turn start, the spit in `_hostile_turn`), `core/combat.gd` (command accuracy in both monster attacks),
  `core/monster_sim.gd` (a commanded foe does not flee).
- Data: Skinner fear, Crypt Lord bile (its `ranged` removed), Regrika agility 8 + "Charge" leap, new enemy
  `goblin_lord` (voice in `audio.json`), Zel's stage wave 3 and the hook enemy list (`4.48.json`).
- Next: user merges the PR. Then M32.4 **[Opus · high]** (Zel lives: the bend reads `zel.saved_by_the_player`). PR #239 (`standing.gd` fix) is merged.
- Gotchas: `-gselect=unit_combat` also runs `unit_combat_db`, `_preview`, `_screen`, `_skills`: use
  `-gselect=unit_combat.gd`. `-gtest=...` without a match runs the whole suite: do not use it. A Godot run can
  stall at exit; kill stray `Godot_v4.7.2*` and rerun. Q_PER_AP is 4 (6 AP a turn at level 0), not 8.
  `canon_ref` / stage `note` max 300 chars.

## Just done (2026-10-26, local): fix race start null home (branch `fix/race-start-null-home`)
- `Standing.race_start` crashed on `String(null)`: Zel's canon `"home"` is `null`, and `Dictionary.get(key, default)`
  returns a stored `null`, not the default. It now returns 0 when race or home is not a String. Guard test in
  `unit_race_regard`. `sim_book5_last_light` is green again (9/9). Two broken line breaks in `standing.gd` fixed.
- Next: user merges the PR. Optional follow-up in `progress.md` "Fixes": the same broken line breaks in 9 other files.
- Gotcha: the Bash tool turns `\\` into `\` in a Python heredoc. A `\` + newline then vanishes, and a line break
  becomes one long line with tabs. That is most likely how these broken lines were made. Use the Edit tool to write
  a GDScript `\` line break. Also: `--import` rewrites all `.import` files (CRLF noise): `git checkout -- game/addons game/assets game/icon.png.import`.

## Just done (2026-10-25, local): M32.2 Zel's stage (branch `feat/m32.2-zel-stage`)
- User pick: the full save rule (ADR 0044 "M32.2"). Engine: a foe driven off (escape) writes a `drive_off_foe`
  record at fight end, context = base + `enemy`, `waves_left`, and `protect_standing` when the stage has a
  `protect` NPC. Hook key `all`: every `did` entry needs its own record. Old escape fights write the record too.
- Data: map `invrisil_battlefield` (west exit to `invrisil_gate`, east exit added there at [31, 6]); 6 enemies;
  stage on `b6.the_battle_of_invrisil_opens` (hours 9 - 15); hooks `player_fought_beside_zel` and
  `player_broke_bea_and_ijvani` (on `b6.zel_breaks_the_chosen_and_azkerash_comes`; sets `zel.saved_by_the_player`).
- Next: user merges the PR. Then M32.3 **[Opus · medium]** (boss feel), then M32.4 (Zel lives) reads the flag.
- Gotchas: a fight with no foes and waves left does not tick on `Commands.wait` if you erased foes by hand (no
  turn to pass): tests call `Stage.tick` + `Combat.settle_if_over`. Godot runs are slow when an old Godot
  process is still alive: kill stray `Godot_v4.7.2*` first (a `timeout` does not kill the child). Old failure:
  `sim_book5_last_light` 2 tests (`standing.gd:100`), also on main.

## Just done (2026-10-25, local): M32.1 three doors (branch `feat/m32.1-three-doors`)
- Built (ADR 0044 "M32.1"): enemies `calruz` (enemy id = NPC id, so his sheet; an enemy `look` must name an
  enemy) and `nokha_awakened`, both with `escape` (they never die). Awakened Raskghar danger 1.0 -> 0.95, so the
  fight records name Calruz. New object kind `cage` (tools/build_objects.py, last edit) and `raskghar_cages`.
  Waves: Nokha leads the knot, then the Horns, then Calruz alone. Helpers with the Watch and Antinium doors.
  Hooks: `player_stood_with_the_horns_against_calruz`, `player_reached_the_cages`,
  `player_held_the_inn_in_the_night_raid`, `player_fought_the_daylight_raid`. Hook count 133.
- Tests: see `progress.md` M32.1. Full suite not run.
- Next: user merges the PR. Then M32.2 **[Opus · high]** (Zel's stage on `invrisil_battlefield`).
- Gotchas: `gs.combat.lines` keeps only the last lines; a test that wants an early line must check state
  instead. After a stage fight, NPC allies walk back to their schedule. JSON numbers are floats: compare
  `hook.days` with `int()`. `godot --import` segfaulted once (run it twice); after it, many `.import` files show
  as changed (LF noise): delete them and `git checkout --` them. `.gitignore`, `web/` and stray `.uid` files
  are not part of this branch.

## Just done (2026-10-25, local): M32.0 choices and reading (branch `docs/m32.0-choices`)
- User picks (ADR 0044 "M32.0"): Zel can be saved; new map `invrisil_battlefield`; Tremborag's hall stays news;
  Klbkch always dies. Win rule: drive off Bea and Ijvani before the last wave while Zel stands. A living Zel gives
  Selys the Heartflame himself (sets `heartflame.selys_inherits`, so her 12 Book 7 events still run).
- Reading (Sonnet agents, summaries only): 5.44 and 4.47 – 4.49. Key facts are in ADR 0044 "M32.0". No Drakes
  fight beside Zel (Human levy, Rose Knights, Thomast, Reynold, Ressa, two War Golems). Five Chosen (Venitra,
  Ijvani, Bea, Oom, Kerash). Nokha is a swordswoman who goes for Mrsha's cage; her fate is open (she flees).
- `docs/plans/m32.md` rewritten for the picks: M32.1 doors, M32.2 Zel's stage (he still dies), M32.3 boss feel,
  M32.4 the "Zel lives" bend. ROADMAP and `progress.md` updated. Docs only, no tests run.
- Next: user merges the PR. Then M32.1 **[Opus · high]**. Ask first (rule 11) if Calruz's yield needs a new enemy
  field (`flee_below` makes a foe run, not give up).
- Gotchas: Book 6 text is now in `canon/raw/book6/` (extracted from the epub; gitignored). The Book 6 copy check
  can run now. The Zel cascade list (who `depends_on` his death, which events assume it) is in ADR 0044 "M32.0"
  and `docs/plans/m32.md` M32.4. Most mourning events have no flag check on his death yet: M32.4 adds
  `requires.flags: ["zel.dead_at_invrisil"]` to them. Untracked `.uid` files, `web/` and the `.gitignore`
  `secrets/` line are not part of this branch.

## Just done (2026-10-25, local): sim_canon_book8 (branch `test/sim-canon-book8`)
- New `game/tests/sim_canon_book8.gd` (6 tests, all pass): 269 events done days 143 - 163 with drift 0; the 4 named dead;
  3 stages each with `xp_window`; moon / boycott / Calruz flags; chapter order. Test only, no data change. Full suite not run.
- Next: user merges the PR. Then M32.0 **[Opus · high]**: ask the user the choices first (Zel, his stage, Tremborag's hall, Klbkch).
- Gotchas: `mrsha.taken_by_the_raskghar` and `ceria.taken_by_the_raskghar` are cleared in 5.44 (freed). Dead check: `gs.world.is_alive(_db.canon, id)`.

## Just done (2026-10-25, local): ROADMAP update (branch `docs/roadmap-update-2`)
- PR #232 (M31.3) and #233 (Greydath fix) are merged. ROADMAP "At a glance" says M31.0 – M31.3 merged; next step
  is `sim_canon_book8`, then M32.0. Checked: `sim_canon_book6` 13/13 pass on main. Docs only.
- Next: user merges the PR. Then `sim_canon_book8` **[Sonnet · medium]**, then M32.0 **[Opus · high]** (ask the user
  the choices first: can Zel be saved, his stage, Tremborag's hall, Klbkch).
- Gotchas: local branch `data/m31.3-beats-books-5-8` was behind main; branch from `origin/main`.

## Just done (2026-10-24, local): Greydath one id (branch `fix/greydath-one-id`)
- `sim_canon_book6` `test_greydath_is_a_flag_not_a_merge` failed at line 185 (`npcs.has("greydath")`), not at
  the flag check. The flag was set on day 126 all along. Cause: M28.1 added a `greydath` NPC record in
  `game/data/canon/book8/npcs.json`, a second id for Greybeard.
- Fix: record removed; `b8.greydath_duels_garen` and `b8.greydath_throws_a_sword_at_the_kingslayer` (5.37 G) now
  prefer and require `greybeard`. Event ids and `greydath.*` flags kept. Guard added in `sim_book8_world`.
- Tests in `progress.md` ("Fixes"). Full suite not run.
- Next: user merges the PR. Then the M31 play check and M32, as in the M31.3 note below.
- Gotchas: a fresh worktree needs `godot --headless --path game --import` first, or every test shows
  "Could not find type DataDb". The import rewrites many `.import` files (line ends only): do not commit them.
  `canon_ref.note` is max 300 chars (validator).

## Just done (2026-10-24, local): M31.3 beats for Books 5 – 8 and the fights (branch `data/m31.3-beats-books-5-8`)
- `"beats"` on all 30 Books 5 – 8 scenes (5 – 6 each) and all 25 fight stages (2 – 3 ally shouts). M31 data is
  complete. Three reading agents (Sonnet) gave paraphrased summaries; book 6 was written from the canon JSON.
- `game/tests/unit_scene_beats.gd` covers all scenes (47) and fights (25).
- ADR 0044 "M31.3", ROADMAP, `docs/plans/m31.md`. Tests in `progress.md`. Full suite not run.
- Next: user merges the PR, then plays a signposted day and a scene (M31 "Done when"). Then M32
  (`docs/plans/m32.md`). Separate: the old `sim_canon_book6` failure (see `progress.md`).
- Gotchas: the copy check (7-word runs) can hit plain lines like "hold the line"; reword and rerun.
  Do not run `godot --import`: it rewrites every `.import` file's line endings (content unchanged).
  A beat speaker who arrives in a wave must get a beat time at or after that wave.

## Just done (2026-10-24, local): M31.2 beats for Books 1 – 4 (branch `data/m31.2-beats-books-1-4`)
- `"beats"` added to the stage of all 17 Books 1 – 4 scenes (16 chapter files; 3.25 and 3.27M hold two each).
  5 – 6 beats each, every 40 – 70 s, from 0 to about 290 s. Own words; no lyrics.
- New test `game/tests/unit_scene_beats.gd` (real data). Its `BOOKS` list and the count 17 grow in M31.3.
- ADR 0044 "M31.2", ROADMAP, `docs/plans/m31.md`. Tests in `progress.md`. Full suite not run.
- Next: user merges the PR. Then M31.3 **[Sonnet · high]**: beats for the Books 5 – 8 scenes (30 scenes) and
  1 – 3 ally shouts per fight stage. Same method: a reading agent (Sonnet) summarises the chapters with the
  allowed speakers per scene; write beats; extend `unit_scene_beats` to b5 – b8 and fights.
- Gotchas: a heredoc with many apostrophes broke Git Bash; write such scripts with the Write tool. Mute NPCs
  (Toren, Mrsha) get no-speaker beats. Book 6 has no raw text here, so its copy check is skipped.

## Just done (2026-10-24, local): M31.1 signposts (branch `data/m31.1-signposts`)
- One `"foreshadow"` line inserted before `"stage"` in 35 canon events (books 1 – 8): 25 fights, 10 key scenes.
  No `where` / `hours` given: they come from the stage. Own words; no outcome.
- `tools/validate_data.py`: `_hour_set`; `check_foreshadow` now takes the stage and checks given hours fit it.
  Test `test_foreshadow_hours_fit_the_stage`.
- `game/tests/unit_foreshadow.gd`: real-data tests (every fight stage and each `KEY_SCENES` id has a foreshadow;
  the burning's signpost starts after the Regrika fight).
- ADR 0044 "M31.1", ROADMAP, `docs/plans/m31.md`. Tests in `progress.md`. Full suite not run.
- Next: user merges the PR. Then M31.2 **[Sonnet · high]**: 3 – 6 beats per Books 1 – 4 scene; a reading agent
  summarises each chapter (no book text back).
- Gotchas: book 6 has no raw text locally, so its copy check is skipped. A new signpost on a death-dependent
  scene needs `days_before` 0 (see the burning). Untracked `.uid` files and the `.gitignore` `secrets/` line are
  not part of this branch.

## Just done (2026-10-24, local): M31.0 signposts and beats engine (branch `feat/m31.0-foreshadow-beats`)
- Event field `foreshadow` {days_before, text, where?, hours?}: `core/foreshadow.gd` (`coming`, `morning_lines`,
  `hours_text`). Morning page "Talk in Town" (`SystemMessages.TOWN`), journal "Coming up" (`Journal.NOTHING_COMING`).
- Stage field `beats` [{after_seconds, line, npc?}]: `core/stage.gd` (`_beat`, `beat_line`, `last_beat`); one beat
  per command; `world/view_bubbles.gd` shows the newest beat over its speaker. `combat.stage_run["beat"]`, tolerant read.
- Checks: `core/canon_db.gd` (`_validate_foreshadow`, `_validate_beats`, `foreshadows` list), `core/combat_db.gd`
  (foreshadow map), `tools/validate_data.py` (`check_foreshadow`, `check_beats`, copy check). ADR 0044 "M31.0".
- Tests in `progress.md`. Full suite not run.
- Next: user merges the PR. Then M31.1 **[Sonnet · medium]**: a `foreshadow` on each of the 25 fight stages and the
  key scenes (list in `docs/plans/m31.md`). Own words; never the outcome.
- Gotchas: `unit_stage` takes about 10 minutes and `unit_battle` about 5 when two Godot runs share the CPU. Give a
  single-script run a 1500 s limit, or it is cut off with no summary line (looks like a crash, is not).
  `Stage.foes_left` stays -1 for a stage without a `waves` key (keeps the HUD and the battle music as before).

## Just done (2026-10-24, local): ROADMAP cleanup (branch `docs/roadmap-cleanup`)
- `docs/ROADMAP.md` 595 -> about 170 lines. Open work first (`sim_canon_book8`, M31 – M33), then "Waits on the
  user" (all play checks in one list, Google Play steps left), Later, Releases (table, v0.1.0 – v0.1.8), Done (one
  line per milestone with its ADR). Ticked steps of M27 – M30 and M34 are gone; their detail is in the ADRs, plans,
  archive and git history. Stale lines fixed: last release, Google Play permission, "ask pirateaba" to-do.
- Docs only. No tests run.
- Next: user merges the PR. Then M31.0 (ask the `foreshadow` / `beats` schema first).

## Just done (2026-10-24, local): v0.1.8 sent to the Play closed test
- Play Console (Chrome, account Thrive IT Solutions, developer 8735138160545874037, app 4974346913680933873):
  new release on Closed testing - Alpha. The user dragged in `export/InnworldRPG-v0.1.8-alpha-play.aab` (88 MB;
  the Chrome tool cannot upload over 10 MB). Name "7 (0.1.8-alpha)", en-US notes, full rollout. Saved, then
  Publishing overview -> "Submit 1 change for review" -> "Send changes for review". Release 5 (v0.1.6) was live.
- Next: Google reviews (up to 7 days). The user checks the M34.5 fixes on the phone. Then M31.0.
- Gotchas: Play release notes need the language tags on their OWN lines: type `<en-US>`, press Enter, type the
  text, press Enter, type `</en-US>`. Typing it all in one `type` action, or on one line, fails the check.

## Just done (2026-10-24, local): release v0.1.8-alpha published
- PR #225 merged (c331307). Tag `v0.1.8-alpha` pushed. GitHub release (pre-release):
  https://github.com/Daddy-Ousen/innworld-rpg/releases/tag/v0.1.8-alpha with 3 zips + apk. Pages deploy started.
- Next: the user installs the apk and checks the M34.5 fixes (fight: End turn free; shop: Buy button upright).
  Then M31.0 signposts and scene beats (ask the `foreshadow` / `beats` schema first). Optional: aab to Play.

## Just done (2026-10-24, local): release build v0.1.8-alpha (branch `release/v0.1.8`)
- Bumped `game/project.godot` and both Android presets (`version/code=7`). `--import`, then `tools/release.ps1`
  (PowerShell tool, System32 first in PATH). Smoke tests pass. Apk verifies (v2 + v3), versionCode 7.
- Next: user merges the PR. Then tag `v0.1.8-alpha` on the merge commit and `gh release create --prerelease`
  with the 3 zips + apk (same notes style as v0.1.7). Then the user checks the M34.5 fixes on the phone.
- Gotchas: a new apk can have the SAME byte size as the last one (zip padding). Check it by comparing the files
  inside both apks with Python `zipfile`; scripts are binary `.gdc`, so a text search finds nothing.

## Just done (2026-10-22, local): M34.5 phone fixes (branch `fix/m34.5-fight-column`)
- User played v0.1.7 on the phone, UPRIGHT (orientation 6 = sensor). Two bugs: the empty context button covered
  End turn in a fight; the shop's Buy button was a sliver upright.
- Fixes: `ui/touch_controls.gd` (`context.visible`, `set_bottom_room`), `world/main_panels.gd` (`_bar_room`, no
  targets in a fight), `ui/shop_panel.tscn` (Strip is an `HFlowContainer`), `ui/shop_panel.gd` (`DEAL_WIDTH`).
  ADR 0045 "M34.5". Tests in `progress.md`. Full suite not run.
- Next: user merges the PR; then a v0.1.8 build if the user wants to check on the phone. Then M31.0.
- Gotchas: ALWAYS render both 1080 x 2400 and 2400 x 1080 for phone layout: the user plays upright. The render
  script takes width and height as user args; set `root.size` and the dpi / mobile overrides.

## Just done (2026-10-22, local): release v0.1.7-alpha published
- PR #222 merged (e42ae14). Tag `v0.1.7-alpha` pushed. GitHub release (pre-release):
  https://github.com/Daddy-Ousen/innworld-rpg/releases/tag/v0.1.7-alpha with 3 zips + apk. Pages deploy started.
- Next: the user installs the apk on the phone and plays M34 (sizes, card, shop, context button, tap walk). Then
  M31.0 signposts and scene beats (ask the `foreshadow` / `beats` schema first). Optional: aab to the Play track.
- Gotchas: the apk (84.5 MiB) is too big for SendUserFile to the phone app (30 MiB): use the release page.

## Just done (2026-10-22, local): release build v0.1.7-alpha (branch `release/v0.1.7`)
- Bumped `game/project.godot` and both Android presets (`version/code=6`). Ran `--import`, then `tools/release.ps1`
  from the PowerShell tool with `C:\Windows\System32` first in PATH. Smoke tests pass for all three. The apk verifies
  (apksigner v2 + v3, versionCode 6). SendUserFile cannot reach the phone with it (84.5 MiB, limit 30 MiB): the phone
  gets the apk from the GitHub release.
- Next: user merges the PR. Then tag `v0.1.7-alpha` on the merge commit and `gh release create` with the 3 zips + apk
  (Pages deploys from the release). The aab (`export/InnworldRPG-v0.1.7-alpha-play.aab`) goes to the Play closed track
  only if the user wants (the user drags it in; the Chrome tool cannot upload 88 MB).
- Then the user plays M34 on the phone; then M31.0.
- Gotchas: `--import` and the export rewrite many `.import` files: `git checkout -- game/assets game/icon.png.import`.

## Just done (2026-10-21, local): M34.4 phone render check (branch `feat/m34.4-phone-sizes`)
- Rendered at 2400 × 1080, 250 %, touch on, no stretch (the Android build). Found 64 px touch buttons and tiles
  (about 25 dp) and 30 dp card buttons. User pick: buttons and map by dpi on a phone; desktop stays.
- Code: `game/ui/ui_scale.gd` (`px_per_dp`, `touch_grow`, `map_grow`, `touch_ui_px`, `dpi_override`,
  `mobile_override`; `camera_zoom` uses `map_grow`), `game/world/main_panels.gd` (`set_factor(f / touch_grow)`),
  `game/ui/interact_menu.gd` (`row_h()`), `game/ui/shop_panel.gd` (`_size_buttons`). ADR 0045 "M34.4 as built",
  ADR 0033 "Later change". Tests in `progress.md`. Full suite not run.
- M34 is all built. Next: user merges the PR, then a new release build so the user can play M34 on the phone. Then
  M31.0 signposts and scene beats (ask the `foreshadow` / `beats` schema first). Later: the bag screen (old list).
- Gotchas: a 1200 × 540 render at 250 % is NOT the phone; the Android build has no stretch, so render at
  2400 × 1080 with `root.size` set and `UiScale.dpi_override = 405`, `UiScale.mobile_override = 1`. A real phone's
  dpi may differ from 405. Mobile override also turns on the see-through boxes (`MOBILE_ALPHA`).

## Just done (2026-10-21, local): M34.3 tap the world (branch `feat/m34.3-tap-world`)
- New `game/world/main_tap.gd` (`MainTap`: `tap`, `next`, `cancel`, `walking`, static `target_at`). Wiring:
  `world/main.gd` (`tapper`, `tap_world`, `cancel`, `_walking`, `_process` steps the walk), `world/main_input.gd`
  (`world_tap`, `_tap_from`), `world/main_panels.gd` (Cancel shows during the walk), `ui/touch_controls.gd`
  (`stick_walked`), `ui/touch_settings.gd` (`controls`, `TAP`, `STICK`), `ui/session.gd` (`set_touch_controls`,
  `tap_walk_on`), `ui/options_menu.gd` / `.tscn` (Controls row). Detail in ADR 0045 "M34.3 as built".
- Tests: new `unit_tap_walk` (10); list in `progress.md`. Full suite not run. No render (behaviour only).
- Next: user merges the PR. Then M34.4 phone render check **[Sonnet · medium]**: renders at 2400 × 1080 / 250 % of
  the card, shop, context button and chips, Options; then the user plays on the phone (needs a new release build).
- Gotchas: Godot sends the emulated mouse event BEFORE its screen-touch event, so `stick_walked` is reset in
  `stick_down` (touch down) and read at the mouse release. `world_tap` ignores real mouse clicks (desktop) on purpose.
  Tests set `Session.touch.set_controls` without saving; the Options test points `touch_settings_path` at a temp file.

## Just done (2026-10-21, local): M34.2 context button (branch `feat/m34.2-context-button`)
- `game/ui/touch_controls.gd`: `context` button (in `buttons[&"use"]`), `chips`, `menu_button`, `set_targets`,
  `targets`, `chip_ids`, `press_chip`, `set_top_room`, signal `context_pressed(id)`; `_place_right` became
  `_place_bottom_right` + `_place_top_right`. `game/ui/interact_menu.gd`: `targets`, `verb_of`, GROUPS order (trade
  before work). `game/ui/hud.gd`: `top_bottom`. `game/world/main_panels.gd`: `refresh_context` (cached by a key),
  `open_target`. `game/world/main.gd`: one connect. Detail in ADR 0045 "M34.2 as built".
- Tests: new `unit_context_button` (9); list in `progress.md`. Full suite not run.
- Next: user merges the PR and tries it on the phone. Then M34.3 tap the world **[Opus · medium]**: outside a fight
  a tap on a target walks next to it (normal move commands) and opens its card; Options "Controls: Tap + stick /
  Stick only" in `ui/touch_settings.gd`. Files: `world/main_input.gd`, `world/main_aim.gd`. New test `unit_tap_walk`.
- Gotchas: a Git Bash heredoc with tabs and quotes broke again: put Python patch scripts in the scratchpad with the
  Write tool. The HUD status line "Coins 0c" touches "H: help" in a long place name at 250 % (old, not from this
  work). Render with touch on: set `session.touch_settings_path` to the out dir first, then `set_touch_mode("on")`.

## Just done (2026-10-21, local): M34.1 shop screen (branch `feat/m34.1-shop-screen`)
- New `game/ui/shop_panel.gd` / `.tscn` (`ShopPanel`), node `MenuLayer/ShopPanel` in `world/main.tscn`.
  `InteractMenu.action_rows` gives one `InteractMenu.SHOP` row ("menu:shop") per shop; picking it emits
  `shop_opened(option)`. Wiring in `world/main.gd` (`shop` var, 3 connects) and `world/main_panels.gd`
  (`open_shop`, `use_from_shop`, `shop_back`, `_option`; `panel_open` and the console close the shop).
  `InteractMenu.open_on(options, db, id)` opens a given target's card. Detail in ADR 0045 "M34.1 as built".
- Test API: `open`, `rows`, `cards`, `pick`, `step_count`, `set_max`, `deal`, `sell_all`, `show_tab`, `back`,
  `deal_text`, `deal_enabled`, `sub_text`, `tab`, `good`, `count`. Test list in `progress.md`. Full suite not run.
- Next: user merges the PR and tries it on the phone. Then M34.2 context button **[Opus · medium]**: replaces Use
  ("Talk · Erin"), chips for 2+ targets, Menu to the top right (`ui/touch_controls.gd`).
- Gotchas: a `extends SceneTree` render script must not name UI classes (`InteractMenu`, `ShopPanel`) in types or
  constants: they use the `Session` autoload and fail to compile before autoloads load. Use untyped vars and string
  ids. At 250 % the UI is only about 216 px high on a 1200 × 540 render: every extra row in a panel costs a card
  row. The test that loads `world/main.tscn` prints the old "ObjectDB leaked / resources still in use" lines.

## Just done (2026-10-21, local): M34.0 action card (branch `feat/m34.0-action-card`)
- `game/ui/interact_menu.gd` / `.tscn` rewritten in place (class `InteractMenu` kept, so `world/main.gd` and
  `world/main_panels.gd` did not change). Pages `TARGETS` / `ACTIONS` / `CONFIRM`; static `action_rows(o, db, gs)`;
  inner classes `CardButton` (drag-safe) and `HoldButton` (Attack on touch). Test API: `rows()`, `buttons()`,
  `pick(i)`, `confirm(yes)`, `back()`, `title_text()`, `touch_override`. Detail in ADR 0045 "M34.0 as built".
- Tests moved from the old `%Items` list: `unit_world_view`, `unit_brawl`, `unit_economy`, `unit_spell_ui`,
  `unit_portrait`. New `unit_action_card` (11). List in `progress.md`. Full suite not run.
- Next: user merges the PR and tries it on the phone. Then M34.1 shop screen **[Opus · medium]**: a "Shop" button on
  the card opens a Buy / Sell panel with a count strip; picks stay `Interact.trade_action(prefix, good, count)`.
- Gotchas: at inn_interior (20, 2) the stove is ONE target (the rolling pin is its `item`), and Erin is near on day 1.
  Render recipe that worked locally: a `game/_scratch/shot.gd` SceneTree script, console exe with
  `--path game --resolution 1200x540 --audio-driver Dummy -s res://_scratch/shot.gd -- <out>`; force 250 % with
  `session.ui_scale.mode = "2.5"` then `session.apply_ui_scale()` (setting `content_scale_factor` alone is undone);
  call `main.view.refresh(gs, db)` after moving the player by hand. On touch the Attack button needs a hold, so
  `pick()` on it does nothing (by design). `--import` touches `game/icon.png.import`: check it out after.

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
- Save is v24 (see `core/game_state.gd`). `MapDb` holds maps in `areas`; use `objects_on(area)` or `objects_near`, not `areas[a]['objects']`, so flag-hidden objects stay hidden. Enemy `danger` must be 0.0–1.0.
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


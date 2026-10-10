# Handoff

## Just done (2026-10-10, local): M22.3 consolidation (branch `feat/m22.3-consolidation`)
- Cherry-picked 565bc9b onto main (code + tests + DESIGN). Fixed the `rules.json` conflict by hand (kept
  `levels.breakthrough`, added `offers.consolidation_min_level: 10`). Old state-file edits from 565bc9b dropped.
- `unit_class_tree_step3` now calls `make_offers(gs, db, budget)` (no `kind`). New test in `unit_class_tree_step2`:
  consolidation waits for the source class's level 10 breakthrough; keys do not carry over.
- ADR 0035 "Steps" has the M22.3 build note. ROADMAP ticked.
- Tests run (all pass): `unit_class_system`, `unit_class_tree_step2`, `unit_class_tree_step3`, `unit_night`,
  `unit_system_messages`, `unit_journal`, `unit_game_state`, `unit_data_db`, `unit_breakthrough`, `sim_decline`;
  Python 107 OK; validator 0 errors. Full suite not run.
- Next: M22.4 probe sim **[Sonnet · high]**. After the PR merges, `git branch -D feat/class-tree-wiki` (user OK first).
- Gotchas: a source class that gets its canon key in night step 5b reaches level 10 there, so it consolidates on
  the NEXT night (step 4 runs before 5b). The Python test run prints validator ERROR lines from its fixtures: read
  only the `Ran` / `OK` lines.

## Just done (2026-10-10, local): M22.2 breakthrough data (branch `feat/m22.2-breakthrough-data`)
- `game/data/classes.json`: `breakthrough` {hint, trials} on innkeeper, cook, warrior, runner, mage, scout, priest, carpenter.
- Six `boon` hooks (tags effect) in `1.21`, `1.29`, `1.60`, `2.26`, `2.31`, `3.20T`. `sim_player_hooks` count is 74 now.
- Tests run (all pass): `unit_breakthrough` (17), `unit_data_db`, `unit_canon_db`, `unit_director`, `unit_player_hooks`,
  `sim_player_hooks`, `sim_canon_book1..3`; Python 107 OK; validator 0 errors. Full suite not run.
- Next: M22.3 consolidation **[Opus · medium]** (start from `git show 565bc9b`), then M22.4 probe sim **[Sonnet · high]**
  (tunes the bar numbers; they are guesses).
- Gotchas: all these data files are CRLF in the working copy: patch on bytes (scratchpad script), not `sed -i`.

## Just done (2026-10-10, local): M22.1 breakthrough engine (branch `feat/m22.1-breakthrough-engine`)
- New `game/core/breakthrough.gd` (sources 1 – 3, hint, key line, `validate`). `Night.resolve_xp` checks a waiting
  class before `level_up`; new `Night.level_lines` and `Night.resolve_canon_keys` (step 5b). `Director._fire` runs
  `boon` hooks (outcome stays, history `"boons"`, no `"by"`); `_player_hook` skips them. `_record_matches` is now
  public `Director.record_matches` (trials use it). `_apply_effects` takes `db` now.
- `rules.json` `levels.breakthrough` added (ADR numbers). No class has a `breakthrough` block yet; no canon hook
  uses `boon` yet. That is M22.2.
- Tests run (all pass): `unit_breakthrough` (new, 16), `unit_levels`, `unit_class_system`, `unit_night`,
  `unit_director`, `unit_canon_db`, `unit_player_hooks`, `unit_data_db`, `sim_canon_book1`; Python 107 OK;
  validator 0 errors. Full suite not run.
- Next: M22.2 data **[Sonnet · medium]**: trials + hints in `game/data/classes.json` for inn, cook, warrior, runner,
  mage, scout, priest, crafter; a few `boon` hooks (Books 1 – 3). Run `unit_breakthrough` (real-data test),
  `unit_data_db`, the validator, Python tests and `sim_canon_book1..3`.
- Gotchas: the Python validator only checks the `breakthrough` shape; class and tag ids are checked by
  `Breakthrough.validate` (in `DataDb.load_dir`). Toy capstone is 3, so toy classes wait at level 2.
  A heredoc `\` + newline lost the backslash in a Python patch: use the Edit tool for GDScript line breaks.

## Just done (2026-10-09, local): M22.0 breakthrough design (branch `docs/m22.0-breakthrough-design`)
- ADR `docs/adr/0035-breakthroughs.md`. User picks: all three sources (hard moment, class trial, canon `boon` hook),
  a moment counts only at level 9 / 19 / 29 (key kept until XP fills), a vague hint line. Docs only, no tests run.
- Schema changes the user approved (build them in M22.1): `rules.json` `levels.breakthrough`; optional `classes.json`
  `breakthrough` {hint, default, trials}; hook `"then": "boon"` (event runs as canon, no drift, hook effects apply);
  hook effect `breakthrough` {tags | class}. No save change.
- Next: M22.1 engine **[Opus · medium]**. Files: new `core/breakthrough.gd`, `core/night.gd` (step 2 check, step 5b
  level again), `core/director.gd` + `core/canon_db.gd` (boon), `core/data_db.gd` + `tools/validate_data.py` (checks).
- Gotchas: the director runs AFTER `resolve_xp`, so a canon key needs the step-5b `level_up`. A `change` hook adds
  0.25 drift; that is why `boon` is a new hook result. Records already store `risk`, `duress`, `window`.

## Just done (2026-10-09, local): M21.4 NPC art (branch `feat/m21.4-npc-art`)
- 35 new looks at the end of `game/data/appearance.json` (all Book 6 – 7 NPCs with a schedule that had none) and their sheets in `game/assets/characters/`. Portraits are cut from the sheets. `unit_art` and `unit_portrait` pass. Most looks are guesses (noted per look). The LPC clone was in the scratchpad (gone later). CREDITS.md was rewritten by the builder.
- Next: M21.6 play pass (user), then M22.0 (user picks how a breakthrough is earned).

## Just done (2026-10-09, local): M21.4 full suite (branch `fix/m21.4-red-tests`)
- Full run: 166 scripts, 6 red. Fixed 4: `sim_player_hooks` (68), `unit_cover` (bones half cover; estate plaque not solid), `unit_sign_art` (plaque sign), `unit_portal` (links form). Still red: `unit_art`, `unit_portrait` (35 NPCs have no sheet, 10 or so no portrait; list in the test output). User chose to make the art (option 2).
- Next: build the missing character sheets and portraits (needs the LPC clone, about 240 MB: ask the user first).

## Just done (2026-10-09, local): M21.5 (branch `docs/m21.5-legal`)
- Read https://wanderinginn.com/fanworks-permissions/ . Result in `docs/DESIGN.md` §7 and `docs/ITCH.md` ("Policy check"). Docs only.
- Open for the user: the policy bans book titles in marketing material; ask pirateaba or reword the itch.io and README text.

## Just done (2026-10-09, local): M21.3 (branch `chore/m21.3-export-cleanup`)
- Deleted local v0.1.0 – v0.1.2 builds in `export/` (still on GitHub releases). v0.1.3 files, `android/` and `itch/` kept. Docs only.
- Next: M21.4 (full suite; user asks), M21.5 (legal), M21.6 (play pass).

## Just done (2026-10-09, local): M21.2 (branch `chore/m21.2-docs`)
- README counts fixed (1,089 events, 296 NPCs, 122 places, 50 maps, 166 GUT scripts, 105 Python tests). Old detail from `progress.md` and `handoff.md` moved to `docs/PROGRESS_ARCHIVE.md`. Gotchas were not deduped.
- Next: M21.3 (delete old builds in `export/`; user confirms), M21.4 (full suite; user asks), M21.5 (legal, user).

## Just done (2026-10-09, local): M21.1 (branch `chore/m21.1-consolidation-decision`)
- Decision: 565bc9b is not merged now. Redo it in M22.3. Branch `feat/class-tree-wiki` stays as the source. Docs only.
- Next: M21.2 (docs cleanup).

## Just done (2026-10-09, local): M21.0 (branch `chore/m21.0-housekeeping`)
- Committed the stray `.uid`; deleted 39 merged local branches. Only `main` and `feat/class-tree-wiki` (unmerged, M21.1) remain. No tests needed (no code).
- Next: M21.1 (user decides on 565bc9b), then M21.2 docs. M22.0 needs a user design pick.

## Just done (2026-10-08, local): full project audit (read-only, branch `feat/magnolia-npcs`, PR 137 already merged)
- Findings are in `progress.md` "Audit". No code or data changed. Memory `targeted-tests` updated to match CLAUDE.md.
- Biggest bug: capstone level 10 is unreachable in play (no breakthrough source except the debug console). Check: `grep -rn grant_breakthrough game --include=*.gd`.
- Biggest vision gap: Books 2–7 events only `cancel` on failure; few hooks. The director cannot patch the story after Book 1.
- 2026-10-09: on `main`, pulled (at 1a94073). Findings are now modules M21 – M26 in `docs/ROADMAP.md` "Audit work".
  These ROADMAP / progress / handoff edits are NOT committed yet: commit them on a branch (`docs/audit-modules`) with M21.0.
- Next: start M21.0 (stray .uid, merged branches), then M22.0 (user picks how a breakthrough is earned).
- 2026-10-09: PR 138 merged. Each roadmap step M21 – M26 now ends with `[Model · effort]` (branch `docs/roadmap-model-tags`).
  The user runs Sonnet · medium by default; tell them to switch when a step says Opus or another effort.
- 2026-10-09: `docs/ROADMAP.md` reordered (branch `docs/roadmap-open-first`): "Next up" (M21 – M26) first, then "Open: waits on a user
  check" (M20, Releases), Later, then "Done (newest first)" M19 … M0. No line text changed. When a milestone is fully ticked, move it to the top of Done.

## Waiting on the user
- Merge the M19.P PR.
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
- Save is v14 (M13.T traps; v13 = M10.0 portal trips). `MapDb` holds maps in `areas`; use `objects_on(area)` or `objects_near`, not `areas[a]['objects']`, so flag-hidden objects stay hidden. Enemy `danger` must be 0.0–1.0.
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


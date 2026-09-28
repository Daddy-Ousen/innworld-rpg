# Handoff

## Just done (2026-09-28)
- M13.5 merged ([PR #64](https://github.com/Daddy-Ousen/innworld-rpg/pull/64)); ticked on main (commit 02b138f),
  tag `m13.5-done` on merge commit 62806ef.
- M13.6 done on branch `data/book5-m13.6` (PR open, not merged). User choices: 4.24 = day 110, Council that
  night, 4.27 H = day 111; Niers 110-113 and Magnolia 111-112 off-map; stages: Razorbeak fight, Brunkr's lesson,
  the bad news (day 110); Creler nest = NEW cave map + 2 new enemies; unowned [Warrior] 1 = Lyonette (likely).
- Data made by `scratchpad/gen_m136.py` (this session's scratchpad; gone next session). All data, art (brunkr,
  hawk, creler_hatchling, creler_juvenile), ADR 0020 "M13.6", count tests, `sim_canon_book5` and new
  `sim_book5_creler_nest.gd` (10 tests). Full suite 97 scripts / 902 tests pass; validator 0 errors; Python 78 OK.
  Detail: ADR 0020 "M13.6".

## Next steps
1. Wait for the user to merge the M13.6 PR. Then on main: tick M13.6 in `docs/ROADMAP.md` and `progress.md`,
   tag `m13.6-done` on the merge commit.
2. M13.7 canon batch (4.28 - 4.31). 4.28 starts the night of day 111 (Brunkr's feast; Ryoka held by Venitra).
3. Event ids: after `b5.zzzzd_` the next are `b5.zzzze_`, ... (`_` sorts before letters).

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
- Merge the M13.6 PR.
- Delete old remote branches `data/book4-*` (optional).

## Gotchas
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

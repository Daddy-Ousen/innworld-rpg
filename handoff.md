# Handoff

## Just done (2026-09-27)
- M11 closed. The user picked **M12 Audio**. Plan accepted: ADR `docs/adr/0019-m12-audio.md`, ROADMAP M12 section.
  User choices: free packs + our own tool (`tools/build_sfx.py`); music by place and mood **plus canon moments**.
- Branch `feat/m12.0-audio-spike` (off main): commit 1 = the open M11 docs edits; then the M12.0 spike:
  bus layout, autoload `Audio` (`game/ui/audio.gd`), `game/world/sound_cues.gd`, `WorldView.sounds` signal,
  footsteps (grass / wood / snow / stone), hit sound, System chime, button blips, title music (also in game).
  GUT 745/745 (80 scripts), Python 77/77, `python tools/build_sfx.py --check` OK.

## Next steps
1. The user approved the sound (2026-09-27). [PR #52](https://github.com/Daddy-Ousen/innworld-rpg/pull/52) is open (no CI checks).
   After the merge: tag `m12.0-done` on the merge commit, tick M12.0 in ROADMAP and progress.
2. M12.1: show the user the `audio.json` schema (draft in ADR 0019 / the plan) before coding (rule 11).
   Move the temporary tables (`Audio.CUES`, `Audio.TRACKS`, `SoundCues.STEPS`) into `game/data/audio.json`.
   Add cross-fade, `user://settings.cfg` volumes and an Options menu (title + pause).
3. Then M12.2 effects, M12.3 music, M12.4 ambience (ask before adding `"sound"` to objects.json), M12.5 moments.

## Audio notes (M12)
- Downloads so far are in the session scratchpad (gone next session): Kenney RPG Audio zip (doors, coins,
  chop, cloth, book, metal pot, knife: for M12.2). Re-download: https://kenney.nl/assets/rpg-audio (CC0).
- Music candidates (CC0, RandomMind on OpenGameArt, full + loop versions): "Medieval: Market Day",
  "Minstrel Dance", "The Bard's Tale", "King's Feast". Sir Gawain's "CC0 Fantasy Music & Sounds" collection
  has battle, cave, town and forest ambience tracks. Ask the user before each download (file, source, size).
- After adding audio run `godot --headless --path game --import`, then set `loop=true` in a music `.import`
  and import again. Then `git checkout -- game/assets/characters game/assets/objects game/assets/tiles`
  (import noise).
- `Audio` hooks every button through `get_tree().node_added`: menus need no audio code.

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
- Merge PR #52 (M12.0). OK the `audio.json` schema for M12.1.
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
- GUT exits 0 even on a parse error - grep for `Parse Error` and check the script count (80 now).
- Validator: `python tools/validate_data.py game/data/canon --all` (the folder with book<N> in it, not a book folder).
- Toy dbs erase `rules.economy`; real-db tests have hunger on.
- Rhir is real; Calruz stays missing; never link two canon entities unless the text says so (Ylawes is Yvlon's brother: 3.24 says so).
- Book 3 "E" chapters are Laken, not Erin. Laken, Geneva, Niers (3.22L) and Venitra use placeholder days.
- Save is v13 (M10.0 portal trips). `MapDb` holds maps in `areas`; use `objects_on(area)` or `objects_near`, not `areas[a]['objects']`, so flag-hidden objects stay hidden. Enemy `danger` must be 0.0–1.0.
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

## Active files
- `game/ui/audio.gd`, `game/world/sound_cues.gd`, `game/world/world_view.gd`, `game/world/main.gd`,
  `game/tests/unit_audio.gd`, `tools/build_sfx.py`, `docs/adr/0019-m12-audio.md`.

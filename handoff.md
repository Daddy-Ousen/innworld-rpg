# Handoff

## Just done (2026-09-29, M16.6 complete: the other maps)
- Branch `feat/m16.6-other-maps` (stacked on `feat/m16.5-celum`; nothing pushed, ask before push / PR). ADR `docs/adr/0026-m16-6-other-maps.md`
  (canon table + results). 6 commits M16.6.0-M16.6.5 + docs. M16.0-M16.6 are all done: one PR for the whole M16 chain is next.
- What changed: Celum gate towers + fee stand, Liscor gatehouses, inn goblin board (no stable/fence/well: canon has none), floodplains ford sign,
  Esthelm 4 refugee shacks, ruins entrance ditch (`chasm` at x=9, x=22) + 2 Watch tents, road camp signs + cart, tile `wood_window`
  (`tools/build_windows.py`, `game/assets/tiles/windows.png`) in 11 rooms, cave props `cobweb`/`bones`/`glow_mushrooms` (`tools/build_objects.py`).
  New test `unit_other_maps` (8); `tools/tests/test_build_windows.py` (3). No core change, no save change.
- Full suite (subagent): 118 scripts, 1101 tests. One failure: `sim_esthelm_siege.test_holding_the_barricade_changes_the_battle`, caused by
  a shack near the siege player's spot (8,6). Shack 1 moved to (2-4,1-2); Esthelm-related scripts (12) pass. The rest of the suite was run before
  that one map change (data only), so it was not rerun in full.
- Waiting on the user: walk the changed maps in the game (`godot --path game`): both gates, inn hill (board), Esthelm, ruins entrance,
  a room with windows, the depths/crypt. Then ask the user before pushing; one PR for M16.0-M16.6, then archive M16 in `docs/PROGRESS_ARCHIVE.md`.
- Next: M17 (tactical combat), plan mode first.
- Gotchas: keep props out of a stage map's fight lanes (see ADR 0026 lesson). The map patch helper (scratchpad `mp.py`) is gone next session;
  map JSON is tab-indented CRLF, one object per line; `json.dumps` does not round-trip it, edit by lines. After `--import`, do NOT
  `git checkout` every modified asset blindly: `git ls-files -m game/assets | xargs git checkout` also reverts a rebuilt `edits.png`.
  Screenshot scene `game/_scratch` is deleted before commit (recipe: M16.1 notes below).

## Just done (2026-09-29, M16.5 complete: Celum districts)
- Branch `feat/m16.5-celum` (stacked on `feat/m16.4-liscor`; nothing pushed, ask before push / PR). ADR `docs/adr/0025-m16-5-celum-districts.md`
  (canon table + results). One commit for M16.5.0-3.
- Graph: `celum_gate` - `celum_square` (hub) - `celum_main_street` (N, Runners' Guild door) / `celum_stitchworks_street` (W, "Springbottom Street",
  Stitchworks door + `stitchworks_door` shop plaque) / `celum_hare_street` (E, Hare door) - `celum_poor_quarter` (S of Hare street).
  Rooms keep size, door cell and all old objects; furniture only added. Mage's / Adventurers' / Merchants' Guild are signed closed plaques.
- Gotchas: `ToyMaps.walk_to_area` is ONE hop (tests walk square, street, room). A wide exit shifts `arrive` per cell: `arrive` must be free
  floor for every cell of the exit rect. A `plaque` object needs a `sign` (icon `none` = empty sign, used for the shop plaque).
- Waiting on the user: look at the 4 Celum streets and 3 rooms in the game (`godot --path game`): do the streets, signs and crowds look right?
- Next: M16.6 the other maps (Esthelm, road camp, inn hill, ruins entrance...: new buildings, props, signs). Plan mode first. The FULL suite
  (subagent) runs at M16.6's end, before its PR (M16.0-M16.5 changed no `game/core/` code).
- Generators (scratchpad `gen_celum.py`, `patch_square.py`, `run_targets.sh`, `_scratch` screenshot scene) are gone next session; the JSON is the source.
  Screenshot recipe: scene with a SubViewport + `WorldView` (see M16.1 notes); `_scratch` is deleted before commit.

## Just done (2026-09-29, M16.4 complete: M16.4.0 - M16.4.4)
- M16.4.4 done: Tailless Thief + Gnoll tavern rooms, Krshia and Ilvriss evening goals. All door plaques are exits now. Next: M16.5 Celum districts
  (plan mode first; reuse `Crowd`, `SignArt`, house tiles; the same graph idea: gate, square, guild street, Frenzied Hare street, Stitchworks street, homes;
  Celum `celum_*` ids and their tests must keep working; Celum houses are brick (`brick_house`, `brick_door`).
- M16.4.3 done: Watch House rooms + schedules for Zevara, Beilmark, Klbkch, Relc (ADR 0024). Only `homes_gnoll_tavern` and `gs_thief` plaques
  remain to turn into doors (M16.4.4). Ilvriss (Wall Lord) is off-map 'staying at the Tailless Thief' (4.09 scene brings him out): he can
  get a `work`/rest goal in the Tailless Thief room, guessed hours.
- Sim tests that wait in a room: park the player away from doorways (an NPC cannot pass them).
- M16.4.2 done: guild rooms + Selys at the desk (see ADR 0024). `sim_liscor_rooms.gd` grows with M16.4.3/4. Remaining door plaques on
  `liscor_watch` (`watch_barracks`) and `liscor_homes` (`homes_gnoll_tavern`); the Tailless Thief plaque `gs_thief` is on the guild street.
  Room generators: scratchpad `roomgen.py` + `gen_guilds.py` (gone next session; copy the JSON of a room instead).
- Branch `feat/m16.4-liscor` (stacked on `feat/m16.3-signs`; nothing pushed, ask before push / PR). ADR `docs/adr/0024-m16-4-liscor-districts.md`
  has the canon table (chapter refs) and results. User answers: 6 street maps; interiors for guilds, Watch barracks, taverns.
- M16.4.0 crowd: `game/world/crowd.gd` (pure), `WorldView._show_crowd/_move_crowd`, map field `crowd` (lanes of walkers, real time,
  hours 6-22). M16.4.1 streets: `liscor_plaza`, `liscor_guild_street`, `liscor_watch`, `liscor_homes` + market west exit.
  Generator (scratchpad `gen_liscor.py`, gone next session) wrote them; edit the JSON directly now.
- Doors of enterable buildings are `stone_door` cells with a sign PLAQUE beside them (`gs_adventurers`, `gs_mages`, `gs_thief`,
  `watch_barracks`, `homes_gnoll_tavern`). In M16.4.2-4: add the room map, an exit on the door cell with `sign`, delete that plaque,
  add the room id to `ROOMS` in `unit_liscor_map.gd`, a mood in `audio.json` moods.by_map (and ambience if a tavern), and
  crowd lanes only on cells free of solid objects (`unit_crowd` checks).
- Canon notes for the rooms (ADR table): Adventurers' Guild = one hall, counter (Selys), job board, tables, stairs to a small
  upper floor; Mages' Guild = front counter with a Drake clerk; Watch House = big ground room with tables and a desk near the door,
  Zevara's office upstairs; Tailless Thief = Drake-only costly inn, counter with kegs, kitchen; Gnoll tavern = Gnoll staff and patrons.
  Olesm is Council, NOT at the guild. Terbore, Tekshia, Peslas have no look sheet: no NPC.
- NPC schedule edits (Selys at the guild 8-12 / 13-18; Watch off-hours in the barracks) can break `sim_npc_day`, `sim_walk_day`,
  `sim_canon_fights`, `unit_console` (beilmark line): run them after each edit.
- Scratch screenshot scene sources: scratchpad `scratchscene/` (copy to `game/_scratch/`, env OUT, ONLY, WINTER, POS; delete before commit).

## Just done (2026-09-29, M16.3)
- M16.3 signs on branch `feat/m16.3-signs` (stacked on `feat/m16.2-buildings`; nothing pushed, ask before push / PR).
  Result table in `docs/adr/0023-m16-art-audit.md` ("M16.3 result"). Passing: `unit_sign_art` (7), `unit_gated_exits`,
  `unit_ground_art`, `unit_art`, `unit_world_view`, `unit_map_db`, `unit_sound_cues`, `unit_monster_art`, `unit_ambience`,
  `sim_liscor_depths`, `sim_canon_book1..5`, `sim_walk_day`, Python 91, validator 0 errors. No core change, so no full suite (M16.6).
- Waiting on the user: look at `celum_square`, `liscor_market`, `inn_hill` and a room door in the game
  (`godot --path game`): do the signs, arrows, plaques and labels (they show within 2-4 cells) look right?
- Design: object or exit field `sign` = `{icon, text?}`. Icons: `game/data/objects.json` key `signs` (built by
  `tools/build_signs.py`; `--check` compares). `game/world/sign_art.gd` (`SignArt.marks`, `label_alpha`) is pure;
  `WorldView._add_mark` draws (marker nodes in the Marks layer carry meta `mark` = sign / arrow / label; sign sprites go
  in Props). Unsigned exits get an arrow to the nearest map edge and a "To <map name>" label. Kind `plaque` = empty art,
  the sign is the object (place "here"). `EXIT_COLOR` is gone.
- New M16.4/M16.5 maps: give each door an exit `sign` (or an object `sign`), and doorless houses a `plaque` object.
  `unit_sign_art.test_every_enterable_house_door_has_a_sign` checks `celum_square` and `inn_hill` only; extend its list.
- Next: M16.4 Liscor districts (plan mode first).
- Screenshot scratch scene (`game/_scratch`, deleted): env OUT, ONLY, WINTER, POS ("x,y" = player cell, so labels show).

## M16.2 (2026-09-29)
- M16.2 buildings on branch `feat/m16.2-buildings` (stacked on `feat/m16.1-nature-art`; nothing pushed, ask before
  push / PR). Result table in `docs/adr/0023-m16-art-audit.md` ("M16.2 result"). Passing: `unit_ground_art` (21),
  `unit_art`, `unit_world_view`, `unit_map_db`, `unit_gated_exits`, `unit_sound_cues`, `unit_monster_art`,
  `sim_liscor_depths`, `sim_canon_book1..5`, Python 86, validator 0 errors. No core change, so no full suite (M16.6).
- Waiting on the user: look at `liscor_market`, `celum_square`, `inn_hill`, `esthelm_ruins` in the game
  (`godot --path game`) and say if the houses look right (roof colours, window spacing, the plain inn).
- Next: M16.3 doors and signs (plan mode first). The yellow exit tint (`EXIT_COLOR`, `world_view.gd` ~line 566) lies over
  every door: replace it with a door marker. Object doors (`celum_square` (24,3), (1,14)) keep the old door art.
  A side door (`celum_square` (1,13), tile `door`) has no art: a house draws only its south face.
- Houses: tile field `house` (`{sheet, block, group, door, see_through}`); `GroundArt.house_look` / `house_piece`; sheet
  `game/assets/tiles/houses.png` from `tools/build_houses.py` (blocks 0-3 summer stone/brick/plain/ruin, 4-7 snow roofs;
  each block 5x4 cells: roof top, roof fill, upper wall + window + door top, lower wall + door). Map chars: `B`/`b` =
  two houses of one style side by side (`building`/`building_b`, `brick_house`/`_b`, `plain_house`/`_b`), doors
  `stone_door`, `brick_door`, `plain_door` (they join either group), `ruin_wall`. A wall along the map edge shows only roof.
- A tree prop is 5 cells high: `unit_ground_art` fails if a tree stands within 4 cells below a house or city wall.
- Screenshot recipe below still works (scene `game/_scratch/shot.tscn` + `shot.gd`, deleted before commit; env OUT,
  ONLY, WINTER). Import noise: after `--import` run `git checkout -- game/assets/audio game/assets/fonts` and
  `git ls-files -m game/assets | xargs -r git checkout --`.
- Patching map rows: a Python helper that keeps tabs and CRLF (rows replaced line by line) was in the scratchpad (gone).
  Edit tool output on `.gd` files with CRLF is fine; do not open them in Python without `rb`/`utf-8` (the `×` breaks).

## M16.1 (2026-09-29)
- M16.1 nature art on branch `feat/m16.1-nature-art` (stacked on `feat/m16.0-art-audit`; nothing pushed). Result table in
  `docs/adr/0023-m16-art-audit.md` ("M16.1 result").
- Answered 2026-09-29: audit list is complete; the inn building waited for M16.2 (ADR 0023 "User answers").
- Waiting on the user: look at road camp, ruins entrance, bee cave, crypt, floodplains and say if the cliffs, boulders
  and ford look right.
- New code: `GroundArt.edge_pieces` / `mix` (several edge pieces per cell, drawn by `WorldView._add_mix` in the
  `EdgeMixes` node), `GroundArt.cliff_look` / `cliff_piece` (tile field `cliff`), `tools/build_cliffs.py` (writes
  `game/assets/tiles/cliffs.png`: earth, stone, snow_earth, snow_stone blocks, 3x4 cells each).
- Map legend chars added: `R` = rock (isolated cliff cell), `O` = boulder. Cliff maps use `^` = `cliff` (outdoor) or
  `stone_cliff` (caves).
- Screenshot recipe (scratch scene, deleted): `game/_scratch/shot.tscn` + `shot.gd` (`extends Node`, `_ready` calls a
  deferred coroutine). For each map id in `db.maps.areas`: a `SubViewport` sized `MapDb.size * WorldView.TILE`
  (`UPDATE_ALWAYS`) holds a `WorldView` from `res://world/world_view.tscn`; `v.setup(db.maps, {}, db.combat.enemies, {}, "winter")`;
  `gs = GameState.new(1)`; `gs.flags["winter"] = true` for winter; `gs.player.place(id, Vector2i(0,0))`;
  `v.refresh(gs, db)`; hide `v.player` and `v.atmosphere`; camera zoom 1; wait 4 frames; `get_texture().get_image().save_png`.
  Run with the console exe (not `--headless`, needs the renderer): `OUT=<dir> WINTER=1 ONLY=id1,id2 Godot..._console.exe --path game res://_scratch/shot.tscn`.
- `godot --headless --import` may segfault (known) but still imports; then `git checkout -- game/assets/audio game/assets/fonts`
  and the LF-rewritten `.import` files under `assets/tiles|objects|characters` (keep new untracked ones).
- Tile facts: `rock` = one grey rock (atlas 26,25), `boulder` = atlas 27,26 (3x2), `shallows` shares the water ground
  and adds stepping stones; `water`/`shallows` have `winter_sprite` (ice, terrains block 27,14).

## M16.0 (2026-09-29)
- M15 merged (PR #77, b93e2df) and archived. M16.0 audit is on branch `feat/m16.0-art-audit`
  (`docs/adr/0023-m16-art-audit.md`, 25 problems mapped to M16.1-M16.6). Docs only.

## M15 (2026-09-29, merged)
- M15.0–M15.3 merged as one PR (#77) and archived in `docs/PROGRESS_ARCHIVE.md`.

## M15.2 (2026-09-29)
- M15.2 done on branch `feat/m15.2-hud-log` (stacked on `feat/m15.1-player-day`; nothing pushed). Log strip 3 lines,
  bottom left, see-through, fades; `Hud.history()`; L = `MessageLog`, H = `Help` (`ui/text_page.*`);
  keys in `SystemMessages.KEYS`. Targeted tests pass (`unit_hud_log` new, `unit_world_view`, `unit_play_loop`,
  `unit_ui_theme`, `unit_system_messages`, `unit_journal`). No core change, so no full suite.
- Next: M15.3 (no XP numbers): `world/main.gd` XP line, `ui/character_sheet.gd` class lines + "Total level",
  `ui/system_messages.gd` HINTS 2 and 3, `ui/journal.gd` last line. Keep `ui/console_commands.gd` numbers.

## M15.1 (2026-09-29)
- M15.1 done on branch `feat/m15.1-player-day` (stacked on `feat/m15.0-font`; nothing pushed, ask before push / PR).
  `Clock.player_day(canon_day, rules["clock"])` (arrival = Day 1). Used by HUD, character sheet, journal, morning
  page, "Loaded" line, log day line (`main.gd _day_line`), save slot label (`SaveSlots.info["player_day"]`).
  The debug console keeps calendar days. Full suite: 109 scripts, 1026 tests pass.
- Tests that print a day use the real db: convert with `Clock.player_day(day, _db.rules["clock"])`.
- Next: M15.2 (HUD log: `ui/hud.tscn`, `ui/hud.gd` `LOG_LINES`), then M15.3 (no XP numbers).

## Earlier (2026-09-29)
- The user played M14 and sent 8 problems (screenshots in `The Wandering Inn Books 1-17 Pirateaba/Temp/`, not in git).
- Plan written: M15 (readability, lore), M16 (maps, art, cities), M17 (XCOM-style combat) in `docs/ROADMAP.md`;
  decisions and the user's AP rules in `docs/adr/0022-m15-m17-play-report.md`; DESIGN §1 updated.
  Branch `docs/m15-m17-plan` (from main d75adfa). Docs only, no code.
- Earlier: M14 merged (PR #75, tags `m14-done`), archived (PR #76). Rock Crab and day-21 raid stay as they are.

## Next steps
1. Answered 2026-09-29: order M15 → M16 → M17 OK; extra AP uses the TOTAL level (secret: never shown, AP gains
   silent; M15.3 removes "Total level" from the character sheet); level cost by total level + hidden cap 100
   goes in M17.7. All in ADR 0022.
2. M15.0 done on branch `feat/m15.0-font` (stacked on `docs/m15-m17-plan`): Pixel Operator, Large text box in
   Options (`ui/text_settings.gd`, `Session.set_large_text`). Not pushed yet; ask the user before push / PR.
   Screenshot helper: `game/_scratch/shot.gd` (deleted before commit) + `--write-movie`; window size is ignored.
   Test runner: `scratchpad/run_targets.sh <script>...` (gone next session).
3. M15.1: done (see above).
4. M15.2: `ui/hud.tscn` (Bottom panel, Log label, Hint label), `ui/hud.gd` (`LOG_LINES` = 6).
5. M15.3: `world/main.gd:308` (XP line), `ui/character_sheet.gd:56-59`, `ui/system_messages.gd:41-42`,
   `ui/journal.gd:134`. Keep `ui/console_commands.gd` numbers.

## Probe notes (M14.8)
- A test that skips days with `ToyCanon.sleep_through` piles up hunger (max HP x0.5): set `gs.economy.hunger = 0`.
- `unit_bag` and `unit_brawl` leave state in `Session.gs`; a test that reads `Session.gs` should set its own game.
- The wave rule (`Stage.tick`): a wave waits while `here >= max_on_map` (12) and, if `here > 0`, until
  `after_seconds` has passed or `here <= left_at_most`. One player turn = 6 s.

## M14.7 notes
- Journal news stays text only (one Label). A face per news line would need a rebuilt journal.
- `Import` may rewrite `game/assets/fonts/*.import` line endings: `git checkout` them before committing.
- A menu test can feed `InteractMenu.open` hand-made option dicts (needs `id`, `name`, `npc`, `actions`, `sleep`,
  `item`, `price`, `trades`, `ride`); `Session.gs` may be null.

## M14.6 notes
- Theme covers Button, ItemList, PanelContainer, LineEdit, HSlider, Label, CheckBox, RichTextLabel. The System dialog
  keeps its own blue panel and `[Title]` headings stay blue on purpose (System voice).
- Font `.import` is edited by hand: antialiasing=0, hinting=0, subpixel_positioning=0. A reimport keeps it.
- Font (M15.0) is Pixel Operator on a 16 px grid: use 16 or 32 only (`unit_ui_theme` checks the scenes).

## M14.5 notes
- Major NPC = a pending, non-mutate-target canon event names them in a role `prefer` or `requires.alive`
  (`Brawl.is_major`). Warned ids live in `gs.flags["fate_warned.<id>"]`.
- Hostile lasts until the day number changes (`hostile_day == clock.day()`), not until sleep. A long gap heals
  the NPC's hp (old `NpcSim` rule) but not the hostility.
- A test that kills an NPC through `Commands.attack_npc` must keep the player up (`Combat.set_hp(gs, db, 9999)`
  each turn): the hostile NPC hits back after every command.
- `Combat.in_danger` is now also true for a hostile NPC: NPCs near it stand still (NpcReact) and patrons leave.
- `Import` of the project segfaults sometimes (known); GUT runs fine after it anyway.

## M14.4 notes
- Who gets a schedule: canon NPCs with a place on one of our maps. Left out (no map): terbore, tekshia, peslas,
  timbor_parithad, ulia_ovena, theofore, termin, ressa, magnolia_reinhart, esthelm_florist. `princess_thief` is the
  Book 1 placeholder for Lyonette: not linked (confirmed-links-only rule).
- Grev is a `teen` body: the sprite tool cannot read LPC child hair (single `child/<colour>.png`, no walk/ folder).
- The LPC clone is in this session's scratchpad (`.../4654847b-.../scratchpad/ulpc`; gone next session).
- The test-run helper `scratchpad/run_targets.sh` (gone next session) ran one GUT script per Godot call and grepped
  the summary. Monitor with an `until grep -q DONE` loop.

## M14.3 notes
- Town = nearest `settlement` above a map's location (`Standing.town_of`): liscor, celum, esthelm. The inn area
  has no town. Faction = the NPC's canon `faction`.
- A relationship fades only with the player ("player" key) and only after 7 days with no contact
  (`WorldState.contact`). No contact record: the clock starts that night.
- Shop prices use the town of the PLAYER's area, so a price read with the player elsewhere shows no shift.
- Friends (regard >= 10) fight like `rules.npc.react.ally`. A test that talks to one NPC on 10 days will now see
  them fight in a monster fight.
- `Standing.add_reputation(gs, db, key, delta)` is the one writer; M14.5 uses it for witnesses.

## M14.2 notes
- Patron rolls use `Rng.new(seed ^ meal_key * 2654435761)`, not `gs.rng`: the main stream stays the same.
- Patrons roll only at the first command in a meal while the player is in `inn_interior`. Tests that stand in the
  inn at 7-10, 12-14 or 18-22 now get patrons; a patron on a seat blocks the player (not NPCs or monsters).
- Cooking takes 45-120 min; cooking during a meal makes patrons give up (-2 each while the player is in the room).
- `sim_inn_service` cooks between meals for that reason.

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
- Look at M14.6 and M14.7 in the game (`godot --path game`) and say if colours, sizes or the face crop need changes.
- Delete old remote branches `data/book4-*` (optional).

## Book 5 canon notes (M13.7)
- A fight stage with helpers who come at once lets them box the foe in on all four sides; the player never gets a
  hit and the hook never fires. Delay the helper wave (M13.7 uses 30 s). Klbkch joins inn fights 18-21.
- Ryoka dies and is revived in two same-night events (`kill`, then `revive`); nothing between them in id order may
  need her alive.
- 4.31 clears `izril.winter` on day 114: winter rules and snow end there.
- The LPC clone for M13.7 is in this session's scratchpad (`.../47ef78fc-.../scratchpad/ulpc`, only Regrika's parts;
  gone next session).
- The auto-mode safety check failed for a long stretch this session (Bash, PowerShell and Agent all blocked). Read,
  Grep, Write and Edit still worked, so chapter reading and data prep went on by hand.

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
- M13.7: `game/data/canon/book5/chapters/4.28.json` ... `4.31.json`, `4.24.json`, `4.27H.json`, `book5/npcs.json`,
  `book3/npcs.json` (Ijvani), `game/data/enemies.json`, `appearance.json`, `audio.json`, `npc_behaviour.json`,
  `game/assets/characters/regrika_blackpaw.png`, `game/tests/sim_book5_last_light.gd`, `sim_canon_book5.gd`,
  `docs/adr/0020-m13-book5.md`.
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

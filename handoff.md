# Handoff

## Just done (2026-09-27)
- PR #43 (M10.3) merged. Tag `m10.3-done` on 51fbbae (pushed).
- M10.4 (3.36-3.39) built on branch `data/book4-3.36-3.39`. Detail: ADR 0017 "M10.4". Committed; PR #44 is open.
  - User choices: one scene with a hook (the Rock Crab, day 93, 10:00-12:00, `floodplains_south`); slime scene moved to day 92; about 27 events.
  - 27 events: `chapters/3.36.json` (6), `3.37.json` (6), `3.38.json` (7), `3.39.json` (8). New NPCs `hedault`, `merec`, `raisha`, `regisand_curle`; new locations `hedault_house`, `invrisil_merchants_guild`.
  - Erin rides home on the night of day 92 (`erin.back_from_esthelm`; `erin.at_esthelm` cleared). Valceif dies on day 93. `ryoka.heading_home_to_liscor` is set. Christmas is named; the party is day 95.
  - GUT 679/679 (73 scripts). Python 51 OK. Validator 0 errors. The Rock Crab scene was NOT checked on screen.

## Next steps
1. The user merges PR #44 (M10.4). Then tag `m10.4-done` on the merge commit.
2. M10.5 (3.40-3.42 + Interlude - Winter Solstice; raw text in `canon/raw/book4/022..025`): read with a subagent, then ask the user for stage and hook choices. Christmas party is day 95.
   - Clear `ryoka.heading_home_to_liscor` when Ryoka arrives. She holds `ryoka.holds_magnolias_seal`, Hedault has the Horns' relics (`hedault.holds_the_horns_relics`) and she said she would return to him.
   - Rags heads south (`rags.heading_south`, `rags.wants_to_see_erin`); `rags.tribe_turns_north` still blocks her foraging near Liscor. Clear it when she arrives.
   - Brunkr: `brunkr.hand_infected` and `brunkr.treated_with_honey_and_salt_water` are both set. Resolve when the text shows the result.
   - Octavia researches matches and penicillin (`octavia.researches_matches`, `octavia.researches_penicillin`).
3. Toren is alive in the Liscor dungeon (`toren.in_liscor_dungeon`). Keep him alive unless the text says he died.
4. Halrac, Jelaqua, Xrn, Typhenous, Revi, Moore, Ulrien, Seborn, Olesm, Belgrade and Octavia have no `npc_behaviour` entries. Add them if a later scene must place them.
5. Laken has Durene and Gamel in 3.36-3.37 (Frostwing at the inn); flags are consistent now.

## Waiting on the user
- Merge the M10.4 PR (once opened).
- Delete the old remote branches `data/book4-3.26-3.29`, `data/book4-3.30-3.31`, `data/book4-3.32-3.35` (optional).

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
- GUT exits 0 even on a parse error - grep for `Parse Error` and check the script count (73 now).
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

## Active files
- M10.4: `game/data/canon/book4/chapters/3.36.json` to `3.39.json`, `npcs.json`, `locations.json`, `3.35.json` (slime window), `game/tests/sim_book4_relief_home.gd`, `sim_canon_book4.gd`, `sim_book4_homecoming.gd`, `sim_player_hooks.gd`, `docs/adr/0017-m10-book4.md`. Generator script was a throwaway (not in repo).
- M10.3: `game/data/canon/book4/chapters/3.32.json`, `3.33.json`, `3.34.json`, `3.35.json`, `game/data/canon/book4/npcs.json`, `game/data/classes.json`, `game/data/skills.json`, `game/data/npc_behaviour.json` (Erin), `game/tests/sim_book4_homecoming.gd`, `game/tests/sim_canon_book4.gd`, `docs/adr/0017-m10-book4.md`.
- M10.2: `game/tests/sim_book4_wistram.gd`, `chapters/3.30.json`, `3.31G.json`.
- M10.0 door: `game/core/portal.gd`, `game/data/maps/celum_stitchworks.json`.

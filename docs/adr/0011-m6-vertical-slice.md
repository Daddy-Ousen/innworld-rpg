# ADR 0011 — M6 Vertical slice

Date: 2026-09-23 · Status: accepted for M6.1, M6.4 and M6.5 (M6 plan approved by the user 2026-09-23; M6.4 and M6.5 schemas approved 2026-09-24).

## User choices (plan)
- Canon: all chapters 1.15–1.25 as event data (Ryoka, Antinium and King chapters too). Two data parts: M6.2 (1.15–1.20R), M6.3 (1.21–1.25).
- The player changes canon through optional `hooks` on each canon event (M6.4; schema change, ask first).
- A player who works hard at the inn gets the first class offer on night 2–3 (was day 22, ADR 0009).
- Save UI: a title menu, 3 save slots, and an autosave each morning.
- 5 parts: M6.1 play loop, M6.2 canon 1.15–1.20R, M6.3 canon 1.21–1.25, M6.4 player hooks + news, M6.5 canon fights + slice check.

## M6.1 Play loop
Presentation and data numbers only. No schema change, no save version change.

**Save slots — `core/save_slots.gd` (headless).** Three manual slots (`"1"`, `"2"`, `"3"`) and `"autosave"`, each a `GameState` JSON file in one folder: `slot_<n>.json`, `autosave.json`. The folder is a parameter (default `user://saves`). `load_game` runs `Commands.settle` after the load, like the console. `info` loads the file to show day, time and area; a file that does not parse is "cannot be read" and is never continued. `latest` (Continue) = newest file time, then later game time, then slot order.

**Session.** `save_dir`, `start_new_game(seed)` (sets `fresh`), `save_slot`, `load_slot`, `autosave`. `set_state` clears `fresh`. GUT runs save to `user://test_saves`: the pre-run hook `test_support/gut_pre_run.gd` (in `.gutconfig.json`) sets `Session.save_dir`, so scene tests never touch the player's saves.

**Title menu — `ui/title_menu.tscn` (the main scene now).** New game (seed from the system clock), Continue (off with no save), Load (slot list; empty slots greyed out), Quit. `switch_scene = false` in tests; they watch `entered_game`.

**Pause menu (Esc) — `ui/pause_menu.tscn`.** Resume, Save (manual slots only; a full slot is overwritten), Load, Quit to title (autosaves first). Save and load work at any time, also in a fight: the save holds the fight (ADR 0010), and a loaded fight plays on the same. `ui/slot_list.tscn` is shared by the title and the pause menu. Esc in the slot list goes back.

**Autosave.** Each time the System dialog closes (every morning, after a knock-out, and after the welcome page), on quit to title, and when the window closes.

**Welcome page.** A new game from the title opens `SystemMessages.welcome_page()` (kind `welcome`): who the player is, then `SystemMessages.HINTS`. A loaded game gets no welcome page. The hints are UI help text, so they live in the UI script, not in data.

**Journal (J) — `ui/journal.tscn`.** Day, focus, hints, and a focus list: "No focus", then "Become <class>" for each class that is not a consolidation, has no class prereqs and was not declined. A choice calls `Commands.set_focus` with the class's main tags (weight ≥ 0.5, strongest first). The character sheet shows the focus by the same name. News and history come in M6.4.

**XP pacing.** All `offer_threshold` values in `data/classes.json` are one third of the old ones, rounded to 5 (150 → 50, 180 → 60, 200 → 65, 400 → 135). The XP formula and level curve are unchanged. A plain inn workday (3 stews, sweep, clean room) now gets [Innkeeper] on night 3 (day 11); with the [Innkeeper] focus it comes one night earlier. `sim_m4_done` now asks for an offer within 3 nights.

**Console.** `save` / `load` still use `user://debug_save.json` (debug only).

**Known limits.** Levels after the first class are still slow (canon Erin is [Innkeeper] level 9 by day 9); tune in M6.5 if the slice feels slow. The focus list shows every class, which a new Earther would not know.

## M6.4 Player hooks and news
User choices (2026-09-24): the schema below as planned, with the outcome `changed`; the three cases below; the player hears all local news (Liscor is small).

**Canon event schema (rule 11, approved).** Two new optional event fields:
- `news`: one short line (max 200 chars, own words) that people in Liscor say when the event happens. It is design text about a canon event, not a new canon fact.
- `hooks`: a list of ways the player can change the event.
```json
"hooks": [{
  "id": "player_beat_rock_crab",
  "did": [{"action": ["attack_melee", "throw_object"], "outcome": ["success"], "context": {"enemy": "rock_crab"}}],
  "days": [10, 11],
  "then": "mutate:b1.player_beat_rock_crab_first",
  "effects": {},
  "news": "Word on the road: ..."
}]
```
- `did`: the hook matches if one action record matches one entry: the action id is in `action`; the outcome is in `outcome` (if given); each `context` key has that value (or one of a list).
- `days`: `[from, to]`, absolute days. Records from these days count, but never after the day the director is running. The action log keeps 7 days (`xp.novelty.window_days`), so the span is at most 7 days (validator error).
- `then`: `cancel` (the event does not happen), `mutate:<id>` (the alt event runs in its place; the alt is alt-only, like an `on_fail` mutate target), or `change` (the event runs with the hook's `effects` added; `effects` only here).
- `news`: the hook's news line. On `change` it replaces the event's news.

**Action records keep their `context`** (the enemy of a fight, the location, the NPC). Hooks match on it. On load, whole numbers in a context become ints again (JSON reads them as floats; real floats are f64 text).

**Director.** Before an event that is due is checked, its `cancel` / `mutate` hooks are tried in order; the first that matches wins. A mutate hook whose alt is not pending or cannot run now is skipped. A `change` hook is tried when the event fires. History entries of a hook result get `"by": "player"` and `"hook": <id>`; the reason is `the player: <id>`. The new outcome/status `changed` counts as happened for `depends_on` (like `done` and `substituted`). Drift weights: `changed` 0.25 (like `substituted`), `mutated` 0.5, `cancelled` 1.0; dependents that cancel add their own drift.

**News.** `gs.world.news`: `{"day", "event", "kind", "text"}` in order; kind `news` (event or hook `news`) or `rumor` (T1 `rumor`). A new game clears the news of days 1–7 (the player was not there). The night result gets `news` (texts of kind `news`); `lines` gets `News: <text>` after the offers and before the world lines. `SystemMessages` shows a "Local News" page after levels and skills, before rumors. Console: `news`.

**Journal (J).** Day, focus, "Your mark on the story" (each hook result as its news line, each player kill as "You killed <name>."), a drift line (0 = "The story runs as you know it."; at `unreliable_at` or more, the unreliable line), the news of the last 7 days (newest first), then the hints. The text scrolls (PgUp / PgDn, mouse wheel).

**Save v7.** Migration 6 → 7: every old record gets `"context": {}`; `world.news` starts empty.

**Validator.** Checks `news` and `hooks` (shape, `days` span, `then`, effects only with `change`, mutate targets, NPCs in hook effects), warns when hook days start after the window, checks hook action ids against `game/data/actions.json` (auto-detected, or `--actions`), and runs the copy check on news and hook news. 32 Python tests.

**The three divergence cases (data).**
| Event | Hook | The player… | Result |
|---|---|---|---|
| `b1.erin_screams_off_rock_crab` (day 11) | `player_beat_rock_crab` | wins a fight against a Rock Crab on day 10–11 | mutate → `b1.player_beat_rock_crab_first` (new, `candidate`, `guess`, not canon): no crab at Erin's door |
| `b1.inn_first_regulars` (day 15) | `player_cooked_for_regulars` | cooks or serves at the Wandering Inn on day 15 | change: flag `wandering_inn.earther_cooks`, Klbkch and Pisces → Erin +1 (design values) |
| `b1.rags_brings_goblins_to_eat` (day 19) | `player_fought_goblins` | wins a fight against Goblins on days 14–19 | cancel: the tribe does not come to eat |

News lines on 13 T2 events of days 8–19. They are new text on reviewed events: the user reviews them in the PR.

**Tests.** `unit_player_hooks` (toy canon: cancel, mutate, change, no match, days, first hook wins, news, night result, `CanonDb` checks, save round trip, v6 → v7), `sim_player_hooks` (real Book 1: a real bump-attack fight and real cooking at the inn stove for each case, a save/load between deed and night, the journal). `sim_canon_book1` also checks one news line per event with news and no news before day 8.

**Known limits.** A hook sees only the last 7 days of actions. Hooks cannot see where the player stood or who watched; only the action records. A fight counts as won when any foe died or ran off.

## M6.5 Canon fights and the slice check
User choices (2026-09-24, all as proposed): the Chieftain fight ends in a `change` (not a mutate); sparing gives a record and the Rags hook needs a kill; NPCs have no hit points; levels after the first class cost less.

**Canon event schema (rule 11, approved).** One new optional event field:
```json
"stage": {
  "area": "inn_interior", "hours": [9, 12],
  "when_flags": ["goblin_tribe.lost_two_to_relc"], "unless_flags": [],
  "foes": [{"enemy": "goblin_chieftain", "pos": [12, 14]}],
  "allies": ["erin_solstice"],
  "line": "...", "note": "..."
}
```
A stage puts the event's fight on the map. It runs when the player is in `area` at `hours` (whole hours, `[from, to)`, may wrap), on a day in the event's window (with delays), while the event is pending, every NPC in its `requires.alive` lives, and the flags fit. Its `requires.flags` are **not** checked: the director sets them at night, after the day of the fight. Each event stages once (`world.staged`: event id → day). The foes come in hostile as one pack (spawn `""`, `stage` = event id) on their tile, or the nearest free one. `line` (own words) goes to the combat text. A stage never changes canon by itself: the fight writes normal records, and the event's hooks (M6.4) read them.

**`core/stage.gd`**: `Stage.check` runs from `MonsterSim.run` after every command (`is_open`, `run`, `allies_of`, `free_near`). `CanonDb` checks the stage shape and lists `stages`. `CombatDb.validate` checks the enemies, the map and the foe tiles (walkable, not an exit). `MonsterSim.in_hours` is shared with spawns.

**NPCs near a fight — `core/npc_react.gd`.** While a hostile monster is in the player's area (`Combat.in_danger`), NPCs there do not follow their goals:
- A fighter walks to the nearest hostile monster and hits it when side by side. Fighters are NPCs with a tag in `rules.npc.react.fight_tags` (`guard`: Relc, Klbkch, Zevara, Beilmark, Belsc…) within `help_radius` (8, king moves), and the allies of a monster's stage at any distance. Hits use `react.fighter` (tagged) or `react.ally` accuracy and damage against the monster's evasion and armor, and count as fight kills. A fighter with no monster in reach follows its goal.
- Any other NPC within `flee_radius` (4) of a hostile monster steps to the side tile farthest from it (not onto the player, a monster or an exit). The rest stand still until the danger is over.

NPCs act once per `react.act_seconds` (6), after the monsters. Rolls use `gs.rng`. NPCs have no hit points: monsters attack only the player. `Commands._after` also ends the fight after the NPCs act (`Combat.settle_if_over`), because an NPC can kill the last foe.

**Sparing.** Every fight record's context now has `killed` (a foe died, by anyone's hand). A won fight where foes ran and none died, against an enemy with a tag in `rules.combat.spare_tags` (`goblin`), adds a `spare_foe` record ("Let a beaten foe go", `social.empathy`) and the line "You let them go."

**Data.**
- `enemies.json`: `goblin_chieftain`. Guess stats: hp 20, armor 1, accuracy 4, damage 2–4, a bow (2–3 at range 5), `flee_below` 0. Tags `goblin`, `chieftain`. No spawn uses it.
- `b1.erin_kills_chieftain`: the stage above (day 9, 09–12, he comes in by the door, and Erin fights with the player). Hook `player_fought_chieftain` (`attack_melee` / `throw_object` / `block_attack`, success, enemy `goblin_chieftain`, days 9–11) → `change`: flag `wandering_inn.earther_fought_chieftain`, clears `erin.stab_wound` and `erin.hands_burned`, Erin → player +3, and its own news line. Erin still kills him in the story, so every later event runs (drift 0.25).
- `b1.rags_brings_goblins_to_eat`: the hook now needs `killed: true`. Goblins that ran away unkilled still come to eat.
- A hook's relationship effect may use `"player"` as `to` (the player's relationship id). The validator allows it only in hooks.
- `rules.levels`: `base_xp` 60 → 40, `growth` 1.35 → 1.25. A player who works hard at the inn now reaches level 5 by about day 18–21 (was level 4). `sim_m6_done` reaches level 6 by day 22.

**Save v8.** Migration 7 → 8: `world.staged` starts empty, and old monsters get `"stage": ""`.

**Validator.** `check_stage` checks the shape and the flags, checks that allies are known NPCs, limits `line` to 200 characters, and runs the copy check on `line`. 36 Python tests.

**Tests.**
- `unit_stage` (toy stage): hours, window, pending event, flags, NPCs alive, runs once, free tile, won → changed, fled → canon, save round trip, v7 → v8, shape and tile checks.
- `unit_npc_react`: a guard kills a Goblin, same seed same fight, a bystander steps away and goes back to work, a far bystander stands still, stage allies (also from far away), a fighter out of reach keeps its goal.
- `unit_combat`: spare and no spare.
- `sim_canon_fights` (real data): a win next to Erin → changed, and the rest of the canon runs (drift 0.25 only); a knock-out → canon; no stage after the hours; a Liscor guard kills a Goblin at the gate; Goblins let go still come on day 19.
- `sim_m6_done`: the M6 "Done when" through the main scene (seed 1). From the gate to the inn; work and sleep on days 8–21; the first offer accepted; the Chieftain fight won on day 9; the journal shows the change; a save in the middle of the fight plays on the same; a slot saved on day 15 loads back the same game.
- `sim_m4_done` marks the stage as done (it tests the M4 loop).

**Known limits.** A stage has its own `when_flags`, because the director sets the event's flags only at night. Monsters attack only the player. The Chieftain comes in by the only door, so a player in the inn at 09:00 must fight him or be knocked out. NPCs flee inside the area only (they never leave by an exit). The name labels of markers side by side overlap. Klbkch still fights Goblins as a guard after he promises Erin not to hunt them (`klbkch.spares_goblins` is not read yet).

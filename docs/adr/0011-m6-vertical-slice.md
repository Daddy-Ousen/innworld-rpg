# ADR 0011 — M6 Vertical slice

Date: 2026-09-23 · Status: accepted for M6.1 and M6.4 (M6 plan approved by the user 2026-09-23; M6.4 schema approved 2026-09-24). Later parts add their sections here.

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

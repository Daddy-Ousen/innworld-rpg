# ADR 0011 — M6 Vertical slice

Date: 2026-09-23 · Status: accepted for M6.1 (M6 plan approved by the user 2026-09-23). Later parts add their sections here.

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

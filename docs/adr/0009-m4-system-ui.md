# ADR 0009 — M4.5 System message UI

Date: 2026-09-23 · Status: accepted (M4 plan approved by the user 2026-09-23; bed flag = user choice "object flag")

## Night result sections — `core/night.gd`
- `Night.run` keeps `lines` (all lines in order) and adds `collapsed` (bool), `progress` (levels, skills, breakthrough notes, class loss) and `world` (the director's rumors and the drift warning).
- `Night.COLLAPSE_LINE` is the collapse text. The UI reads the sections; it does not parse text.

## Pages — `ui/system_messages.gd` (`SystemMessages`, headless)
- `pages(night, gs, db)` → pages in a fixed order: collapse, "Levels and Skills", rumors, drift warning (`Director.UNRELIABLE_LINE` gets its own page), one page per open offer, morning.
- A page: `{kind, title, lines, choices, class}`. Choices: `next`; offers `accept` / `decline`; the decline confirm `yes` / `back`.
- Offer pages come from `gs.progression.offers`, not from the night result. So older unanswered offers (from the console or a save) show too.
- A consolidation offer names the classes it replaces and the start level (`max(1, best − level_cost)`, ADR 0003).
- Empty night: one morning page, "The System is silent." + the wake time.
- `is_open(page, gs)` is false for an offer that is gone (accepting a class can withdraw offers it excludes). The dialog skips those pages.

## Dialog — `ui/system_dialog.tscn/.gd` (`SystemDialog`)
- "Voice of the World" panel, dark blue with a light blue border, above everything else (canvas layer 4).
- Shows one page at a time. Accept → `Commands.accept_class`; Decline → confirm page ("This is permanent") → Yes → `Commands.decline_class`, or Back → the offer again. The System's answer is shown as a result page next.
- There is no skip: every offer gets an answer before the dialog closes. Enter presses the focused button.
- The debug console cannot open while the dialog waits (it could answer the offer behind the dialog's back).
- Buttons connect deferred (a button is freed while its own signal runs otherwise). Tests call `choose()` directly.

## Sleep and collapse — `world/main.gd`
- Z sleeps anywhere. A refused step, wait or use when a collapse is due runs the same sleep (a collapse). The dialog opens after every sleep.
- Map objects get an optional `"sleep": true` (schema change, user choice). The inn bed has it. `Interact.options` adds `"sleep"` to each option; the use menu adds "Sleep (end the day)" for it; `Interact.SLEEP` is not an action, so the UI calls `Commands.sleep`.
- `MapDb` checks that `sleep` is a bool. An object with `sleep: true` may have no actions.
- Console: `use <bed> sleep`; `look` lists `sleep` with the object's actions.
- A bed does not change the night yet (same as Z). Better rest in a bed can come later.

## Character sheet — `ui/character_sheet.tscn/.gd` (`CharacterSheet`)
- C opens it, C or Esc closes it. Read-only. Static `lines(gs, db)`: day, time, awake time, race, total level, classes (level, XP / next, breakthrough note), skills (from which class and level), focus, open offers, declined classes.

## Tests
- `unit_system_messages`: page order, empty night, offer choices, consolidation text, confirm and `is_open`, night sections, dialog accept / decline-confirm-back / skip withdrawn offers, sheet lines, beds (toy cot, real inn bed), console `use cot sleep`, main scene sleep in the bed → dialog → accept.
- `sim_m4_done`: the M4 "Done when" check through the main scene (gate → market with traders → inn, work, sleep in the bed, answer the first offer).

## Known issue: first offer pacing
With a plain inn workday (3 stews, sweep, clean room) the first offer ([Innkeeper]) comes on day 22, after 14 nights. In canon, Erin gets [Innkeeper] on her first night. The XP and threshold numbers (ADR 0002/0003) are not changed here. Balance is for a later pass (M6 vertical slice).

## Later
- The "thread of fate" kill warning (M5; no kill action exists in the world yet).
- First-day hints (M6).

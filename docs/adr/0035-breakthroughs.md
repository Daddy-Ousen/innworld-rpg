# ADR 0035: Breakthroughs (M22)

Status: accepted (2026-10-09). User picks: all three sources, a moment counts from the level before the capstone,
a vague hint.

## Problem
Levels 10 / 20 / 30 are capstones (DESIGN §3.4). `Levels.level_up` stops a class at 9 / 19 / 29 until the class id
is in `Progression.breakthroughs`. Only the debug console (`ClassSystem.grant_breakthrough`) adds it. So no class can
pass level 9 in play.

## Decision
A breakthrough is a key for one class and one capstone. It is earned by a moment, not by XP. Three sources give it.
All are pure functions of `GameState` and data: no RNG, no new save data (`breakthroughs` is already saved).

### When a moment counts
- Only while the class is at the level just under a capstone (9, 19 or 29) and has no key yet. The XP does not have to
  be full: the key is kept until the XP fills (`level_up` already uses a key that is there early).
- A moment at a lower level is lost. The key is used up when the capstone level is reached (today's code).
- Class loss erases the key (today's code).

### Source 1: hard moment (default, all classes)
One action record of the day passes when all of these hold:
- the record fits the class: `Tags.match_score(record.tags, class.tag_weights) >= min_match`;
- the outcome is not `fail`;
- at least `need` of these bars hold: `risk >= risk`, `duress >= duress`, `window >= window`
  (the record already stores `risk`, `duress` and the `xp_window` factor `window`).
`need` grows with the capstone: 1 for level 10, 2 for level 20, 3 for level 30.
Rules in `rules.json` `levels.breakthrough` (first numbers are guesses; M22.4 tunes them):
```json
"breakthrough": {
  "min_match": 0.5,
  "bars": {"risk": 0.6, "duress": 1.8, "window": 2.0},
  "need": {"10": 1, "20": 2, "30": 3},
  "hint": "Something must still test you as %s."
}
```
Duress 1.8 is 10 guests for the inn actions (1.0 at 2 guests, 2.0 at 12; cold multiplies), or 90 % HP lost
in a fight. Window 2.0 is an `xp_window`
of tier 2 or 3.

### Source 2: class trial (optional, per class)
`classes.json` gets an optional `breakthrough` block (schema change, approved by the user's pick):
```json
"breakthrough": {
  "hint": "Something must test you as an [Innkeeper].",
  "default": true,
  "trials": [
    {"action": ["serve_guests"], "outcome": ["success"], "min": {"duress": 1.8}, "at": [10]}
  ]
}
```
- A trial matches one record like a hook's `did` entry (`action`, optional `outcome`, optional `context`), plus
  optional `min` bars on `risk` / `duress` / `window`. Optional `at` limits it to some capstones (none = all).
- `default` (true when left out): the hard-moment rule still counts for this class. `false` = only the trials count.
- `hint` replaces the rules hint for this class.
M22.2 writes trials for the main class lines (inn, cook, warrior, runner, mage, scout, priest, crafter).

### Source 3: canon moment (hook result `boon`)
A canon event hook gets a new result `"then": "boon"` (schema change). When the player did the hook's deeds, the
event still runs as canon: outcome `done`, no drift. The hook's `effects` apply on top. The new effect key:
```json
"effects": {"breakthrough": {"tags": {"hospitality": 1.0}}}
```
or `{"class": "innkeeper"}`. With `tags`, the key goes to the held class that fits the tags best (ties: the class
gained first). The usual rule holds: the class must be at 9 / 19 / 29 without a key, or nothing happens.
`breakthrough` is only allowed in hook effects (the player must take part), never in an event's own `effects`.

### Night order
- Step 2 (`Night.resolve_xp`): feed the records, then check sources 1 and 2 for each held class at a capstone − 1
  without a key, then `level_up`. A class that reaches 9 tonight is not checked with today's records.
- Step 5 (director) may grant keys by source 3. Step 5b: `level_up` again for the classes that got a key in step 5,
  so the level comes the same night. Its lines join the progress lines.

### What the player sees
- When a class reaches 9 / 19 / 29: one hint line after the level line (class hint, else the rules hint with the
  class name). No numbers, no source named.
- When a key is earned: `Breakthrough: [Innkeeper] can grow past level 9.`
- Today's "needs a breakthrough" line and the character sheet note stay as they are.
- The debug console `breakthrough <class>` stays (it ignores the level rule).

## Built (M22.1, 2026-10-10)
- `core/breakthrough.gd` holds sources 1 – 3, the hint, the key line and `Breakthrough.validate` (rules, class
  trials, hook effects: classes and tags must exist). `Night.resolve_xp` checks each class before its `level_up`;
  `Night.resolve_canon_keys` is step 5b. Its lines go into `progress` and in `lines` right after step 2's lines.
- A `breakthrough` effect works in `change` and `boon` hooks. `CanonDb` refuses it in an event's own effects.
- With `tags`, the best-fitting held class is picked first; if that class is not waiting, nothing happens (no
  fallback to the next class).
- A `boon` history entry has `"boons": [hook ids]` and no `"by"`, so the journal does not list it as a change.
- A trial `outcome` left out matches every outcome (like a hook). The hard moment never counts a `fail`.
- Records from old saves have no `risk` / `duress` / `window`: they count as 0.0 / 1.0 / 1.0.

## Built (M22.2, 2026-10-10)
- Trials and a hint on `innkeeper`, `cook`, `warrior`, `runner`, `mage`, `scout`, `priest`, `carpenter` ("crafter" = carpenter). All keep `default` true. Trials need `outcome: success` and one `min` bar (risk 0.6, duress 1.8 or window 2.0). Numbers are guesses; M22.4 tunes them.
- Six `boon` hooks (each beside the event's own hook, same deeds): `b1.inn_first_regulars` (hospitality), `b1.klbkch_dies_defending_erin`, `b1.skinner_leads_the_dead_into_liscor` (combat), `b2.battle_at_the_wandering_inn` (combat), `b2.pawns_faith_crisis_earns_the_acolyte_class` (faith), `b3.the_last_battle_of_esthelm` (combat). `sim_player_hooks` hook count 68 -> 74.

## Not chosen
- A random chance per night: breaks the hidden but fair feel, and hard to test.
- Key by XP alone (no moment): the capstone would be only a bigger number.

## Steps
- M22.1 engine: `core/breakthrough.gd` (checks for sources 1 – 3), night steps 2 and 5b, the `boon` hook in
  `CanonDb` / `Director`, data checks in `DataDb` and `tools/validate_data.py`, messages. Tests: new
  `unit_breakthrough`, plus `unit_levels`, `unit_class_system`, `unit_night`, `unit_director`, `unit_canon_db`, validator,
  Python tool tests.
- M22.2 data: trials and hints for the main class lines; a few `boon` hooks on big canon moments (Books 1 – 3).
- M22.3 consolidation on top (redo 565bc9b). Built 2026-10-10: consolidation is automatic at night step 4 (no offer,
  no choice) once the player holds every `from` class, one of them is at level 10
  (`rules.offers.consolidation_min_level`) and the pool is full. So a source class must first pass its own level 10
  breakthrough. The source keys go with the source classes; the new class starts at `best − level_cost` and needs
  its own key at its next capstone. `ClassSystem.make_offers` lost its `kind` argument; `consolidate_ready` is new.
  An old save with a pending consolidation offer can still accept it.
- M22.4 probe sim: a busy player passes level 10 in one class within the Book 1 – 3 days.

## Probe result (M22.4, 2026-10-10)
`sim_breakthrough_probe` plays days 1 – 87 on three seeds (no RNG-sensitive result: all three agree within one night).
| Play style | Level 9 | Key | Level 10 |
|---|---|---|---|
| Busy inn worker (guests up to 20) | night 25 – 26 | night 26 – 27 | night 31 – 32 |
| Quiet inn worker (guests up to 4) | night 37 – 38 | night 73 | night 73 |
| Fighter (two Goblin fights a day) | night 13 – 16 | night 14 – 22 | night 17 – 22 |
- The busy worker has the key one night after level 9 (10 guests is duress 1.8 from day 8), so the gate costs a busy
  player nothing. The XP still takes 5 more nights. After level 10 the class keeps growing (level 16 on night 87).
- The quiet worker has no hard moment, so the key waits about 35 days for a Book 3 moment. The gate holds, and the
  player is not stuck for good.
- The fighter is the fastest by 10 nights or more. That is the M17.8 balance, not a breakthrough effect.
- Decision: the bar numbers stay (risk 0.6, duress 1.8, window 2.0). Levels 20 / 30 are not probed (Books 1 – 3 end at
  day 87 and the curve is far from them).

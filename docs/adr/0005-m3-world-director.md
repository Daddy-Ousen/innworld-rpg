# ADR 0005 — M3 world director

Date: 2026-09-23 · Status: accepted (plan approved by the user 2026-09-23)

## Canon data moves into the game
- `canon/events/` → `game/data/canon/` (user choice). The game can only read `res://`. One copy, no export step.
- `canon/raw/` stays outside `game/` (gitignored, copyrighted). The validator still finds it from the repo root.
- Layout per book is unchanged (ADR 0004): `game/data/canon/book<N>/{npcs,locations}.json`, `chapters/<ch>.json`.
- CLAUDE.md layout updated (rule 11: approved).

## Loader — `core/canon_db.gd` (`CanonDb`)
- `CanonDb.load_root("res://data/canon")` loads every `book*` folder (sorted) and merges them. New books add data, not code.
- `DataDb.load_dir()` sets `db.canon`; canon errors join `db.errors`. Toy dbs set `db.canon` by hand.
- Light checks only (unknown `depends_on` / `mutate:` / NPC ids, `on_fail` ends in `cancel`, cycles). `tools/validate_data.py` is the full check.
- Precomputed: `order` (Kahn topological sort; ties → `window.earliest`, then id), `dependents`, `alt_only` (every `mutate:` target; never scheduled on its own).

## State — `core/world_state.gd` (`WorldState`, `gs.world`)
- Stores only changes to canon defaults: NPC `alive` overrides, relationships `{from: {to: int}}`, event runtime `{status, day, roles, latest}`, `history`, `drift`, `last_day`.
- A missing event = `pending`; a missing NPC = its `alive_at_start`.
- `SAVE_VERSION` 3. Migration 2 → 3 adds `"world": {}` (the director catches up on the next night).

## Rules — `rules.json` `director` (rule 11: approved)
```json
"director": {"default_delay_limit": 3,
  "drift": {"substituted": 0.25, "mutated": 0.5, "cancelled": 1.0},
  "tier_weight": {"1": 0.5, "2": 1.0}, "unreliable_at": 5.0}
```

## Director — `core/director.gd` (night step 5)
- Runs for every day from `last_day + 1` to the day before the wake day (`Clock.wake_day`). A nap in the morning runs nothing; a collapse runs the skipped day.
- Per day: fire every due event that passes, repeat until nothing changes (same-day chains work even without `depends_on`); then resolve the due events that cannot wait; repeat.
- An event fires on the first night in its window when it passes.
- Failure kinds:
  - **wait** — missing flag, blocking `not_flag`, pending dependency. The event waits while `day < latest`.
  - **role** — a non-optional role has no living `prefer` NPC.
  - **hard** — a `requires.alive` NPC is dead, or a dependency is `cancelled`/`mutated`. Never waits.
- `requires.alive` is strict: substitution never covers it.
- Roles: first living `prefer` NPC not already in the event. A later `prefer` NPC is not a failure and adds no drift. Roles with empty `prefer` (monsters) are **anonymous** (`*<first tag>`) and never take a named NPC. Optional roles may stay empty.
- `on_fail` steps:
  - `substitute`: no hard failure. Each open role gets the living named NPC with the most `fallback_tags` (≥ 1; ties → lowest id). Remaining wait failures go on to the next step.
  - `delay`: only wait failures, and `latest < window.latest + delay_limit`. `latest += 1`; history `delayed` (no drift).
  - `mutate:<id>`: the alt event must pass now. Original → `mutated` (`via`), alt → `done`.
  - `cancel`: always last.
- Propagation: after `cancelled` or `mutated`, every pending dependent fails hard at once (recursive). Substitute and delay are skipped; mutate is allowed.
- Effects: `set_flags`, `clear_flags`, `kill`, `relationship`. A `kill`/`relationship` NPC id that a role replaced means the replacement.
- Drift = Σ `drift[outcome] × tier_weight[tier]`. One morning line when drift first crosses `unreliable_at`.
- A tier 1 event that runs adds `Rumor: <rumor>` to the morning summary.
- No RNG. All choices follow data order and ids (rule 3).

## Player hooks
- `Commands.kill_npc` (history `killed`, `player.kill`) and `Commands.set_flag`. Console: `kill`, `flag`, `history`, `drift`.
- M4 interactions and M5 combat will call these. Only the core changes state (rule 1).

## Tests
- `unit_canon_db`, `unit_director` (toy data), `sim_divergence` (the three ROADMAP scenarios + baseline + determinism), `sim_canon_book1` (real data: days 1–7 with no input → every event `done`, drift 0).

## Later
- Off-screen NPC sim and goals (M4). "Thread of fate" warning before a kill (M4/M5 UI). The player filling canon roles. Monster populations for anonymous roles.

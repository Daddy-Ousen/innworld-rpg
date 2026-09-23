# ADR 0003 — M1 class system, levels, skills, night pipeline

Date: 2026-09-23 · Status: **proposed** — the data/schema items marked (ASK) need the user's OK (CLAUDE.md rule 11).

## State (`GameState`, save version 2)
- New fields: `race` ("human" for Earthers), `flags` (world flags; class prereqs now, canon events in M3), `progression`, `morning` (last night's System messages).
- `Progression` (`core/progression.gd`) holds: `pools`, `classes` (id → level, xp, last_active_day, in the order gained), `skills`, `declined`, `lost`, `offers`, `breakthroughs`, `day_start`.
- (ASK) `SAVE_VERSION` 1 → 2 with `SaveMigrations._migrate_1_to_2` (a v1 save becomes an Earther with no class). Tested.
- Action records get one more field: `skill_mult`.

## Class pools
- Each night, each record of the day adds `xp × Tags.match_score(record.tags, class.tag_weights)` to the pool of every class the player does not hold and did not decline.
- Pools are **not** zero-sum: one record can fill several pools. So adding classes to the data does not slow the others.
- **Decline** blacklists the class id for good. Its pool is frozen. "The XP keeps flowing to related classes" holds on its own: related classes fill from the same tags. (Tested in `sim_decline`: declined [Warrior], later got [Guardsman].)

## Offers (night steps 3 and 4)
- A class is ready when `pool ≥ offer_threshold` and `can_offer` is true: not held, not declined, not already offered, prereq classes held, prereq flags set, no `excludes` conflict (both ways), race allowed.
- Best-filled pool (pool / threshold) first; ties keep data order. At most `offers.max_per_night` new offers per night, shared by normal and consolidation offers.
- Offers stay open until the player answers. An offer that a newly accepted class excludes is withdrawn (not blacklisted).
- **Accept** → level 1, XP 0, and `skills.on_accept` skills at once.
- **Consolidation** classes are offered only in step 4, when all `from` classes are held and the pool is full. Accept → the `from` classes are removed; new level = `max(1, best from level − level_cost)`; skills stay.

## Levels and dilution
- Cost from level L to L+1: `base_xp × growth^(L−1)`.
- (ASK) Tuning: `levels.base_xp` 100 → 60. With 100, the 30-day script reached only [Innkeeper] 3. With 60 it reaches [Innkeeper] 5 and [Cook] 2.
- **Dilution:** per record, `m_c` = match score for each held class. The best match decides how much XP counts: `min(1, max m)`. That amount is split by `m_c / Σ m`. One class → `xp × m`. Two classes that fit the same work → each gets less.
- **Capstones** (10/20/30): the level waits for a breakthrough (`ClassSystem.grant_breakthrough`, used by canon events in M3 and by the debug console). XP keeps building while blocked. The night says so once.
- Class XP is spent at night only.

## Skills
- Candidates: skills with a pool entry for the class whose level band has the new level, not held.
- Weight = `pool.weight × (skills.base_weight + affinity)`. Affinity = share of the player's lifetime tag XP that fits the skill's `tag_affinity`.
- A normal level gives a skill with chance `skills.chance_per_level`. A capstone always gives one and prefers rare skills.
- Only `xp_mult` is applied now: `skill_mult = Π (1 + (value − 1) × overlap)`, in the XP formula. `stat_mod`, `action_unlock` and `passive_trigger` are validated and stored; they do nothing until stats and action gates exist.
- (ASK) New `rules.json` section: `"skills": {"on_accept": 1, "chance_per_level": 0.75, "base_weight": 0.1}`.

## Class loss (night step 4)
- A held class with `loss` is active on a day when a record with XP matches its `neglect_tags`.
- `today − last_active_day ≥ neglect_days` → the class loses 1 level per night (XP reset). At 0 it is lost: moved to `lost`, its pool starts from 0. A lost class can be offered again (a declined one cannot).

## Night pipeline (`core/night.gd`)
1. `close_day`: records with `time ≥ day_start`; then `day_start = now`.
2. `resolve_xp`: feed records → level-ups (classes in the order gained) → a skill roll per level.
3. New offers.
4. Loss, then consolidation offers.
5–7. Not yet (M3+).
8. `clock.sleep(rules, collapsed)`; messages go to `gs.morning`.
`Commands.sleep` makes it a collapse when the player is past the awake limit.

## Commands and console
- `core/commands.gd` is the only door for presentation: perform, sleep, knock_out, accept/decline, set_focus, grant_breakthrough.
- `ui/console_commands.gd` (headless, tested) parses text; `ui/debug_console.tscn` is the main scene until M4.

## Data
- `data/classes.json`: 17 classes. `data/skills.json`: 47 skills. Every class has skills.
- `canon_ref.chapter` may be `null` when the chapter is not known. Only [Innkeeper] is `confirmed` (1.00). [Basic Cleaning] and [Basic Cooking] are `likely` for 1.00. Most others are `likely` (the class name exists in the series) or `guess`. **M2 must check these against the Book 1 ebook.**
- Tag weights, thresholds and skill effects are game rules, not canon.

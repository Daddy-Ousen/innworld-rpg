# ADR 0002 — M1 data schemas (actions, tags, classes, skills, rules)

Date: 2026-09-23 · Status: accepted (user approved 2026-09-23: outcome_mult yes, tags.json yes)

## Common rules
- Each data file is a JSON object with `"schema_version": 1` and one map keyed by id.
- Ids are lowercase snake_case. Tags are lowercase, dotted (`cooking.stew`).
- Display names hold the brackets: `"[Innkeeper]"`, `"[Basic Cooking]"`.
- Canon content (classes, skills) has `canon_ref` and `confidence` (`confirmed` | `likely` | `guess`). Actions are game rules, not canon, so they have none.

## `data/tags.json` — tag registry
```json
{
  "schema_version": 1,
  "tags": {
    "cooking": "Making food.",
    "cooking.stew": "Slow-cooked pot food.",
    "hospitality": "Serving guests."
  }
}
```
- Every tag used anywhere must be in this list. The parent of a dotted tag must also be in it.
- Matching: a class/skill weight on `cooking` also matches `cooking.stew`. The most specific key wins.

## `data/actions.json`
```json
{
  "schema_version": 1,
  "actions": {
    "cook_stew": {
      "name": "Cook a stew",
      "minutes": 60,
      "base_xp": 10,
      "risk": 0.0,
      "tags": {"cooking.stew": 1.0},
      "context": [
        {"key": "guests", "min": 10, "add_tags": {"hospitality": 0.5}},
        {"key": "location", "equals": "inn", "add_tags": {"hospitality": 0.2}}
      ]
    }
  }
}
```
- `tags`: relative weights. After context rules add tags, weights are normalised to sum 1.0.
- `risk`: 0.0–1.0 base danger. The caller may pass a higher value (real combat).
- `context`: rules checked against a context dictionary the caller passes. A rule has `key` plus one of `min` / `max` / `equals`, and `add_tags` and/or `add_risk`.

## Action record (runtime, lives in `GameState`)
```json
{"time": 3420, "day": 3, "minute": 540, "action_id": "cook_stew",
 "tags": {"cooking.stew": 0.67, "hospitality": 0.33},
 "intensity": 1.0, "risk": 0.0, "novelty": 0.74, "conviction": 1.0,
 "outcome": "success", "witnesses": ["relc"], "xp": 7.4}
```

## `data/rules.json` — tunables (numbers only, no content)
```json
{
  "schema_version": 1,
  "clock": {"start_minute": 360, "wake_minute": 360, "min_sleep_minutes": 240,
            "collapse_after_awake": 2160, "collapse_sleep_minutes": 720},
  "xp": {
    "intensity_min": 0.25, "intensity_max": 3.0,
    "risk_scale": 3.0,
    "outcome_mult": {"success": 1.0, "partial": 0.75, "fail": 0.5},
    "novelty": {"window_days": 7, "half_life_days": 2.0, "k": 0.35, "floor": 0.1, "first_time_bonus": 1.5},
    "conviction": {"match_mult": 1.25}
  },
  "levels": {"base_xp": 100, "growth": 1.35, "capstones": [10, 20, 30]},
  "offers": {"max_per_night": 2}
}
```

## XP formula
`xp = base_xp × intensity × risk_mult × novelty_mult × conviction_mult × outcome_mult`
- `intensity`: from caller, clamped to `[intensity_min, intensity_max]`.
- `risk_mult = 1 + risk_scale × risk` → 1.0 (safe) to 4.0 (deadly).
- `novelty_mult`: `w = Σ 0.5^(age_days / half_life_days)` over earlier records of the same `action_id` in the last `window_days`. `novelty = max(floor, 1 / (1 + k × w))`. First time ever: × `first_time_bonus`.
- `conviction_mult = 1 + (match_mult − 1) × overlap`. `overlap` = share of the record's tag weight that matches the player's declared focus tags (0–1). No focus → 1.0.
- `outcome_mult`: failing still teaches, at half rate.

## Clock
- The clock stores one counter: `total_minutes` since the game started (it never goes back), plus `awake_minutes`.
- `day = total_minutes / 1440 + 1` and `minute = total_minutes % 1440` are derived. So `day` is the calendar day, and canon windows use it.
- Sleep → wake at the next `wake_minute`. If that is less than `min_sleep_minutes` away, wake after `min_sleep_minutes`. The night can span more than one calendar day if the player stayed up (the pipeline gets `days_passed`).
- `awake_minutes ≥ collapse_after_awake` (36 h) → forced collapse: sleep for `collapse_sleep_minutes`, and `last_sleep_collapsed = true` goes into the night.
- A new action is refused while a collapse is due.
- Changed from the first draft (time could run backward after a late night): `collapse_wake_minute` → `collapse_sleep_minutes`; added `start_minute`, `min_sleep_minutes`.

## Saves
`GameState.to_json` writes floats at full precision, so XP totals are exact after a load.

## `data/classes.json` (built in M1 part 2)
```json
{
  "schema_version": 1,
  "classes": {
    "innkeeper": {
      "name": "[Innkeeper]",
      "tag_weights": {"hospitality": 1.0, "cooking": 0.6, "cleaning": 0.5, "commerce": 0.3},
      "offer_threshold": 300,
      "prereqs": {"classes": [], "flags": []},
      "excludes": [],
      "race_limits": null,
      "loss": {"neglect_days": 30, "neglect_tags": ["hospitality"]},
      "consolidation": null,
      "canon_ref": {"book": 1, "chapter": "1.00", "confidence": "confirmed"}
    }
  }
}
```
- `race_limits`: `null` = any race, or `{"allow": ["human"]}`.
- `consolidation`: `null`, or `{"from": ["warrior", "strategist"], "level_cost": 2}`.

## `data/skills.json` (built in M1 part 2)
```json
{
  "schema_version": 1,
  "skills": {
    "basic_cooking": {
      "name": "[Basic Cooking]",
      "rarity": "common",
      "pools": [{"class": "innkeeper", "min_level": 1, "max_level": 9, "weight": 1.0}],
      "tag_affinity": {"cooking": 1.0},
      "effects": [{"type": "xp_mult", "tags": ["cooking"], "value": 1.1}],
      "canon_ref": {"book": 1, "chapter": "1.00", "confidence": "guess"}
    }
  }
}
```
- Skills name their pools, so a new skill never edits `classes.json`.
- `tag_affinity` × the player's tag history = pick weight ("needs and desires").
- Effect types: `stat_mod` {stat, value}, `action_unlock` {action}, `xp_mult` {tags, value}, `passive_trigger` {trigger, special}. `special` names a script in `core/skills/special/`.

## GameState
`data` placeholder is replaced by typed fields: `clock`, `action_log` (only the last `window_days` of records), `action_counts` (lifetime count per action id), `tag_totals` (lifetime XP per tag), `focus_tags`. `SAVE_VERSION` stays 1: no save file is in use yet.

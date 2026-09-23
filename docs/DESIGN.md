# Innworld RPG — Design

> The books define how the world begins. The player decides what happens next.

## 0. Pillars
1. **You level by living.** Every meaningful action feeds the System. Classes come from behaviour, not a menu.
2. **Nights move the world.** Sleep is the commit point: levels, offers, world events, next day.
3. **Canon is the default, not a rail.** The Book 1 timeline runs if you do nothing. Your actions bend it.
4. **Simulation first, graphics second.** A top-down 2D skin over a headless sim.

Reference games: Caves of Qud, Elona, Warsim, Roadwarden, Stardew Valley (day loop).

## 1. Presentation and combat
- 2D top-down, 16×16 or 32×32 tiles, a lot of text. Portraits optional.
- Combat is **turn-based on the same map grid** (Qud-style), not a separate battle screen. Less UI, and combat reuses movement and interaction code.
- Combat is one activity among many. A non-fighter must be able to progress.
- **No permadeath / no roguelite runs.** The game is a persistent alternate history. Death = game over with a save reload, or a "rescued" outcome for some fights.

## 2. Time
- In-day clock in minutes. Every action costs time.
- Day ends when the player sleeps **or is knocked unconscious** (both are canon level-up triggers).
- Forced collapse after ~36 h awake. The player cannot freeze the world by staying awake.
- **Night resolution pipeline** (fixed order, each step is a pure function over `GameState`):
  1. Close the day's action log.
  2. XP resolution → level-ups → skills.
  3. Class offers (accept/decline prompt, shown as the Voice of the World).
  4. Class loss / consolidation checks.
  5. World director: evaluate canon events, fallbacks, propagation.
  6. Off-screen simulation (NPCs, factions, economy), at low detail.
  7. Relationship and reputation decay/updates.
  8. Advance to Day + 1. Build the morning summary (messages, rumors).

## 3. The System (classes, levels, skills)
### 3.1 Actions and tags
- Every action emits a record: `{action_id, tags[], intensity, novelty, risk, outcome, witnesses[]}`.
- Tags are fine-grained (`cooking.stew`, `blade.parry`, `running.escape`, `commerce.haggle`).
- `data/actions.json` defines base tags per action. Context adds tags (e.g. cooking *for* 20 guests adds `hospitality`).

### 3.2 XP formula (tunable)
`xp = base × intensity × risk_mult × novelty_mult × conviction_mult`
- **novelty_mult** falls with repetition of the same action in a short window (canon: you must challenge yourself). Recovers over days.
- **risk_mult** spikes for real danger (surviving Rock Crabs gives far more than chopping wood).
- **conviction_mult**: the player can declare a focus ("I want to be an innkeeper") in the journal. Canon says classes need mental commitment. This is the hook.

### 3.3 Class candidates and offers
- Each class in `data/classes.json` has `tag_weights`, `offer_threshold`, `prereqs`, `excludes`, `race_limits`.
- XP flows into hidden candidate pools by tag weight.
- At night, pool ≥ threshold → offer. Max 1–2 offers per night (drama, readability).
- **Decline = permanent blacklist of that exact class id.** The XP for that pool is not lost; it keeps flowing to related classes.
- Earthers start with no class and level 0.

### 3.4 Levels
- Cost per level grows exponentially. Levels 10/20/30 are capstones (rare skill, needs a "breakthrough" event, not only XP).
- **Multi-class dilution:** XP is split across accepted classes by tag match. More classes → slower each. No hard cap; the curve does the work.
- Class loss: acting against a class (e.g. `[Innkeeper]` who abandons the inn for 30 days) drains it; at 0 the class is lost.
- Consolidation/advancement: rules in data (`[Warrior]` + `[Strategist]` → `[Commander]`), offered at night, can cost levels.

### 3.5 Skills
- Skill pools per class and level band. Choice is weighted by the player's tag history ("needs and desires").
- Skills are data with typed effects (`stat_mod`, `action_unlock`, `xp_mult`, `passive_trigger`). No bespoke code per skill unless unavoidable; those go in `core/skills/special/`.

## 4. Canon and divergence
### 4.1 Two timelines
- **Canon state:** what happens if the player does nothing. Stored as event data.
- **Emergent state:** what actually happened. Stored in `GameState.history`.
- **Drift** = weighted count of canon events changed/cancelled. Shown to the player. At high drift the game says canon knowledge is unreliable.

### 4.2 Event tiers
| Tier | What | How it runs |
|---|---|---|
| T1 Distant | Events far away (Rhir, Baleros, Wistram) | Happen as canon unless a causal chain from the player reaches them. Player learns via rumors/news. |
| T2 Local canon | Events near the player (Floodplains, Liscor) | Event nodes with roles, preconditions and fallbacks. |
| T3 Emergent | Small daily life | NPC goals and schedules; no script. |

### 4.3 Event node schema (sketch)
```json
{
  "id": "b1.example",
  "tier": 2,
  "window": {"earliest": 20, "latest": 26},
  "location": "liscor",
  "roles": {"defender": {"prefer": ["relc"], "fallback_tags": ["guard", "drake", "senior"]}},
  "requires": {"alive": ["relc"], "flags": ["liscor.walls_intact"], "not_flags": []},
  "depends_on": ["b1.earlier_event"],
  "on_fail": ["substitute", "delay", "mutate:b1.example_alt", "cancel"],
  "effects": {"set_flags": [], "kill": [], "relationship": []},
  "canon_ref": {"book": 1, "chapter": "1.12", "confidence": "confirmed"},
  "summary": "Short summary in our own words."
}
```

### 4.4 Director algorithm (per night)
1. For each due event: check `requires`.
2. Pass → run it, apply effects, log to history.
3. Fail → try `on_fail` in order:
   - **substitute**: fill the role with the best living NPC by `fallback_tags`.
   - **delay**: move the window forward (limit applies).
   - **mutate**: run the alternate event.
   - **cancel**: mark cancelled.
4. Cancel → walk `depends_on` in reverse and re-check every downstream event (propagation).
5. Add drift.

### 4.5 NPCs
- Canon NPCs have: goals, schedule, relationships, faction, knowledge flags, class/level.
- Behaviour: **utility AI** (score a few goals, pick the best), not an LLM.
- **Simulation level of detail:** full sim near the player, coarse daily rolls off-screen, pure canon for T1.
- NPCs can level and gain classes via the same system at low resolution.
- A saved canon NPC who "should" be dead gets a generic goal set, plus hand-written goals for major characters when content exists.

### 4.6 Player freedom
- Anyone can be killed. No essential flags.
- On killing a major NPC: a one-time warning with a short delay ("the thread of fate…" style). Then the director patches the story.
- The player can leave the start region, but content density is highest near Liscor in Book 1.

## 5. AI inside the game
- **v1: none.** All state changes are deterministic code + data.
- Later (optional): LLM for rumors, flavour text, or free-text dialogue. Rule: LLM output never changes `GameState` directly; it can only pick from actions the engine offers.

## 6. Content pipeline (canon → data)
1. `tools/extract_epub.py` splits the Book 1 ebook into chapter text in `canon/raw/book1/`.
2. An agent reads one chapter at a time and proposes events, NPCs, locations and classes seen, as JSON with `canon_ref` and `confidence`.
3. A human reviews and commits to `game/data/canon/book1/` (moved from `canon/events/` in M3, ADR 0005).
4. Days: the book gives few exact dates. We set **windows**, not fixed days. Mark guesses.

## 7. Known risks
- Scope creep ("do anything"). Mitigation: vertical slice first, T1/T2/T3 tiers, level-of-detail sim.
- Lore drift from agents. Mitigation: `canon_ref` + `confidence` on every canon record; human review.
- Save breakage. Mitigation: versioned saves + migrations from day one.
- Art. Mitigation: one paid/free tileset (e.g. Kenney, a 16×16 fantasy pack); no AI art mixing styles.
- Legal. Free, non-commercial, no book text shipped. Check pirateaba's stance before public release.

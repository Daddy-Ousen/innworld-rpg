# ADR 0044 — Player audit work (M29 – M33)

Date: 2026-10-17 · Status: proposed. Merging the plan PR approves the order and the milestones. Each schema or
save change below is still asked at the start of its step (CLAUDE.md rule 11).

## Context
The player audit of 2026-10-17 (`docs/AUDIT_PLAYER_2026-10-17.md`) played v0.1.5 and ran all 8 books headless.
The canon backbone, the night System and the Book 1 – 5 fights work. A book reader will still miss the world in
their head: NPCs have no voice, the story arrives as next-day news, nobody reacts to an Earther, the Book 6 – 8
climaxes are off screen or ignore the player, and some lore slips show in the first minutes.
The user said (2026-10-17): "We will do all."

## Decisions
- **Five milestones, in this order:**
  1. **M29 Lore polish** (small, fast): book-style System lines, the inn's name and signs by flag, no generic
     guests before the inn has regulars, Human distrust in Liscor, art fixes, an end-of-story page, the fight view.
     First because it fixes what a reader sees in the first five minutes, and the System text change touches
     strings that later milestones add to. Plan: `docs/plans/m29.md`.
  2. **M30 Voices and the Earther** (the biggest gain): own lines and talk options for the main cast, barks,
     the "you're from Earth too?" meeting with Erin, and character creation. Plan: `docs/plans/m30.md`.
  3. **M31 Signposts and scene beats:** talk of the town before each big day; scenes that play several lines.
     Uses the M30 speech bubbles. Plan: `docs/plans/m31.md`.
  4. **M32 Climaxes of Books 6 – 8:** Calruz and the Horns in the three-door battle, hooks on every Book 8
     stage, Zel's last stand, boss abilities. Plan: `docs/plans/m32.md`.
  5. **M33 Depth:** canon spells, Erin's dishes, a quest engine and personal quest lines, friendship perks.
     Plan: `docs/plans/m33.md`.
- **One branch + PR per sub-step,** as before. Model tags `[Model · effort]` on each roadmap step.
- **Own words only (rule 10).** Voice lines, beats and signposts are short lines we write. No quotes from the
  books, not even catchphrases word for word. A line may echo a trait the books show (Relc hates "lizard").
  Each data file with lines has `confidence` and a `canon_ref` where a line rests on a book fact.
- **Determinism (rule 3).** A line that changes state (a talk, a quest step) picks with `gs.rng`. A bark that is
  only shown (a bubble over a head) must not touch `gs.rng`: the view picks it by a stable hash of
  (day, NPC id, minute bucket). Barks never change `GameState`.
- **Spoilers.** A signpost says what townsfolk could know before the day (a raid is planned, the dead are
  restless, the moons are nearly full), and where and when to be. It never says the outcome.
- **Headless core (rule 1).** New logic (`Voice`, foreshadow, beats, quests) lives in `game/core/` as
  `RefCounted`. Bubbles and the creation screen are presentation.

## Schema and save changes proposed (each asked at its step)
| Step | Change | Save |
|---|---|---|
| M29.1 | canon location: optional `names` `[{flag, name}]` (the inn's name by flag) | no |
| M29.1 | `rules.inn`: optional patron gate by flag (no generic patrons before the inn has regulars) | no |
| M29.2 | `rules.standing`: optional `race_regard` (start regard and price by NPC race toward a Human, per town) | no |
| M29.4 | `rules.director`: end-of-story page text (or computed from the last canon day) | no |
| M30.1 | new `data/voices.json` (per NPC: greet by band, idle, lines by flag, talk options) | no |
| M30.5 | player name, look and Earth background | v22 + migration |
| M31.0 | event field `foreshadow` and stage field `beats` | no (beat index lives in `combat.stage_run`; check at the step) |
| M32.1 | enemy field for a boss who yields (not killed) if `flee_below` is not enough | no |
| M33.0 | new spell effect kinds (for example blink, light) only if needed | maybe |
| M33.2 | new `data/quests.json` and quest state | v23 + migration |

## M29.0 (2026-10-17): the System's lines
- One core helper, `core/system_voice.gd` (`SystemVoice`), builds every System line. Data names keep their
  brackets ("[Innkeeper]"); the helper takes them off and frames the whole line.
- From the books: "[Innkeeper Level 2!]", "[Skill – Basic Cooking obtained!]", "[Innkeeper Class Obtained!]"
  then "[Innkeeper Level 1!]", "[Conditions Met: Cook, Server → Innkeeper Class!]" (consolidation).
- Our own, in the same frame (no book line found): "[X Class Offered!]" (offer page title "[Class Offered]"),
  "[X Level 3 → Level 2.] It fades from neglect.", "[X Class Lost.]", "[Breakthrough: X can grow past Level 10!]".
- Plain prose stays for hints and how-to lines ("If you decline, it is never offered again.").
- The action `talk_with_guest` shows "Talk". The id is unchanged, so records, hooks and saves still work.
- No schema change, no save change.

## M29.1 (2026-10-17): the inn's name, signs and first guests
User picks (rule 11): names by flag, and two optional guest rules.
- Schema: optional `names: [{flag, name}]` on a canon location. `CanonDb.location_name(flags, id)` gives the
  last entry whose flag is set, else `name`. The HUD, the knock-out page and the console `where` use it. The
  validator checks it. The inn: "The abandoned inn on the hill" until `wandering_inn.named` (1.18, day 13 in our
  data), then "The Wandering Inn".
- Signs (data only): the door sign says "Inn"; a plaque "The Wandering Inn" (`inn_name_sign`) shows from
  `wandering_inn.named`; the No Killing Goblins board from `wandering_inn.no_killing_goblins_sign`.
- Schema: optional `rules.inn.patron_flags [flag]`: no patron comes until ANY of these flags is set (any, not all,
  so one cancelled event does not keep the inn empty forever). Canon NPC guests are not gated. Data:
  `wandering_inn.has_regulars` (new flag on `b1.inn_first_regulars`, 1.21, day 15) and `wandering_inn.full_house`.
- Schema: optional `rules.inn.race_flags {race: flag}`: a race weighs 0 while its flag is not set. Data: Goblin
  patrons (weight 2, a guess) from `goblin_tribe.paying_guests` (1.25, day 19). Goblins stay a patron race after
  that; later books may want to clear or boycott it.
- Save v21 -> v22 (user pick): an old save in which `b1.inn_first_regulars` already ran (done, substituted or
  changed) gets `wandering_inn.has_regulars` on load, so its patrons keep coming.

## M29.2 (2026-10-18): Liscor is wary of Humans
User pick (rule 11): regard and shop price. Schema: optional `rules.standing.race_regard`
`[{town, race, start, fade, price?, shops?, except?}]`.
- An NPC of `race` whose `home` is in `town` (and not in `except`) gets `start` added to their regard
  (`Standing.race_start`, used by `regard`, so bands, greetings and "friends fight" all see it).
- The shops in `shops` charge `price` more on BUY only (`Standing.shop_markup`, used by `Economy.price`
  before the town's reputation shift). What the shop pays is unchanged.
- Both shrink linearly with the player's reputation in `town`: full at 0 or below, gone at `fade`.
- Data (all guesses): Liscor Drakes start at -3 ("wary"), fade 10; `lism_stall` +15%. Excepted: `relc`,
  `olesm`, `selys` (friendly to Erin in Books 1 – 2). Gnolls and Krshia: no change.
- No save change. The gate-guard stranger line waits for M30.

### M29.3 – M29.5 (2026-10-18)
- Looks: Magnolia `all.lpcr.pink` dress and skirt, Erin a green T-shirt (guess). New optional look key `scale`
  (user pick): `CharacterSprite.scale_for` reads it from `appearance.json`; the sprite scales around its feet and
  `head()` moves the label. Moore 1.35. The sheet tool ignores the key. Antinium art: later, its own step.
- End of the story: `CanonDb.last_day()`; `Night.run` sets flag `story.end_shown` once the director has passed it
  and returns `story_end`; `SystemMessages` adds the page "The Story So Far" (text is a const, no rules key).
- Fight view: `WorldView.FIGHT_LIFT` (60 px) moves the camera offset down while `combat.has_fight()`.

## Consequences
- More text in data. The validator and `tools/tests` grow a check for each new file.
- More hooks and stages raise the cascade risk. Each canon change keeps `sim_canon_book<N>` at drift 0 and the
  book's kill sim green.
- Book text reading (Zel's last stand, Calruz, beats, spells, recipes) goes to reading agents (CLAUDE.md
  "Context discipline"); only summaries reach the main session.

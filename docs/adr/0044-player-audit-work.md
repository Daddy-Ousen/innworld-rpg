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
| M30.1 | new `data/voices.json` (per NPC: greet by band, idle, lines by flag, talk options); `rules.voice` | no |
| M30.5 | player name, look and Earth background | v23 + migration (v22 went to M29.1) |
| M31.0 | event field `foreshadow` and stage field `beats` | no (checked: "beat" in `combat.stage_run`, tolerant read) |
| M32.1 | enemy field for a boss who yields (not killed) if `flee_below` is not enough | no |
| M32.4 | none expected: the Zel bend uses `requires`, `mutate:` alts and flag hand-offs (ADR 0036) | no |
| M33.0 | new spell effect kinds (for example blink, light) only if needed | maybe |
| M33.2 | new `data/quests.json` and quest state | v24 + migration (if M30.5 takes v23) |

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

## M30.0 (2026-10-18): voices, talk options and barks
User picks (rule 11): the plan schema with talk options, the 15-NPC Book 1 cast, short lines in our own words,
barks as planned.

### `data/voices.json` (new, one object per canon NPC id)
```
"relc": {
  "confidence": "guess",                       // required: confirmed | likely | guess (DataDb.CONFIDENCE)
  "canon_ref": {"book": 1, "chapter": "1.04"}, // optional: where the trait shows
  "greet": {                                   // optional; keys: "stranger" (the "" band) or a band label
    "stranger": ["..."], "wary": ["..."], "acquaintance": ["..."], "friend": ["..."], "close friend": ["..."]
  },
  "idle": ["..."],                             // optional: map barks (view only)
  "lines": [                                   // optional: said on a talk while the gate passes
    {"text": "...", "flags": ["..."], "not_flags": ["..."], "days": [a, b], "min_band": "acquaintance"}
  ],
  "options": [                                 // optional: own rows in the NPC's talk menu
    {"id": "spar", "label": "Ask Relc to spar", "action": "weapon_practice",
     "context": {...}, "flags": ["..."], "not_flags": ["..."], "days": [a, b], "min_band": "acquaintance"}
  ]
}
```
- Gate fields (`flags` all set, `not_flags` none set, `days` [from, to] inclusive, `min_band`) work as in
  `data/talk.json`. `min_band` means regard at or above that band's minimum in `rules.standing.bands`.
- `greet` key `stranger` is the band with label "". A band with no key uses the generic band line, as today.
- An NPC with no entry, or an entry with no `greet`, behaves exactly as before M30.
- Text in square brackets is an action, not speech: "[Toren rattles.]", "[Mrsha waves her paws.]".

### `rules.voice` (new, optional)
`{"confidence": "guess", "bark_tiles": 4, "bark_minutes": 20, "max_words": 20, "line": "%s: \"%s\""}`.
No `rules.voice` = no voice lines and no barks (toy dbs stay as they are).

### Talk (core, `core/voice.gd`, M30.1)
- First talk of the day (`NpcSim.note_talk` is true): the greet line is the NPC's own line for the current band,
  else the generic band line. Then one own `lines` entry whose gate passes; if there is none, a talk topic as
  today (`TalkTopics.line`). So one talk adds at most two log lines.
- Picks inside a list use a stable hash (own FNV-1a over "day|npc|kind"), not `gs.rng`. Reason: a voice must
  not shift the RNG stream, so canon sims and balance sims keep their numbers (drift 0).
- Own options: `Interact.options` gives an NPC row a `voice` list `[{id, label}]` of options whose gate passes.
  The menu pick is `"voice:<option id>"` (`Interact.VOICE`). `Interact.perform` runs the option's `action` with
  the NPC context, then the option's `context` merged on top. Everything else (witness, +1 relationship, greet) is
  the same as a normal talk. The generic rows (Talk, Persuade, Comfort, Attack, Learn) stay after the own rows.
- No new state: a line or option is never marked "said". `days` windows and flags keep one-time lines short-lived.
  M30.4 (the Earther talk) sets its own flag with an action effect, so it needs no voice state either.

### Barks (view only, `world/view_markers.gd`, M30.1)
- A bubble over an NPC with `idle` lines who is within `bark_tiles` (Chebyshev distance) of the player.
- Bucket = minute of day / `bark_minutes`. One bark per NPC per bucket, line = hash("day|npc|bucket") over `idle`.
  Shown when the bucket changes or the NPC comes into range; it fades after a few seconds (real time).
- Never in a fight, never during a night page, never for a dead or hidden NPC. Never reads or writes `gs.rng`
  or any state. Headless tests can check the pure pick `Voice.bark(db, day, npc, minute)`.

### Tone rules (all voice text)
- Our own words. No book quotes, no catch phrases copied from the text (rule 10).
- Short: under about 15 words; the validator refuses more than `max_words` (20).
- 2 – 3 lines per band, 3 – 5 idle lines. Swearing only as mild as the character (Relc mild).
- Each NPC entry is `confidence: guess` unless a reading agent finds the trait in the Book text.
- Rags speaks few, simple words; Toren and Mrsha act in brackets.

### Validator (`tools/validate_data.py` and `DataDb`, M30.1)
NPC ids exist in any `canon/book<N>/npcs.json`; greet keys are `stranger` or band labels; every text is a
non-empty string of at most `max_words` words; option ids are unique per NPC; `action` is in `actions.json`;
`min_band` is a band label; `days` is [from, to] with 1 <= from <= to.

### First cast (M30.2, Book 1, 15)
Erin, Relc, Klbkch, Pisces, Olesm, Selys, Krshia, Zevara, Lism, Ryoka, Ceria, Pawn, Rags, Toren, Beilmark.
Ids (checked): `erin_solstice`, `relc`, `klbkch`, `pisces`, `olesm`, `selys`, `krshia`, `zevara`, `lism`,
`ryoka_griffin`, `ceria_springwalker`, `pawn`, `rags`, `toren`, `beilmark`. Options: Erin (ask for work, chess, ask about the inn), Relc (spar), Pisces (magic), Olesm (chess), Krshia
(trade talk). Ryoka gets lines only (she never levels; no class talk).

### M30.1 (2026-10-18): built as designed
- `core/voice.gd` (`Voice`): `greet`, `line`, `lines_now`, `options`, `option`, `bark`, `bark_bucket`, `say`,
  `pick` / `hash32` (FNV-1a 32 bit), `passes`, `band_min`, `validate`. `DataDb.voices` from `data/voices.json`
  (empty `{}` now; the cast comes in M30.2). `rules.voice` added to `rules.json`; toy dbs erase it.
- `Interact`: NPC rows carry `voice`; pick `Interact.VOICE + id`; `Interact.action_of` gives the real action
  (used by `world/main.gd` for the sound and the log name). The use menu lists own rows before the generic ones;
  the console `look` lists `voice:<id>` and `use <npc> voice:<id>` works.
- Bubbles: new `world/view_bubbles.gd` (`ViewBubbles`, layer "Bubbles" in WorldView), fed from `refresh(gs, db)`.
  Barks show only after a command (time only moves then). A night page shows no new barks (no time passes).
- Python: `validate_data.py --all` also checks `voices.json` (`check_voices`, `validate_voices`). No copy check
  against book text for voices yet (they have no chapter); the tone rule and review cover it.

### M30.2 (2026-10-18): the Book 1 cast
- `data/voices.json` has the 15 entries (all `confidence: guess`): 2 lines per band for stranger, acquaintance,
  friend, close friend (more for "wary" where the NPC starts wary: Liscor Drakes Zevara and Lism, M29.2), 4 – 5 idle
  barks, 3 – 8 flag lines each. Toren speaks only in brackets. Ryoka, Klbkch, Zevara, Rags, Pawn have lines only.
- Own options: Erin (work = `serve_guests`, chess 0.95, inn), Relc (spar), Pisces (magic, a talk), Olesm (chess 0.85),
  Krshia (`haggle`), Toren (chess 0.3, after `toren.plays_chess`).
- A new game starts on day 8 with the inn open, so a line gated on the inn being closed never shows. Lines gate on
  flags that canon events really set (`unit_voice.test_book1_voice_flags_are_real` checks every flag).
- A reading agent (Sonnet) checked traits against the Book 1 text; 11 fixes applied (eye colour, Rags's fire bug,
  Pawn cleans the inn, Ceria and Pisces have history, and so on). The first talk with a voiced NPC now adds a greeting
  line AND an own line (or topic), so `unit_talk_topics` expects 2 lines and `unit_standing` clears voices for the generic band line.

### M30.3 (2026-10-18): the Books 2 – 8 cast (one step, not split)
- 20 more entries (35 in all): Lyonette, Mrsha (brackets only), Bird, Ksmvr, Yvlon, Numbtongue, the Redfang four
  (Headscratcher, Badarrow, Rabbiteater, Shorthilt), Zel, Ilvriss, Jelaqua, Moore, Halrac, Wesle, Octavia, Magnolia,
  Laken, Calruz. Every later line waits for a story flag (zel.*, ilvriss.periss, mrsha.*, calruz.* and so on).
- Own options: Bird (archery, needs `bird.has_a_yew_bow`), Yvlon (spar), Zel (a stance, friend band), Octavia (haggle).
- Two reading agents checked 20 characters against the Book 2 – 5, 7, 8 text; Book 6 flags (Zel's death) only against our
  canon summaries, no Book 6 text on this machine. 33 fixes applied: invented facts removed (a siege, a cat, a tall tower),
  lines moved to the right flag (Rabbiteater and Shorthilt use `redfang_band.broke_toren`), Halrac and Bird reversed.
- Calruz's greeting no longer names the Horns (he is a Raskghar chief in Book 8). Open: Wesle and Laken are thin
  (3 and 4 lines); Laken and Durene appear only in the north, so most players meet them late.

### M30.4 (2026-10-19): the Earther meeting
User picks (rule 11): three new optional fields on a voice option; all six Earthers the player can meet react.
- Schema: a voice option may have `set_flags` [flag] (set once the option's action is done), `relationship`
  (a whole number added to the NPC's relationship with the player) and `page` {`title`, `lines`} (each line at most
  `max_words` words). `Voice.apply` does it; `Interact.perform` returns `page` in its result. The option's own
  `not_flags` (the flag it sets) make it one-time, so a voice still keeps no state. No save change.
- Screen: `SystemMessages.talk_page` (kind `talk`, with the NPC's face) opens in the System dialog after the talk.
  The console prints the page lines.
- Data: option `earth` on Erin (+3, page "From Earth", 6 lines, ends with her work offer), Ryoka, Laken (+2 each),
  and new small entries for Rose, Imani and Joseph (only the Earth talk). Flags `<name>.knows_player_is_earther`.
  Erin has 4 Earth lines (food, songs, games, keep it quiet) and Ryoka 1, gated on their flag.
- Canon is not touched: `sim_earther_meeting` plays the same seed with and without the talk to day 12 and gets the
  same history, drift 0 and the same RNG stream.

### M30.5 (2026-10-19): who you are
User picks (rule 11): save v23; backgrounds start their class pool 25 % full; 6 look presets.
- Save v23: `player.name` (default "Earther", at most 20 characters), `player.look` (default "player"),
  `player.background` ("" = none). `_migrate_22_to_23` gives an old save the defaults (old look, no head start).
- New `data/backgrounds.json` (`DataDb.creation`): `pool_start` 0.25, `looks` [{id, name}] (the first is the old
  "player" look) and `backgrounds` {id: {name, blurb, class}}: student → Scholar, cook → Cook, nurse → Healer,
  athlete → Runner, office → Merchant, gamer → Strategist. All guesses. A background sets the flag
  `background.<id>`; Erin has one line per background once she knows you are an Earther (M30.4 flag).
- `core/player_identity.gd` (`PlayerIdentity`): `apply` (no `gs.rng`), `who` / `line`, `validate`. Python
  `check_backgrounds` in `validate_data.py --all`.
- Looks: `player_2` – `player_6` in `appearance.json` (3 female, 2 male; light, brown, black, olive skin), built
  with `tools/build_sprites.py`. The world view and the fight bar show `gs.player.look`.
- New game: start → "Who are you?" (`ui/create_player.gd`, built in code: name field, look arrows with a front
  frame, 6 background buttons in a 3-wide grid, Back / Begin) → game. It sits in a full-screen scroll box, so at a
  big menu size (a phone) Begin is one scroll away. The welcome page and the character sheet name the player.

### M31.0 (2026-10-24): signposts and scene beats
User picks (rule 11): `where` / `hours` optional; morning page and journal; log line and bubble; no save bump.
- Event field `foreshadow` {"days_before" >= 0, "text", "where"?: map id, "hours"?: [from, to]}. Without a stage,
  `where` and `hours` are needed; with one they default to the stage's area and hours.
- `core/foreshadow.gd` (`Foreshadow.coming`): shows from `window.earliest - days_before` to the last window day
  (with delays) while the event is pending, not staged, has no hard fail (`Director.evaluate`) and no set stage
  `unless_flags`. Read only. `CanonDb.foreshadows` lists them in run order.
- Morning: a "Talk in Town" page (`SystemMessages.TOWN`) after the drift warning: "<text> (tomorrow, <place>,
  18:00 – 23:00)". Journal: a "Coming up" list ("Day N, hours, place: text").
- Stage field `beats` [{"after_seconds" >= 0, "line", "npc"?}] on any stage, in time order. A beat's npc must be a
  scene npc, a stage ally or a wave ally. One due beat per command: the log gets "Name: line"; a dead speaker's
  beat is skipped. The view shows the newest beat over its speaker once (`Stage.last_beat`, `ViewBubbles`), not in
  a fight.
- `combat.stage_run` gets "beat" (next beat). A fight stage with waves or beats gets a run; a scene with beats gets
  one if no fight run is on. A scene's run ends when the scene ends or the player leaves. Old saves read "beat" as
  0: no save version change (like M17.8). `Stage.foes_left` stays -1 for a scene or a fight with no `waves`, so the
  HUD and the battle music do not change.
- Checks: `CanonDb` (shape, beat order, beat npc on the stage), `CombatDb` (foreshadow map), Python
  `check_foreshadow` / `check_beats` (with the copy check on the text and beat lines).

### M31.1 (2026-10-24): the signposts
- A `foreshadow` on all 25 fight stages and on 10 key scenes: the concert, the Frost Faerie banquet, Romeo and
  Juliet and Frozen at the Hare, Brunkr's feast, the burning of Brunkr and Ulrien, the Goblin party, the Silver
  Swords' arrival, the Players of Celum at the inn, Zel's funeral. The list is `KEY_SCENES` in `unit_foreshadow`.
- Text is what the town could know (a sighting, a plan, a warning), in our own words, never the outcome.
  `where` and `hours` come from the stage, so no line gives them.
- `days_before` is 1, except the burning (0: they are still alive the day before) and Zel's funeral (2).
- New check: given foreshadow `hours` must fit inside the stage's hours (Python `check_foreshadow`).

### M31.2 (2026-10-24): beats for the Books 1 – 4 scenes
- All 17 scenes of Books 1 – 4 have 5 – 6 beats (Book 1 has no scenes). Beats come every 40 – 70 game seconds,
  from 0 to about 290 s, so a player who stays a few minutes sees them all.
- Speakers are only NPCs the scene places. Toren and Mrsha cannot speak, so their moments are lines with no
  speaker. A reading agent gave paraphrased chapter summaries; no book text reached the data.
- Each beat has at most `rules.voice.max_words` (20) words, so it fits a speech bubble. `unit_scene_beats`
  checks the count (3 – 6), the speakers, the word limit and that each beat falls inside the scene's hours.
- No song lyrics: a beat says what a song is about, never its words.

### M31.3 (2026-10-24): beats for the Books 5 – 8 scenes and the fights
- All 30 scenes of Books 5 – 8 have 5 – 6 beats, like M31.2. All 25 fight stages (Books 1 – 8) have 2 – 3
  beats: ally shouts, or a line with no speaker. A shout comes only after its speaker's wave has arrived.
- Book 6 has no raw text on this machine. Its 6 scenes and 1 fight are written from the canon JSON summaries
  only; the copy check for book 6 is skipped. Check them when the book 6 text is available.
- The copy check caught 3 lines that matched book text by chance; they were reworded.
- A fight with beats now always has a `stage_run` (as M31.0 allows); `Stage.foes_left` stays -1 without waves.
- `unit_scene_beats` now checks all 47 scenes (3 – 6 beats) and all 25 fights (1 – 3 beats).

### M32.0 (2026-10-25): the user's picks and the reading
Two reading agents (Sonnet) read 5.44 and 4.47 – 4.49 (book 6 text was extracted locally for this). Summaries only.
**Picks (user, 2026-10-25):**
1. **Zel can be saved** if the player wins (option b). A large bend, built as its own step (M32.4).
2. **Zel's stage is on a new map**, an open battlefield near Invrisil (not `road_to_invrisil`).
3. **Tremborag's hall stays news.** No stage.
4. **Klbkch (1.29) always dies.** No bend.
5. **Win rule:** the player saves Zel by driving off **Bea** (her plague) and **Ijvani** (black fire) before the
   last wave, while Zel is still standing. Then Az'kerash does not come (the book hints a faster Zel would have
   made him stay away). Driven off, not killed: the Chosen flee or yield, as in canon they are repaired.
6. **Selys:** if Zel lives, he gives Selys the Heartflame armour himself. The alt sets `heartflame.selys_inherits`,
   so her 12 Book 7 events still run (flag hand-off, ADR 0036 rule 3).

**Facts from the reading that change the plan:**
- 4.47 – 4.49: the field is open grassland about four miles outside Invrisil. Flat, churned mud, overcast, light
  drizzle, daytime. A ring-shaped dome of bone closes over Zel and the Goblin Lord in mid-field.
- **No Drakes fight beside Zel.** Ilvriss is in Liscor. Zel's side: Magnolia's Human levy (cavalry, archers,
  mages), about 40 Rose Knights under Lady Bethal, Sir Thomast, Reynold and Ressa (Magnolia's servants), two War
  Golems. Allies on the stage come from these.
- **Five Chosen**, not three: Venitra (bone knight, heavy), Ijvani (skeleton mage, black fire), Bea (plague touch;
  healing potions make it worse), Oom (acid slime; Zel destroys him in canon), Kerash (undead Gnoll swordsman,
  leader). Az'kerash arrives last by scroll and is never a foe the player can fight (a beat only).
- Goblin side: soldiers, Hobs, Shield Spiders, undead (zombies, ghouls, Crypt Lords), lieutenants Snapjaw, Eater
  of Spears, Illbreath, Noface. The Goblin Lord rides a Shield Spider.
- 5.44: three doors (Gold-rank teams; Liscor's army, Watch, Relc, Klbkch, Ilvriss; the Antinium). Calruz fights
  the Horns (Ceria, Yvlon, Pisces, Ksmvr), drops his axe and falls to Ceria's ice spike: alive, jailed.
- **Nokha is a swordswoman, not a caster.** She breaks toward Mrsha's cage; Lyonette, Apista and Moore stop her;
  her fate is open. In the game she flees (never dies). About 20 Gnolls are caged at the back of the camp.
- The Zel cascade (from the data): after `b6.zel_names_the_goblin_lord_reiss_and_dies`, 4 events `depends_on` it
  (Reiss withdraws, Magnolia's bounty, Az'kerash's words, Klbkch and the Grand Queen) and about 25 Book 6 – 7
  events assume his death (the mourning, the casket, the will, the funeral, the vengeance vow, the ashes) — most
  with no flag that says so. Selys's Heartflame thread (12 events) hangs on `heartflame.selys_inherits`.

**Step layout after the picks:** M32.1 three doors; M32.2 Zel's stage on the new map (he still dies, the hook flag
is recorded); M32.3 boss feel; **M32.4 the "Zel lives" bend** (replaces the old optional Tremborag / Klbkch step).
Detail per step in `docs/plans/m32.md`.

### M32.1 (2026-10-25): the three-door battle in full
- **No new enemy field.** Calruz's yield and Nokha's flight use the M8.1 `escape` field (the foe cannot die; a hit
  below its share removes it with a line; a foe counts as routed). The question in the plan (rule 11) is closed.
- **New enemies:** `calruz` (enemy id = his NPC id, so he is drawn with `calruz.png`; the enemy `look` must name
  another enemy, so a `look: "calruz"` was refused by the validator) and `nokha_awakened` (Gnoll art, very fast,
  no ranged attack). Boss numbers are guesses.
- **The fight names its foe by danger.** A fight's action records carry the most dangerous foe type, ties going to
  the first foe. So Calruz has danger 1.0 alone: `awakened_raskghar` drops from 1.0 to 0.95 and Nokha is 0.98.
  The hook on Calruz matches `context.enemy: "calruz"`, which only shows once he joined the fight.
- **Waves:** Nokha leads the knot to the cages; the Horns (Ceria, Yvlon, Pisces, Ksmvr) come as one ally wave;
  Calruz comes alone in the last wave. Watch guardsmen and Antinium Soldiers come as helpers with their doors.
- **The cages:** one new object kind `cage` (art in `tools/build_objects.py`), one object `raskghar_cages` at the
  back of the camp with `comfort_someone`, shown while `raskghar.camp_holds_the_gnoll_captives`.
- **Hooks (all `change`; the canon still runs; each adds a flag, relationships and news):**
  `player_stood_with_the_horns_against_calruz` (on `b8.the_horns_bring_down_calruz`), `player_reached_the_cages`
  (on `b8.lyonette_and_moore_take_back_mrsha`), `player_held_the_inn_in_the_night_raid` (5.34) and
  `player_fought_the_daylight_raid` (5.38). Calruz and Nokha stay alive in every outcome. A `change` hook adds 0.25
  drift; a player who stays away keeps drift 0.

## Consequences
- More text in data. The validator and `tools/tests` grow a check for each new file.
- More hooks and stages raise the cascade risk. Each canon change keeps `sim_canon_book<N>` at drift 0 and the
  book's kill sim green.
- Book text reading (Zel's last stand, Calruz, beats, spells, recipes) goes to reading agents (CLAUDE.md
  "Context discipline"); only summaries reach the main session.

# Roadmap

Rule: finish a milestone's acceptance tests before starting the next. Tick boxes as you go.
Order: **At a glance** → **Next up** (open work, in order) → **Waits on the user** → **Later** → **Releases** →
**Done** (newest first, one line each).
When a milestone's build steps are all ticked, move it to the top of Done. If only "the user plays" checks are
left, put them under "Waits on the user". Detail of finished work lives in `docs/DECISIONS.md`, the plans
(`docs/plans/`) and git history.

## At a glance

| Milestone | State | Model · effort (Antigravity) |
|---|---|---|
| M37 Book 10 (The Wind Runner) | Plan written (`docs/plans/m37.md`, ADR 0048). M37.1 done. Next: M37.2 Tails and Scales map, M37.3 – M37.8 canon, M37.9 sims (M37.0 skipped). | M37.1, M37.2: Gemini 4 Argon (High) · M37.3, M37.5, M37.7, M37.8: Gemini 4 Argon (High) · M37.4, M37.6: Gemini 4 Argon (High) · M37.9: Gemini 4 Argon (High) |
| M36 Book 9 (Tears of Liscor) | Done and merged (M36.P – M36.10, ADR 0047). | – (done) |
| M35 New content (Ceria's fire lesson, stat sheets, Invrisil Runners' Guild staff, Magnolia's whereabouts) | Done and merged (M35.0 – M35.3, ADR 0046). | – (done) |
| M33 Depth: spells, dishes, quests, friends | Done (M33.0 – M33.4, ADR 0044); only the play check is open. | – (done) |
| Play checks (M20, M27 – M35) | waits on the user | – (user) |
| Google Play | closed test running | – (user) |
| Microsoft Store | kit ready (`docs/WINDOWS_STORE.md`); needs Partner Center account, name and identity | – (user) |

Last release: v0.2.1-alpha (2026-11-04, tag and GitHub pre-release published): v0.2.0 plus M35 (Ceria's fire lesson, stat sheets, Magnolia) and all of Book 9 (M36). v0.1.8 is on Google Play's closed test track, waiting for review.
Next step: M37.2 (Tails and Scales map), see `docs/plans/m37.md`. Book 10 text is in the private repo `Daddy-Ousen/innworld-canon-raw`.

How to read the model column: select that model and effort in Antigravity's model selector before you start the step. Use Gemini 4 Argon (High) (or Claude Sonnet/Opus 5.5) for canon batches, records, maps, fight stages, and book sims; use Gemini 3.8 Flash (High) for fast checks, targeted test runs, and doc updates. Reading agents (summaries only) run on Gemini 3.8 Flash or Argon.

---

# Next up

One branch + PR per sub-step. Steps marked (user) need the owner to do or decide something.

## Audit follow-ups (2026-11-11)
- [x] Quick bugs B1 - B3 ([PR #279](https://github.com/Daddy-Ousen/innworld-rpg/pull/279)): phone menu size, class offer title, first day line once
- [x] Sleep asks first, and Rest passes time (audit D1, D2; ADR 0051)
- [x] Android Back is Esc, and the game saves when the app is paused (audit B5; ADR 0052)
- [x] Desktop: the menu size and the map follow the window; full screen (F11, Options) (audit W3, W4, T1; ADR 0053)

## M37 — Book 10 (The Wind Runner) (plan `docs/plans/m37.md`, ADR 0048)
- [x] M37.P Plan: 17 chapters read, day anchor 176, short version for Baleros & Chandrar, 1 fight stage, 2 hooks, 1 new map, 0 kills **[Gemini 4 Argon (High)]**
- [-] M37.0 Engine: skipped (no new engine mechanics or schema changes needed)
- [x] M37.1 World and records: 51 NPCs, 22 places, 4 checks, notes on existing records, `sim_book10_world` (ADR 0050) **[Gemini 4 Argon (High)]**
- [ ] M37.2 Tails and Scales map: Pallass floor 5 bar, link from `pallass_door_street`, goals for Rufelt and Lasica **[Gemini 4 Argon (High)]**
- [ ] M37.3 Canon 6.00, 6.01: Ryoka at Reizmelt (days 181–183), off map, no stage, no hook, no Ryoka class **[Gemini 4 Argon (High)]**
- [ ] M37.4 Canon 6.02, 6.03: door reopened, inn barred, night undead fight stage (`inn_hill`, day 183, `xp_window`), Numbtongue walk hook (`liscor_market`, day 184) **[Gemini 4 Argon (High)]**
- [ ] M37.5 Canon 6.08 – 6.10: Apista, Erin in Pallass, mana cave, Tails and Scales (day 190) **[Gemini 4 Argon (High)]**
- [ ] M37.6 Canon 6.11, 6.16: Calruz, Ilvriss leaves, Gold-rank farewell hook (`inn_interior`, day 192), Garia [Martial Artist] **[Gemini 4 Argon (High)]**
- [ ] M37.7 Canon 6.04 D – 6.07 D: Baleros short version (days 183–187), off map, neutral summaries for explicit scenes **[Gemini 4 Argon (High)]**
- [ ] M37.8 Canon 6.12 K – 6.15 K: Chandrar short version (days 189–194), off map, Reim, banquet, edict, Pomle **[Gemini 4 Argon (High)]**
- [ ] M37.9 Book 10 full sims: `sim_canon_book10`, `sim_kill_book10`, validator `--all` **[Gemini 4 Argon (High)]**
**Done when:** Book 10 canon events run with drift 0; Tails and Scales bar map works; fight stage and hooks work; sims and validator pass.

---

# Waits on the user

## Play checks
All build steps are merged. Run the game with `godot --path game`, or install the apk from the latest release.
- [ ] Desktop size and full screen (ADR 0053): on the PC, run the game, press F11, look at the text and map size; drag the window small and large; Options > Menu size 300 %
- [ ] Android Back and save on pause (ADR 0052; needs a new release build): on the phone, Back closes a card and opens the menu, Back on the title closes the app; play to midday, switch to another app, close the game from the app list, open it again: Continue is at midday
- [ ] Sleep and Rest (ADR 0051): press Z in the inn at midday (the question shows the wake time), say "Stay awake", then press R and rest until dinner; the same on the phone (Sleep and Rest in the More grid)
- [ ] M33: play a quest line (Erin, Pawn, or Pisces) and learn [Flash Step] from Pisces after his lesson
- [ ] M35.3: sleep to Book 6 day 129 – 134 and find Magnolia and Ressa: the battlefield on day 130, the Invrisil gate by day on days 131 – 133, the estate hall after
- [ ] M35.0: take "Ceria and the spark" from Ceria on day 36 (she eats at the inn at 6 – 9 h and 18 – 23 h), finish it, then learn [Flashfire] from her
- [ ] Bag screen (card look, 2026-10-31): open the bag on the phone, eat, hold a tool, "Leave 1", put the held item in the bag
- [ ] M32: the three doors (the Book 8 raid, Calruz yields) and Zel's last stand at Invrisil (drive off Bea and Ijvani: Zel lives)
- [ ] M31: a signposted day (the Skinner night) and a scene with beats (the play in Celum)
- [ ] M34 on the phone (v0.1.8 apk): shop at Krshia's, talk to Erin, serve a guest, attack a guard; the M34.5 fixes (End turn free in a fight; the shop's Buy button upright)
- [ ] M30: talk to the Book 1 cast, tell Erin you are from Earth, start a new game; the "Who are you?" screen on a phone
- [ ] M29: the first night's System page, the inn on day 1 and day 14, Lism's prices, a fight at a map's edge
- [ ] M28: Book 8: the raid stages, the camp door on day 163, the Drake boycott
- [ ] M27: do level 5 and level 10 come at a fair pace? Does trading feel right?
- [ ] M20: play on a PC with a touch screen

## Google Play (ADR 0037, `docs/PLAY_STORE.md`)
Done: store prep, permission (author's Discord, 2026-10-19), Play Console app, v0.1.6 live on the closed track "Alpha",
v0.1.8 sent for review (2026-10-24).
- [ ] Google approves the v0.1.8 release
- [ ] Closed test: 12+ testers for 14 days (personal account only)
- [ ] Check a tablet or a large-screen emulator: API 36 can not lock landscape there
- [ ] Apply for production, then the production release
**Done when:** the game is public on Google Play.

## Other user to-dos
- [ ] Back up the release keystore and its password file (`%USERPROFILE%\.android\`). A lost key means no app updates.

---

# Later
- Optional generated flavour text
- Console `skip <days>` command (offered 2026-10-11, no answer yet)
- Outside PR #164 (DKemp98, more Skills and classes): changes asked 2026-10-12; wait for rebased, split PRs
- Outside PR #210 (DKemp98, sort the tags, add `crafting.potions`): open since 2026-10-18, not reviewed yet
- Web build on its own subdomain (CNAME + Settings → Pages → Custom domain)
- Rags's Book 8 thread (Pyrite, Bethal, Lancrel) has no alt when Laken dies (design pick, from PR #242)

---

# Releases
ADR 0029 (Windows, Linux), ADR 0031 (web), ADR 0034 (Android), ADR 0037 (Play aab). Build with `tools/release.ps1`.
Every release uploads the signed Android apk too. The aab goes to Play only.

| Version | Date | What |
|---|---|
| v0.2.0-alpha | 2026-11-01 | bag screen in the card look on top of v0.1.9 (Android code 9); the aab stays local |
| v0.2.1-alpha | 2026-11-04 | Book 9 (M36) + M35 (Ceria's fire lesson, stat sheets, Magnolia) (Android code 10); the aab stays local |
| v0.1.9-alpha | 2026-10-31 | M31 – M33 (Android code 8); the aab stays local |
| v0.1.8-alpha | 2026-10-24 | M34.5 phone fixes (Android code 7); sent to the Play closed test |
| v0.1.7-alpha | 2026-10-22 | M34 phone controls (code 6) |
| v0.1.6-alpha | 2026-10-19 | M28 – M30 (code 5); first Play closed test release |
| v0.1.5-alpha | 2026-10-15 | balance and trading (M27) |
| v0.1.4-alpha | 2026-10-10 | up to M23.3 |
| v0.1.3-alpha | 2026-10-08 | first signed apk (M20.2) |
| v0.1.2-alpha | 2026-10-06 | touch controls and UI scale |
| v0.1.1-alpha | 2026-10-02 | web build, GitHub Pages, itch.io |
| v0.1.0-alpha | 2026-10-01 | first build: Windows and Linux |

---

# Done (newest first)

| Milestone | What it gave the game | ADR |
|---|---|---|
| M36 Book 9 (Tears of Liscor) | canon 5.45 – 5.62 + Thereafter (days 164 – 180), 4 fight stages, 6 scene stages, 13 dead, `liscor_watch_cells` map | 0047 |
| M35 New content | Ceria fire quest [Flashfire], NPC stat sheets, Magnolia whereabouts | 0046 |
| M33 Depth: spells, dishes, quests, friends | 12 spells (hold/blink/hide/wall), 5 recipes/dishes, quest engine, 3 lines, 32 friend perks | 0044 |
| M32 Climaxes of Books 6 – 8 | three-door battle, Zel's stand on `invrisil_battlefield`, boss abilities (fear, bile, command), Zel can live | 0044 |
| M31 Signposts and scene beats | event signposts (talk, journal "Coming up"), timed scene beats, ally shouts | 0044 |
| M34 Phone controls, second pass | action card per target, shop screen, context button, tap to walk, sizes by dpi, upright fixes | 0045 |
| M30 Voices and the Earther | NPC voices and barks for Books 1 – 8, the Earther meeting, "Who are you?" (save v23) | 0044 |
| M29 Lore polish | System voice like the books, inn name by flag, Liscor wary of Humans, looks, end-of-story page | 0044 |
| M28 Book 8 (Blood of Liscor) | canon 5.21 – 5.44 (days 143 – 163), Drake boycott, 3 fight stages, `raskghar_camp` | 0043 |
| M27 Balance from player feedback | faster leveling, consolidation from level 5, bulk trade, slower forgetting | 0042 |
| M26 Code health | `main.gd` and `world_view.gd` split in parts | 0040, 0041 |
| M25 NPC life | NPC levels, talk topics, job boards, more character sheets, Magnolia by flags | 0038, 0039 |
| M24 Level by living | actions, recipes, spells and capstone Skills for the new classes | – |
| M23 Canon bends | substitute / delay / mutate and hooks for Books 2 – 7, kill sims, drift warning | 0036 |
| M22 Breakthroughs | breakthroughs earned in play; consolidation on top; level 10+ in normal play | 0035 |
| M21 Housekeeping | branches, docs, disk, full suite green, legal note, play pass | – |
| M20 Touch controls | input actions, touch layer, Android build, UI scale (only the touch-PC check is open) | 0032 – 0034 |
| M19 Book 7 (The Rains of Liscor) | canon 5.00 – 5.20 G, door links, rains and floods, Pallass door, Invrisil, north road | 0030 |
| M18 Book 6 (The General of Izril) | canon 4.32 G – 4.49, chapter order, Laken's calendar, Wirclaw, ossuary | 0028 |
| M17 Tactical combat | AP turns, combat screen, Skills and spells in fights, mana, cover, hidden XP and duress (save v18 – v20) | 0027 |
| M16 Maps, art and cities | art audit, nature and building art, signs, Liscor and Celum districts | 0023 – 0026 |
| M15 Readability and lore fixes | pixel font, player day count, small log, no XP numbers | 0022 |
| M14 Engine works | bag, cooking, guests, reputation, schedules, attack NPCs, UI skin, portraits, balance | 0021 |
| M13 Book 5 (The Last Light) | canon 4.00 K – 4.31, depths and traps (save v14) | 0020 |
| M12 Audio | music, sound effects, ambience, canon moment tracks | 0019 |
| M11 Graphics | LPC art, characters, animation, monsters, day and night | 0018 |
| M10 Book 4 (Winter Solstice) | canon 3.26 G – Winter Solstice, the Albez door (save v13) | 0017 |
| M9 Book 3 (Flowers of Esthelm) | canon 3.00 E – 3.25, Esthelm siege, bee cave | 0016 |
| M8 Book 2 (Fae and Fare) + Celum | canon to 2.48, winter, Celum start, economy and travel (save v10 – v11) | 0014, 0015 |
| M7 Rest of Book 1 | canon 1.26 – 1.63, big battles (save v9) | 0012, 0013 |
| M6 Vertical slice | play loop, saves, journal, player hooks, canon fights | 0011 |
| M5 Combat | first combat, monsters on the map, combat UI | 0010 |
| M4 2D world | world grid, 2D view, NPC schedules and AI, System dialog | 0006 – 0009 |
| M3 World director | event nodes, fallbacks, drift | 0005 |
| M2 Canon pipeline | epub extraction, schemas, validator | 0004 |
| M1 Sim core | clock, actions, XP, classes, levels, Skills, night pipeline | 0002, 0003 |
| M0 Setup | repo, Godot project, GUT, RNG, `GameState` | 0001 |

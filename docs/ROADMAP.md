# Roadmap

Rule: finish a milestone's acceptance tests before starting the next. Tick boxes as you go.
Order: **At a glance** → **Next up** (open work, in order) → **Waits on the user** → **Later** → **Releases** →
**Done** (newest first, one line each).
When a milestone's build steps are all ticked, move it to the top of Done. If only "the user plays" checks are
left, put them under "Waits on the user". Detail of finished work lives in the ADRs (`docs/adr/`), the plans
(`docs/plans/`), `docs/PROGRESS_ARCHIVE.md` and git history.

## At a glance

| Milestone | State | Model · effort per step |
|---|---|---|
| M33 Depth: spells, dishes, quests, friends | M33.0, M33.1 done; next: M33.2 quest engine (`docs/plans/m33.md`) | M33.0: Opus · medium · M33.1: Sonnet · medium · M33.2: Opus · high · M33.3: Sonnet · high · M33.4: Sonnet · medium |
| Play checks (M20, M27 – M32, M34) | waits on the user | – (user) |
| Google Play | closed test running | – (user) |

Last release: v0.1.8-alpha (2026-10-24). It is on Google Play's closed test track, waiting for review.
Next step: the user merges M33.1 (Erin's food). Then M33.2 quest engine **[Opus · high]**. The play checks do not block M33.

How to read the last column: pick that model and effort in the app before you start the step's session. Reading
agents that a step starts (book text, summaries only) run on Sonnet · medium. Default is Sonnet · medium. Opus for
engine, save and design work and for canon logic; high effort where lore, balance or cascades are easy to get wrong.

---

# Next up

M33 comes from the player audit of 2026-10-17 (the last of M31 – M33; `docs/AUDIT_PLAYER_2026-10-17.md`, ADR 0044); the user said
"we will do all". One branch + PR per sub-step. Steps marked (user) need the user to do or decide something.

## M33 — Depth: spells, dishes, quests, friends (plan `docs/plans/m33.md`, ADR 0044)
- [x] M33.0 Canon spells (10 – 15) with teachers and spellbooks; new effect kinds only where the user agrees **[Opus · medium]** (2026-10-26: 12 new spells, kinds `hold`, `blink`, `hide`, `wall`, friend gate)
- [x] M33.1 Erin's food and drink from the books (names from the text, numbers guessed) **[Sonnet · medium]**
- [ ] M33.2 Quest engine: `data/quests.json`, journal "Tasks", save version bump + migration (schema ask) **[Opus · high]**
- [ ] M33.3 Three personal quest lines (user picks: Erin's inn, Pawn, magic from Pisces or Ceria) **[Sonnet · high]**
- [ ] M33.4 Friendship that does something: one perk per main NPC at friend and close-friend level **[Sonnet · medium]**
- [ ] (user) Play a quest line and learn a spell from a friend
**Done when:** the spells, dishes, quest lines and perks work; old saves load; the touched tests pass; the user has played it.

---

# Waits on the user

## Play checks
All build steps are merged. Run the game with `godot --path game`, or install the apk from the latest release.
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
- Optional LLM flavour layer
- Console `skip <days>` command (offered 2026-10-11, no answer yet)
- Bag screen with the new card look (M34 left it on the old list)
- Outside PR #164 (DKemp98, more Skills and classes): changes asked 2026-10-12; wait for rebased, split PRs
- Outside PR #210 (DKemp98, sort the tags, add `crafting.potions`): open since 2026-10-18, not reviewed yet
- Web build on its own subdomain (CNAME + Settings → Pages → Custom domain)
- Rags's Book 8 thread (Pyrite, Bethal, Lancrel) has no alt when Laken dies (design pick, from PR #242)

---

# Releases
ADR 0029 (Windows, Linux), ADR 0031 (web), ADR 0034 (Android), ADR 0037 (Play aab). Build with `tools/release.ps1`.
Every release uploads the signed Android apk too. The aab goes to Play only.

| Version | Date | What |
|---|---|---|
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

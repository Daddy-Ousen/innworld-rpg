# ADR 0022 — M15–M17 from the user's first play report

Date: 2026-09-29 · Status: plan proposed 2026-09-29; the user's choices below are final, the order waits for approval

## Context
The user played M14 and listed 8 problems (screenshots in the books folder `Temp/`, not in git):
1. The font (Pixelify Sans) is too curly to read.
2. The HUD says "Day 8" at the start. For the player, day 8 is the day they arrived. The bottom log covers
   nearly half the screen (`console.png`: 6 log lines plus a two-line key list, full width).
3. Bad art: the `rock` prop (`lpc_atlas` 28,26) is a flat slab that reads as neither rock nor mountain
   (`gfx1.png`); rows of rock slabs and flat stone blocks for a cliff (`gfx2.png`); thin water between two ponds
   draws broken edge tiles (`gfx3.png`).
4. In cities nothing says what a door or a building is (`celum.png`: two bare doors on a brick wall).
5. The Liscor market is empty; the `building` tile is one brick cell repeated, so houses are flat red blocks
   (`liscor1.png`).
6. Liscor and Celum are big cities, but each is 2–3 maps of 32x24 and looks like a small yard.
7. XP numbers on screen are not lore-accurate (`world/main.gd` prints "<action>: 2.5 XP."; the character sheet
   shows "12 / 40 XP").
8. The user wants grid, turn-based combat like XCOM: action points per turn to move or act, with class Skills
   and spells.

Code facts found:
- Skills have only `stat_mod` and `xp_mult` effects. No active Skills, no spells, no MP, no [Mage] class.
- Combat (M5, ADR 0010) has no combat mode: each player command is one 6-second turn, monsters act after it
  (`MonsterSim`). Stages (waves), brawls, traps, helpers and fighting NPCs all build on that.
- The day shown is `gs.clock.day()`, the canon day. The player arrives at `rules.clock.start_minute` (day 8).
- Maps are 32x24; `liscor_market` has 5 objects and two 4x3 `building` blocks.

## User choices (2026-09-29)
1. **Font:** Pixel Operator (CC0). Ask before the download (file, source, size).
2. **AP rules** (the user's own model, not one of the offered ones):
   - Base 6 AP per turn. Movement costs 0.25 AP per tile. A turn may spend at most 1 AP on movement (4 tiles)
     unless a class or Skill raises the cap ([Runner]: 2 AP = 8 tiles).
   - A normal attack costs 2 AP. Skills cost 1–10 AP. Spells cost 1–10 AP plus 1–10 MP.
   - MP is kept between fights like HP and regenerates slowly.
   - Move, attack, move, attack is allowed while AP and the move cap last.
   - Some Skills give permanent AP (the user's example: a lesser stamina Skill +1, a greater one +2).
   - +1 AP at level 10, 25, 50 and 75.
3. **Turn order:** each fighter by Agility (player, NPC allies, helpers and each monster have their own place).
4. **Cities:** district maps. Each big city is 5–7 small maps with edges that show the city going on.

## Decisions
- **Order:** M15 (small UI and lore fixes) first, then M16 (maps and art), then M17 (combat). M16 before M17 so
  that M17.6 cover uses the final map objects, and fights are tested on the new maps.
- **Player day (M15.1):** a view helper: player day = canon day − arrival day + 1, from
  `rules.clock.start_minute`. Core, the director and saves keep the canon day. No save change.
- **XP hidden (M15.3):** DESIGN §1 now says the player never sees XP. The debug console keeps the numbers.
- **AP in quarter points:** store AP as integers in quarter points (6 AP = 24) so the math is exact and
  deterministic. Rule values live in `rules.combat.tactical` (data, tunable).
- **One round = 6 s** of world time (today's `world.step_seconds`), so the clock, hunger and schedules still move
  during a fight. The rest of the world waits while the fight runs.
- **Spells need learning** (teacher or spellbook) and MP. No spell comes from nothing. Spell data carries
  `canon_ref` and `confidence`; the first spells come from Books 1–5 text only.
- **Schema changes approved with this plan (rule 11):** object field `sign` (M16.3), `rules.combat.tactical`
  (M17.0), encounter state + save v18 (M17.1), skill effects `combat_action`, `ap_mod`, `move_ap_mod` (M17.4),
  `data/spells.json`, MP in the player state + save v19 (M17.5), cover values on tiles and objects (M17.6),
  enemy `abilities` (M17.7).

## User answers (2026-09-29, second round)
- **Order M15 → M16 → M17:** approved.
- **Extra AP uses the TOTAL level** (all class levels added: 5 [Runner] + 5 [Warrior] = total level 10). +1 AP when
  the total level reaches 10, 25, 50 and 75.
- **The total level is a secret of the world.** The player never sees it, and no message says why AP went up.
  The character sheet today prints "Total level: N" (`ui/character_sheet.gd:36`): M15.3 removes it. Per-class
  levels stay visible.
- Lore basis: Ryoka's level-cap theory (Book 2, 2.41, event `b2.ryoka_explains_the_level_cap_theory`, confirmed):
  the cost of a level follows the total level, not the class level, and there is a cap near level 100 in total.
  Junk side classes make the main class slower; consolidation eases it. The user's wiki excerpt agrees with 2.41.
  Today `Levels.xp_to_next` uses the class level only.
- **Level cost follows the total level, with a hidden cap of 100 total levels — but later, in M17.7** (the
  balance pass), so the XP curve and the combat numbers are tuned once. A level-20 [Warrior] then pays the cost
  of level 21 for [Digger] level 2. The curve (`rules.levels` base_xp, growth) needs a retune for it.

## Open points (ask at the start of the sub-milestone)
- MP regen speed and whether sleep refills it fully (M17.0 numbers).
- Skill names for permanent AP: check the Book text; the user's names are examples. Invented names get
  `"confidence": "guess"`.
- Which Liscor and Celum districts are canon in Books 1–5 (M16.4 / M16.5 start with a place list from the
  canon data, checked by the user).

## M15.0 Font (2026-09-29)
- Pixel Operator by Jayvee Enaguas, CC0 1.0, `pixel_operator.zip` (104 KB) from dafont.com, download approved by
  the user. Only `PixelOperator.ttf` and `PixelOperator-Bold.ttf` ship, with `CC0-PixelOperator.txt`. Pixelify Sans
  and its OFL file are removed.
- The font is drawn on a 16 px grid. Every size we set is a multiple of 16 (`unit_ui_theme` checks the HUD, System
  dialog and title scenes): title 36 → 32, System dialog 18 → theme size, HUD hint 14 → theme size. World labels
  (NPC names, damage numbers) draw at 32 and scale down by 3 (`WorldView.NAME_FONT_SIZE`); the object letter is 16.
- Import flags stay as in M14.6: antialiasing 0, hinting 0, subpixel positioning 0.
- Text size: `TextSettings` (`ui/text_settings.gd`) keeps `large_text` in the `display` section of
  `user://settings.cfg` next to the volumes. `Session.set_large_text` sets the project theme's `default_font_size`
  (16 or 32); controls with no size override follow at once. The Options panel has a "Large text" box. Tests use
  the test settings file (`gut_pre_run`).
- The project has no stretch mode: a bigger window shows more world at 1:1, so 16 px text is small on a 1920x1080
  screen. Large text is the fix for that; a UI scale mode was not needed.

## M15.1 Player day (2026-09-29)
- `Clock.player_day(canon_day, rules["clock"])` = calendar day − (`start_minute` / 1440). The arrival is Day 1;
  a toy game that starts on day 1 is unchanged. One static helper, no save change.
- Changed screens: HUD status, character sheet, journal (header, news, changes), morning page, "Loaded" line,
  the new-day line in the log, and the save slot label (`SaveSlots.info` gains `player_day`; `day` stays the
  calendar day).
- Unchanged on purpose: the debug console (`ui/console_commands.gd`), the director, windows, history, saves.
  The console prints calendar days ("D11"), so a developer can match them to canon.

## M15.2 HUD log (2026-09-29)
- The log strip (`Bottom` in `ui/hud.tscn`) is bottom left, anchor right 0.5 with an 8 px gap, panel `self_modulate`
  alpha 0.55. `Hud.LOG_LINES` = 3. It is fully shown for `FADE_AFTER` (6 s) after a new line and fades over
  `FADE_TIME` (1.5 s); `Hud.tick(delta)` does it (`_process` calls it), so tests can step time.
- `Hud.history()` keeps the last `HISTORY_MAX` (500) lines for the whole game screen. It is presentation only, not
  game state: a load or a new game screen starts an empty history.
- New `ui/text_page.tscn` / `TextPage`: a read-only page with a title, opened and closed by its key or Esc,
  PageUp/PageDown scroll. Two instances in `world/main.tscn`: `MessageLog` (L, newest first) and `Help` (H).
- The key list moved from the HUD to `SystemMessages.KEYS` (the H page). The HUD keeps one line, "H: help", top right.
- M15.3 still has to drop "Every action gives XP" and "matching actions give more XP" from the hints.

## M15.3 No XP numbers (2026-09-29)
- Gone from player screens: the action line ("Cook a stew." with no amount), the class lines on the character
  sheet (now "[Cook] level 4", plus "(needs a breakthrough)" when blocked), the "Total level" line, and the words
  "XP" in the welcome hints and the journal footer. The hints now say work that matches a focus "brings that class
  closer". `unit_no_xp_shown` checks the sheet, journal, hints, help page, welcome page and action line.
- Kept on purpose: the debug console (`do`, `use`, `status` print XP) and every core number. Levels stay visible.
- The class XP still exists in the save (`progression.classes[id].xp`); only the display is gone.

## Risks
- M17 changes every fight test (stages, brawls, traps, helpers). M17.2 budgets a full port and a full-suite run.
- Canon stages were tuned for the old turns (M14.8). M17.7 redoes the balance probes.
- New tile and house art must stay LPC-compatible (licences in `CREDITS.md`); ask before each download.

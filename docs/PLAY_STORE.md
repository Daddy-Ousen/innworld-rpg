# Google Play

What we need to put Innworld RPG on Google Play, and the text for each Play Console page.
Prepared 2026-10-11. Text checked against the author's rules 2026-10-19 (v0.1.6-alpha).
Developer account: "Thrive IT Solutions" (Personal account, ID 8735138160545874037). Package `org.daddyousen.innworldrpg`.

## 0. Permission and the author's rules

**User decision 2026-10-19:** a moderator on the author's Discord said a fan game is fine to develop and release
while it keeps the author's fan-work rules. Upload is allowed from now on. Keep a screenshot of that message:
Google can ask for proof if someone reports the app (Play policy "Intellectual property").

The rules, and how this listing keeps them:

| Rule | How we keep it |
|---|---|
| No book or series names (trademarks) in marketing | Store text, graphics and screenshots never name a book or the series. Say "pirateaba's Innworld". |
| No book covers in ads | Icon, feature graphic and screenshots are our own art and real game frames. |
| Character names and scenes are fine, with credit | The description credits pirateaba for the characters, world and ideas. |
| No copyrighted text or interior art | The game holds no book text (CLAUDE.md rule 10) and no art from the books or the website. |
| No merchandise with the author's IP | We sell nothing. |
| Do not license fan art to third parties | Our own art stays under the licences in `CREDITS.md`; we grant no rights in the author's IP. |
| Do not claim it is official | The description says "unofficial" and "not made or approved by pirateaba". |
| No crowdfunding | No Patreon, Ko-fi, donation or sponsor links anywhere (no `.github/FUNDING.yml`). |
| Non-commercial | Free, no ads, no in-app purchases. Keep it that way. |

## 1. Build the AAB

Google Play takes an Android App Bundle (`.aab`), not an `.apk`.

```powershell
$env:GODOT = "$env:LOCALAPPDATA\Microsoft\WinGet\Links\godot_console.exe"
powershell -ExecutionPolicy Bypass -File tools/release.ps1
```

- Output: `export/InnworldRPG-v<version>-play.aab` (next to the zips and the apk).
- Only the AAB: add `-PlayOnly` to the command.
- Preset `Android Play` in `game/export_presets.cfg`: Gradle build, AAB, target API 36, min API 29 (Android 10),
  arm64-v8a. The old preset `Android` still makes the GitHub apk (no Gradle).
- The Gradle template goes in `game/android/` (gitignored). `tools/release.ps1` installs it when it is missing.
  It sets `GRADLE_OPTS` to 2 GB of memory (the default 4.5 GB crashed on this 16 GB PC) and no Gradle daemon
  (a daemon left running made the script wait for ever).
- If Godot crashes during the import (a known random crash), run the import first:
  `& $env:GODOT --headless --path game --import` (again if it crashes), then the script.
- The first Gradle build downloads Gradle and the Android libraries (some minutes).
- **Each upload needs a higher `version/code`.** Raise it in both Android presets in `game/export_presets.cfg`.

## 2. Signing (Play App Signing)

- Google keeps the real app signing key. We sign each upload with an **upload key**.
- Our upload key is the release keystore we already have: `%USERPROFILE%\.android\innworld-release.keystore`
  (alias `innworld`, ADR 0034). `tools/release.ps1` signs the AAB with it.
- If this key is lost, Google support can reset the upload key. But back it up anyway.
- Note: the GitHub apk and the Play app then have different signatures. A player can not update one with the
  other. They must uninstall first (saves are lost: `user_data_backup/allow=false`).

## 3. Developer account (the user does this)

1. Go to https://play.google.com/console/signup .
2. Pick **Personal** (one person) or **Organization** (needs a D-U-N-S number, a free company ID).
3. Pay the one-time fee (25 USD). Verify your ID and phone.
4. A new **Personal** account must run a **closed test with at least 12 testers for 14 days in a row** before it can
   ask for a public (production) release. An Organization account does not have this rule.

## 4. Upload order

1. Play Console > Create app. Name `Innworld RPG`, language English (US), Game, Free.
2. Fill "App content" (section 6) and "Store listing" (section 5).
3. Testing > Internal testing: upload the AAB. Install it on your phone from the test link. Play a short session.
4. Testing > Closed testing: same AAB, add 12+ testers (their Google emails), wait 14 days.
5. Apply for production. Google reviews it (some days).

## 5. Store listing

| Field | Value |
|---|---|
| App name (30 at most) | `Innworld RPG` |
| Short description (80 at most) | `A free fan-made pixel RPG. Run an inn, level by living, and change the story.` |
| App icon | `export/play/icon_512.png` (512 × 512, 32-bit PNG) |
| Feature graphic | `export/play/feature_graphic.png` (1024 × 500) |
| Phone screenshots | `export/play/screenshot_1.png` … `_6.png` (2304 × 1296, landscape) |
| Category | Game > Role Playing |
| Tags | Role playing, Pixel art, Fantasy, Turn-based, Single player, Offline |
| Contact email | the user's developer email (Play Console shows it to players) |
| Website | https://github.com/Daddy-Ousen/innworld-rpg |
| Privacy policy | https://github.com/Daddy-Ousen/innworld-rpg/blob/main/PRIVACY.md |

Make the graphics: `python tools/build_store_art.py` (reads `export/itch/screenshot_*.png`, writes `export/play/`).
The screenshots are from the PC build (no touch buttons). Better: take new ones on a phone later.

Marketing text says "pirateaba's Innworld". It never names a book or the series, not even in the credit line
(author's rule, section 0). The in-game credits (`CREDITS.md`) may keep the title: they are not marketing.

### Full description (4000 at most)

```
Innworld RPG is a free, fan-made RPG set in pirateaba's Innworld.

You are an unnamed Earther. You arrive in Innworld at the start of Book 1. The story goes on around you, day by day. What you do with your days is up to you.

The books define how the world begins. You decide what happens next.

• You level by living. Cook, fight, run, trade, talk. Every action feeds hidden class pools. At night the System can offer you a class. Say no, and that offer never comes back.
• Nights move the world. When you sleep, the day ends. You gain levels and Skills, and the events of the night happen.
• Canon is the default, not a rail. Do nothing, and the story happens as written. Step in, and you can change, delay or stop events. The world reacts to what you did.
• Fights are tactical. Turn-based on the map grid: action points, cover, combat Skills, mana and spells.
• A real place to live in. Liscor, Celum, the Floodplains, the inn on the hill, the dungeon below. People keep their own schedules. Work at the inn, cook, take guests, go hungry, and get through the winter.

In this alpha:
• Books 1–8 as story data: 1,403 events, 319 characters, 127 places
• 51 maps, day and night, winter snow
• Make your own Earther: name, look and background
• People talk: 35 characters have their own voice lines
• Classes, levels, Skills, spells, tactical combat, traps, cooking, money, hunger, travel
• Pixel art, animation, music and sound
• Touch controls, 3 save slots and a morning autosave
• No ads, no purchases, no internet needed, no data collected

This is an alpha. Expect bugs. Saves may not load in a later version.

Fan work: an unofficial, free, non-commercial fan game. It is not made or approved by pirateaba. The characters, places, world and story ideas belong to pirateaba and are used with credit. The game holds no text or art from the books: events are short summaries in our own words. Read pirateaba's story online and support the author.

Credits: art from the Liberated Pixel Cup (LPC) on OpenGameArt (CC-BY-SA), music by RandomMind and cynicmusic, sounds by Kenney (CC0), font Pixel Operator (CC0). Made with Godot. Full list and source code: github.com/Daddy-Ousen/innworld-rpg
```

## 6. App content answers

| Page | Answer |
|---|---|
| Privacy policy | the URL in section 5 |
| Ads | No, the app has no ads |
| App access | All functions work without special access (no login) |
| Content rating (IARC form) | Category: Game. Answer each question true. Our content: fantasy violence against monsters and people, characters die, blood is named in text (no gore drawn); text speaks of alcohol and drunk people (an inn); one event summary names an attempted sexual assault (not shown); no swearing, no gambling, no drugs, no purchases, no user chat. Expect about PEGI 12 – 16 / ESRB Teen |
| Target audience | 16 – 17 and 18+ only (not for children, so the Families rules do not apply) |
| Data safety | No data collected, no data shared. Data is not encrypted in transit (none is sent). No account, so no deletion request page |
| Government app | No |
| Financial features | None |
| Health | No |
| News app | No |

## 7. Known items before a public release

- **Large screens:** an app that targets API 36 can not lock landscape on a screen 600 dp or wider (tablets,
  open foldables). There the game can run in portrait. Test on a tablet (or the Android emulator) before production.
- **Only 64-bit ARM** (arm64-v8a). Most phones from 2017 on. Add `armeabi-v7a` for old 32-bit phones if testers need it.
- **Size:** the AAB must stay under 200 MB for the base download. Today it is about 90 MB.
- Gradle warns that its Android plugin was not tested with compile SDK 36. The build still works.

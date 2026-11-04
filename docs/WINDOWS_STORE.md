# Microsoft Store (Windows)

What we need to put Innworld RPG in the Microsoft Store, and the text for each Partner Center page.
Prepared 2026-11-04 (v0.2.1-alpha). Same author's rules as Google Play: see `docs/PLAY_STORE.md` section 0.
Design note: `docs/adr/0049-windows-store-msix.md`.

## 0. The short version

1. Make a Partner Center account (section 2). Free for one person (check the price on the sign-up page).
2. Reserve the name `Innworld RPG` and copy the three identity values (section 3).
3. Build: `release.ps1` → `build_windows_store_art.py` → `windows_store.ps1` (section 1). Result: `export/InnworldRPG-v<version>-store.msix`.
4. Create the submission and paste the text from sections 5 – 7. Upload the .msix and the images in `export/store_windows/listing/`.
5. Submit. Certification takes up to a few days.

What is ready already: the build scripts, all images, all text below, the privacy policy page. What only you can do:
the account, the name reservation, the three identity values, the age-rating form, the Submit button.

## 1. Build the package

```powershell
$env:GODOT = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe"
powershell -ExecutionPolicy Bypass -File tools/release.ps1          # the Windows build the package uses
python tools/build_windows_store_art.py                             # logos + listing images -> export/store_windows/
powershell -ExecutionPolicy Bypass -File tools/windows_store.ps1    # -> export/InnworldRPG-v<version>-store.msix
```

- The identity comes from `-IdentityName`, `-Publisher`, `-PublisherDisplayName`, or from the file
  `%USERPROFILE%\.innworld-store.txt` (outside git):
  ```
  identity=12345Publisher.InnworldRPG
  publisher=CN=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
  publisherdisplay=Your Publisher Name
  ```
- **Upload the .msix unsigned.** The Store signs it. We need no code-signing certificate.
- The package is `x64`, `Windows.Desktop`, Windows 10 1809 (10.0.17763) or newer, capability `runFullTrust`.
  The game exe is the same one as in the GitHub zip (the data is inside the exe).
- **Store version = game version with Major + 1**, last part 0: game `0.2.1-alpha` → `1.2.1.0`. The Store needs
  `Major.Minor.Build.0` and a Major above 0. Each upload must be higher than the one before. Game `1.0.0` → `2.0.0.0`.
  Override with `-StoreVersion`.
- The Windows SDK must be installed (`makeappx.exe`, `makepri.exe`, `signtool.exe`). It is on this PC.
- **Test it on your PC first (optional):** `windows_store.ps1 -Test` makes `export/InnworldRPG-v<version>-store-TEST.msix`
  with a throw-away identity and a self-signed certificate. Install steps print at the end (PowerShell as Administrator:
  trust the `.cer`, then `Add-AppxPackage`). Remove with `Get-AppxPackage InnworldRPG.Test | Remove-AppxPackage`.
  The test build packs and signs fine (checked 2026-11-04). **It was not installed or run**: do that once before you submit.
- Optional check: the Windows App Certification Kit (in the SDK) runs the same tests the Store runs.
- **Saves:** the Store version keeps its saves inside the package's own storage, apart from the zip version
  (`%APPDATA%\Godot\app_userdata\Innworld RPG`). A player who moves from the zip to the Store starts a new game.
  Say so in the release notes if it matters to you.

## 2. Developer account (the user does this)

1. Go to https://storedeveloper.microsoft.com and sign up as an **individual**. Microsoft made this free in
   September 2025 ([announcement](https://blogs.windows.com/windowsdeveloper/2025/09/10/free-developer-registration-for-individual-developers-on-microsoft-store/)).
   One report still showed a 19 USD fee on an older sign-up path: use the link above and look at the price before you pay.
2. Verify your identity (ID document and a selfie). Add a developer email (players can see the support email).
3. Open Partner Center: https://partner.microsoft.com/dashboard/apps-and-games/overview

## 3. Reserve the name and get the identity

1. Partner Center > Apps and games > New product > **MSIX or PWA app**.
2. Reserve the name `Innworld RPG`. If it is taken, use `Innworld RPG (fan game)`; the name is also the manifest `DisplayName`
   (change it in `tools/release/AppxManifest.template.xml` if you pick another).
3. Open the product > **Product management > Product identity**. Copy three values:
   - Package/Identity/Name → `identity=`
   - Package/Identity/Publisher → `publisher=` (starts with `CN=`)
   - Package/Properties/PublisherDisplayName → `publisherdisplay=`
4. Put them in `%USERPROFILE%\.innworld-store.txt` (section 1) and run `windows_store.ps1`.

## 4. Submission pages, in order

| Page | What to enter |
|---|---|
| Pricing and availability | Markets: all. Visibility: Public. Price: Free. No sale, no trial |
| Properties | Category: Games. Subcategory: Role playing. Privacy policy URL: https://github.com/Daddy-Ousen/innworld-rpg/blob/main/PRIVACY.md . Website: https://github.com/Daddy-Ousen/innworld-rpg . Support contact: your developer email. Game settings: single player only, no online features. System requirements: section 8. Product declarations: leave all unchecked |
| Age ratings | The questionnaire (IARC). Answers: section 7 |
| Packages | Upload `InnworldRPG-v<version>-store.msix`. Device family: Windows 10/11 Desktop. Leave "Xbox" off |
| Store listings (en-US) | Section 5 text and section 9 images |
| Submission options | Publishing: as soon as it passes certification. Notes for certification: section 6 |

## 5. Store listing text (en-US)

Marketing text says "pirateaba's Innworld". It never names a book or the series, not even in the credit line
(author's rule). The field limits below are the ones Partner Center showed at the time of writing; the page shows the live count.

**Product name:** `Innworld RPG`

**Short title** (Start tile, 40 at most): `Innworld RPG`

**Short description** (1,000 at most):
```
A free fan-made pixel RPG. Run an inn, level by living, and change the story. No ads, no purchases, no internet needed.
```

**Description** (10,000 at most):
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
• Books 1–9 as story data: more than 1,600 story events
• 53 maps, day and night, winter snow
• Make your own Earther: name, look and background
• People talk: many characters have their own voice lines
• Classes, levels, Skills, spells, tactical combat, traps, cooking, money, hunger, friends and quests
• Pixel art, animation, music and sound
• Keyboard and mouse, 3 save slots and a morning autosave
• No ads, no purchases, no internet needed, no data collected

This is an alpha. Expect bugs. Saves may not load in a later version.

Fan work: an unofficial, free, non-commercial fan game. It is not made or approved by pirateaba. The characters, places, world and story ideas belong to pirateaba and are used with credit. The game holds no text or art from the books: events are short summaries in our own words. Read pirateaba's story online and support the author.

Credits: art from the Liberated Pixel Cup (LPC) on OpenGameArt (CC-BY-SA), music by RandomMind and cynicmusic, sounds by Kenney (CC0), font Pixel Operator (CC0). Made with Godot. Full list and source code: github.com/Daddy-Ousen/innworld-rpg
```
(Check the counts again before each release: events 1,614 and maps 53 are from the v0.2.1-alpha smoke test.)

**What's new in this version** (release notes, 1,500 at most), for 1.2.1.0:
```
First Microsoft Store release (game version 0.2.1-alpha).
- Story days of the fan-made world now run through Book 9, up to the battle at the east gate.
- Tactical fights, spells and cover. Tasks from Erin, Pawn and Pisces. Friends give perks.
- Big story days warn you the day before.
- Saves in this version are separate from the zip download on GitHub.
```

**Features** (up to 20 lines, 200 characters each):
```
Level by living: every action feeds hidden class pools.
Canon is the default, not a rail: step in and change the story.
Turn-based tactical fights with cover, Skills and spells.
Run an inn, cook, trade, and get through the winter.
Books 1–9 as story data, 53 maps, day and night.
Free. No ads, no purchases, no internet, no data collected.
```

**Search terms** (7 at most, 30 characters each):
`fan game`, `pixel RPG`, `inn simulator`, `tactical RPG`, `fantasy RPG`, `isekai`, `offline RPG`

**Copyright and trademark info** (200 at most):
```
Unofficial fan game. Characters, places and world belong to pirateaba. Art under CC-BY-SA (LPC), see CREDITS.md in the app.
```

**Additional license terms:**
```
Free, non-commercial fan work. The game's own code and data are published at github.com/Daddy-Ousen/innworld-rpg. Third-party art, music and sounds keep their own licences: see CREDITS.md and the licenses folder in the app. Our edits of CC-BY-SA art are CC-BY-SA.
```

## 6. Notes for certification and the capability reason

**Notes for certification** (paste into Submission options):
```
Innworld RPG is a free, offline, single-player pixel RPG. No account, no sign-in, no network access, no in-app purchases, no ads.
To test: install, start the game, click New Game on the title screen and pick a start. WASD or the arrow keys walk, Space waits, the mouse clicks tiles in fights, H shows help. Saves are local.
It is an unofficial fan work set in an author's fictional world (pirateaba's Innworld). It follows the author's published fan-work rules: free, non-commercial, credited, no book text and no art from the books, no claim to be official. Evidence of the author's permission can be supplied on request.
The package uses the runFullTrust capability because the game is a normal Win32 program built with the Godot engine.
```
- Before you paste it, check the permission sentence is true to the wording you want to stand behind
  (`docs/PLAY_STORE.md` section 0 holds the Discord moderator decision of 2026-10-19). Keep that screenshot.
- Partner Center may ask for a reason for `runFullTrust`: "Win32 desktop game built with the Godot engine; it needs a normal desktop process and no system access beyond its own save folder."

## 7. Age rating (IARC questionnaire) answers

Same content as the Play form (`docs/PLAY_STORE.md` section 6). Category: Game. Our content: fantasy violence against
monsters and people, characters die, blood is named in text (no gore drawn); text speaks of alcohol and drunk people
(an inn); one event summary names an attempted sexual assault (not shown); no swearing, no gambling, no drugs,
no purchases, no user chat, no location sharing, no online play. Expect about PEGI 12 – 16, ESRB Teen.
Answer each question true. Do not lower an answer to get a lower rating: a wrong answer can pull the app.

## 8. System requirements (Properties page)

- OS: Windows 10 version 1809 or newer, 64-bit.
- Minimum: 4 GB RAM, a GPU that supports Direct3D 12 or Vulkan 1.2 (the project uses Godot's default Forward+ renderer), 300 MB free disk, keyboard and mouse.
- Recommended: 8 GB RAM, any GPU from the last 8 years.
(These are our estimates for a small 2D Godot game: no test on weak hardware yet. Change them if testers report more.
Open question: a PC with an old GPU may not start the game. Test one before you promise more.)

## 9. Images

All made by `python tools/build_windows_store_art.py` into `export/store_windows/` (gitignored). Our own art and real game
frames only: no book covers, no book or series name, no extra logos on screenshots (Store rule).

| Partner Center field | File | Size |
|---|---|---|
| Screenshots (1 needed, up to 10, at least 4 advised) | `listing/screenshot_1.png` … `_6.png` | 2304 × 1296 (min 1366 × 768) |
| 1:1 App tile icon | `listing/icon_300.png` | 300 × 300 |
| 1:1 Box art | `listing/box_art_1080.png` | 1080 × 1080, title in the top two thirds |
| 2:3 Poster art | `listing/poster_720x1080.png` | 720 × 1080, title in the top two thirds |
| Package logos (inside the .msix) | `assets/*.png` (44, 71, 150, 310, wide 310 × 150, StoreLogo; scales 100 – 400; taskbar target sizes) | made into the package by `windows_store.ps1` |

- Not made: the 16:9 Super hero art (1920 × 1080, no text, no UI) and trailers. They are optional; the hero needs art with
  no HUD. The Xbox images are not needed (we do not ship to Xbox).
- Screenshot captions (200 at most), in order:
  1. `Walk through the inn on the hill and meet the guests.`
  2. `Turn-based fights on a map grid, with action points and cover.`
  3. `At night the System can offer you a class. You can refuse it.`
  4. `Buy, sell and trade in the markets.`
  5. `The world goes on through winter.`
  6. `The battle at the gate of Liscor.`
  (Check each against the picture; the order matches `export/itch/screenshot_1_…6_…`.)
- The Windows exe itself still shows the Godot icon in Explorer (`application/modify_resources=false` in the Windows
  preset). The Start tile, the taskbar entry of the Store version and the in-game window use our icon. Setting the exe
  icon needs the `rcedit` tool (a new dependency: ask first).

## 10. After the first submission

- **Each update:** raise the game version, run section 1 again, Partner Center > Update > Packages: upload the new
  .msix (the Store version is higher by itself), new release notes, Submit. Run the Windows App Certification Kit first.
- **Do not name** a book or the series in any field above or in a reply to a reviewer. Say "pirateaba's Innworld".
- If certification fails, the report names the policy and the file. The usual causes: a wrong identity value in the
  manifest, a missing icon size, or an age rating that does not match the content.
- Add the Store link to `README.md` and the itch.io page after the listing goes live.

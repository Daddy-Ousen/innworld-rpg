# ADR 0034: Android build (M20.2)

Status: accepted (2026-10-08)

## Decision
- Export preset `Android` in `game/export_presets.cfg`: arm64-v8a only, no Gradle build (uses the prebuilt template),
  package `org.daddyousen.innworldrpg`, no permissions, immersive mode.
- `window/handheld/orientation=6` (sensor landscape) in `project.godot`: landscape only.
- `rendering/textures/vram_compression/import_etc2_astc=true`: Android export refuses without it.
- Output: `export/android/InnworldRPG-debug.apk` (about 89 MB, gitignored). Signed with the Godot debug keystore.

## Build (PowerShell, from the repo root)
```powershell
& $env:GODOT --headless --path game --export-debug Android ../export/android/InnworldRPG-debug.apk
git checkout -- game/assets   # the export rewrites .import files
```
Needs: Android SDK (build-tools 34.0.0), JDK 17 and the 4.7.2 Android templates, set in Editor Settings.

## Install on a phone
Turn on USB debugging, plug in, then:
```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" install -r export/android/InnworldRPG-debug.apk
```

## Release APK
- Icon: `game/icon.png`, drawn by `tools/build_icon.py` (original pixel art), set in `project.godot`.
- Keystore: `%USERPROFILE%\.android\innworld-release.keystore` (alias `innworld`; password in `%USERPROFILE%\.android\innworld-release.txt`).
  It is outside the repo and `.gitignore` blocks `*.keystore`. BACK IT UP: a lost key means no updates to an installed app.
- The preset holds no secret. Export reads three env vars:
```powershell
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH = "<keystore path>"
$env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = "innworld"
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = "<password>"
& $env:GODOT --headless --path game --export-release Android ../export/android/InnworldRPG-v0.1.2-alpha.apk
```
- Output: `export/android/InnworldRPG-v0.1.2-alpha.apk` (87 MB, signed with the release key).

## Not done
- AAB (Play Store) needs the Gradle build; not set up.
- Not played on a device yet.

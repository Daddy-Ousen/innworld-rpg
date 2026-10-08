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

## Not done
- Release APK / AAB: needs a release keystore (the user makes it; never commit it).
- Project icon: none set (Godot logs an error and uses its default). Needs art.
- Not played on a device yet.

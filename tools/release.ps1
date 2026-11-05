# Build the release files (Windows, Linux, Web zips + signed Android apk + Google Play aab) into export/. See ADR 0029 and ADR 0031 in docs/DECISIONS.md.
#
#   $env:GODOT = "<path to Godot_v4.7.2-stable_win64_console.exe>"
#   powershell -ExecutionPolicy Bypass -File tools/release.ps1
#
# Needs the Godot 4.7.2 export templates (Editor > Manage Export Templates).
# Use the *console* exe: the WinGet "godot" link returns before Godot is done.
# The version comes from game/project.godot (application/config/version).
# Android: signed with the release key kept OUTSIDE the repo (ADR 0034). If the three env vars
# GODOT_ANDROID_KEYSTORE_RELEASE_PATH / _USER / _PASSWORD are not set, they are read from
# %USERPROFILE%\.android\innworld-release.txt (lines path=, alias=, password=).
# Also bump version/code in both Android presets (game/export_presets.cfg) for each release.
# -PlayOnly builds only the Google Play aab (docs/PLAY_STORE.md).

param([string]$Godot = $env:GODOT, [switch]$PlayOnly)

# Godot writes notes to stderr: do not let them stop the script. Checks throw below.
$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
if (-not $Godot) { $Godot = (Get-Command godot -ErrorAction Stop).Source }

$m = Select-String -Path "$root/game/project.godot" -Pattern '^config/version="(.+)"'
if (-not $m) { throw 'No config/version in game/project.godot' }
$version = $m.Matches[0].Groups[1].Value
Write-Host "Innworld RPG v$version"

$out = "$root/export"
$builds = @(
    @{ Preset = 'Windows Desktop'; Dir = 'windows'; File = 'InnworldRPG.exe'; Pack = 'InnworldRPG.exe' },
    @{ Preset = 'Linux'; Dir = 'linux'; File = 'InnworldRPG.x86_64'; Pack = 'InnworldRPG.x86_64' },
    # Web: index.html at the zip root (itch.io and GitHub Pages need it there); the data is index.pck.
    @{ Preset = 'Web'; Dir = 'web'; File = 'index.html'; Pack = 'index.pck'; Web = $true }
)

if ($PlayOnly) { $builds = @() }
foreach ($b in $builds) {
    $name = "InnworldRPG-v$version-$($b.Dir)"
    $dir = "$out/$name"
    if (Test-Path $dir) { Remove-Item -Recurse -Force $dir }
    New-Item -ItemType Directory -Force $dir | Out-Null
    $bin = "$dir/$($b.File)"

    Write-Host "Export $($b.Preset)..."
    & $Godot --headless --path "$root/game" --export-release $b.Preset $bin *> "$out/export_$($b.Dir).log"
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $bin)) { throw "Export failed: see export/export_$($b.Dir).log" }

    Write-Host "Smoke test $($b.Preset)..."
    $smoke = & $Godot --headless --main-pack "$dir/$($b.Pack)" -s "$root/tools/release/smoke.gd" 2>&1 | Select-String 'SMOKE'
    $smoke | ForEach-Object { Write-Host "  $_" }
    if ($LASTEXITCODE -ne 0) { throw "Smoke test failed for $($b.Preset)" }

    if (-not $b.Web) {
        $readme = (Get-Content -Raw "$root/tools/release/README-PLAYERS.txt").Replace('{VERSION}', "v$version")
        Set-Content -Path "$dir/README.txt" -Value $readme -NoNewline
    }
    Copy-Item "$root/CREDITS.md" $dir
    New-Item -ItemType Directory -Force "$dir/licenses" | Out-Null
    Get-ChildItem -Recurse -Filter *.txt "$root/game/assets" | Copy-Item -Destination "$dir/licenses"

    $zip = "$out/$name.zip"
    if (Test-Path $zip) { Remove-Item -Force $zip }
    # tar.exe (Windows 10+) writes '/' in zip paths; Compress-Archive in PowerShell 5 writes backslashes.
    if ($b.Web) { $items = (Get-ChildItem $dir).Name; tar.exe -a -c -f $zip -C $dir @items } else { tar.exe -a -c -f $zip -C $out $name }
    if ($LASTEXITCODE -ne 0) { throw "Zip failed: $zip" }
    Write-Host "Made $zip"
}

# Android apk (signed with the release key). Not zipped: the .apk is the release file.
if (-not $env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH) {
    $keyFile = "$env:USERPROFILE/.android/innworld-release.txt"
    if (-not (Test-Path $keyFile)) { throw "No release key: set GODOT_ANDROID_KEYSTORE_RELEASE_* or make $keyFile" }
    $kv = @{}
    Get-Content $keyFile | ForEach-Object { $k, $v = $_ -split '=', 2; $kv[$k] = $v }
    $env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH = $kv.path
    $env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = $kv.alias
    $env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = $kv.password
}
if (-not $PlayOnly) {
    Write-Host 'Export Android...'
    $apk = "$out/InnworldRPG-v$version-android.apk"
    if (Test-Path $apk) { Remove-Item -Force $apk }
    & $Godot --headless --path "$root/game" --export-release Android $apk *> "$out/export_android.log"
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $apk)) { throw 'Export failed: see export/export_android.log' }
    Write-Host "Made $apk"
}

# Google Play AAB: preset 'Android Play' (Gradle build, signed with the same key, which Play uses as the upload key).
# See docs/PLAY_STORE.md. The Gradle template lives in game/android/ (gitignored); the first run installs it.
# GRADLE_OPTS: no daemon, because a daemon left running holds Godot's output open and the script then waits for
# ever. Without a daemon Gradle builds in its own small JVM (64 MB), so -Xmx2g; the template's 4.5 GB crashed a 16 GB PC.
$env:GRADLE_OPTS = '-Xmx2g -Dorg.gradle.daemon=false -Dorg.gradle.jvmargs=-Xmx2g'
$install = @()  # an `if` expression would unroll a one-item array to a string, and the splat below would drop it
if (-not (Test-Path "$root/game/android/build")) { $install = @('--install-android-build-template') }
Write-Host 'Export Android Play (aab)...'
$aab = "$out/InnworldRPG-v$version-play.aab"
if (Test-Path $aab) { Remove-Item -Force $aab }
& $Godot --headless --path "$root/game" @install --export-release 'Android Play' $aab *> "$out/export_play.log"
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $aab)) { throw 'Export failed: see export/export_play.log' }
Write-Host "Made $aab"

Write-Host 'Done. If git now shows .import files as changed and you did not change art:'
Write-Host '  git checkout -- game/assets'

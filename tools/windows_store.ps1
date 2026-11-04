# Build the Microsoft Store package (.msix) from the Windows build. See docs/WINDOWS_STORE.md and ADR 0049.
#
#   1. powershell -ExecutionPolicy Bypass -File tools/release.ps1      (makes export/InnworldRPG-v<version>-windows)
#   2. python tools/build_windows_store_art.py                         (makes export/store_windows/assets)
#   3. powershell -ExecutionPolicy Bypass -File tools/windows_store.ps1
#
# The three package names come from Partner Center (Product identity page). Give them as parameters, or put them in
# %USERPROFILE%\.innworld-store.txt (outside git), one per line:
#     identity=12345Publisher.InnworldRPG
#     publisher=CN=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
#     publisherdisplay=Your Publisher Name
# The Store signs the package itself: upload the .msix unsigned. -Test builds a package for your own PC instead:
# a placeholder identity and a self-signed certificate (export/store_windows/InnworldRPG-test.cer / .pfx).
# Needs the Windows 10/11 SDK (makeappx.exe, makepri.exe, signtool.exe).

param(
    [string]$IdentityName,
    [string]$Publisher,
    [string]$PublisherDisplayName,
    [string]$StoreVersion,
    [switch]$Test
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

# --- version -----------------------------------------------------------------------------------
$m = Select-String -Path "$root/game/project.godot" -Pattern '^config/version="(.+)"'
if (-not $m) { throw 'No config/version in game/project.godot' }
$version = $m.Matches[0].Groups[1].Value
if (-not $StoreVersion) {
    # The Store wants Major.Minor.Build.0 and a Major above 0. Game 0.2.1-alpha -> 1.2.1.0 (Major + 1).
    if ($version -notmatch '^(\d+)\.(\d+)\.(\d+)') { throw "Can not read the version '$version'" }
    $StoreVersion = '{0}.{1}.{2}.0' -f ([int]$Matches[1] + 1), $Matches[2], $Matches[3]
}
if ($StoreVersion -notmatch '^[1-9]\d{0,4}\.\d{1,5}\.\d{1,5}\.0$') {
    throw "Store version '$StoreVersion' is not valid: it needs Major.Minor.Build.0 with Major above 0 and the last part 0"
}

# --- identity ----------------------------------------------------------------------------------
$cfg = @{}
$cfgFile = Join-Path $env:USERPROFILE '.innworld-store.txt'
if (Test-Path $cfgFile) {
    foreach ($line in Get-Content $cfgFile) { if ($line -match '^\s*(\w+)\s*=\s*(.+?)\s*$') { $cfg[$Matches[1]] = $Matches[2] } }
}
if ($Test) {
    $IdentityName = 'InnworldRPG.Test'
    $Publisher = 'CN=InnworldRPG Test'
    $PublisherDisplayName = 'Innworld RPG Test'
} else {
    if (-not $IdentityName) { $IdentityName = $cfg['identity'] }
    if (-not $Publisher) { $Publisher = $cfg['publisher'] }
    if (-not $PublisherDisplayName) { $PublisherDisplayName = $cfg['publisherdisplay'] }
    if (-not $IdentityName -or -not $Publisher -or -not $PublisherDisplayName) {
        throw 'Missing identity. Reserve the app name in Partner Center, then give -IdentityName, -Publisher and -PublisherDisplayName (or fill %USERPROFILE%\.innworld-store.txt). Use -Test for a local test package.'
    }
}
if ($Publisher -notmatch '^CN=') { throw "Publisher must start with CN= (copy it from Partner Center, Product identity): '$Publisher'" }

# --- tools -------------------------------------------------------------------------------------
function Find-SdkTool([string]$name) {
    $hit = Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits\10\bin\*\x64\$name" -ErrorAction SilentlyContinue |
        Sort-Object { [version]($_.FullName -replace '.*\\bin\\([\d.]+)\\x64\\.*', '$1') } -Descending | Select-Object -First 1
    if (-not $hit) { throw "$name not found. Install the Windows 10/11 SDK (https://developer.microsoft.com/windows/downloads/windows-sdk/)." }
    $hit.FullName
}
$makeappx = Find-SdkTool 'makeappx.exe'
$makepri = Find-SdkTool 'makepri.exe'

# --- inputs ------------------------------------------------------------------------------------
$buildDir = "$root/export/InnworldRPG-v$version-windows"
if (-not (Test-Path "$buildDir/InnworldRPG.exe")) { throw "No $buildDir/InnworldRPG.exe. Run tools/release.ps1 first." }
$assets = "$root/export/store_windows/assets"
if (-not (Test-Path "$assets/StoreLogo.scale-100.png")) { throw "No Store logos in $assets. Run: python tools/build_windows_store_art.py" }

# --- stage the package folder ------------------------------------------------------------------
$work = "$root/export/store_windows"
$pkg = "$work/package"
if (Test-Path $pkg) { Remove-Item -Recurse -Force $pkg }
New-Item -ItemType Directory -Force "$pkg/Assets" | Out-Null
Copy-Item "$buildDir/InnworldRPG.exe" $pkg
Copy-Item "$buildDir/CREDITS.md" $pkg
if (Test-Path "$buildDir/licenses") { Copy-Item -Recurse "$buildDir/licenses" "$pkg/licenses" }
Copy-Item "$assets/*.png" "$pkg/Assets"

$xml = (Get-Content -Raw "$root/tools/release/AppxManifest.template.xml").
    Replace('{IDENTITY_NAME}', $IdentityName).Replace('{PUBLISHER}', $Publisher).
    Replace('{PUBLISHER_DISPLAY_NAME}', $PublisherDisplayName).Replace('{STORE_VERSION}', $StoreVersion)
[System.IO.File]::WriteAllText("$pkg/AppxManifest.xml", $xml, (New-Object System.Text.UTF8Encoding($false)))

# --- resources.pri: lets Windows pick the right logo size ---------------------------------------
$pri = "$work/priconfig.xml"
& $makepri createconfig /cf $pri /dq en-US /o | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'makepri createconfig failed' }
& $makepri new /pr $pkg /cf $pri /mn "$pkg/AppxManifest.xml" /of "$pkg/resources.pri" /o | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'makepri new failed' }

# --- pack --------------------------------------------------------------------------------------
$out = "$root/export/InnworldRPG-v$version-store.msix"
if ($Test) { $out = "$root/export/InnworldRPG-v$version-store-TEST.msix" }
if (Test-Path $out) { Remove-Item -Force $out }
& $makeappx pack /d $pkg /p $out /o | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'makeappx pack failed' }
Write-Host ("Made {0} ({1:N1} MB), Store version {2}" -f $out, ((Get-Item $out).Length / 1MB), $StoreVersion)

# --- test signing (own PC only) ----------------------------------------------------------------
if ($Test) {
    $signtool = Find-SdkTool 'signtool.exe'
    $pfx = "$work/InnworldRPG-test.pfx"
    $cer = "$work/InnworldRPG-test.cer"
    $pass = ConvertTo-SecureString -String 'innworld-test' -Force -AsPlainText
    $cert = New-SelfSignedCertificate -Type Custom -Subject $Publisher -KeyUsage DigitalSignature `
        -FriendlyName 'Innworld RPG test' -CertStoreLocation 'Cert:\CurrentUser\My' `
        -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.3', '2.5.29.19={text}')
    Export-PfxCertificate -Cert $cert -FilePath $pfx -Password $pass | Out-Null
    Export-Certificate -Cert $cert -FilePath $cer | Out-Null
    Remove-Item "Cert:\CurrentUser\My\$($cert.Thumbprint)"   # the files are enough; keep the store clean
    & $signtool sign /fd SHA256 /a /f $pfx /p 'innworld-test' $out | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'signtool sign failed' }
    Write-Host 'Signed with a self-signed test certificate. To install on this PC (PowerShell as Administrator):'
    Write-Host "  Import-Certificate -FilePath `"$cer`" -CertStoreLocation Cert:\LocalMachine\TrustedPeople"
    Write-Host "  Add-AppxPackage `"$out`""
    Write-Host 'Remove it later: Get-AppxPackage InnworldRPG.Test | Remove-AppxPackage, then delete the certificate from Trusted People.'
} else {
    Write-Host 'Upload this unsigned .msix in Partner Center > Packages. The Store signs it.'
}

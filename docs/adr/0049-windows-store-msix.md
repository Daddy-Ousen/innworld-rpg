# ADR 0049: Microsoft Store package (MSIX)

Status: accepted (2026-11-04)

## Decision
- Ship to the Microsoft Store as an **MSIX package** that wraps the same `InnworldRPG.exe` as the GitHub Windows zip
  (`binary_format/embed_pck=true`, so one file holds the code and the data). No new export preset, no engine change.
- The package is built by `tools/windows_store.ps1` from the Windows build folder made by `tools/release.ps1`.
  The manifest comes from `tools/release/AppxManifest.template.xml`. The logos come from `tools/build_windows_store_art.py`.
  Tools: `makeappx.exe`, `makepri.exe`, `signtool.exe` from the Windows SDK (already on the dev PC; no new dependency).
- **The Store signs the package.** We upload it unsigned, so we need no code-signing certificate. (An installer hosted
  on our own site would need a certificate from a trusted authority: that costs money every year, so we did not pick it.)
- Capability `runFullTrust` only. The game is a normal Win32 program. No internet, no file or device capability.
- **Store version = game version with Major + 1, last part 0** (`0.2.1-alpha` → `1.2.1.0`). The Store reserves the last
  part and does not allow a first part of 0.
- Package identity (`Name`, `Publisher`, `PublisherDisplayName`) is **not** in git. It comes from Partner Center and goes in
  `%USERPROFILE%\.innworld-store.txt` or the script parameters. `-Test` uses a throw-away identity and a self-signed certificate.
- Same author's rules as Play (no book or series name, no book art, free, no ads). Text and answers: `docs/WINDOWS_STORE.md`.

## Consequences
- The Store version has its own save folder (MSIX storage), apart from the zip version.
- The exe icon in Explorer is still the Godot default (`application/modify_resources=false`). Fixing it needs `rcedit`: ask first (CLAUDE.md rule 11).
- Not yet checked: installing and running the signed test package (`windows_store.ps1 -Test`). Only packing and signing were run.
- Each release needs one more manual step: upload the new .msix in Partner Center.

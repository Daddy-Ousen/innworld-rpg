# Kickoff — moving to Claude Code

## 1. Install (PowerShell, one time)
Claude Code runs inside the Claude desktop app (Code tab). It still needs these tools on your PC, because it runs your commands locally:
```powershell
winget install Git.Git            # required: Claude Code on Windows uses Git Bash
winget install GodotEngine.GodotEngine
winget install Python.Python.3.12
```
Restart the Claude desktop app after the installs, so it sees the new PATH. Check in PowerShell:
```powershell
git --version; python --version
Get-Command godot*    # find the Godot exe name/path
```
If `godot` is not found, add the folder of the Godot exe to your user PATH:
```powershell
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\path\to\godot\folder", "User")
```
Or tell Claude Code the full exe path in the first session and have it save it in CLAUDE.md.

## 2. Start
1. `git init` once:
   ```powershell
   cd "D:\ClaudeC\Innworld RPG"
   git init
   ```
2. Open the Claude desktop app → **Code** tab.
3. Select the folder `D:\ClaudeC\Innworld RPG` as the working folder (local, not cloud).
4. Claude Code reads `CLAUDE.md` automatically.

## 3. Session prompts (paste one per session)
Set the mode to **Plan** first (mode picker near the prompt box). Approve the plan, then switch to a mode that edits files.
Start a **new session** per milestone.

**Session 1 — M0**
> Read CLAUDE.md, docs/DESIGN.md and docs/ROADMAP.md. Do milestone M0 only. Create the Godot 4 project in `game/`, install GUT (a version that matches my Godot version) into `game/addons/gut`, create the folder layout, `core/rng.gd` and `core/game_state.gd` with JSON save/load and `save_version`, and one GUT test. Show me the headless test command output. Commit.

**Session 2 — M1 part 1**
> Read CLAUDE.md and the M1 section of docs/ROADMAP.md. Plan the data schemas for actions, classes and skills first and show them to me before you write code. Then build the clock, action log, tag system and XP formula with tests.

**Session 3 — M1 part 2**
> Continue M1: class candidates, offers, decline blacklist, levels, dilution, skills, night pipeline, debug text console. Finish with the `sim_30_days` test.

**Session 4 — M2**
> Do M2. Write `tools/extract_epub.py` for the Book 1 ebook (it contains images; skip them). Write the event schema validator. Then extract event candidates from the first 10 chapters, one chapter at a time, with `canon_ref` and `confidence`. Stop for my review before committing events.

Then M3 → M6 the same way: one milestone (or half) per session.

## 4. Habits that keep AI-built code healthy
- Start a new session per milestone. Long sessions drift.
- Use `/clear` (or a new session) between unrelated tasks.
- Use the diff view in the app to review changes before you accept them.
- Allow it to run `godot --headless …` and `git` without asking each time; keep file deletes on "ask".
- Review every diff that touches `game/core/` or a JSON schema.
- When an agent breaks a rule, add the rule to CLAUDE.md so it does not happen again.
- Tag a git commit at each finished milestone: `git tag m1-done`.

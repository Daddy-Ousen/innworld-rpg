# Cloud sessions (Claude Code on the web and in the Claude app)

This repo is ready for Claude Code cloud sessions. A cloud session runs on a Linux VM. It clones this repo,
then a start hook (`tools/cloud/setup.sh`) sets it up. You steer it from claude.ai/code or the Claude app.

## What the setup does (by itself, each session)
1. Installs Godot 4.7.2. It tries the official download first. If that is blocked, it uses the unchanged copy
   in this repo's Releases (tag `tools-godot-4.7.2`).
2. Installs Pillow (for the art tools).
3. Links the Book 6 and Book 7 text into `canon/raw/` from the PRIVATE repo `Daddy-Ousen/innworld-canon-raw`.
   `canon/raw/` is gitignored. The book text never goes into this public repo.
4. Sets the git name to Daddy-Ousen.
5. Runs the Godot import (about 2 minutes).

You see `[setup] ...` lines at the start of the session. All lines must say ok, or name the books.

## One-time setup (do this before you travel)
1. **Give Claude access to the private repo.** Open https://github.com/apps/claude, select **Configure**, then
   your account. Under **Repository access**, add `innworld-canon-raw` (keep `innworld-rpg`). Save.
   (If you connected GitHub with `/web-setup` instead, your `gh` token already covers both repos.)
2. **Optional, makes each session start faster.** At claude.ai/code, open your cloud environment settings.
   Put this in the **Setup script** field. The environment then keeps Godot between sessions:
   ```bash
   #!/bin/bash
   curl -fsSL https://raw.githubusercontent.com/Daddy-Ousen/innworld-rpg/main/tools/cloud/install_godot.sh | bash
   ```
3. **Optional, for long test runs.** In the same settings, add these environment variables:
   ```
   BASH_DEFAULT_TIMEOUT_MS=600000
   BASH_MAX_TIMEOUT_MS=1800000
   ```
4. Keep the network access at **Trusted** (the default).

## How to start a session
1. Open claude.ai/code (or the Code tab in the Claude app). Select **New session**.
2. Select the repo `Daddy-Ousen/innworld-rpg` only, branch `main`. (Only one repo: with two repos the start
   hook does not run.)
3. Paste the next prompt from the task queue below.
4. Answer its questions when it asks. It waits for you.
5. When it opens a PR, check it and merge it on GitHub (the GitHub app works).
6. Merge BEFORE you start the next session. The next session starts from `main`.

If the setup line says `book text: NOT FOUND`, the private repo access (step 1) is missing. Fix it, then
start a new session. Only the book tasks need the text.

If it still says NOT FOUND: start the session with BOTH repos (`innworld-rpg` and `innworld-canon-raw`).
With two repos the hook does not run, so begin your prompt with:
> First run `bash innworld-rpg/tools/cloud/setup.sh --force`, then work inside `innworld-rpg/` and read its CLAUDE.md.

## What a cloud session cannot do
- Play the game or show it. The "you play a fight" checks wait until you are home.
- Read Books 1–5 text. It uses the canon JSON for those books.
- Push tags (maybe). It writes "tag pending" in `progress.md`. At home, run the tag commands it lists.

## Task queue (one session each, in this order)
Each prompt is ready to paste.

1. **M17.6 Cover and position**
   > Do M17.6 (cover and position) from docs/ROADMAP.md. Follow CLAUDE.md. Plan first and write the plan
   > to docs/plans/m17.6.md. Ask me the open choices, then build, test, update the docs, and open a PR.
2. **M17.7 Enemy abilities and balance** (last M17 step: full suite before the PR)
   > Do M17.7 from docs/ROADMAP.md. Follow CLAUDE.md. Plan first (docs/plans/m17.7.md), ask me the open
   > choices, then build, run the full suite in a subagent, update the docs, and open a PR.
3. **M18.P Book 6 plan**
   > Do M18.P: plan Book 6 (The General of Izril) like ADR 0020 did for Book 5. Read the chapters in
   > canon/raw/book6 with subagents (summaries only). Write ADR 0028 and the M18 steps in docs/ROADMAP.md.
   > Ask me the open choices. Open a PR with the plan only.
4. **M18.0 … M18.n Book 6 steps** (one session per step, as the approved plan lists them)
   > Do the next open M18 step in docs/ROADMAP.md. Follow CLAUDE.md and ADR 0028. Ask me the stage and hook
   > choices first. Then build, test, update the docs, and open a PR.
5. **M19.P Book 7 plan**, then **M19.0 … M19.n** (same prompts, with Book 7, ADR 0029, canon/raw/book7)

To continue after a break, paste: "Read progress.md and handoff.md. Go on with the next open task."

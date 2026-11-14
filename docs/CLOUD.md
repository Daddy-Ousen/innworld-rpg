# Cloud sessions (Claude Code on the web and in the Claude app)

This repo is ready for Claude Code cloud sessions. A cloud session runs on a Linux VM. It clones this repo,
then a start hook (`tools/cloud/setup.sh`) sets it up. You steer it from claude.ai/code or the Claude app.

## What the setup does (by itself, each session)
1. Installs Godot 4.7.2. It tries the official download first. If that is blocked, it uses the unchanged copy
   in this repo's Releases (tag `tools-godot-4.7.2`).
2. Installs Pillow (for the art tools).
3. Links the text of Books 1 – 10 into `canon/raw/` from the PRIVATE repo `Daddy-Ousen/innworld-canon-raw`.
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

## New Claude account or new computer
A cloud environment and its GitHub link belong to one Claude account. On a new account, do the one-time setup above
again: connect GitHub as Daddy-Ousen with access to both repos, then put the setup script and the two variables in the
new environment. The computer needs only a browser or the Claude app: no Godot, no Python, no clone.
- The rules for a session are in `CLAUDE.md` in this repo. Memory files and private settings on the home PC do not
  come along.
- Releases (apk, Store package, tags) need the keystore on the home PC. Do them there.
- Play checks: use the browser build on itch.io, the apk on a phone, or the home PC.

## How to start a session
1. Open claude.ai/code (or the Code tab in the Claude app). Select **New session**.
2. Select the repo `Daddy-Ousen/innworld-rpg` only, branch `main`. (Only one repo: with two repos the start
   hook does not run.)
3. Paste the next prompt from the task queue below.
4. Answer its questions when it asks. It waits for you.
5. When it opens a PR, check it and merge it on GitHub (the GitHub app works).
6. Merge BEFORE you start the next session. The next session starts from `main`.

If the setup line says `book text: NOT FOUND`, you do not need a new session. The session proxy lets the hook
reach only the repos attached to the session. Claude attaches `innworld-canon-raw` itself (add_repo), clones it
to `/home/user/innworld-canon-raw` and links `canon/raw/book<N>` for every book in it (seen on 2026-10-01). If the attach
fails, step 1 is missing. Only the book tasks need the text.

If it still says NOT FOUND: start the session with BOTH repos (`innworld-rpg` and `innworld-canon-raw`).
With two repos the hook does not run, so begin your prompt with:
> First run `bash innworld-rpg/tools/cloud/setup.sh --force`, then work inside `innworld-rpg/` and read its CLAUDE.md.

## What a cloud session cannot do
- Play the game or show it. The "you play a fight" checks wait until you are home.
- Build character art (looks, sheets). That needs a clone of the LPC generator (`tools/build_sprites.py --ulpc`).
  M37 does not need art. Ask first if a step wants a new look.
- Run the full test suite on a whim. Run only the scripts a step lists (CLAUDE.md "Test scope"). A single
  script such as `unit_spells` can take 7 minutes: run it in the background.
- Push tags (maybe). It writes "tag pending" in `progress.md`. At home, run the tag commands it lists.

## Next task
**M37 Book 10** (plan `docs/plans/m37.md`, ADR 0048; text in `canon/raw/book10`). M37.P is merged, M37.0 is skipped.
M37.1 is done. Next is M37.2 (Tails and Scales map), then M37.3 – M37.9, one session per step, in order.
The open items of the game audit (`docs/AUDIT_2026-11-11.md`) are the other queue: see `handoff.md` for the next one.
Prompt to paste:
> Do the next open M37 step in docs/plans/m37.md. Read progress.md and handoff.md first. Follow CLAUDE.md
> and ADR 0048. Ask me the stage and hook choices first. Then build, run only the tests the step lists,
> update the docs, and open a PR.

Do not run two canon batches of one book at once: two sessions that edit the same JSON file will conflict.
To continue after a break, paste: "Read progress.md and handoff.md. Go on with the next open task."

## Before each cloud session
- [ ] The last session's PR is merged into `main` (the next session starts from `main`).
- [ ] The setup line says `book text: book1 … book10`. If not, see "If the setup line says `book text: NOT FOUND`".
- [ ] You are ready to answer questions. A step stops and waits for your picks.

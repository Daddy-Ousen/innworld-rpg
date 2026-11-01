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
  M35 to M37 do not need art. Ask first if a step wants a new look.
- Run the full test suite on a whim. Run only the scripts a step lists (CLAUDE.md "Test scope"). A single
  script such as `unit_spells` can take 7 minutes: run it in the background.
- Push tags (maybe). It writes "tag pending" in `progress.md`. At home, run the tag commands it lists.

## Task queue (one session each, in this order)
Each prompt is ready to paste. Finished tasks are listed at the bottom of this file.
**Model · effort:** pick the model and the effort in the session's menu BEFORE you send the first prompt.
Reading agents that a session starts run on Sonnet · medium by themselves.
Rule of thumb: Sonnet · high for data from the books; Opus · high for plans, cascades and anything with a
schema or save question; Opus · medium for engine code and fight-stage logic.

1. **M35 New content** (plan `docs/plans/m35.md`; four sessions; the first one writes ADR 0046)
   **Model · effort per session:**
   - M35.0 Ceria's magic line: **Sonnet · high** (built 2026-11-01, ADR 0046; skip it)
   - M35.1 Stat sheets: **Sonnet · medium**
   - M35.2 Runners' Guild staff in Invrisil: **Sonnet · high**
   - M35.3 Magnolia's whereabouts: **Opus · high** (built 2026-11-01; skip it)
   > Do M35.0 (Ceria's magic line) from docs/plans/m35.md. Read progress.md and handoff.md first. Follow
   > CLAUDE.md. Read the chapters in canon/raw with subagents (summaries only). Ask me the open choices, then
   > build, run only the tests the plan lists, update the docs, and open a PR.
   > (For the others, say M35.1 stat sheets, M35.2 Runners' Guild staff in Invrisil, or M35.3 Magnolia's whereabouts.)
2. **M36.P Book 9 plan** (plan `docs/plans/m36.md`, text in `canon/raw/book9`). Needs no earlier M35 PR.
   **Model · effort: Opus · high** (a plan with a day map, conflicts and schema questions).
   > Do M36.P: plan Book 9 (Tears of Liscor) like M28.P did for Book 8 (docs/plans/m28.md, ADR 0043). Follow
   > docs/plans/m36.md. Read progress.md and handoff.md first. Read all of canon/raw/book9 with subagents
   > (summaries only). Write the plan into docs/plans/m36.md and ADR 0047. Ask me the open choices. Open a PR
   > with docs only.
3. **M36.0 … M36.n Book 9 steps** (one session per step, as the merged plan lists them)
   **Model · effort:** the merged plan tags every step; use that tag. If a tag is missing:
   - engine or schema step (M36.0): **Opus · medium**
   - world and records (M36.1): **Sonnet · high**
   - canon batch with events only: **Sonnet · high**
   - canon batch with a fight stage, hook or kill: **Opus · medium**
   - last step (`sim_canon_book9`, `sim_kill_book9`): **Sonnet · medium**
   > Do the next open M36 step in docs/plans/m36.md. Read progress.md and handoff.md first. Follow CLAUDE.md
   > and ADR 0047. Ask me the stage and hook choices first. Then build, run only the tests the step lists,
   > update the docs, and open a PR.
4. **M37.P Book 10 plan** (after M36 is merged; plan `docs/plans/m37.md`, text in `canon/raw/book10`), then
   **M37.0 … M37.n** (same prompts as items 2 and 3, with Book 10, ADR 0048 and docs/plans/m37.md).
   **Model · effort:** M37.P **Opus · high**; the steps follow the tags in item 3 (use the merged M37 plan's tags first).
   M37.P also checks the `6.` chapter ids in the validator and `core/canon_db.gd`; if one fails, that fix is an
   **Opus · medium** step.

## Before each cloud session (checklist, 1 minute)
- [ ] The last session's PR is merged into `main` (the next session starts from `main`).
- [ ] `git status` on your PC has nothing you need in the cloud. The cloud sees only what is pushed.
- [ ] The setup line says `book text: book1 … book10`. If not, see "If the setup line says `book text: NOT FOUND`".
- [ ] You are ready to answer questions. A step stops and waits for your picks. If you will be away, tell it
      "use the recommended choices".

## How the sessions fit in the next days (guide)
Size is from M28 (Book 8: one plan session, 10 steps, 26 chapters). Book 9 has 22 chapters, Book 10 has 17.
- Days 1 – 2: M35.0 (Ceria) and M36.P (the Book 9 plan) touch different files, so they may run at the same
  time. Run M35.1, M35.2 and M35.3 one after the other (they share `npcs.json` and `npc_behaviour.json`).
  Merge each PR before the next session starts from `main`.
- Days 2 – 5: M36.0 … M36.n (about 8 – 10 steps, one per session, in order: each needs the one before).
- After M36 is merged: M37.P, then M37.0 … M37.n (about 7 – 9 steps).
Do not run two canon batches of one book at once. Two sessions that edit the same JSON file will conflict.

To continue after a break, paste: "Read progress.md and handoff.md. Go on with the next open task."

## Done tasks (kept as examples of the prompt style)
All five are merged (M17.6 – M19.9). Only your play checks are left (ROADMAP, "Waits on the user").

D1. **M17.6 Cover and position**
   > Do M17.6 (cover and position) from docs/ROADMAP.md. Follow CLAUDE.md. Plan first and write the plan
   > to docs/plans/m17.6.md. Ask me the open choices, then build, test, update the docs, and open a PR.
D2. **M17.7 Enemy abilities and balance**, then **M17.8 Hidden XP** (both done; last M17 steps)
   > Do M17.7 from docs/ROADMAP.md. Follow CLAUDE.md. Plan first (docs/plans/m17.7.md), ask me the open
   > choices, then build, run only the tests that touch the change, update the docs, and open a PR.
D3. **M18.P Book 6 plan** (done 2026-10-01, ADR 0028)
   > Do M18.P: plan Book 6 (The General of Izril) like ADR 0020 did for Book 5. Read the chapters in
   > canon/raw/book6 with subagents (summaries only). Write ADR 0028 and the M18 steps in docs/ROADMAP.md.
   > Ask me the open choices. Open a PR with the plan only.
D4. **M18.0 … M18.7 Book 6 steps** (done; one session per step)
   > Do the next open M18 step in docs/ROADMAP.md. Follow CLAUDE.md and ADR 0028. Ask me the stage and hook
   > choices first. Then build, test, update the docs, and open a PR.
D5. **M19.P Book 7 plan** (done 2026-10-07, ADR 0030), then **M19.0 … M19.9** (done; same prompt as D4, with ADR 0030
   and canon/raw/book7)

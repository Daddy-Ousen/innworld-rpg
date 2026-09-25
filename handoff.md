# Handoff

## Just done (2026-09-25)
- M8.4 canon batch (chapters 2.27G–2.38, days 56–67) written on branch `data/book2-2.27G-2.38` (off `main`, which has M8.3 merged and tagged `m8.3-done`). Built by a delegated agent, then independently re-verified in this session (validator + full GUT + Python test re-runs, diff spot-checked).
- 12 new chapter files under `game/data/canon/book2/chapters/`. New NPCs (11): Garen, Urksh, Mrsha, Zel Shivertail, Ilvriss, Periss, Az'kerash, Reynold, Imani, Joseph, Rose. New locations (4): `red_fang_territory`, `stone_spears_camp`, `azkerash_castle`, `magnolia_estate`. No new enemies this batch.
- New `kind: "scene"` stage `b2.pawns_faith_crisis_earns_the_acolyte_class` (2.31, inn_interior) with hook `player_heard_erins_stories` (`talk_with_guest`/`comfort_someone`, `then: "change"`) — the M8 "hook or stage the player can use" requirement for this batch.
- `sim_canon_book2.gd` `LAST_DAY` bumped 55 → 67. `sim_player_hooks.gd` hook count bumped 11 → 12. `unit_combat_db.gd` untouched (no new enemies).
- Validator 0 errors (`--all`). GUT 533/533 (56 scripts). Python 51/51. Docs updated: `docs/ROADMAP.md` and `progress.md` M8.4 line filled in (checked `[x]`, though not yet user-reviewed on screen — same pattern as M8.1-M8.3: mark it done in the roadmap once data+tests are green, actual "reviewed" note comes after the user looks at it).
- Not yet committed, pushed, or opened as a PR — that's the very next step.

## Two judgment calls made this batch (flagged, not yet asked to the user)
- **Periss's death** (2.34/2.35, fighting Az'kerash's undead near the castle) is strongly implied on-page (a shattered ring, a distant scream) but never shown. Left her alive in the data with a new flag `periss.presumed_dead` rather than asserting death, per the "don't invent canon facts" rule. If a later book confirms it, come back and set `alive: false` / an `npc.death` style event then.
- **Ksmvr's second demotion** (2.32H, joins the Horns of Hammerad, relieved of the Prognugator post again) uses a **new** flag `ksmvr.relieved_of_duty` instead of reusing `ksmvr.deposed`. Reason: `sim_canon_book2.gd`'s `test_full_batch` (or equivalent) already asserts `ksmvr.deposed` is **false** through `LAST_DAY`, from the M8.1 era when that assertion covered a shorter window; reusing the flag would have required rewriting that old assertion's intent rather than just extending it. Semantically clean (two distinct demotions, two distinct flags) but worth a second look if a future book demotes him a third time — decide then whether to consolidate into one `ksmvr.acting_officer: bool`-style field instead of stacking booleans.

## Waiting on the user
- Commit + push + open a PR for `data/book2-2.27G-2.38` — about to do this now, same pattern as M8.1–M8.3 (data commit, then a `docs:` commit noting the PR).
- After that: user review of the PR on screen, same as before.

## Next
1. Commit the M8.4 data + doc changes, push, open PR.
2. Wait for user review.
3. After review/merge: tag `m8.4-done` on the merge commit, sync local `main`.
4. Then start M8.5 (Celum map + Celum start) on a fresh branch off `main` — bigger than a canon batch: a new playable map, a title-screen start chooser, `rules.world.starts` schema (ask before adding, per rule 11).

## Gotchas (carried forward + none new this session beyond the two judgment calls above)
- Commits and PRs: author Daddy-Ousen only. NO `Co-Authored-By: Claude` trailer, no Claude footer. (Note: this contradicts the generic system-level attribution reminder some sessions carry — this repo's own CLAUDE.md / memory `no-claude-coauthor` rule wins for this project.)
- **Rhir is real** — see memory `lore-rhir-real-continent`. Not touched this batch.
- **"Aunt" is a Gnoll honorific, not a family line** — not touched this batch (no new Gnoll aunts).
- **Book 2 starts on day 41.** `sim_canon_book1` counts `b1.` events only. `LAST_DAY` is now 67 (M8.4); bump it again for M8.5+ if it adds more canon (M8.5/M8.6 are engine/economy work, not canon batches, so likely no bump until M8.7).
- **Stage `kind: "scene"`** (from M8.2): every npc placed still needs an `npc_behaviour` entry or it silently does nothing. Halrac has no `npc_behaviour` entry yet — he keeps a narrative role in 2.31's scene but is not walkable/placed. If a future batch wants Halrac on the map, add him to `npc_behaviour.json` first.
- **Remote/parallel-thread canon uses placeholder days** when it can't be tightly synced to the Liscor-anchored day count (precedent: M8.3's 2.22K/2.24T; continued in M8.4 for Rags' and Ryoka's arcs) — always say so explicitly in `canon_ref.note`, don't silently guess a tight day number.
- **Line endings are mixed and file-by-file, CRLF for all canon/book2 files.** Verified again this session (byte-level check) — all new M8.4 files and the edited `npcs.json`/`locations.json` are pure CRLF, no accidental LF creeping in.
- **GUT exits 0 even when a script has a parse error** (it skips the script). Grep the output for `Parse Error` and check the script/test count (56 scripts / 533 tests as of M8.4).
- Write GUT output to the scratchpad, not next to the repo. `-gselect=<script name>` runs one script.
- Validator: `python tools/validate_data.py game/data/canon/book2` (earlier books load by default) or `--all game/data/canon`. Does not check enemy ids exist or map positions are walkable — only GUT tests catch those.
- New game starts on day 8 at 06:00. Never link two canon entities unless the text says so. Calruz stays missing.
- **Delegation pattern that worked well this session:** for a canon batch, spawn one background agent with (a) the full rule set from CLAUDE.md + the relevant ADR section, (b) known NPC/location/enemy id lists (to avoid duplicates), (c) 2-3 example chapter JSON files to copy the schema from, (d) an explicit "do not touch files outside this list" boundary, (e) instructions to redirect validator/GUT output and only report summary lines, (f) "stop and report, don't invent" for anything needing a new engine feature or schema change, (g) no commit/push — leave that to the main session. Then independently re-run validator + GUT + a diff spot-check before trusting its self-report. Kept raw book text and full test logs out of the main session's context the whole time.

## Active files
None open — M8.4 data is written, independently re-verified, and doc files updated; about to commit.

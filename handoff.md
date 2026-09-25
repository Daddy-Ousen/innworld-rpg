# Handoff

## Just done (2026-09-25)
- M8.4 (Book 2 canon 2.27G-2.38, days 56-67) is merged. [PR #31](https://github.com/Daddy-Ousen/innworld-rpg/pull/31), merge commit `18d61bce7be11ad2192c9713ddad041f4ff77c52`, tagged `m8.4-done`. Local `main` synced.
- See `docs/PROGRESS_ARCHIVE.md`-style detail in `progress.md`'s M8.4 line and `docs/adr/0014-m8-book2-and-celum.md` for what happened in the chapters, the new NPCs/locations, and the two judgment calls (Periss presumed dead not confirmed dead; Ksmvr's second demotion uses a new flag `ksmvr.relieved_of_duty` instead of reusing `ksmvr.deposed`).

## Waiting on the user
- Whether to start M8.5 now (Celum map + Celum start) or pause here.

## Next
1. M8.5 Celum map + Celum start: a new playable map for Celum, a title-screen start chooser (arrive at Liscor day 8 vs. arrive at Celum day 8), and a `rules.world.starts` schema. **Rule 11 says ask before adding a dependency, changing a JSON schema, or changing a rule in CLAUDE.md** - the `rules.world.starts` schema addition needs the user's sign-off before building, same as M7.B/M8.2's `stage kind` additions were user-approved calls, not unilateral engine changes.
2. Then M8.6 (economy + travel: coins, goods bag, hunger, rooms, paid ride, road camp map - a save format change) and M8.7 (final 3 canon batches: interludes + 2.39-2.48) close out M8.

## Gotchas (carried forward, none new this turn)
- Commits and PRs: author Daddy-Ousen only. NO `Co-Authored-By: Claude` trailer, no Claude footer.
- **Rhir is real** - see memory `lore-rhir-real-continent`.
- **"Aunt" is a Gnoll honorific, not a family line.**
- **Book 2 starts on day 41.** `sim_canon_book2` `LAST_DAY` is now 67 (M8.4). M8.5/M8.6 are engine/economy work, not canon batches - no `LAST_DAY` bump expected until M8.7.
- **Stage `kind: "scene"`** (M8.2): every npc placed still needs an `npc_behaviour` entry. Halrac has none yet.
- Remote/parallel-thread canon (Rags, Ryoka) uses placeholder days when it can't sync tightly to the Liscor day count - say so in `canon_ref.note`.
- Line endings: CRLF, file-by-file, verified at byte level through M8.4.
- GUT exits 0 even on a parse error - grep for `Parse Error`; 56 scripts / 533 tests as of M8.4.
- Validator: `python tools/validate_data.py --all game/data/canon`. Doesn't check enemy ids or walkable map positions - only GUT catches those.
- New game starts on day 8, 06:00. Never link two canon entities unless the text says so. Calruz stays missing.
- **Delegation pattern that worked well for M8.4:** one background agent given the full rule set, known id lists, 2-3 example chapter files to copy schema from, an explicit file boundary, redirect-and-summarize instructions for validator/GUT, "stop and report, don't invent" for anything needing a new engine feature, and no commit/push (left to the main session). Then independently re-run validator + GUT + a diff spot-check before trusting the self-report - worth repeating for future canon batches (not for M8.5, which is engine/map work, not a text-extraction task).

## Active files
None open.

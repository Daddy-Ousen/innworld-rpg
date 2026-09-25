# Handoff

## Just done (2026-09-25)
- M8.5 (Celum map + Celum start) is merged. [PR #32](https://github.com/Daddy-Ousen/innworld-rpg/pull/32), merge commit `53e9d9f`, tagged `m8.5-done`. Local `main` synced.
- User choices this session: starts become a list (`rules.world.starts`); Celum gets 3 maps (gate, square, Runners' Guild inside).
- Full detail: `docs/adr/0014-m8-book2-and-celum.md`, section "M8.5 Celum map + Celum start".

## Waiting on the user
- Whether to start M8.6 (economy + travel) now.

## Next
1. M8.6 economy + travel (ADR 0015, save change -> v11 + migration): coins, goods bag, simple hunger (one meal a day; Erin feeds you on a day you work at her inn), paid room in Celum (the Rat's Tail sign on `celum_square` is the hook), odd jobs (the `request_board` in `celum_runners_guild`), selling, paid ride, road with one camp map. The road exit goes on the south edge of `celum_gate` (road tiles at x 16-17). Plan first; ask before new JSON schemas (rule 11).
2. M8.7: final canon batches (3 interludes + 2.39-2.48, Erin in Celum, Octavia).

## Gotchas
- Commits and PRs: author Daddy-Ousen only. NO `Co-Authored-By: Claude` trailer, no Claude footer.
- **Never use `sed -i` in Git Bash on repo files** - it strips CRLF. Patch with Python on bytes, or the Edit tool. All repo text files are CRLF.
- Screenshots: a throwaway scene in `game/_scratch/` run with `godot --path game res://_scratch/shot.tscn` (a `-s` SceneTree script cannot see the `Session` autoload at compile time). Delete `game/_scratch` before committing.
- GUT API: `assert_signal_not_emitted` (not `assert_not_signal_emitted`). GUT exits 0 even on a parse error - grep for `Parse Error` and check the script count (57 / 544 tests now).
- `Movement.start_of(db, id)`: "" = first start, unknown = {}. `new_game` with an unknown id falls back to the first start.
- Celum is not linked to Liscor yet. A Celum player stays in Celum until M8.6.
- **Rhir is real** - see memory `lore-rhir-real-continent`. "Aunt" is a Gnoll honorific. Calruz stays missing. Never link two canon entities unless the text says so.
- Book 2 starts on day 41. `sim_canon_book2` `LAST_DAY` is 67; no bump until M8.7.
- Stage `kind: "scene"`: every npc placed needs an `npc_behaviour` entry. Halrac has none yet.
- Validator: `python tools/validate_data.py --all game/data/canon`. It does not check maps, enemy ids or walkable positions - only GUT does.

## Active files
None open.

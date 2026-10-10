# ADR 0036: Canon bends (M23)

Status: accepted (2026-10-10, M23.1 Book 2). Applies to M23.2 – M23.6 (Books 3 – 7) too.

## Problem
Books 2 – 7 had only `cancel` in `on_fail`, and few hooks. One dead NPC cancelled long chains that did not need
that NPC, because many `depends_on` links were only story order. In Book 2, Erin's death cancelled 140 of 207
events, and Yvlon's death gave drift 107 (the Horns of Hammerad chain into Books 3 – 4).
The M23.0 report (`docs/divergence/report.md`) and the user's picks (`docs/divergence/picks.md`) name the key NPCs
and events per book.

## Decision
1. **`depends_on` only for a real cause.** If the later event makes sense without the earlier one, the link goes.
   Example: Rags builds crossbows because the Broken Spear tribe rejects her, not because Ceria warned her.
   Side effect: the run order inside one day can change a little (the statuses do not). `sim_canon_book<N>` must
   stay at drift 0.
2. **Substitute only with a plain local stand-in.** A role gets `fallback_tags` and `on_fail` starts with
   `substitute` only when someone nearby would clearly do the same thing. The tags are picked so the best match is
   that NPC (the director scores all NPCs in the world, ties go to the lowest id). The kill sim checks the pick.
3. **Mutate with a flag hand-off.** A mutated event "never happened", so `_propagate` cancels everything that
   `depends_on` it. When an alt event should keep a chain alive, the next events do not `depends_on` the canon event.
   They wait on a flag that both the canon event and its alt set, with `on_fail: ["delay", "cancel"]` and
   `delay_limit: 3`.
4. **Engine (director): an alt runs on its own day.** During propagation, a dependent with a `mutate:` step whose
   window has not opened is left pending. It fails and mutates when it is due. Before, the alt ran on the day the
   chain broke (Ryoka dies, her day-56 thread breaks, the day-65 Goblin Lord alt ran on day 56).
   `unit_director.test_cancel_propagates_down_the_chain` changed for this; a new test covers an open window.
   No save change.
5. **Alt events are not in the book.** `canon_ref.confidence` is `guess`, the note starts "Not in the book (M23.x,
   divergence only)". An alt kills no one. Alts are `alt_only`: they never run on their own.
6. **Hooks: one per day of on-map canon.** A day has on-map canon when a book event on it is at a location that has
   a game map. Each such day gets at least one player hook (mostly `change`: a flag plus relationships).
7. **A kill sim per book** (`sim_kill_book<N>`): each key NPC dies on the book's first day. The sim checks a ceiling
   for lost book events and total drift (a regression guard), the threads that must go on, and the bends
   (substitutes and alts) by name. It also checks the hook-per-day rule.

## Book 2 (M23.1)
- Links cut or moved: Pisces's call log, Rags's crossbows / Jawbreaker ambush / Esthelm, Val's chessboard, Ryoka's
  run north / reunion / dreamcatcher / morning run, the iPhone night, the faerie banquet, Ryoka's return with Mrsha
  and the 2.40 scenes after it, Erin's protection of Lyonette, the inn battle, Niers's alarm map.
- Substitutes: Klbkch leads the Ruins rescue (2.02) if Erin cannot; Relc carries Selys's warning (2.23) if Pisces
  cannot.
- Mutates: `ceria_reforms_the_horns_of_hammerad` → `ceria_reforms_the_horns_short_handed` (Yvlon or Pisces dead;
  Ceria founds the Horns, so her death still ends them); `goblin_lords_army_destroys_stone_spears_camp` →
  `goblin_lord_overruns_the_stone_spears` (the Ryoka / Mrsha thread or Urksh gone); `toren_drags_erin_north_and_leaves_her`
  → `erin_winters_in_liscor` (no Toren).
- Flag hand-off + delay: `ksmvr_joins_the_horns_of_hammerad` (flag `horns_of_hammerad.reformed`; Erin no longer
  required), `drake_assembly_silences_zel` and `magnolia_plans_to_bring_zel_north` (Goblin Lord flags).
- 19 new `change` hooks: every one of the 22 on-map days (41 – 71) has a hook.

| Dies on day 41 | Book 2 lost before → after | Drift before → after |
|---|---|---|
| Erin | 140 → 109 | 261.5 → 161.25 |
| Ryoka | 76 → 64 | 127 → 103.75 |
| Toren | 77 → 57 | 135 → 117 |
| Rags | 42 → 27 | 40.5 → 26 |
| Ceria | 42 → 25 | 136 → 122 |
| Pisces | 30 → 13 | 124.5 → 11.25 |
| Yvlon | 7 → 4 | 107.5 → 4 |

"Lost" counts cancelled and mutated canon events. Most of what is left is real: the dead NPC's own scenes, and
stories that need them (no Erin, no Lyonette at the inn; no Toren, no inn explosion and no trip to Celum).

## Open
- Ksmvr's death still drops the Albez chain (110 events, most in Books 3 – 4). That is Book 3's key event set (M23.2).
- Drift counts later-book cancels at once, so a Book 2 death shows drift for Books 3 – 7 too.
- Event effects are not remapped for flags: a substitute in Erin's rescue role still sets `erin.fought_in_the_ruins`.
  Later events that read such flags need Erin anyway.

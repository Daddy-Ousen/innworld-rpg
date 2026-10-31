# ADR 0046: M35 new content

Status: accepted (2026-11-01). Plan: `docs/plans/m35.md`. One note per step; M35.0 is the first.

## M35.0 (2026-11-01): Ceria's fire lesson
- **Reading** (three Sonnet agents, summaries only, Books 1 – 4 and 7 – 8). Facts that count:
  - Ceria's class is [Elementalist] and [Cryomancer] (canon record, 1.26R, 1.47R, 1.48R). The plan said
    [Pyromancer]; that was wrong and is fixed in `docs/plans/m35.md`. No level is stated in Books 1 – 2 or 7 – 8.
  - Fire: [Fireball] needs her wand (1.58H, 2.20). Ice is her main magic ([Ice Spike], [Ice Wall], [Frost Bloom]).
  - She teaches Ryoka [Light] (1.45) and spell tiers (2.20). She says casting makes a mage hungry (1.47R).
  - She tells Erin a cold needs hot soup, not a spell (1.50, 1.53). The Horns lodge at the inn from night 35 (1.49).
  - No scene in Books 7 – 8 shows her teaching a spell.
- **User picks:** the line unlocks [Flashfire]; it starts on Book 1, day 36.
- **Data only, no code, schema or save change.** New quest `ceria_teaches_flashfire` (giver `ceria_springwalker`):
  - Gate: flag `ryoka.knows_light_spell` (set by `b1.ceria_teaches_ryoka_light`, days 34 – 35).
  - Steps: talk with Ceria about magic twice; cook a meal for her; wait for `erin.has_a_cold` (day 37 – 38,
    `b1.pawn_goes_home_to_the_hive`); cook hot soup or stew; tell Ceria.
  - Reward: +3 regard and the flag `quest.ceria_fire_lesson`. No coins, no goods.
  - No `fail` rule except her death: after day 39 she is off the map until Celum (day 85+), so the last step may
    wait for weeks.
- `spells.json`: `flashfire` has `learn.flags: ["quest.ceria_fire_lesson"]`. Ceria teaches it only after the task
  (and still needs the event `b1.ceria_teaches_ryoka_light` and friend regard). [Ice Spike] stays free for a friend.
- Her fight spell list in `npc_behaviour.json` (`flashfire` after `b1.gazi_hunts_for_ryoka`) is not changed: it is
  what she casts, not what the player learns.
- Why the quest steps are guesses: the quest is made up (confidence `guess`). The flags are real canon flags.
- Known gap (not changed here): between day 40 and her move to Celum she has no map goal, so Book 2 (she lodges at
  the inn from day 43) has no Ceria on the map. M35 does not add one.

## M35.1 note (2026-11-01)
- Reading (Sonnet agents, Books 1 - 8, summaries only): the text states NO level for Merec, Raisha, Reynold, Rose,
  Imani, Joseph or the two estate golems. Classes in the data ([Merchant], [Guardswoman], [Butler]) match the text.
  Rose, Imani and Joseph name no class (the Earthers only talk about choosing one, 2.37). The golems are constructs:
  no class, level or Skill.
- User pick: add Reynold's past [Lieutenant] (4.48) with `level: null`, nothing else. Data only (`book2/npcs.json`).
  Reynold's "few levels" in unnamed auxiliary classes (3.36) are not recorded.
- The NPC record has no place for Skills (`classes` only). Not added: a schema change needs the user (Rule 11).
  Named Skills seen: Magnolia [Sense Intentions] (2.38, 3.13); Ressa is [Head Maid] (2.37). Not in scope.
- Effect: a `null` level counts as `unknown_level` (1) in `NpcLevels`, so the extra class adds a small hidden total.

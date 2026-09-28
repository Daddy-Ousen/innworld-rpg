# Credits

Innworld RPG is a free, non-commercial fan game set in *The Wandering Inn* by pirateaba.
All art comes from the Liberated Pixel Cup (LPC) family on OpenGameArt, plus our own edits.
Our edits of CC-BY-SA art are CC-BY-SA too. See ADR 0018.

## Tiles (`game/assets/tiles/`)

- `lpc_terrains.png` is `terrain-v7.png` from "[LPC] Terrains" by bluecarrot16, Lanea Zimmerman (Sharm),
  Daniel Eddeland (Daneeklu), Richard Kettering (Jetrel), Zachariah Husiar (Zabin), Hyptosis, Casper Nilsson,
  Buko Studios, Nushio, ZaPaper, billknye, William Thompson, caeles, Redshrike, Bertram and Rayane Félix (RayaneFLX).
  Licence: CC-BY-SA 4.0 / CC-BY-SA 3.0. https://opengameart.org/content/lpc-terrains
  Full credits: `game/assets/tiles/lpc_terrains_CREDITS.txt`.
- `lpc_atlas.png` is `terrain_atlas.png` from "LPC Tile Atlas" (submitted by adrix89), made of the LPC contest
  base assets by Lanea Zimmerman (Sharm) and LPC entries by Casper Nilsson, Daniel Eddeland and others.
  Licence: CC-BY-SA 3.0 / GPL 3.0. https://opengameart.org/content/lpc-tile-atlas
  Full credits: `game/assets/tiles/lpc_atlas_Attribution.txt`.

- `lpc_house.png` (`house.png`) and `lpc_inside.png` (`inside.png`) from "Liberated Pixel Cup (LPC) Base Assets"
  by Lanea Zimmerman (Sharm) and others. Licence: CC-BY-SA 3.0 / GPL 3.0.
  https://opengameart.org/content/liberated-pixel-cup-lpc-base-assets-sprites-map-tiles
  Full credits: `game/assets/tiles/lpc_base_CREDITS.txt`.

## Map objects (`game/assets/objects/`)

- `tavern_furniture.png`, `tavern_cooking.png`, `tavern_deco.png` from "[LPC] Tavern" by bluecarrot16,
  Lanea Zimmerman (Sharm), William.Thompsonj, Jetrel, DCSS Contributors, Reemax, Hyptosis, Daniel Eddeland
  (Daneeklu), BenCreating, Evert and tapatilorenzo. Licence: CC-BY-SA 3.0. https://opengameart.org/content/lpc-tavern
  Full credits: `game/assets/objects/tavern_CREDITS.txt`.
- `lpc_interior.png` (`interior.png`) from "LPC House Interior and Decorations" by Reemax, with parts by
  Lanea Zimmerman (Sharm), Hyptosis, Daniel Eddeland, William.Thompsonj, wulax and makrohn; edits by Tuomo Untinen.
  Licence: CC-BY-SA 3.0 / GPL 3.0 / GPL 2.0. https://opengameart.org/content/lpc-house-interior-and-decorations
  Full credits: `game/assets/objects/lpc_interior_credits.txt`.
- `lpc_well.png` (`lpc-well.png`) "LPC Style Well" by Xenodora, buckets by Lanea Zimmerman (Sharm).
  Licence: CC-BY 3.0 / GPL 3.0. https://opengameart.org/content/lpc-style-well
- `edits.png` is made by `tools/build_objects.py` (our edits): the wagon, chess table and market stall use
  "[LPC] Tavern" pieces; the blue fruit tree, dead tree and stone doors use "LPC Tile Atlas" pieces; the rope
  anchor uses "LPC House Interior and Decorations"; the brazier flames use "[LPC] Tavern". The notice board,
  broom, horseshoe, honeycomb, bee nest, bedroll and mat are drawn by the tool in the LPC style.
  Licence of the edits: CC-BY-SA 3.0 (the same as the art they use).

## Characters (`game/assets/characters/`)

Our edits: the Antinium antennae, mandibles and second pair of arms are drawn by `tools/build_sprites.py`
(`innworld_*` parts) from the LPC body and the LPC alien head of the same sheet (credits below).
Licence of the edits: CC-BY-SA 3.0 (the same as the art they use).

### Creatures (M11.4)

Built by `tools/build_creatures.py` (recoloured and laid out as character sheets) from these files in
`tools/art/creatures/`:
- `golem-walk.png`, `golem-atk.png`, `golem-die.png` from "[LPC] Golem" by Stephen "Redshrike" Challener
  (art) and William.Thompsonj. Licence: CC-BY 4.0 / CC-BY 3.0 / GPL 3.0 / GPL 2.0 / OGA-BY 3.0.
  https://opengameart.org/content/lpc-golem. Used for `crypt_lord` (recoloured).
- `bee.png`, `big_worm.png` from "[LPC] Monsters" by bluecarrot16, Charles Sanchez (CharlesGabriel) and bagzie,
  based on the LPC base assets. Licence: CC-BY-SA 3.0 / GPL 3.0. https://opengameart.org/content/lpc-monsters.
  Used for `ashfire_bee`, `skinner`, `crypt_worm` and `giant_leech` (recoloured).
- `bird_2_eagle.png` from "[LPC] Birds" by bluecarrot16 (commissioned by castelonia), inspired by "winter
  birds" by Refuzzle. Licence: CC-BY 4.0 / CC-BY 3.0 / CC-BY-SA 4.0 / CC-BY-SA 3.0 / GPL 3.0 / GPL 2.0 /
  OGA-BY 3.0. https://opengameart.org/content/lpc-birds. Used for `razorbeak` (recoloured, twice the size).

Our edits: `rock_crab` (a boulder crab in the colours of the "LPC Tile Atlas" rock; `shield_spider` is the
same shape in dark grey) and `snow_golem` (a snowman) are drawn by `tools/build_creatures.py`. The recoloured sheets are CC-BY-SA 3.0 where the source
is CC-BY-SA, else CC-BY 4.0 like their source.

<!-- build_sprites:begin -->
Built by `tools/build_sprites.py` from the Universal LPC Spritesheet Character Generator
(https://github.com/LiberatedPixelCup/Universal-LPC-Spritesheet-Character-Generator, commit `4963a69795255fb15a934c47f478a8bdcf3668f5`).
The sheets in `game/assets/characters/` combine these files. Do not edit this block by hand.

- `arms/armour/plate/male` by Michael Whitlock (bigbeargames), Matthew Krohn (makrohn), Johannes Sjölund (wulax), bluecarrot16, JaidynReiman. Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
  - http://opengameart.org/content/lpc-clothing-updates
  - Notes: original by wulax, recolors by bigbeargames; adapted to v3 bases and further recolors by bluecarrot16, climb/emote/jump by JaidynReiman
- `arms/armour/plate/thin` by Michael Whitlock (bigbeargames), Matthew Krohn (makrohn), Johannes Sjölund (wulax), bluecarrot16, JaidynReiman. Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
  - https://opengameart.org/content/lpc-combat-armor-for-women
  - http://opengameart.org/content/lpc-clothing-updates
  - Notes: original by wulax, adapted to female by makrohn, recolors by bigbeargames; adapted to v3 bases and further recolors by bluecarrot16, climb/emote by JaidynReiman
- `beards/mustache/basic` by JaidynReiman, Carlo Enrico Victoria (Nemisys). Licence: CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-brunet-mustache
  - Notes: Original by Nemisys, repositioning by JaidynReiman.
- `body/bodies/child` by bluecarrot16, Benjamin K. Smith (BenCreating), ElizaWy, MuffinElZangano, Durrani, Nila122, kheftel, Stephen Challener (Redshrike). Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/liberated-pixel-cup-lpc-base-assets-sprites-map-tiles
  - https://opengameart.org/content/lpc-child-standing-template
  - https://opengameart.org/content/lpc-children-walk-animation
  - https://opengameart.org/content/lpc-male-jumping-animation-by-durrani
  - https://opengameart.org/content/lpc-male-jumping-animation-by-durrani
  - https://opengameart.org/content/lpc-jump-expanded
  - https://opengameart.org/content/lpc-jump-expanded
- `body/bodies/female` by Benjamin K. Smith (BenCreating), bluecarrot16, TheraHedwig, Evert, MuffinElZangano, Durrani, Pierre Vigier (pvigier), ElizaWy, Matthew Krohn (makrohn), Johannes Sjölund (wulax), Stephen Challener (Redshrike). Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/liberated-pixel-cup-lpc-base-assets-sprites-map-tiles
  - https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
  - https://opengameart.org/content/lpc-ladies
  - https://opengameart.org/content/lpc-7-womens-shirts
  - https://opengameart.org/content/lpc-jump-expanded
  - https://opengameart.org/content/lpc-be-seated
  - https://opengameart.org/content/lpc-revised-character-basics
  - https://gitlab.com/vagabondgame/lpc-characters
  - https://opengameart.org/content/lpc-male-jumping-animation-by-durrani
  - https://opengameart.org/content/lpc-runcycle-and-diagonal-walkcycle
  - Notes: see details at https://opengameart.org/content/lpc-character-bases
- `body/bodies/male` by bluecarrot16, JaidynReiman, Benjamin K. Smith (BenCreating), Evert, Eliza Wyatt (ElizaWy), TheraHedwig, MuffinElZangano, Durrani, Johannes Sjölund (wulax), Stephen Challener (Redshrike). Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/liberated-pixel-cup-lpc-base-assets-sprites-map-tiles
  - https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
  - https://opengameart.org/content/lpc-male-jumping-animation-by-durrani
  - https://opengameart.org/content/lpc-runcycle-and-diagonal-walkcycle
  - https://opengameart.org/content/lpc-revised-character-basics
  - https://opengameart.org/content/lpc-be-seated
  - https://opengameart.org/content/lpc-runcycle-for-male-muscular-and-pregnant-character-bases-with-modular-heads
  - https://opengameart.org/content/lpc-jump-expanded
  - https://opengameart.org/content/lpc-character-bases
  - Notes: see details at https://opengameart.org/content/lpc-character-bases; 'Thick' Male Revised Run/Climb by JaidynReiman (based on ElizaWy's LPC Revised)
- `body/bodies/skeleton` by bluecarrot16, Napsio, JaidynReiman, Johannes Sjölund (wulax), Stephen Challener (Redshrike). Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/liberated-pixel-cup-lpc-base-assets-sprites-map-tiles
  - https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
  - https://opengameart.org/content/lpc-skeleton
  - https://opengameart.org/content/lpc-character-bases
- `body/tail/fluffy` by JaidynReiman. Licence: OGA-BY 3.0+ / CC-BY 3.0+ / GPL 3.0.
  - https://opengameart.org/content/lpc-furry-ears-tails-for-rpg-sprites
- `body/tail/lizard` by Nila122, bluecarrot16, JaidynReiman. Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/drakes-and-lizardfolk
  - Notes: edited for v3 bases and recolored by bluecarrot16, additional animations added by JaidynReiman
- `cape/solid/bg` by Nila122, JaidynReiman. Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-curly-hair-elven-ears-white-cape-with-blue-trim-and-more
  - https://opengameart.org/content/lpc-roman-armor
- `cape/solid/fg` by bluecarrot16, JaidynReiman. Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-curly-hair-elven-ears-white-cape-with-blue-trim-and-more
  - https://opengameart.org/content/lpc-roman-armor
  - http://opengameart.org/content/lpc-clothing-updates
- `cape/tattered/bg` by Nila122, JaidynReiman. Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-curly-hair-elven-ears-white-cape-with-blue-trim-and-more
  - https://opengameart.org/content/lpc-roman-armor
- `cape/tattered/fg` by Nila122, JaidynReiman. Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-curly-hair-elven-ears-white-cape-with-blue-trim-and-more
  - https://opengameart.org/content/lpc-roman-armor
- `eyes/cyclops` by kirts, JaidynReiman. Licence: CC0.
  - https://opengameart.org/content/cyclops-and-his-eye
  - Notes: original by kirts, repositioned by JaidynReiman
- `feet/armour/plate` by Matthew Krohn (makrohn), Johannes Sjölund (wulax). Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
  - Notes: original by wulax, recolors by bigbeargames, edits for v3 base and recolors by bluecarrot16
- `feet/boots/basic` by JaidynReiman, bluecarrot16, Nila122. Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 2.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-clothes-and-hair
  - https://opengameart.org/content/lpc-expanded-socks-shoes
  - Notes: original by Nila122, edited for male and v3 bases by bluecarrot16, Jump/Sit/Emote/Run/Revised Combat by JaidynReiman
- `feet/boots/basic/thin` by JaidynReiman, bluecarrot16, Nila122. Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 2.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-clothes-and-hair
  - https://opengameart.org/content/lpc-expanded-socks-shoes
  - Notes: original by Nila122, edited for v3 bases by bluecarrot16, Jump/Sit/Emote/Run/Revised Combat by JaidynReiman
- `feet/shoes` by JaidynReiman, bluecarrot16, Johannes Sjölund (wulax). Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
  - http://opengameart.org/content/lpc-clothing-updates
  - https://opengameart.org/content/lpc-expanded-socks-shoes
  - Notes: original by wulax, edited for v3 base by bluecarrot16, Jump/Sit/Emote/Run/Revised Combat by JaidynReiman
- `feet/shoes/basic/thin` by JaidynReiman, Joe White, Johannes Sjölund (wulax). Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
  - http://opengameart.org/content/lpc-clothing-updates
  - https://opengameart.org/content/lpc-expanded-socks-shoes
  - Notes: original by wulax, edited for female base by Joe White, edited for v3 base by bluecarrot16, Jump/Sit/Emote/Run/Revised Combat by JaidynReiman
- `hair/bob` by ElizaWy, bluecarrot16. Licence: CC0.
  - https://opengameart.org/content/lpc-hair
  - https://github.com/ElizaWy/LPC/blob/main/Characters/Hair
  - https://opengameart.org/content/lpc-expanded-sit-run-jump-more
  - Notes: Original by bluecarrot16. Edited and animated by ElizaWy.
- `hair/dreadlocks_long` by bluecarrot16. Licence: CC0.
  - https://opengameart.org/content/lpc-hair
- `hair/high_ponytail` by JaidynReiman, ElizaWy, bluecarrot16. Licence: OGA-BY 3.0.
  - https://opengameart.org/content/lpc-hair
  - https://opengameart.org/content/lpc-expanded-hair
- `hair/long` by JaidynReiman, Manuel Riecke (MrBeast). Licence: CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/liberated-pixel-cup-lpc-base-assets-sprites-map-tiles
  - https://opengameart.org/content/lpc-expanded-hair
- `hair/messy1` by JaidynReiman, Manuel Riecke (MrBeast). Licence: CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/liberated-pixel-cup-lpc-base-assets-sprites-map-tiles
  - https://opengameart.org/content/lpc-expanded-hair
- `hair/plain` by JaidynReiman, Manuel Riecke (MrBeast), Joe White. Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/liberated-pixel-cup-lpc-base-assets-sprites-map-tiles
  - https://opengameart.org/content/ponytail-and-plain-hairstyles
  - https://opengameart.org/content/lpc-expanded-hair
- `hair/ponytail` by JaidynReiman, Manuel Riecke (MrBeast). Licence: CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/liberated-pixel-cup-lpc-base-assets-sprites-map-tiles
  - https://opengameart.org/content/lpc-expanded-hair
- `hat/cloth/bandana` by Matthew Krohn (makrohn), JaidynReiman, Marcel van de Steeg (MadMarcel), JaidynReiman. Licence: OGA-BY 3.0 / CC-BY-SA 3.0.
  - https://opengameart.org/content/lpc-female-orcogregoblintroll-base-walkcycle
  - https://github.com/makrohn/Universal-LPC-spritesheet/commit/f50007cb47c235d8896cafae7a613f0b6a9a09a8?short_path=02b86d4#diff-02b86d45789a3e3e8e79519c7d17d15c9e6ecc9b4ddecb1bcd8dfbbaef430b75
  - https://opengameart.org/content/lpc-expanded-hats-facial-helmets
- `hat/cloth/hood` by Johannes Sjölund (wulax), JaidynReiman. Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
  - https://opengameart.org/content/lpc-expanded-hats-facial-helmets
  - Notes: Brown hood by Wulax, original black/white recolors by ??, mapped to idle/run/jump/revised combat by JaidynReiman, along with additional recolors.
- `hat/cloth/leather_cap` by Johannes Sjölund (wulax), Matthew Krohn (Makrohn), JaidynReiman. Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
  - https://opengameart.org/content/lpc-expanded-hats-facial-helmets
  - Notes: original by Johannes Sjölund (wulax), female by Matthew Krohn, mapped to all frames w/recolors by JaidynReiman
- `hat/helmet/barbarian` by bluecarrot16, JaidynReiman, Napsio (Vitruvian Studio). Licence: CC-BY 3.0 / CC-BY 4.0 / OGA-BY 3.0 / GPL 2.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-helmets
  - https://opengameart.org/content/lpc-expanded-hats-facial-helmets
  - Notes: original version by bluecarrot16, color reduction by Napsio (Vitruvian Studio)
- `hat/helmet/close` by bluecarrot16. Licence: OGA-BY 3.0 / CC-BY 3.0 / CC-BY 4.0 / GPL 2.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-helmets
  - https://opengameart.org/content/lpc-expanded-hats-facial-helmets
- `hat/helmet/kettle` by Johannes Sjölund (wulax), JaidynReiman, Napsio (Vitruvian Studio). Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
  - https://opengameart.org/content/lpc-expanded-hats-facial-helmets
  - Notes: previously referred to as chain-hat, color reduction by Napsio (Vitruvian Studio)
- `hat/helmet/nasal` by bluecarrot16. Licence: CC-BY 3.0 / CC-BY 4.0 / OGA-BY 3.0 / GPL 2.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-helmets
  - https://opengameart.org/content/lpc-expanded-hats-facial-helmets
- `hat/magic/wizard` by Michael Whitlock (bigbeargames), Tuomo Untinen (reemax), JaidynReiman. Licence: CC-BY-SA 3.0 / GPL 2.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-items-and-game-effects
  - https://opengameart.org/content/lpc-pointed-hats
  - https://opengameart.org/content/lpc-expanded-hats-facial-helmets
  - Notes: Original Wizard Hat and Recolors by bigbeargames and reemax; split into separate layers with new recolors by JaidynReiman
- `head/ears/elven` by JaidynReiman, bluecarrot16, Thane Brimhall (pennomi), laetissima, Matthew Krohn (makrohn), JaidynReiman. Licence: GPL 3.0 / CC-BY-SA 3.0.
  - https://opengameart.org/content/lpc-base-character-expressions
  - http://opengameart.org/content/lpc-clothing-updates
  - Notes: adapted to v3 base by bluecarrot16; expanded to other animations and child by JaidynReiman
- `head/heads/alien` by bluecarrot16, Benjamin K. Smith (BenCreating), Nila122. Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/drakes-and-lizardfolk
  - https://opengameart.org/content/lpc-character-bases
  - Notes: based on lizard originally by Nila122, modified by BenCreating, further edited by bluecarrot16. Nila122 gave blanket permission to MedicineStorm to use Nila122's LPC assets under OGA-BY 3.0 (where original or derived only from other works under OGA-BY).
- `head/heads/goblin` by bluecarrot16, Stephen Challener (Redshrike), William.Thomsponj. Licence: OGA-BY 3.0 / CC-BY 4.0 / GPL 2.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-goblin
  - https://opengameart.org/content/lpc-folk
  - Notes: original goblin by Redshrike, commisioned by William.Thomsponj; modular head extracted and enlarged by bluecarrot16
- `head/heads/goblin/child` by bluecarrot16, Stephen Challener (Redshrike), William.Thomsponj. Licence: OGA-BY 3.0 / CC-BY 4.0 / GPL 2.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-goblin
  - https://opengameart.org/content/lpc-folk
  - Notes: original goblin by Redshrike, commisioned by William.Thomsponj; modular head extracted and slightly modified by bluecarrot16
- `head/heads/human/female` by bluecarrot16, Benjamin K. Smith (BenCreating), Stephen Challener (Redshrike). Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/
  - https://opengameart.org/content/lpc-character-bases
  - Notes: original head by Redshrike, tweaks by BenCreating, modular version by bluecarrot16
- `head/heads/human/female_elderly` by Benjamin K. Smith (BenCreating), Eliza Wyatt (ElizaWy), Stephen Challener (Redshrike). Licence: OGA-BY 3.0 / CC-BY 3.0.
  - https://opengameart.org/content/liberated-pixel-cup-lpc-base-assets-sprites-map-tiles
  - https://opengameart.org/content/lpc-revised-elders
  - https://opengameart.org/content/lpc-character-bases
- `head/heads/human/male` by bluecarrot16, Benjamin K. Smith (BenCreating), Stephen Challener (Redshrike). Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/liberated-pixel-cup-lpc-base-assets-sprites-map-tiles
  - https://opengameart.org/content/lpc-character-bases
  - Notes: original head by Redshrike, tweaks by BenCreating, modular version by bluecarrot16
- `head/heads/human/male_gaunt` by Stephen Challener (Redshrike), bluecarrot16. Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/liberated-pixel-cup-lpc-base-assets-sprites-map-tiles
  - https://opengameart.org/content/lpc-folk
  - Notes: original head by Redshrike, gaunt version by bluecarrot16
- `head/heads/lizard/female` by bluecarrot16, Benjamin K. Smith (BenCreating), Nila122. Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/drakes-and-lizardfolk
  - https://opengameart.org/content/lpc-character-bases
  - Notes: original lizard/drake by Nila122, reworked by BenCreating, modular head and further revisions by bluecarrot16. Nila122 gave blanket permission to MedicineStorm to use Nila122's LPC assets under OGA-BY 3.0 (where original or derived only from other works under OGA-BY).
- `head/heads/lizard/male` by bluecarrot16, Benjamin K. Smith (BenCreating), Nila122. Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/drakes-and-lizardfolk
  - https://opengameart.org/content/lpc-character-bases
  - Notes: original lizard/drake by Nila122, reworked by BenCreating, modular head and further revisions by bluecarrot16. Nila122 gave blanket permission to MedicineStorm to use Nila122's LPC assets under OGA-BY 3.0 (where original or derived only from other works under OGA-BY).
- `head/heads/minotaur` by Evert, Nila122, Daniel Eddeland (daneeklu). Licence: CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-style-farm-animals
  - https://opengameart.org/content/lpc-lizard-headgear
  - https://opengameart.org/content/lpc-faun-and-minotaur
  - Notes: original cow by daneeklu, combined with horns by Nila122 and adapted to minotaur by Evert
- `head/heads/rabbit` by bluecarrot16, Stephen Challener (Redshrike), Napsio (Vitruvian Studio), JaidynReiman. Licence: OGA-BY 3.0 / CC-BY 3.0 / CC-BY-SA 3.0.
  - https://opengameart.org/content/bunny-rabbit-lpc-style-for-pixelfarm
  - http://opengameart.org/content/lpc-folk
  - Notes: original rabbit by Redshrike, adapted to modular head by bluecarrot16, color reduction by napsio (Vitruvian Studio) and JaidynReiman
- `head/heads/skeleton` by bluecarrot16, Napsio, JaidynReiman, Johannes Sjölund (wulax), Stephen Challener (Redshrike). Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/liberated-pixel-cup-lpc-base-assets-sprites-map-tiles
  - https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
  - https://opengameart.org/content/lpc-skeleton
  - https://opengameart.org/content/lpc-character-bases
- `head/heads/wolf/child` by bluecarrot16, Sander Frenken (castelonia), Benjamin K. Smith (BenCreating), William.Thompsonj, Stephen Challener (Redshrike). Licence: CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/liberated-pixel-cup-lpc-base-assets-sprites-map-tiles
  - https://opengameart.org/content/lpc-wolf-animation
  - https://opengameart.org/content/lpc-wolfman
  - https://opengameart.org/content/lpc-character-bases
  - Notes: original wolf animation by Redshrike, commissioned by William.Thompsonj; wolfman sprite by BenCreating, commissioned by castelonia; child version by bluecarrot16
- `head/heads/wolf/female` by bluecarrot16, Sander Frenken (castelonia), Benjamin K. Smith (BenCreating), William.Thompsonj, Stephen Challener (Redshrike). Licence: CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/liberated-pixel-cup-lpc-base-assets-sprites-map-tiles
  - https://opengameart.org/content/lpc-wolf-animation
  - https://opengameart.org/content/lpc-wolfman
  - https://opengameart.org/content/lpc-character-bases
  - Notes: original wolf animation by Redshrike, commissioned by William.Thompsonj; wolfman sprite by BenCreating, commissioned by castelonia; tweaks and headless version by bluecarrot16
- `head/heads/wolf/male` by bluecarrot16, Sander Frenken (castelonia), Benjamin K. Smith (BenCreating), William.Thompsonj, Stephen Challener (Redshrike). Licence: CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/liberated-pixel-cup-lpc-base-assets-sprites-map-tiles
  - https://opengameart.org/content/lpc-wolf-animation
  - https://opengameart.org/content/lpc-wolfman
  - https://opengameart.org/content/lpc-character-bases
  - Notes: original wolf animation by Redshrike, commissioned by William.Thompsonj; wolfman sprite by BenCreating, commissioned by castelonia; tweaks and headless version by bluecarrot16
- `head/heads/zombie` by bluecarrot16, Benjamin K. Smith (BenCreating), Sander Frenken (castelonia), Stephen Challener (Redshrike). Licence: CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/liberated-pixel-cup-lpc-base-assets-sprites-map-tiles
  - https://opengameart.org/content/lpc-zombie
  - https://opengameart.org/content/lpc-character-bases
- `legs/armour/plate` by bluecarrot16, JaidynReiman, Michael Whitlock (bigbeargames), Matthew Krohn (makrohn), Johannes Sjölund (wulax). Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
  - Notes: reduced to 7 colors an adapted to v3 bases by bluecarrot16, climb/jump/sit/emote/run by JaidynReiman
- `legs/pants/child` by Nila122. Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-clothes-for-children
- `legs/pants/male` by bluecarrot16, JaidynReiman, ElizaWy, Matthew Krohn (makrohn), Johannes Sjölund (wulax), Stephen Challener (Redshrike). Licence: OGA-BY 3.0 / GPL 3.0 / CC-BY-SA 3.0.
  - https://opengameart.org/content/liberated-pixel-cup-lpc-base-assets-sprites-map-tiles
  - https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
  - https://opengameart.org/content/lpc-expanded-pants
  - Notes: original male pants by wulax, recolors and edits to v3 base by bluecarrot16, climb/jump/run/sit/emotes/revised combat by JaidynReiman based on ElizaWy's LPC Revised
- `legs/pants/thin` by bluecarrot16, JaidynReiman, ElizaWy, Joe White, Matthew Krohn (makrohn), Johannes Sjölund (wulax), Stephen Challener (Redshrike). Licence: OGA-BY 3.0 / GPL 3.0 / CC-BY-SA 3.0.
  - https://opengameart.org/content/liberated-pixel-cup-lpc-base-assets-sprites-map-tiles
  - https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
  - http://opengameart.org/content/lpc-clothing-updates
  - https://opengameart.org/content/lpc-expanded-pants
  - Notes: original male pants by wulax, edited for female by Joe White, recolors and edits to v3 base by bluecarrot16, teen legs by ElizaWy derived from base, climb/jump/run/sit/emotes/revised combat by JaidynReiman based on ElizaWy's LPC Revised
- `legs/shorts/shorts` by ElizaWy, JaidynReiman, Johannes Sjölund (wulax), Stephen Challener (Redshrike). Licence: OGA-BY 3.0.
  - https://github.com/ElizaWy/LPC/tree/main/Characters/Clothing
  - https://opengameart.org/content/lpc-expanded-sit-run-jump-more
  - https://opengameart.org/content/lpc-expanded-pants
  - Notes: Original bases by Redshrike, thrust/shoot bases by Wulax, original shorts by ElizaWy, climb/jump/run/sit/emotes/revised combat by JaidynReiman
- `legs/shorts/shorts/male` by JaidynReiman, ElizaWy, Bluecarrot16, Johannes Sjölund (wulax), Stephen Challener (Redshrike). Licence: OGA-BY 3.0 / GPL 3.0.
  - https://github.com/ElizaWy/LPC/tree/main/Characters/Clothing
  - https://opengameart.org/content/lpc-expanded-pants
  - Notes: Original bases by Redshrike, thrust/shoot bases by Wulax, original overalls and shorts by ElizaWy, base animations adapted from v3 overalls by bluecarrot16, shorts by JaidynReiman
- `legs/skirts/plain` by bluecarrot16, Pierre Vigier (pvigier), Johannes Sjölund (wulax), Ahmad3366, JaidynReiman. Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
  - Notes: original by wulax, edited for female base by pvigier, edited for v3 base by bluecarrot16, idle & sit by Ahmad3366, color reduced & female sit/emote by JaidynReiman
- `shield/heater/revised/trim` by bluecarrot16, Sander Frenken (castelonia), ElizaWy, JaidynReiman. Licence: OGA-BY 3.0.
  - https://opengameart.org/content/lpc-shields
- `shield/kite` by DarkwallLKE, Tuomo Untinen (reemax), Michael Whitlock (bigbeargames). Licence: CC-BY-SA 3.0 / GPL 2.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-kite-shield
  - https://opengameart.org/content/lpc-shields-pack
- `shield/round` by Johannes Sjölund (wulax), Michael Whitlock (bigbeargames), DarkwallLKE, Tuomo Untinen (reemax). Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
  - https://opengameart.org/content/lpc-shields-pack
- `torso/aprons/apron` by Nila122. Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 2.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-aprons
- `torso/armour/leather` by Johannes Sjölund (wulax), bluecarrot16, JaidynReiman. Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
  - https://opengameart.org/content/lpc-clothing-updates
  - https://opengameart.org/content/lpc-expanded-armor
  - Notes: adapted to v3 bases by bluecarrot16, reduced colors and climb/emote/jump by JaidynReiman
- `torso/armour/leather/female` by Michael Whitlock (bigbeargames), Matthew Krohn (makrohn), Johannes Sjölund (wulax), bluecarrot16, JaidynReiman. Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
  - https://opengameart.org/content/lpc-combat-armor-for-women
  - https://opengameart.org/content/lpc-clothing-updates
  - https://opengameart.org/content/lpc-expanded-armor
  - Notes: recolor of torso/armour/leather/female/brown.png, adapted to v3 bases by bluecarrot16, reduced colors and climb/emote/jump by JaidynReiman
- `torso/armour/plate/female` by JaidynReiman, bluecarrot16, Michael Whitlock (bigbeargames), Matthew Krohn (makrohn), Johannes Sjölund (wulax). Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
  - https://opengameart.org/content/lpc-combat-armor-for-women
  - http://opengameart.org/content/lpc-clothing-updates
  - Notes: original by wulax, adapted to female base by makrohn, recolor by bigbeargames, color reduced to 7 colors and adapted to v3 bases by bluecarrot16, run/jump/sit/climb/revised combat by JaidynReiman, reduced colors to 6 (based on Napsio's Vitruvian)
- `torso/armour/plate/male` by Napsio (Vitruvian Studio), JaidynReiman, bluecarrot16, Michael Whitlock (bigbeargames), Johannes Sjölund (wulax). Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
  - https://opengameart.org/content/lpc-combat-armor-for-women
  - Notes: original by wulax, recolor by bigbeargames, color reduced to 7 colors and adapted to v3 bases by bluecarrot16, run/jump/sit/climb/revised combat by JaidynReiman, reduced colors to 6 (based on Napsio's Vitruvian)
- `torso/chainmail` by Johannes Sjölund (wulax), Napsio (Vitruvian Studio), JaidynReiman. Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
  - Notes: minor edits by bluecarrot16, reduced colors by Napsio, adjusted Male colors and Idle/Sit/Emote/Climb/Run by JaidynReiman
- `torso/clothes/longsleeve/longsleeve/female` by bluecarrot16, ElizaWy, JaidynReiman, Stephen Challener (Redshrike). Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/liberated-pixel-cup-lpc-base-assets-sprites-map-tiles
  - https://opengameart.org/content/lpc-7-womens-shirts
  - http://opengameart.org/content/lpc-clothing-updates
  - https://opengameart.org/content/lpc-revised-character-basics
  - https://github.com/ElizaWy/LPC/tree/main/Characters/Clothing
  - https://opengameart.org/content/lpc-expanded-sit-run-jump-more
  - https://opengameart.org/content/lpc-expanded-simple-shirts
  - Notes: original by ElizaWy, edited to v3 bases by bluecarrot16; cleanup and climb/jump/run/sit/emote/revised combat adapted from LPC Revised by JaidynReiman
- `torso/clothes/longsleeve/longsleeve/male` by JaidynReiman, Johannes Sjölund (wulax). Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
  - http://opengameart.org/content/lpc-clothing-updates
  - https://opengameart.org/content/lpc-revised-character-basics
  - https://github.com/ElizaWy/LPC/tree/main/Characters/Clothing
  - https://opengameart.org/content/lpc-expanded-sit-run-jump-more
  - https://opengameart.org/content/lpc-expanded-simple-shirts
  - Notes: original by wulax; tweaks and further recolors by bluecarrot16; cleanup and climb/jump/run/sit/emote/revised combat adapted from LPC Revised by JaidynReiman
- `torso/clothes/shirt/child` by Nila122. Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-clothes-for-children
- `torso/clothes/shortsleeve/tshirt` by ElizaWy, JaidynReiman, Stephen Challener (Redshrike), Johannes Sjölund (wulax). Licence: OGA-BY 3.0.
  - https://opengameart.org/content/lpc-revised-character-basics
  - https://github.com/ElizaWy/LPC/tree/main/Characters/Clothing
  - https://opengameart.org/content/lpc-expanded-sit-run-jump-more
  - https://opengameart.org/content/lpc-expanded-simple-shirts
  - Notes: original by ElizaWy; spellcast/thrust/shoot/hurt/male adapted from original by JaidynReiman
- `torso/clothes/vest_open` by bluecarrot16, Thane Brimhall (pennomi), laetissima. Licence: CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-2-characters
  - https://opengameart.org/content/lpc-gentleman
  - https://opengameart.org/content/lpc-pirates
- `weapon/blunt/waraxe` by Benjamin K. Smith (BenCreating), bluecarrot16, Sander Frenken (castelonia). Licence: CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-medieval-weapons
- `weapon/magic/simple` by bluecarrot16, Dr. Jamgo. Licence: CC0.
  - https://opengameart.org/content/lpc-simple-staff
  - Notes: original by DrJamgo, hands switched and split into to layers by bluecarrot16
- `weapon/magic/wand` by Matthew Krohn (makrohn). Licence: CC-BY-SA 3.0 / GPL 3.0 / OGA-BY 3.0.
  - https://opengameart.org/content/lpc-wands
- `weapon/polearm/halberd` by Benjamin K. Smith (BenCreating), bluecarrot16, Sander Frenken (castelonia). Licence: CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-medieval-weapons
- `weapon/polearm/spear` by Pierre Vigier (pvigier), Johannes Sjölund (wulax), Inboxninja. Licence: CC-BY-SA 3.0.
  - https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
  - https://opengameart.org/content/lpc-spear-and-shovel-reworked
  - Notes: original by wulax, walk animations redone by pvigier, split into layers and tweaked for v3 character bases by bluecarrot16
- `weapon/ranged/bow/great` by Daniel Eddeland (daneeklu), gr3yh47, Johannes Sjölund (wulax), Pierre Vigier (pvigier). Licence: CC-BY-SA 3.0.
  - https://opengameart.org/content/lpc-weapons-two-bows-a-spear-and-a-trident
  - https://opengameart.org/content/lpc-walk-animations-for-bows
  - Notes: modified by daneeklu, from "normal" bow by wulax; walk animations by pvigier; split into layers and tweaked for v3 character bases by bluecarrot16
- `weapon/ranged/bow/normal` by Johannes Sjölund (wulax), Pierre Vigier (pvigier). Licence: OGA-BY 3.0+ / GPL 3.0 / CC-BY 4.0.
  - https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
  - https://opengameart.org/content/lpc-walk-animations-for-bows
  - Notes: original by wulax, walk animations by pvigier, split into layers and tweaked for v3 character bases by bluecarrot16. pvigier has agreed to license this sheet as OGA-BY 3.0+.
- `weapon/sword/arming` by ElizaWy; walk and down by JaidynReiman. Licence: OGA-BY 3.0.
  - https://github.com/ElizaWy/LPC/tree/main/Characters/Props/Sword%2001%20-%20Arming%20Sword
  - https://opengameart.org/content/lpc-expanded-sit-run-jump-more
- `weapon/sword/dagger` by bluecarrot16, Johannes Sjölund (wulax), Matthew Krohn (makrohn). Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
  - https://opengameart.org/content/lpc-extended-weapon-animations
- `weapon/sword/longsword` by Johannes Sjölund (wulax), bluecarrot16. Licence: OGA-BY 3.0 / CC-BY-SA 3.0.
  - https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
  - https://opengameart.org/content/lpc-extended-weapon-animations
- `weapon/sword/scimitar` by Pierre Vigier and DCSS artists (see https://github.com/crawl/tiles/blob/master/ARTISTS.md). Licence: OGA-BY 3.0.
  - https://opengameart.org/content/lpc-dcss-swords
<!-- build_sprites:end -->

## Audio (`game/assets/audio/`, M12, ADR 0019)

- `sfx/footstep_*.ogg` and `sfx/impact*.ogg` from "Impact Sounds" by Kenney (www.kenney.nl).
  Licence: CC0 1.0. https://kenney.nl/assets/impact-sounds
  Licence file: `game/assets/audio/sfx/kenney_impact_sounds_License.txt`.
- `music/old_tower_inn.mp3` is "Medieval: The Old Tower Inn" (`The_Old_Tower_Inn.mp3`) by RandomMind.
  Licence: CC0 1.0. https://opengameart.org/content/medieval-the-old-tower-inn
- `music/market_day.mp3` ("Medieval: Market Day", loop version), `music/bards_tale.mp3` ("Medieval: The Bard's
  Tale"), `music/kings_feast.mp3` ("Medieval: King's Feast") and `music/medieval_battle.mp3` ("Medieval: Battle")
  by RandomMind. Licence: CC0 1.0. https://opengameart.org/content/medieval-market-day ,
  https://opengameart.org/content/medieval-the-bards-tale , https://opengameart.org/content/medieval-kings-feast ,
  https://opengameart.org/content/medieval-battle
- `music/town_theme.mp3` ("Town Theme RPG") and `music/battle_theme_a.mp3` ("Battle Theme A") by cynicmusic.
  Licence: CC0 1.0 (Battle Theme A is also offered as CC-BY 3.0 / CC-BY-SA 3.0; we use CC0).
  https://opengameart.org/content/town-theme-rpg , https://opengameart.org/content/battle-theme-a
- `music/field_of_dreams.mp3` ("The Field Of Dreams") by pauliuw. Licence: CC0 1.0.
  https://opengameart.org/content/the-field-of-dreams
- `music/forgotten_tombs.mp3` ("Forgoten tomb ambience", `Forgoten_tombs_1.mp3`) by kindland. Licence: CC0 1.0.
  https://opengameart.org/content/forgoten-tomb-ambience
- `music/lament_warriors_soul.mp3` ("Fantasy: Lament for a Warrior's Soul", `Lament_for_a_Warriors_Soul.mp3`) and
  `music/rising_moon.mp3` ("Fantasy: Rising Moon", `Rising_Moon.mp3`) by RandomMind. Licence: CC0 1.0.
  https://opengameart.org/content/fantasy-lament-for-a-warriors-soul , https://opengameart.org/content/fantasy-rising-moon
- `music/doom_in_the_morning.mp3` ("Doom in the Morning", `MorningAttack.mp3`) by VishwaJai. Licence: CC0 1.0.
  https://opengameart.org/content/doom-in-the-morning
- `music/fall_of_nightmares.ogg` ("Fall of Nightmares [Epic, Orchestral]") by nene, turned from WAV into OGG.
  Licence: CC0 1.0. https://opengameart.org/content/fall-of-nightmares-epic-orchestral
- `music/heavenly_loop.ogg` ("Heavenly Loop") by isaiah658. Licence: CC0 1.0.
  https://opengameart.org/content/heavenly-loop
- `music/snowfall.ogg` ("Snowfall", looped version) by Kistol. Licence: CC0 1.0.
  https://opengameart.org/content/snowfall
- `music/cold_hands.ogg` ("Cold Hands") by SkyleTheFrench. Licence: CC0 1.0.
  https://opengameart.org/content/cold-hands
- `sfx/chop.ogg`, `sfx/knifeSlice*.ogg`, `sfx/metalPot*.ogg`, `sfx/cloth*.ogg`, `sfx/doorOpen_*.ogg`,
  `sfx/handleCoins*.ogg`, `sfx/dropLeather.ogg`, `sfx/handleSmallLeather*.ogg`, `sfx/bookFlip*.ogg` and
  `sfx/creak*.ogg` from "RPG Audio" by Kenney (www.kenney.nl). Licence: CC0 1.0. https://kenney.nl/assets/rpg-audio
  Licence file: `game/assets/audio/sfx/kenney_rpg_audio_License.txt`.
- `sfx/swish-*.wav` from "Swishes Sound Pack" by artisticdude. Licence: CC0 1.0.
  https://opengameart.org/content/swishes-sound-pack
- `sfx/creature_*.ogg` from "80 CC0 creature SFX" by rubberduck (the file names have a `creature_` prefix).
  Licence: CC0 1.0. https://opengameart.org/content/80-cc0-creature-sfx
- `sfx/water_splash_*.ogg` from "40 CC0 water / splash / slime SFX" by rubberduck (`splash_*.ogg`).
  Licence: CC0 1.0. https://opengameart.org/content/40-cc0-water-splash-slime-sfx
- `ui/*.wav` are made by `tools/build_sfx.py` (our own blips, chimes, the magic door, the faerie twinkle and the sad sting).
  Licence: CC0 1.0.
- `ambience/amb_cave.ogg` is "Loopable Dungeon Ambience" (`dungeon_ambient_1.ogg`) by JaggedStone.
  Licence: CC0 1.0. https://opengameart.org/content/loopable-dungeon-ambience
- `ambience/amb_crickets.ogg` is "Crickets Ambient Noise - loopable" (`crickets.mp3`) by Wolfgang_ (credit: Ted
  Kerr), turned into OGG. Licence: CC0 1.0. https://opengameart.org/content/crickets-ambient-noise-loopable
- `ambience/amb_birds.ogg` is cut from "Ambient Bird Sounds" (`birds-isaiah658.ogg`) by isaiah658 (26 s, the end
  cross-faded into the start to loop). Licence: CC0 1.0. https://opengameart.org/content/ambient-bird-sounds
- `ambience/amb_wind.ogg` is "wind whoosh loop" by SketchMan3. Licence: CC0 1.0.
  https://opengameart.org/content/wind-whoosh-loop
- `ambience/amb_fire.ogg` is cut from "Fireplace Sound loop" (`fire.wav`) by PagDev (20 s, mono, cross-faded to
  loop). Licence: CC0 1.0. https://opengameart.org/content/fireplace-sound-loop
- `ambience/amb_water.ogg` is `loop_water_02.ogg` from "40 CC0 water / splash / slime SFX" by rubberduck.
  Licence: CC0 1.0. https://opengameart.org/content/40-cc0-water-splash-slime-sfx
- `ambience/amb_crowd.ogg` is cut from "Crowd Cheering Sounds - 10 - Ambience" in "Free Crowd Cheering Sounds" by
  Gregor Quendel (30 s, cross-faded to loop). Licence: CC-BY 4.0 (https://creativecommons.org/licenses/by/4.0/).
  https://opengameart.org/content/free-crowd-cheering-sounds
- `ambience/amb_bees.ogg` is cut from "Single Bee sound" (`bee.wav`) by IMadeIt (2 s, mono, cross-faded to loop).
  Licence: CC-BY 3.0 (https://creativecommons.org/licenses/by/3.0/). https://opengameart.org/content/single-bee-sound

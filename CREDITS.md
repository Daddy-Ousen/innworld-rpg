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
- `hat/helmet/barbarian` by bluecarrot16, JaidynReiman, Napsio (Vitruvian Studio). Licence: CC-BY 3.0 / CC-BY 4.0 / OGA-BY 3.0 / GPL 2.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-helmets
  - https://opengameart.org/content/lpc-expanded-hats-facial-helmets
  - Notes: original version by bluecarrot16, color reduction by Napsio (Vitruvian Studio)
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
- `legs/skirts/plain` by bluecarrot16, Pierre Vigier (pvigier), Johannes Sjölund (wulax), Ahmad3366, JaidynReiman. Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
  - Notes: original by wulax, edited for female base by pvigier, edited for v3 base by bluecarrot16, idle & sit by Ahmad3366, color reduced & female sit/emote by JaidynReiman
- `shield/heater/revised/trim` by bluecarrot16, Sander Frenken (castelonia), ElizaWy, JaidynReiman. Licence: OGA-BY 3.0.
  - https://opengameart.org/content/lpc-shields
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
- `weapon/blunt/waraxe` by Benjamin K. Smith (BenCreating), bluecarrot16, Sander Frenken (castelonia). Licence: CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-medieval-weapons
- `weapon/magic/simple` by bluecarrot16, Dr. Jamgo. Licence: CC0.
  - https://opengameart.org/content/lpc-simple-staff
  - Notes: original by DrJamgo, hands switched and split into to layers by bluecarrot16
- `weapon/magic/wand` by Matthew Krohn (makrohn). Licence: CC-BY-SA 3.0 / GPL 3.0 / OGA-BY 3.0.
  - https://opengameart.org/content/lpc-wands
- `weapon/polearm/spear` by Pierre Vigier (pvigier), Johannes Sjölund (wulax), Inboxninja. Licence: CC-BY-SA 3.0.
  - https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
  - https://opengameart.org/content/lpc-spear-and-shovel-reworked
  - Notes: original by wulax, walk animations redone by pvigier, split into layers and tweaked for v3 character bases by bluecarrot16
- `weapon/sword/arming` by ElizaWy; walk and down by JaidynReiman. Licence: OGA-BY 3.0.
  - https://github.com/ElizaWy/LPC/tree/main/Characters/Props/Sword%2001%20-%20Arming%20Sword
  - https://opengameart.org/content/lpc-expanded-sit-run-jump-more
- `weapon/sword/dagger` by bluecarrot16, Johannes Sjölund (wulax), Matthew Krohn (makrohn). Licence: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.
  - https://opengameart.org/content/lpc-medieval-fantasy-character-sprites
  - https://opengameart.org/content/lpc-extended-weapon-animations
<!-- build_sprites:end -->

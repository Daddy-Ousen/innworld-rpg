# ADR 0045: Phone controls, second pass (M34)

Status: accepted (2026-10-21).

## Problem
The user played on an Android phone and reported: it is hard to pick an option from a menu (a shop, a talk with
an NPC), and the Use button is not ideal.

The code shows why (`docs/plans/m34.md` section 1):
- The use menu (`ui/interact_menu.gd`) is one flat `ItemList`. It holds every nearby object and every action of
  each: a shop or a busy inn gives 15 – 40 rows.
- One tap on a row runs it (`TouchControls.activate_on_tap`, M20.1). An `ItemList` does not scroll with a finger
  drag, so a try to scroll picks a row. Attack has no guard.
- Rows are one text line high: under the 48 dp touch minimum.
- The Use button does not say what it will do. Outside a fight, a tap on the map does nothing.

Other phone RPGs (Stardew Valley, Shattered Pixel Dungeon, Don't Starve: Pocket Edition) let the player tap a
thing to walk to it and act, and use one context button whose label says what it does. Sources are in the plan.

## Decision
Presentation only. Core, data schemas and the save format do not change (rules 1, 2, 8). Rows still come from
`Interact.options`; picks are the same strings (`Interact.trade_action`, `Interact.VOICE`, ...).

- **Action card (M34.0):** two steps, target first, then action. One card per target: face, name, standing; big
  buttons in groups (Talk, Serve, Trade, Learn, Other). Buttons fire on release and only if the finger moved less
  than 12 px; a drag scrolls. 64 px rows at phone scale, 8 px gaps. It replaces the flat list on every platform
  (user pick: one menu to keep). Keys: arrows, Enter, Esc.
- **Attack guard (M34.0):** on touch, hold Attack for 0.6 s. With keys or a mouse, a "Attack <name>? Yes / No" box.
- **Shop screen (M34.1):** Buy and Sell tabs, item cards, a count strip (− / + / Max, total, one Buy or Sell button).
  It sends the existing trade picks with a count.
- **Context button (M34.2):** replaces Use. It shows the nearest target's main action and name ("Talk · Erin"). With
  2+ targets near, small chips pick the target. Bottom right, bigger than the other buttons. Menu moves to the top
  right.
- **Tap the world (M34.3, later):** outside a fight, a tap on a target walks next to it (normal move commands, so
  rule 3 holds) and opens its card. Options "Controls: Tap + stick / Stick only" in the touch settings file, not in
  `GameState`.

## M34.0 as built (2026-10-21)
- `ui/interact_menu.gd` / `.tscn` were rewritten in place (class `InteractMenu`, same `chosen` signal, `open`,
  `open_bag`, `look_of`), not a new `action_card` file: `main.gd` and the panels needed no change.
- Pages: `TARGETS` (2+ things near; a face icon on each NPC or patron button), `ACTIONS` (one target),
  `CONFIRM` (Attack with keys or a mouse). Back / Escape / the card's Close button go back one page.
- `InteractMenu.action_rows(option, db, gs)` (static) builds a card's rows in group order: talk, serve, work,
  trade, travel, learn, other, attack. Button text has no name prefix ("Take Stone", not "Loose stones — Take Stone").
- `CardButton`: fires on release; a move past `DRAG` (12 UI px) scrolls the card and cancels the pick.
  `HoldButton` (Attack on touch): fires after `HOLD` (0.6 s); a ring fills.
- Buttons are `ROW_H` 32 UI px high (about 53 dp at the phone's 250 % menu size). Two columns, one column when a
  row is longer than 22 letters. The card sits at the bottom middle, at most 560 px wide and 85 % of the height.
- Checked on a render at 1200 × 540 with menu size 250 % (same layout as 2400 × 1080): target list, Krshia's card.

## M34.1 as built (2026-10-21)
- New `ui/shop_panel.gd` / `.tscn` (class `ShopPanel`) in `world/main.tscn` `MenuLayer`. A shop's card now has one
  button, "Shop" or "Shop (N to sell)" (`InteractMenu.SHOP`, a menu pick only). It sends `shop_opened(option)`;
  `MainPanels.open_shop` shows the panel.
- Header row: shop name, Buy and Sell tabs, Back. The line under it shows the coins, or after a deal what the deal did
  and the coins left. Cards: name, price, "(have N)"; two columns. The Sell tab puts "Sell all" next to each good.
- Count strip: `-`, count, `+`, Max, and one big button "Buy 3 for 9c". `-` and `+` repeat while held (0.4 s wait,
  then every 0.08 s). Max = what the coins pay for (1 for a meal eaten there or clothes, `Economy.is_single`), or what
  the bag holds; 99 at most. With too few coins the button says "Not enough coins" and is off.
- A deal sends `chosen(object_id, Interact.trade_action(prefix, good, count))`. `MainPanels.use_from_shop` runs it with
  `MainScreen.use` and opens the panel again on the same shop: tab and good stay, the count is clamped. Back sends
  `went_back`; `InteractMenu.open_on` shows that shop's card again.
- Core: `Economy._single` became public `Economy.is_single` (same code). No schema or save change.
- Checked on a render at 1200 × 540, menu size 250 %: about one and a half rows of cards show, the rest scrolls. The
  first layout had the tabs and the note in their own rows and showed only one row; they moved into the header.

## Consequences
- Tests that drive the old `InteractMenu` list (`unit_world_view`, `unit_play_loop`, others) move to the new card.
- The long flat list is gone, so a keyboard player also picks a target first: one extra key press when several
  targets are near. With one target near, the card opens on it at once.
- Layout must be checked on a phone render (2400 × 1080 at 250 %) and by the user on a phone.

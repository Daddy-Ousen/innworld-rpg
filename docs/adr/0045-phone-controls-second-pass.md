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
  trade, travel, learn, other, attack (M34.2 moved trade before work). Button text has no name prefix ("Take Stone", not "Loose stones — Take Stone").
- `CardButton`: fires on release; a move past `DRAG` (12 UI px) scrolls the card and cancels the pick.
  `HoldButton` (Attack on touch): fires after `HOLD` (0.6 s); a ring fills.
- Buttons are `ROW_H` 32 UI px high (wrong first note: "about 53 dp"; it is about 30 dp on a phone; M34.4 fixed it). Two columns, one column when a
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

## M34.2 as built (2026-10-21)
- `ui/touch_controls.gd`: the Use button is gone. The right column is now More, Bag and the context button (96 px
  high), on the bottom right edge. Menu sits at the top right, just under the HUD status bar
  (`Hud.top_bottom`, `TouchControls.set_top_room`), so it does not cover the coins. Back takes the same spot while a
  panel is open. Cancel and the More grid moved down with the column.
- The context button shows the nearest target's verb and name on two lines ("Talk / Erin"; "-" and off when nothing
  is near). Verbs come from `InteractMenu.verb_of`: Serve, Talk, Shop, Sleep, Door, Ride, Take, Use. A tap sends
  `context_pressed(id)`; `MainPanels.open_target` opens that target's card (`InteractMenu.open_on`).
- Chips: up to 3, in a row LEFT of the context button (not above it as planned: the column has no room above on a
  phone), nearest next to the button. A chip shows the face (NPC, patron) or the first 5 letters of the name. With
  more than 4 targets near, the last chip is "All" (the target list).
- `MainPanels.refresh_context` reads `InteractMenu.targets(Interact.options(...))` only when the game, area, square,
  clock minute or flag count changes (not every frame).
- On a stall the card now lists Shop before Haggle (group order: trade before work).
- Not done: the planned 20 % larger hit area. The button itself is bigger (104 × 96).
- The key E still opens the whole use menu. Checked on a render at 1200 × 540, menu size 250 %, touch on.

## M34.3 as built (2026-10-21)
- New `world/main_tap.gd` (`MainTap`, `MainScreen.tapper`). Outside a fight, a touch tap on an NPC, a seated patron or
  a map object (`MainTap.target_at`) walks next to it, then opens its card (`MainPanels.open_target`). A tap on a
  target that is already near opens the card at once (no time passes). A tap on the floor walks there; a tap on an
  exit walks onto it and leaves the map.
- Each step is `MainScreen.step` (a normal move), one every `STEP_REPEAT`. The path (`Pathfind.path`, around people
  and monsters) is found again before each step, so a moving NPC is followed. At most 80 steps.
- The walk ends on: a new tap, a held direction (stick or key), Cancel (shown during the walk), a panel or the System
  dialog or the long-road question, a fight, a new map, or a step that does not move.
- `MainInput.world_tap`: only emulated (touch) left clicks, and only when the touch controls show and Controls is
  "Tap + stick" (`Session.tap_walk_on`). It acts when the finger lifts, only if it moved less than `MainTap.SLOP`
  (24 px) and did not walk with the stick (`TouchControls.stick_walked`). A desktop mouse click outside a fight still
  does nothing.
- Controls: `TouchSettings.controls` (`tap` default, `stick`), key `controls` in the `touch` section of
  `user://settings.cfg` (not in `GameState`). Options has a "Controls" row (`Session.set_touch_controls`).
- No core, schema or save change. Determinism checked: a tap walk and the same moves by key give the same clock and
  RNG state (`unit_tap_walk`). Not checked on a render (behaviour only, no new layout except one Options row).

## M34.4 as built (2026-10-21)
- Renders at 2400 × 1080, menu size 250 %, touch on, no stretch (the Android build: the UI is 960 × 432). The
  earlier 1200 × 540 renders were a smaller case than the phone.
- Found: the touch pad and the map kept 64 px buttons and 64 px tiles (M20.3), about 25 dp on a 405 dpi phone; card
  and shop buttons were about 30 dp. The touch minimum is 48 dp.
- Fix (user pick: buttons and map by dpi; a desktop stays): `UiScale.px_per_dp` (screen dpi / 160), `touch_grow`
  (smallest pad button 48 dp), `map_grow` (a tile about 40 dp, in `camera_zoom`), `touch_ui_px` (a menu button
  48 dp). Only on a phone or tablet OS (`is_mobile_os`). `InteractMenu.row_h()` replaces `ROW_H` for card and shop
  buttons, Close, Back and the tabs. `UiScale.dpi_override` and `mobile_override` are for tests and renders.
- Rendered again as a 405 dpi phone: pad buttons about 48 dp, labels about 12 dp, tiles about 40 dp, card and
  shop buttons about 48 dp; Erin's card shows 5 buttons, the shop 4 rows of goods plus the strip.
- Left for later: the bag screen is still the old list with key hints ("Enter: Eat"); "H: help" shows on a
  phone. A real phone may report another dpi: the user checks on the phone.

## M34.5 phone fixes (2026-10-22, from the user's first play of v0.1.7 on a phone)
- The phone ran the game upright (portrait; `window/handheld/orientation=6` is "sensor", any way up). The
  M34 renders were all sideways, so two layouts were never seen upright.
- Fight: the empty context button ("-") sat on the combat bar's End turn button, and the column covered the turn
  order faces. Now the context button hides when nothing is near and in every fight
  (`MainPanels.refresh_context`), and the bottom-right controls sit above the combat bar while it shows
  (`TouchControls.set_bottom_room`, `MainPanels._bar_room`). Cancel stays on top of the column.
- Shop: on an upright phone the panel is about 320 UI px wide; the count row took it all and the Buy button
  shrank to a sliver. The strip is now an `HFlowContainer` and the Buy button is at least 4 button heights wide
  (`ShopPanel.DEAL_WIDTH`): upright it wraps to its own line with Max; sideways all stays on one line.
- Rendered upright (1080 x 2400) and sideways (2400 x 1080) as a 405 dpi phone: fight and shop look right.

## Consequences
- Tests that drive the old `InteractMenu` list (`unit_world_view`, `unit_play_loop`, others) move to the new card.
- The long flat list is gone, so a keyboard player also picks a target first: one extra key press when several
  targets are near. With one target near, the card opens on it at once.
- Layout must be checked on a phone render (2400 × 1080 at 250 %) and by the user on a phone.

# ADR 0033 — UI scale for phones (M20.3)

Date: 2026-10-05 · Status: accepted (user answers in the cloud session, plan `docs/plans/m20.3.md`).

## Context
- On a phone in landscape the browser build shows the 1152 × 648 layout on a screen about 68 mm tall. A menu
  button (24 px) is about 2.5 mm and 16 px text about 1.7 mm: too small to tap or read. The touch pad (64 px
  buttons, ADR 0032) is about 6.7 mm, which is good.
- Renders at 2400 × 1080 (Xvfb) showed: at 200 % the menus are readable, but the map zooms in 2×, the touch pad
  doubles, and the Journal (600 × 600), Character sheet, Bag and text pages run off a 324 px tall view.

## Decision
- **One knob:** the root window's `content_scale_factor`. Godot multiplies every Control by it, in the desktop
  stretch mode ("disabled") and the web one ("canvas_items"). No theme or font change.
- **`ui/ui_scale.gd` (`UiScale`):** mode Auto, 1, 1.5 or 2, saved in `user://settings.cfg` (section `display`, key
  `ui_scale`). A user preference, not `GameState`: no save change. Options row "Menu size": Auto / 100% / 150% / 200%.
- **Auto:** 2 on a touch screen whose short side is under 5 inches (`short px / dpi`), else 1. On the web dpi is
  96 × devicePixelRatio, so a phone reads about 4 in, a tablet about 8 in. Without a touch screen Auto is always 1,
  so a small desktop window never jumps. `Session` applies the factor at start, on a window resize (a phone turns)
  and after the first screen touch.
- **The map keeps its size** (user's choice): the world camera zoom is `2 / factor`.
  Rejected: the map zooms with the menus (only a few tiles show; fights need panning).
- **The touch pad keeps its size** (user's choice): the touch buttons sit in one box scaled by `1 / factor`, so
  inside it everything lays out as at 100 %, text included. The HUD log makes room for the pad's real width.
  Rejected: the pad grows with the menus (13 mm buttons; the pad covers half the screen height).
- **Panels fit:** `UiScale.keep_fit` cuts the Journal, Character sheet, Bag and text pages to the view minus 8 px,
  when they show, on a resize and on a scale change. They already scroll inside. The Journal focus list takes at
  most 30 % of the view height. `keep_fit` lets go of the viewport and Session signals when the panel leaves the
  tree, so no signal calls a freed panel.

## Consequences
- Checked on renders: phone 2400 × 1080 at 100 % and 200 % (world, journal, sheet, bag, pause, options), desktop
  1152 × 648 at 150 %. A real phone was not tested.
- The pixel font draws at non-16 sizes at 150 % (TextSettings note): it may look a little soft. 200 % is sharp.
- Headless tests: a faked screen touch makes Auto see a tiny "phone" and pick 200 %. Tests that fake a touch
  call `Session.apply_ui_scale()` after they reset `touch_seen`.

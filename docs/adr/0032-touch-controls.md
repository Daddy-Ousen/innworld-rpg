# ADR 0032 — Touch controls (M20)

Date: 2026-10-05 · Status: accepted (user answers in the cloud session, plan `docs/plans/m20.md`).

## Context
- The browser build is live (ADR 0031) and Android waits (ADR 0029). Both need touch controls.
- The game had no InputMap. About 10 scripts read raw keys (`physical_keycode == KEY_E`), and `world/main.gd`
  polled `Input.is_physical_key_pressed` for held walking. A screen button could not press a command.
- Godot turns a tap into a left mouse click (`emulate_mouse_from_touch`, on by default). Buttons, the System
  dialog, the Skill bar and "click a tile in a fight" already worked on touch. Walking, every hotkey, Esc, right
  click, mouse hover and PageUp/PageDown did not.

## Decision
1. **M20.0: input actions.** Every command is a named action in `project.godot` `[input]` (`move_n/s/e/w`, `wait`,
   `use`, `eat`, `bag`, `sleep`, `sheet`, `journal`, `log`, `help`, `back`, `block`, `throw`, `drop`, `stow`,
   `page_up`, `page_down`, `console`, `skill_1` … `skill_9`). Each keeps today's physical keys, device -1 (all
   devices). The game reads actions only. `InputNames.key_of` gives key names for UI text.
   Rejected: touch buttons that send fake key events. A smaller diff, but it ties the touch layer to key codes and
   breaks with key remapping. Actions also make gamepad support and a remap screen cheap later.
2. **M20.1: touch layer.** `ui/touch_controls.gd` in a `TouchLayer` (CanvasLayer 2, after the menus):
   - a 4-way D-pad with Wait (bottom left). Rejected: a virtual joystick (an analog stick gives wrong steps near
     the diagonals on a 4-way grid) and tap-to-walk (needs paths outside fights, slow for small steps);
   - Use, Bag, More, Menu (middle of the right edge); More opens a grid of the other commands;
   - Back (only while a panel is open; it sends `back`, which every panel reads as Esc); Cancel above the column
     while a Skill is armed or a walk runs (it does what a right click does). Cancel is not in the column, so the
     column never moves under a thumb.
   - Each button sends an `InputEventAction` (press on `button_down`, release on `button_up`) through
     `Input.parse_input_event`. The game cannot tell a tap from a key. A held pad button is a held key.
   - When the pad hides with a finger on it (a panel or the System dialog opens), it lets go of its actions, so
     the player does not walk on after the panel closes.
   - Buttons take no focus (`FOCUS_NONE`), so keys keep going to the game.
   - Plain Godot `Button`s, not `TouchScreenButton`: they use the game theme, show text, and stop the tap from
     reaching the map. The cost: one finger at a time (the mouse emulation follows the first touch). A turn-based
     grid game does not need two at once.
3. **When it shows.** `TouchSettings` (`user://settings.cfg`, section `touch`): Auto (default), On, Off, in the
   Options panel. Auto shows the controls when `DisplayServer.is_touchscreen_available()` or after the first
   `InputEventScreenTouch` in the run (`Session.touch_seen`). A user preference, not game state (rule 2): no save
   change.
4. **Fight taps.** A touch has no hover, so a tap (an emulated click, `device == InputEvent.DEVICE_ID_EMULATION`)
   first shows the plan (path, hit chance); a second tap on the same cell acts. A new game state resets this. A
   real mouse click still acts at once. The cell comes from the event's position, not the mouse pointer.
5. **Lists and panels.** With the controls shown, one tap picks an `ItemList` item (a mouse needs a double click;
   a double tap is hard to find). The bag has buttons for X (leave one behind) and P (put the held item in the
   bag). The Load list has a Back button (the title screen has no touch layer). Text pages scroll by drag
   (ScrollContainer does this on a touch screen).
6. The HUD log moves right of the pad while the controls show (`Hud.make_room_left`).

## Consequences
- Keys work as before. One addition: Delete also drops the held item outside the bag (it was the bag's key).
- Cloud sessions can render the game under Xvfb (`xvfb-run … godot --rendering-driver opengl3`), so the layout
  was checked on 1152x648 renders. A real phone was not tested.
- Open: menu buttons and the 16 px text are small on a phone (about 3 mm). "Large text" helps now; a UI scale
  option is a later step. The debug console needs a typing keyboard (developer tool, left out).
- Next: M20.2 Android build, in a local session (Android SDK, JDK, keystore).

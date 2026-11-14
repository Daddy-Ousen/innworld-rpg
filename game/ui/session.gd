## The running game for the presentation layer (autoload "Session").
## Scenes read `gs` and send Commands. After a command they call
## changed(); a new or loaded game goes through set_state().
## Saves go to SaveSlots in `save_dir` (GUT runs use a test folder, see
## test_support/gut_pre_run.gd).
extends Node

signal state_changed
## The touch controls' mode changed, or the first touch was seen (M20.1).
signal touch_changed
## The UI scale factor changed (M20.3): the option, a resize or the first touch.
signal ui_scale_changed
## The full screen setting changed (audit W3): F11, Alt+Enter or the Options box.
signal display_changed

const NEW_GAME_SEED := 1

var db: DataDb
var gs: GameState
var save_dir := SaveSlots.DEFAULT_DIR
## True for a game started with start_new_game() until the game screen has
## shown the welcome page.
var fresh := false
## The start (rules.world.starts id) of the last new game; "" = the first.
var start_id := ""
## The player's text size (M15.0); tests point the path at a test file.
var text: TextSettings
var text_settings_path := TextSettings.PATH
## When the touch controls show (M20.1); tests point the path at a test file.
var touch: TouchSettings
var touch_settings_path := TouchSettings.PATH
## True after the first screen touch in this run (Auto then shows the controls).
var touch_seen := false
## The size of menus, text and the HUD (M20.3); tests point the path at a test file.
var ui_scale: UiScale
var ui_scale_path := UiScale.PATH
## Full screen or a window (audit W3, desktop only); tests point the path at a test file.
var display: DisplaySettings
var display_settings_path := DisplaySettings.PATH
## What a window switch does. Empty = `DisplaySettings.apply_window` (a no-op in a headless run);
## tests set a Callable taking the new full screen state.
var window_handler := Callable()
var _map_grow_seen := 1.0
## The game screen and the title screen, set by each while it is in the tree (audit B5, ADR 0052).
## The Android Back button and the app-paused save read them. Untyped: a typed link is a script cycle.
var game_screen: Node
var title_screen: Node
## What "quit the app" does. Empty = `get_tree().quit()`; tests set a Callable instead.
var quit_handler := Callable()


func _ready() -> void:
	db = DataDb.load_dir()
	gs = GameState.new_game(NEW_GAME_SEED, db)
	load_text_settings()
	load_touch_settings()
	load_display_settings()
	load_ui_scale()
	get_window().size_changed.connect(apply_ui_scale)  # a phone turns, a browser resizes


## Reads the text size from `text_settings_path` and applies it.
func load_text_settings() -> void:
	text = TextSettings.load_file(text_settings_path)
	text.apply()


## Large (32 px) or normal (16 px) text; applied and saved at once.
func set_large_text(on: bool) -> void:
	text.large = on
	text.apply()
	text.save(text_settings_path)


## Reads the touch controls' mode from `touch_settings_path`.
func load_touch_settings() -> void:
	touch = TouchSettings.load_file(touch_settings_path)
	touch_changed.emit()


## Reads the UI scale from `ui_scale_path` and applies it.
func load_ui_scale() -> void:
	ui_scale = UiScale.load_file(ui_scale_path)
	apply_ui_scale()


## Reads the full screen setting from `display_settings_path` and applies it (desktop only).
func load_display_settings() -> void:
	display = DisplaySettings.load_file(display_settings_path)
	if not DisplaySettings.available():
		display.fullscreen = false  # a phone OS and the web have no window mode
	elif display.fullscreen:
		_apply_window()


## Full screen on or off; applied and saved at once. Ignored on a phone OS and in the web build.
func set_fullscreen(on: bool) -> void:
	if not DisplaySettings.available() or display.fullscreen == on:
		return
	display.fullscreen = on
	display.save(display_settings_path)
	_apply_window()
	display_changed.emit()


func toggle_fullscreen() -> void:
	set_fullscreen(not display.fullscreen)


func _apply_window() -> void:
	if window_handler.is_valid():
		window_handler.call(display.fullscreen)
	else:
		DisplaySettings.apply_window(display.fullscreen)


## Auto, 1, 1.5, 2, 2.5 or 3 (UiScale.MODES); applied and saved at once.
func set_ui_scale_mode(mode: String) -> void:
	ui_scale.set_mode(mode)
	ui_scale.save(ui_scale_path)
	apply_ui_scale()


## The factor for this window and screen.
func ui_factor() -> float:
	var size := DisplayServer.window_get_size()
	return ui_scale.factor(float(mini(size.x, size.y)), float(DisplayServer.screen_get_dpi()),
			touch_seen or DisplayServer.is_touchscreen_available(), UiScale.is_mobile_os(),
			UiScale.window_height())


## Sets the root window's content scale; tells the game screen when it changed.
func apply_ui_scale() -> void:
	UiScale.set_box_alpha(ThemeDB.get_project_theme(),
			UiScale.MOBILE_ALPHA if UiScale.is_mobile_os() else 1.0)
	var f := ui_factor()
	var zoom := UiScale.map_grow()  # a desktop map zoom steps with the window height (ADR 0053)
	var changed := not is_equal_approx(get_window().content_scale_factor, f)
	if changed:
		get_window().content_scale_factor = f
	if changed or not is_equal_approx(_map_grow_seen, zoom):
		_map_grow_seen = zoom
		ui_scale_changed.emit()


## Auto, On or Off (TouchSettings); saved at once.
func set_touch_mode(mode: String) -> void:
	touch.set_mode(mode)
	touch.save(touch_settings_path)
	touch_changed.emit()


## M34.3: Tap + stick or Stick only (TouchSettings); saved at once.
func set_touch_controls(c: String) -> void:
	touch.set_controls(c)
	touch.save(touch_settings_path)


## True when a touch tap on the map walks and acts (M34.3).
func tap_walk_on() -> bool:
	return touch_shown() and touch.controls == TouchSettings.TAP


## True when the touch controls show: On, or Auto on a touch screen.
func touch_shown() -> bool:
	return touch.shows(touch_seen or DisplayServer.is_touchscreen_available())


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"fullscreen") and not event.is_echo():  # F11 or Alt+Enter, on every screen
		toggle_fullscreen()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch and not touch_seen:
		touch_seen = true
		touch_changed.emit()
		apply_ui_scale()  # Auto may now see a phone


## Remembers the screen that is up (`game` or `title`) and forgets it when it leaves the tree.
func screen_up(kind: String, node: Node) -> void:
	if kind == "game":
		game_screen = node
	else:
		title_screen = node
	node.tree_exiting.connect(func() -> void:
		if game_screen == node:
			game_screen = null
		if title_screen == node:
			title_screen = null)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:  # Android Back (quit_on_go_back is off)
		go_back()
	elif what == NOTIFICATION_APPLICATION_PAUSED:  # Android / iOS: the app goes to the background
		save_on_pause()


## The Android Back button (audit B5, ADR 0052): the same as Esc. The root title menu is the one
## place it quits the app; every other screen gets the `back` action.
func go_back() -> void:
	if is_instance_valid(title_screen) and title_screen.at_root():
		quit_app()
		return
	for pressed in [true, false]:  # parse_input_event for both sides (never action_release alone)
		var ev := InputEventAction.new()
		ev.action = &"back"
		ev.pressed = pressed
		Input.parse_input_event(ev)


func quit_app() -> void:
	if quit_handler.is_valid():
		quit_handler.call()
	else:
		get_tree().quit()


## The app went to the background: autosave, only while the game screen is up. A failed save is
## logged and never stops the app. All state is in GameState; a walk's move is made only when it ends.
func save_on_pause() -> Error:
	if not is_instance_valid(game_screen) or gs == null:
		return ERR_UNAVAILABLE
	var err := autosave()
	if err != OK:
		push_warning("Save on pause failed: %s" % error_string(err))
	return err


func set_state(new_gs: GameState) -> void:
	db.maps.sync_flags(new_gs.flags)
	gs = new_gs
	fresh = false
	state_changed.emit()


func changed() -> void:
	state_changed.emit()


## A new game from the title menu, at the start `start` ("" = the first), as `identity`
## (M30.5, PlayerIdentity: name, look, background).
func start_new_game(seed_value: int, start: String = "", identity: Dictionary = {}) -> void:
	set_state(GameState.new_game(seed_value, db, start, identity))
	start_id = start
	fresh = true


func save_slot(slot: String) -> Error:
	return SaveSlots.save(gs, save_dir, slot)


func autosave() -> Error:
	return save_slot(SaveSlots.AUTOSAVE)


## False if the slot is empty or cannot be read (the game is unchanged).
func load_slot(slot: String) -> bool:
	var loaded := SaveSlots.load_game(save_dir, slot, db)
	if loaded == null:
		return false
	set_state(loaded)
	return true

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


func _ready() -> void:
	db = DataDb.load_dir()
	gs = GameState.new_game(NEW_GAME_SEED, db)
	load_text_settings()
	load_touch_settings()
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


## Auto, 1, 1.5 or 2 (UiScale.MODES); applied and saved at once.
func set_ui_scale_mode(mode: String) -> void:
	ui_scale.set_mode(mode)
	ui_scale.save(ui_scale_path)
	apply_ui_scale()


## The factor for this window and screen.
func ui_factor() -> float:
	var size := DisplayServer.window_get_size()
	return ui_scale.factor(float(mini(size.x, size.y)), float(DisplayServer.screen_get_dpi()),
			touch_seen or DisplayServer.is_touchscreen_available())


## Sets the root window's content scale; tells the game screen when it changed.
func apply_ui_scale() -> void:
	UiScale.set_box_alpha(ThemeDB.get_project_theme(),
			UiScale.MOBILE_ALPHA if UiScale.is_mobile_os() else 1.0)
	var f := ui_factor()
	if not is_equal_approx(get_window().content_scale_factor, f):
		get_window().content_scale_factor = f
		ui_scale_changed.emit()


## Auto, On or Off (TouchSettings); saved at once.
func set_touch_mode(mode: String) -> void:
	touch.set_mode(mode)
	touch.save(touch_settings_path)
	touch_changed.emit()


## True when the touch controls show: On, or Auto on a touch screen.
func touch_shown() -> bool:
	return touch.shows(touch_seen or DisplayServer.is_touchscreen_available())


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and not touch_seen:
		touch_seen = true
		touch_changed.emit()
		apply_ui_scale()  # Auto may now see a phone


func set_state(new_gs: GameState) -> void:
	db.maps.sync_flags(new_gs.flags)
	gs = new_gs
	fresh = false
	state_changed.emit()


func changed() -> void:
	state_changed.emit()


## A new game from the title menu, at the start `start` ("" = the first).
func start_new_game(seed_value: int, start: String = "") -> void:
	set_state(GameState.new_game(seed_value, db, start))
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

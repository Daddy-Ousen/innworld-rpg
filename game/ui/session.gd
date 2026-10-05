## The running game for the presentation layer (autoload "Session").
## Scenes read `gs` and send Commands. After a command they call
## changed(); a new or loaded game goes through set_state().
## Saves go to SaveSlots in `save_dir` (GUT runs use a test folder, see
## test_support/gut_pre_run.gd).
extends Node

signal state_changed
## The touch controls' mode changed, or the first touch was seen (M20.1).
signal touch_changed

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


func _ready() -> void:
	db = DataDb.load_dir()
	gs = GameState.new_game(NEW_GAME_SEED, db)
	load_text_settings()
	load_touch_settings()


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

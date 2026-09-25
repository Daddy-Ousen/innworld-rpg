## The running game for the presentation layer (autoload "Session").
## Scenes read `gs` and send Commands. After a command they call
## changed(); a new or loaded game goes through set_state().
## Saves go to SaveSlots in `save_dir` (GUT runs use a test folder, see
## test_support/gut_pre_run.gd).
extends Node

signal state_changed

const NEW_GAME_SEED := 1

var db: DataDb
var gs: GameState
var save_dir := SaveSlots.DEFAULT_DIR
## True for a game started with start_new_game() until the game screen has
## shown the welcome page.
var fresh := false


func _ready() -> void:
	db = DataDb.load_dir()
	gs = GameState.new_game(NEW_GAME_SEED, db)


func set_state(new_gs: GameState) -> void:
	db.maps.sync_flags(new_gs.flags)
	gs = new_gs
	fresh = false
	state_changed.emit()


func changed() -> void:
	state_changed.emit()


## A new game from the title menu.
func start_new_game(seed_value: int) -> void:
	set_state(GameState.new_game(seed_value, db))
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

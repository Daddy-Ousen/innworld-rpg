## The running game for the presentation layer (autoload "Session").
## Scenes read `gs` and send Commands. After a command they call
## changed(); a new or loaded game goes through set_state().
extends Node

signal state_changed

const NEW_GAME_SEED := 1

var db: DataDb
var gs: GameState


func _ready() -> void:
	db = DataDb.load_dir()
	gs = GameState.new_game(NEW_GAME_SEED, db)


func set_state(new_gs: GameState) -> void:
	gs = new_gs
	state_changed.emit()


func changed() -> void:
	state_changed.emit()

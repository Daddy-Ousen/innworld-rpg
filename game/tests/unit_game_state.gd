extends GutTest

const SAVE_PATH := "user://test_save.json"


func after_each() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func test_new_state_has_current_save_version() -> void:
	assert_eq(GameState.new().save_version, GameState.SAVE_VERSION)


func test_save_and_load_round_trip() -> void:
	var gs := GameState.new(99)
	gs.data["note"] = "hello"
	gs.rng.randi()
	assert_eq(gs.save_to_file(SAVE_PATH), OK)

	var loaded := GameState.load_from_file(SAVE_PATH)
	assert_not_null(loaded)
	assert_eq(loaded.to_dict(), gs.to_dict())
	assert_eq(loaded.rng.randi(), gs.rng.randi())


func test_newer_save_version_is_rejected() -> void:
	var d := GameState.new().to_dict()
	d["save_version"] = GameState.SAVE_VERSION + 1
	assert_null(GameState.from_json(JSON.stringify(d)))
	assert_push_error("newer than supported")


func test_invalid_json_is_rejected() -> void:
	assert_null(GameState.from_json("not json"))
	assert_push_error("not a JSON object")

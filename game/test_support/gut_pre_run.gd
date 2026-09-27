## GUT pre-run hook (.gutconfig.json): test runs save to their own folder,
## so autosaves from scene tests never touch the player's saves, and volume
## changes go to a test settings file (M12.1).
extends GutHookScript

const TEST_SAVE_DIR := "user://test_saves"
const TEST_SETTINGS := "user://test_settings.cfg"


func run() -> void:
	var session := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Session")
	if session != null:
		session.save_dir = TEST_SAVE_DIR
	var audio := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Audio")
	if audio != null:
		DirAccess.remove_absolute(TEST_SETTINGS)
		audio.settings_path = TEST_SETTINGS
		audio.load_settings()

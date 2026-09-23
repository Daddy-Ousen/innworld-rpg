## GUT pre-run hook (.gutconfig.json): test runs save to their own folder,
## so autosaves from scene tests never touch the player's saves.
extends GutHookScript

const TEST_SAVE_DIR := "user://test_saves"


func run() -> void:
	var session := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Session")
	if session != null:
		session.save_dir = TEST_SAVE_DIR

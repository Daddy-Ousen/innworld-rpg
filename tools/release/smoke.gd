extends SceneTree

## Release smoke test (tools/release.ps1). Run against a packed build:
##   godot --headless --main-pack <exported exe> -s tools/release/smoke.gd
## Loads all data from the pack, plays 5 nights, and prints one SMOKE line.
## Exit code 0 = good.


func _initialize() -> void:
	var db := DataDb.load_dir()
	var problems: Array[String] = []
	problems.append_array(db.errors)
	problems.append_array(db.canon.errors)
	if db.canon.events.is_empty():
		problems.append("no canon events (is *.json in the export filter?)")
	if db.maps.areas.is_empty():
		problems.append("no maps")
	if load("res://assets/characters/zombie.png") == null:
		problems.append("no textures")
	if ResourceLoader.exists("res://tests/unit_play_loop.gd"):
		problems.append("tests are in the pack")
	var gs := GameState.new_game(42, db)
	for i in 5:
		Commands.sleep(gs, db, Rest.ANYWHERE)
	if gs.world.history.is_empty():
		problems.append("no canon event ran in 5 nights")
	for p in problems.slice(0, 10):
		print("SMOKE problem: ", p)
	print("SMOKE version=%s events=%d maps=%d problems=%d" % [
		ProjectSettings.get_setting("application/config/version"),
		db.canon.events.size(), db.maps.areas.size(), problems.size()])
	quit(0 if problems.is_empty() else 1)

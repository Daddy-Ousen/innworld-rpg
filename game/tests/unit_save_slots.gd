extends GutTest
## M6.1 save slots (ADR 0011): three manual slots and an autosave on disk.

const DIR := "user://test_saves_unit"

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()


func before_each() -> void:
	for slot: String in SaveSlots.all():
		SaveSlots.delete(DIR, slot)


func after_all() -> void:
	for slot: String in SaveSlots.all():
		SaveSlots.delete(DIR, slot)


func test_slots_are_three_manual_and_the_autosave() -> void:
	assert_eq(SaveSlots.all(), ["1", "2", "3", "autosave"] as Array[String])
	assert_eq(SaveSlots.path(DIR, "2"), DIR + "/slot_2.json")
	assert_eq(SaveSlots.path(DIR, SaveSlots.AUTOSAVE), DIR + "/autosave.json")


func test_save_and_load_play_on_the_same() -> void:
	var gs := GameState.new_game(7, _db)
	Commands.move(gs, _db, "w")
	assert_eq(SaveSlots.save(gs, DIR, "2"), OK)
	assert_true(SaveSlots.exists(DIR, "2"))
	var loaded := SaveSlots.load_game(DIR, "2", _db)
	assert_not_null(loaded)
	assert_eq(loaded.to_json(), gs.to_json())
	for g: GameState in [gs, loaded]:
		Commands.wait(g, _db, 3600)
		Commands.move(g, _db, "w")
	assert_eq(loaded.to_json(), gs.to_json(), "the loaded game plays on the same")


func test_empty_slot_loads_nothing() -> void:
	assert_null(SaveSlots.load_game(DIR, "3", _db))
	var i := SaveSlots.info(DIR, "3", _db)
	assert_false(i["exists"])
	assert_eq(SaveSlots.label(i), "Slot 3 — empty")


func test_info_and_label() -> void:
	var gs := GameState.new_game(1, _db)
	gs.clock.advance(135)
	SaveSlots.save(gs, DIR, SaveSlots.AUTOSAVE)
	var i := SaveSlots.info(DIR, SaveSlots.AUTOSAVE, _db)
	assert_true(i["ok"])
	assert_eq(i["day"], 8)
	assert_eq(i["time"], "08:15")
	assert_eq(SaveSlots.label(i), "Autosave — Day 8, 08:15, %s" % _db.maps.areas["liscor_gate"]["name"])


func test_broken_file_cannot_be_read() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	var f := FileAccess.open(SaveSlots.path(DIR, "1"), FileAccess.WRITE)
	f.store_string("not json")
	f.close()
	var i := SaveSlots.info(DIR, "1", _db)
	assert_true(i["exists"])
	assert_false(i["ok"])
	assert_eq(SaveSlots.label(i), "Slot 1 — cannot be read")
	assert_null(SaveSlots.load_game(DIR, "1", _db))
	assert_eq(SaveSlots.latest(DIR, _db), "", "a broken save is not continued")
	for n in 3:  # info, load_game, latest
		assert_push_error("not a JSON object")


func test_latest_is_the_newest_save() -> void:
	assert_eq(SaveSlots.latest(DIR, _db), "")
	var gs := GameState.new_game(1, _db)
	SaveSlots.save(gs, DIR, "3")
	assert_eq(SaveSlots.latest(DIR, _db), "3")
	gs.clock.advance(60)
	SaveSlots.save(gs, DIR, "1")
	# Same file second: the later game time wins.
	assert_eq(SaveSlots.latest(DIR, _db), "1")

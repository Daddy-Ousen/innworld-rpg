extends GutTest
## M12.2 (ADR 0019): which sounds fights, use-menu actions, doors and System
## pages make (SoundCues), and that the real data covers the game's content.

var _audio: AudioDb


func before_all() -> void:
	_audio = AudioDb.load_file()


func _toy() -> AudioDb:
	return AudioDb.from_dict({
		"combat": {"hit": "hit", "hurt": "hurt", "fall": "fall", "gone": "gone", "swing": "swing"},
		"enemies": {"goblin": {"hurt": "g_hurt", "gone": "g_gone"}, "crab": {"hurt": "c_hurt"}},
		"actions": {"chop_wood": "chop", "buy": "coins", "sell": "coins", "use": "eat", "door": "door"},
		"pages": {"open": "chime", "progress": "level_up", "confirm": ""},
	})


func test_hits_falls_swings_and_voices() -> void:
	var units := {"g1": {"type": "goblin"}, "c1": {"type": "crab"}}
	var events: Array[Dictionary] = [
		{"type": AnimDiff.HIT, "id": "g1", "amount": 2},
		{"type": AnimDiff.HIT, "id": AnimDiff.PLAYER, "amount": 1},
		{"type": AnimDiff.FALL, "id": "relc"},
		{"type": AnimDiff.GONE, "id": "g2", "cell": Vector2i.ZERO, "monster_type": "goblin"},
		{"type": AnimDiff.GONE, "id": "c2", "cell": Vector2i.ZERO, "monster_type": "crab"},
		{"type": AnimDiff.SWING, "id": AnimDiff.PLAYER, "dir": "e"},
	]
	assert_eq(SoundCues.from_events(_toy(), events, units),
			["hit", "g_hurt", "hurt", "fall", "g_gone", "gone", "swing"] as Array[String])


func test_a_big_battle_caps_each_cue() -> void:
	var events: Array[Dictionary] = []
	for i in 6:
		events.append({"type": AnimDiff.SWING, "id": "m%d" % i, "dir": "n"})
		events.append({"type": AnimDiff.HIT, "id": "x%d" % i, "amount": 1})
	var cues := SoundCues.from_events(_toy(), events)
	assert_eq(cues.count("swing"), SoundCues.MAX_SAME)
	assert_eq(cues.count("hit"), SoundCues.MAX_SAME)


func test_action_cues_and_use_menu_prefixes() -> void:
	var a := _toy()
	assert_eq(SoundCues.action_cue(a, "chop_wood"), "chop")
	assert_eq(SoundCues.action_cue(a, Interact.BUY + "bread"), "coins")
	assert_eq(SoundCues.action_cue(a, Interact.SELL + "herbs"), "coins")
	assert_eq(SoundCues.action_cue(a, Interact.USE_GOOD + "stew"), "eat")
	assert_eq(SoundCues.action_cue(a, "talk_with_guest"), "", "quiet")


func test_a_door_sounds_only_between_indoors_and_outdoors() -> void:
	var a := _toy()
	assert_eq(SoundCues.door_cue(a, false, true), "door")
	assert_eq(SoundCues.door_cue(a, true, false), "door")
	assert_eq(SoundCues.door_cue(a, false, false), "", "a road to the next map")


func test_page_cues_fall_back_to_open_and_can_be_silent() -> void:
	var a := _toy()
	assert_eq(SoundCues.page_cue(a, "progress"), "level_up")
	assert_eq(SoundCues.page_cue(a, "rumors"), "chime", "not listed: open")
	assert_eq(SoundCues.page_cue(a, "confirm"), "", "listed empty: silent")


func test_every_enemy_type_has_a_voice_entry() -> void:
	var db := DataDb.load_dir()
	for type: String in db.combat.enemies:
		assert_true(_audio.has_key("enemies", type), type)
	for type: String in _audio.data["enemies"]:
		assert_true(db.combat.enemies.has(type), "%s is a real enemy" % type)


func test_action_keys_are_real_actions_or_use_menu_ids() -> void:
	var db := DataDb.load_dir()
	var menu := [Interact.SLEEP, Interact.TAKE, Interact.RIDE, Interact.PORTAL, SoundCues.DOOR,
		Interact.BUY.trim_suffix(":"), Interact.SELL.trim_suffix(":"), Interact.USE_GOOD.trim_suffix(":")]
	for key: String in _audio.data["actions"]:
		assert_true(db.actions.has(key) or menu.has(key), key)
	for key in menu:
		assert_true(_audio.has_key("actions", key), "use-menu id %s has a sound" % key)


func test_page_keys_are_real_page_kinds() -> void:
	var kinds := [SystemMessages.COLLAPSE, SystemMessages.KNOCKOUT, SystemMessages.PROGRESS,
		SystemMessages.NEWS, SystemMessages.RUMORS, SystemMessages.DRIFT, SystemMessages.OFFER,
		SystemMessages.CONFIRM, SystemMessages.RESULT, SystemMessages.MORNING, SystemMessages.WELCOME]
	for key: String in _audio.data["pages"]:
		assert_true(kinds.has(key) or key == SoundCues.OPEN_PAGE, key)
	for kind: String in kinds:
		assert_true(_audio.has_key("pages", kind), "page %s is listed" % kind)


func test_the_system_dialog_sounds_each_page() -> void:
	var d: SystemDialog = add_child_autofree(load("res://ui/system_dialog.tscn").instantiate())
	var before := int(Audio.plays.get("level_up", 0))
	var pages: Array[Dictionary] = [SystemMessages.page(SystemMessages.PROGRESS, "Levels", ["x"]),
		SystemMessages.page(SystemMessages.MORNING, "Morning", ["y"])]
	var db := DataDb.load_dir()
	d.open(pages, GameState.new_game(1, db), db)
	assert_eq(int(Audio.plays.get("level_up", 0)), before + 1)

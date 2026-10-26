extends GutTest
## M30.5 (ADR 0044): who the player is. Name, look preset and Earth background
## (PlayerIdentity, data/backgrounds.json), save v23 and the v22 migration, the
## "Who are you?" step (CreatePlayer) and the player's sprite.

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()


func test_clean_name() -> void:
	assert_eq(PlayerIdentity.clean_name("  Mara  "), "Mara")
	assert_eq(PlayerIdentity.clean_name(""), PlayerIdentity.DEFAULT_NAME)
	assert_eq(PlayerIdentity.clean_name("   "), PlayerIdentity.DEFAULT_NAME)
	assert_eq(PlayerIdentity.clean_name("A".repeat(40)).length(), PlayerIdentity.MAX_NAME)


func test_real_data() -> void:
	assert_eq(PlayerIdentity.validate(_db), [] as Array[String])
	assert_eq(PlayerIdentity.looks(_db).size(), 6)
	assert_eq(PlayerIdentity.looks(_db)[0], PlayerIdentity.DEFAULT_LOOK, "the old look is the first preset")
	for look: String in PlayerIdentity.looks(_db):
		assert_true(CharacterSprite.has_sheet(look), "%s has a sheet" % look)
	assert_eq(PlayerIdentity.backgrounds(_db).keys(),
			["student", "cook", "nurse", "athlete", "office", "gamer"])


func test_new_game_with_a_background() -> void:
	var plain := GameState.new_game(5, _db)
	var gs := GameState.new_game(5, _db, "", {"name": "Mara", "look": "player_4", "background": "cook"})
	assert_eq(gs.player.name, "Mara")
	assert_eq(gs.player.look, "player_4")
	assert_eq(gs.player.background, "cook")
	assert_true(gs.flags.get("background.cook", false))
	var want := 0.25 * float(_db.classes["cook"]["offer_threshold"])
	assert_almost_eq(float(gs.progression.pools.get("cook", 0.0)), want, 0.001, "cook pool starts 25% full")
	assert_lt(ClassSystem.readiness(gs, _db, "cook"), 1.0, "a head start, not an offer")
	assert_eq(gs.rng.to_dict(), plain.rng.to_dict(), "who you are draws no gs.rng")
	assert_eq(plain.player.name, PlayerIdentity.DEFAULT_NAME)
	assert_eq(plain.player.look, PlayerIdentity.DEFAULT_LOOK)
	assert_eq(plain.player.background, "")
	assert_false(plain.progression.pools.has("cook") and float(plain.progression.pools["cook"]) >= want)


func test_unknown_picks_fall_back() -> void:
	var gs := GameState.new_game(5, _db, "", {"name": " ", "look": "dragon", "background": "wizard"})
	assert_eq(gs.player.name, PlayerIdentity.DEFAULT_NAME)
	assert_eq(gs.player.look, PlayerIdentity.DEFAULT_LOOK)
	assert_eq(gs.player.background, "")
	assert_false(gs.flags.keys().any(func(f: String) -> bool: return f.begins_with(PlayerIdentity.FLAG)))


func test_toy_db_has_no_creation() -> void:
	var d := ToyData.db()
	assert_eq(PlayerIdentity.validate(d), [] as Array[String])
	var gs := GameState.new(1)
	PlayerIdentity.apply(gs, d, {"name": "Kim", "look": "player_2", "background": "cook"})
	assert_eq(gs.player.name, "Kim")
	assert_eq(gs.player.look, PlayerIdentity.DEFAULT_LOOK)
	assert_eq(gs.player.background, "")


func test_validate_catches_bad_data() -> void:
	var d := DataDb.load_dir()
	d.creation = {"confidence": "maybe", "pool_start": 3, "looks": [{"id": "x", "name": ""}],
		"backgrounds": {"b": {"name": "B", "blurb": "", "class": "wizard", "more": 1}}}
	var text := "\n".join(PlayerIdentity.validate(d))
	for bit in ["pool_start", "confidence", "id and a name", "keep 'player'", "blurb must be",
			"unknown class 'wizard'", "unknown field 'more'"]:
		assert_true(text.contains(bit), "%s in %s" % [bit, text])


func test_save_v23_keeps_who_you_are() -> void:
	assert_true(GameState.SAVE_VERSION >= 23)
	var gs := GameState.new_game(5, _db, "", {"name": "Mara", "look": "player_2", "background": "gamer"})
	var loaded := GameState.from_json(gs.to_json())
	assert_eq(loaded.player.name, "Mara")
	assert_eq(loaded.player.look, "player_2")
	assert_eq(loaded.player.background, "gamer")


func test_v22_save_migrates() -> void:
	var d := GameState.new_game(5, _db).to_dict()
	d["save_version"] = 22
	for k in ["name", "look", "background"]:
		(d["player"] as Dictionary).erase(k)
	var gs := GameState.from_json(JSON.stringify(d))
	assert_not_null(gs)
	assert_eq(gs.save_version, GameState.SAVE_VERSION)
	assert_eq(gs.player.name, PlayerIdentity.DEFAULT_NAME)
	assert_eq(gs.player.look, PlayerIdentity.DEFAULT_LOOK)
	assert_eq(gs.player.background, "")


func test_line_and_sheet() -> void:
	var gs := GameState.new_game(5, _db, "", {"name": "Mara", "background": "nurse"})
	assert_eq(PlayerIdentity.line(gs, _db), "Mara, an Earther, once a nurse.")
	assert_eq(CharacterSheet.lines(gs, _db)[0], "Mara, an Earther, once a nurse.")
	var plain := GameState.new_game(5, _db)
	assert_eq(PlayerIdentity.line(plain, _db), "An Earther.")
	var w := SystemMessages.welcome_page({}, PlayerIdentity.who(gs, _db))
	assert_true(String(w["lines"][0]).begins_with("You are Mara, an Earther, once a nurse. The Great"), str(w["lines"][0]))
	assert_eq(SystemMessages.welcome_page({}, PlayerIdentity.who(plain, _db))["lines"][0],
			SystemMessages.welcome_page()["lines"][0], "the default reads as before")


func test_erin_names_your_background() -> void:
	var gs := GameState.new_game(5, _db, "", {"background": "cook"})
	var lines := Voice.lines_now(gs, _db, "erin_solstice")
	assert_false(lines.any(func(t: String) -> bool: return t.contains("cooked for a living")), "she does not know yet")
	gs.flags["erin.knows_player_is_earther"] = true
	lines = Voice.lines_now(gs, _db, "erin_solstice")
	assert_true(lines.any(func(t: String) -> bool: return t.contains("cooked for a living")))
	assert_false(lines.any(func(t: String) -> bool: return t.contains("A nurse!")), "only her own background")


func test_create_panel_picks() -> void:
	var c: CreatePlayer = add_child_autofree(CreatePlayer.new())
	c.setup(_db)
	assert_eq(c.identity(), {"name": PlayerIdentity.DEFAULT_NAME, "look": "player", "background": ""})
	c.name_edit.text = "Mara"
	(c.find_child("Next", true, false) as Button).pressed.emit()
	(c.find_child("Bg_nurse", true, false) as Button).pressed.emit()
	assert_eq(c.identity(), {"name": "Mara", "look": "player_2", "background": "nurse"})
	assert_true((c.find_child("Bg_nurse", true, false) as Button).button_pressed)
	(c.find_child("Bg_nurse", true, false) as Button).pressed.emit()
	assert_eq(c.background, "", "the same pick again picks none")
	c.show_look(-1)
	assert_eq(c.identity()["look"], "player_6", "wraps around")
	watch_signals(c)
	c.begin.pressed.emit()
	assert_signal_emitted(c, "begun")


func test_view_shows_the_chosen_look() -> void:
	var gs := GameState.new_game(5, _db, "", {"look": "player_3"})
	var v: WorldView = add_child_autofree(load("res://world/world_view.tscn").instantiate())
	v.setup(_db.maps)
	assert_eq(v.look_id, PlayerIdentity.DEFAULT_LOOK)
	v.refresh(gs, _db)
	assert_eq(v.look_id, "player_3")
	assert_not_null(v.look)

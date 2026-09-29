extends GutTest
## M14.7 (ADR 0021): faces cut from the character sheets, shown in the use menu
## and on System pages.

const SEED := 20260929

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])


func _game() -> GameState:
	return GameState.new_game(SEED, _db, "celum")


func _npc_option(id: String) -> Dictionary:
	return {"id": id, "name": id, "npc": true, "actions": [], "sleep": false, "item": "",
		"price": 0, "trades": [] as Array[Dictionary], "ride": {}, "attack": true}


func _bed_option() -> Dictionary:
	return {"id": "bed", "name": "Bed", "npc": false, "actions": [], "sleep": true, "item": "",
		"price": 0, "trades": [] as Array[Dictionary], "ride": {}}


func test_the_head_is_cut_from_the_front_standing_frame() -> void:
	var frame := CharacterSprite.region_of("walk", "s", 0)
	var r := Portrait.rect()
	assert_eq(r.size, Portrait.HEAD.size)
	assert_true(Rect2(frame).encloses(r), "the crop stays inside the 64 px frame")
	assert_eq(r.position, frame.position + Portrait.HEAD.position)


func test_a_sheet_gives_an_atlas_texture() -> void:
	var t := Portrait.texture("erin_solstice")
	assert_not_null(t)
	assert_eq(t.region, Portrait.rect())
	assert_eq(t.atlas.resource_path, CharacterSprite.path_for("erin_solstice"))


func test_no_sheet_gives_no_face() -> void:
	assert_null(Portrait.texture(""))
	assert_null(Portrait.texture("no_such_look"))
	assert_eq(Portrait.look_of_npc(_db, "no_such_npc"), "")
	assert_null(Portrait.texture_of_npc(_db, "no_such_npc"))


func test_an_npc_uses_their_own_sheet_first() -> void:
	assert_eq(Portrait.look_of_npc(_db, "erin_solstice"), "erin_solstice")
	assert_not_null(Portrait.texture_of_npc(_db, "erin_solstice"))


func test_every_canon_npc_on_the_map_has_a_face() -> void:
	var gs := _game()
	var missing: Array[String] = []
	for id: String in gs.npcs.npcs:
		if Portrait.texture_of_npc(_db, id) == null:
			missing.append(id)
	assert_eq(missing, [] as Array[String], "NPCs on a map need a look (unit_art)")


func test_show_in_shows_and_hides() -> void:
	var v := TextureRect.new()
	add_child_autofree(v)
	assert_true(Portrait.show_in(v, "erin_solstice"))
	assert_true(v.visible)
	assert_not_null(v.texture)
	assert_false(Portrait.show_in(v, ""))
	assert_false(v.visible)
	assert_null(v.texture)


func test_a_page_names_the_npc_whose_face_it_shows() -> void:
	assert_eq(SystemMessages.portrait_npc(SystemMessages.fate_page(_db, "erin_solstice")), "erin_solstice")
	var news := SystemMessages.page(SystemMessages.NEWS, "Local News", ["Someone died."])
	assert_eq(SystemMessages.portrait_npc(news), "", "news with no deaths has no face")
	news["deaths"] = ["relc", "klbkch"]
	assert_eq(SystemMessages.portrait_npc(news), "relc", "the first death")
	assert_eq(SystemMessages.portrait_npc(SystemMessages.page(SystemMessages.MORNING, "Morning", ["x"])), "")


func test_the_dialog_shows_the_face_of_a_fate_page_only() -> void:
	var gs := _game()
	var d: SystemDialog = add_child_autofree(load("res://ui/system_dialog.tscn").instantiate())
	var face: TextureRect = d.get_node("%Face")
	d.open([SystemMessages.fate_page(_db, "erin_solstice"),
			SystemMessages.page(SystemMessages.MORNING, "Morning", ["You wake."])] as Array[Dictionary], gs, _db)
	assert_true(face.visible, "the fate warning shows Erin")
	assert_eq((face.texture as AtlasTexture).atlas.resource_path, CharacterSprite.path_for("erin_solstice"))
	d.choose(SystemMessages.SPARE)
	d.open([SystemMessages.page(SystemMessages.MORNING, "Morning", ["You wake."])] as Array[Dictionary], gs, _db)
	assert_false(face.visible, "a page with no NPC hides the face")


func test_the_dialog_shows_a_death_on_the_news_page() -> void:
	var gs := _game()
	var d: SystemDialog = add_child_autofree(load("res://ui/system_dialog.tscn").instantiate())
	var news := SystemMessages.page(SystemMessages.NEWS, "Local News", ["Erin is gone."])
	news["deaths"] = ["erin_solstice"]
	d.open([news] as Array[Dictionary], gs, _db)
	assert_true((d.get_node("%Face") as TextureRect).visible)


func test_the_use_menu_shows_the_face_of_the_selected_npc() -> void:
	var menu: InteractMenu = add_child_autofree(load("res://ui/interact_menu.tscn").instantiate())
	var face: TextureRect = menu.get_node("%Face")
	var items: ItemList = menu.get_node("%Items")
	assert_true(menu.open([_bed_option(), _npc_option("erin_solstice")] as Array[Dictionary], _db))
	assert_false(face.visible, "row 0 is a bed: no face")
	items.select(1)
	items.item_selected.emit(1)
	assert_true(face.visible, "the NPC's Attack row shows Erin")
	items.select(0)
	items.item_selected.emit(0)
	assert_false(face.visible)
	assert_true(menu.open([_npc_option("erin_solstice")] as Array[Dictionary], _db))
	assert_true(face.visible, "an NPC first in the list shows at once")
	menu.open_bag(_game(), _db)
	assert_false(face.visible, "the bag has no face")


func test_a_patron_shows_their_race_look() -> void:
	var gs := _game()
	gs.inn.guests.append({"id": "p1", "area": "inn_interior", "race": "gnoll", "look": "race_gnoll",
		"seat": [3, 3], "order": "", "arrive": 0})
	var o := {"id": Guests.GUEST + "p1", "npc": false, "guest": true}
	assert_eq(InteractMenu.look_of(o, _db, gs), "race_gnoll")
	assert_eq(InteractMenu.look_of({"id": Guests.GUEST + "p9", "guest": true}, _db, gs), "", "no such patron")
	assert_eq(InteractMenu.look_of({"id": "bed", "npc": false}, _db, gs), "")

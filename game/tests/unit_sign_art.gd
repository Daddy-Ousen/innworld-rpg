extends GutTest
## M16.3 (ADR 0023): door and shop signs. `SignArt.marks` decides what each exit and signed
## object shows; `WorldView` draws it (a hanging sign, a way-out arrow, a label that shows
## when the player is near).


func _maps() -> MapDb:
	var m := ToyMaps.area("m", "toy_town", [
		"wwwwww",
		"wggggg",
		"wggggg",
		"wggggg",
		"wwgwww",
	], {}, [
		{"at": [5, 2], "to": "n", "arrive": [1, 1], "minutes": 0},
		{"at": [2, 4], "to": "n", "arrive": [1, 1], "minutes": 0, "sign": {"icon": "bread"}},
		{"at": [1, 1, 2, 1], "to": "o", "arrive": [1, 1], "minutes": 0},
		{"at": [4, 1], "to": "p", "arrive": [1, 1], "minutes": 0},
	], [
		{"id": "stair", "kind": "stairs", "at": [4, 1], "name": "Stairs", "actions": []},
		{"id": "shop", "kind": "market_stall", "at": [3, 3], "name": "Fish stall", "actions": [],
			"sign": {"icon": "coin"}},
		{"id": "home", "kind": "plaque", "at": [0, 1], "name": "A private home", "actions": [],
			"sign": {"icon": "home"}},
		{"id": "bare", "kind": "well", "at": [5, 3], "name": "Well", "actions": []},
	])
	var areas := {"m": m}
	for id: String in ["n", "o", "p"]:
		areas[id] = ToyMaps.area(id, "toy_town", ["ggg", "ggg"], {}, [], [])
	return MapDb.from_dicts(ToyMaps.tiles(), areas)


func _at(marks: Array, cell: Vector2i, source: String) -> Array:
	return marks.filter(func(m: Dictionary) -> bool: return m["cell"] == cell and m["source"] == source)


func test_marks_follow_exits_and_signed_objects() -> void:
	var marks := SignArt.marks(_maps(), "m")
	var edge := _at(marks, Vector2i(5, 2), "exit")
	assert_eq(edge.size(), 1)
	assert_eq(edge[0]["kind"], "arrow")
	assert_eq(edge[0]["dir"], Vector2i.RIGHT, "out through the east edge")
	assert_eq(edge[0]["text"], "To N")
	var door := _at(marks, Vector2i(2, 4), "exit")
	assert_eq(door.size(), 1)
	assert_eq(door[0]["kind"], "sign")
	assert_eq(door[0]["icon"], "bread")
	assert_eq(door[0]["text"], "N", "a signed exit shows the bare name")
	assert_eq(door[0]["place"], "right", "hung on the wall beside the door")
	var wide := marks.filter(func(m: Dictionary) -> bool: return m["kind"] == "arrow" and m["cell"].y == 1 and m["cell"].x < 3)
	assert_eq(wide.size(), 2, "one arrow per cell of a two-wide exit")
	assert_eq(wide[0]["dir"], Vector2i.UP)
	assert_eq(wide[0]["text"], "To O")
	assert_eq(wide[1]["text"], "", "only the first cell holds the label")
	var under := _at(marks, Vector2i(4, 1), "exit")
	assert_eq(under[0]["kind"], "label", "stairs draw their own art: text only")


func test_signed_objects_and_plaques() -> void:
	var marks := SignArt.marks(_maps(), "m")
	var shop := _at(marks, Vector2i(3, 3), "object")
	assert_eq(shop.size(), 1)
	assert_eq(shop[0]["text"], "Fish stall", "the object's name is the default label")
	assert_eq(shop[0]["place"], "above")
	var home := _at(marks, Vector2i(0, 1), "object")
	assert_eq(home[0]["place"], "here", "a plaque is the whole object")
	assert_eq(home[0]["text"], "A private home")
	assert_eq(_at(marks, Vector2i(5, 3), "object").size(), 0, "no sign, no mark")


func test_label_alpha_fades_with_distance() -> void:
	assert_eq(SignArt.label_alpha(0), 1.0)
	assert_eq(SignArt.label_alpha(SignArt.FULL), 1.0)
	assert_eq(SignArt.label_alpha(3), 0.5)
	assert_eq(SignArt.label_alpha(SignArt.GONE), 0.0)
	assert_eq(SignArt.label_alpha(30), 0.0)
	assert_eq(SignArt.king_dist(Vector2i(1, 1), Vector2i(4, 2)), 3)


func test_edge_dir_picks_the_nearest_edge() -> void:
	var size := Vector2i(10, 8)
	assert_eq(SignArt.edge_dir(size, Vector2i(9, 4)), Vector2i.RIGHT)
	assert_eq(SignArt.edge_dir(size, Vector2i(0, 3)), Vector2i.LEFT)
	assert_eq(SignArt.edge_dir(size, Vector2i(4, 0)), Vector2i.UP)
	assert_eq(SignArt.edge_dir(size, Vector2i(4, 7)), Vector2i.DOWN)
	assert_eq(SignArt.edge_dir(size, Vector2i(2, 2)), Vector2i.UP, "up 2, left 2: up wins the tie")
	assert_eq(SignArt.edge_dir(Vector2i(6, 6), Vector2i(3, 3)), Vector2i.DOWN, "a tie goes down")


func test_the_view_draws_signs_and_fades_labels_by_distance() -> void:
	var v: WorldView = add_child_autofree(load("res://world/world_view.tscn").instantiate())
	v.setup(_maps())
	var gs := GameState.new(1)
	gs.player.place("m", Vector2i(3, 1))
	v.refresh(gs)
	var kinds := {}
	for c in v.marks.get_children():
		if c.has_meta("mark"):
			kinds[c.get_meta("mark")] = int(kinds.get(c.get_meta("mark"), 0)) + 1
	assert_eq(kinds.get("arrow", 0), 3, "east edge and the two-wide exit")
	assert_eq(kinds.get("sign", 0), 3, "the signed door, the stall and the plaque")
	assert_eq(kinds.get("label", 0), 1)
	var colors := v.marks.get_children().filter(func(c: Node) -> bool:
		return c is ColorRect and (c as ColorRect).color == Color(1.0, 1.0, 0.7, 0.3))
	assert_eq(colors.size(), 0, "no yellow exit tint")
	assert_eq(v.props.get_children().filter(func(c: Node) -> bool: return c is Sprite2D and (c as Sprite2D).region_rect.size == Vector2(24, 28)).size(),
			4, "a sign sprite each, and the plaque's empty art cell")
	var alpha := _alphas(v)
	assert_eq(alpha["N"], 0.5, "the door sign is 3 cells away")
	assert_eq(alpha["Fish stall"], 1.0)
	gs.player.place("m", Vector2i(2, 3))
	v.refresh(gs)
	alpha = _alphas(v)
	assert_eq(alpha["N"], 1.0, "next to the door")
	assert_eq(alpha["To N"], 0.5, "the east arrow is 3 cells away")


func _alphas(v: WorldView) -> Dictionary:
	var out := {}
	for c in v.marks.get_children():
		for l in c.get_children():
			if l is Label:
				out[(l as Label).text] = snappedf((l as Label).modulate.a, 0.01)
	return out


func test_every_real_sign_has_art_and_the_real_marks_have_text() -> void:
	var maps := MapDb.load_dir()
	var table := SignArt.load_table()
	assert_gt(table.size(), 5)
	var sheet := (load(WorldView.sheet_path("signs")) as Texture2D).get_size()
	for icon: String in table:
		var r := SignArt.icon_region(table, icon)
		assert_gt(r.size.x, 0.0, "icon %s has a region" % icon)
		assert_true(r.end.x <= sheet.x and r.end.y <= sheet.y, "icon %s inside the sheet" % icon)
	var signed := 0
	for id: String in maps.areas:
		var a: Dictionary = maps.areas[id]
		var defs: Array = []
		for e: Dictionary in a["exits"]:
			defs.append(["exit", e])
		for o: Dictionary in a["objects"]:
			defs.append(["object", o])
			if o["kind"] == SignArt.PLAQUE:
				assert_true(o.has("sign"), "%s/%s: a plaque needs a sign" % [id, o["id"]])
		for pair: Array in defs:
			var s: Variant = (pair[1] as Dictionary).get("sign")
			if s == null:
				continue
			signed += 1
			assert_true(s is Dictionary and String((s as Dictionary).get("icon", "")) != "", "%s: sign needs an icon" % id)
			assert_true(table.has((s as Dictionary)["icon"]), "%s: unknown icon %s" % [id, s])
			assert_true(not (s as Dictionary).has("text") or (s as Dictionary)["text"] is String, "%s: sign text is a string" % id)
		for m: Dictionary in SignArt.marks(maps, id):
			if m["kind"] == "sign":
				assert_ne(m["text"], "", "%s: a sign has a label" % id)
	assert_gt(signed, 10, "the maps carry signs")


func test_every_enterable_house_door_has_a_sign() -> void:
	var maps := MapDb.load_dir()
	for id: String in ["celum_square", "inn_hill"]:
		for e: Dictionary in maps.areas[id]["exits"]:
			var r := MapDb.rect_of(e["at"])
			var edge := r.position.x == 0 or r.position.y == 0 or r.end.x == maps.size(id).x or r.end.y == maps.size(id).y
			assert_true(edge or e.has("sign"), "%s exit %s (a door) needs a sign" % [id, e["to"]])

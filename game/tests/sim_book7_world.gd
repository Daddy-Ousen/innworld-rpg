extends GutTest
## M19.1 (ADR 0030) on the real data: the Book 7 world. The Albez door with
## three links (Celum, Pallass, Liscor's west wall); the Pallass alley map;
## the flood on the Floodplains maps; the Grand Theatre; the smashed
## watchtower; the Face-Eater Moth and the moth swarm; the Book 7 records.

const SEED := 20261007
const FLOOD := "izril.flood"
const PALLASS := "albez_door.anchor_at_pallass"
const LISCOR := "albez_door.anchor_at_liscor_wall"
const FLOODED := ["floodplains_south", "liscor_gate", "inn_hill", "dungeon_rift"]

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])


func _at(area: String, pos: Vector2i, flags: Array = []) -> GameState:
	var gs := GameState.new_game(SEED, _db)
	for f: String in flags:
		gs.flags[f] = true
	gs.player.place(area, pos)
	Commands.settle(gs, _db)
	return gs


func _links(gs: GameState) -> Array:
	var door: Dictionary = {}
	for o: Dictionary in _db.maps.objects_on("inn_interior"):
		if o["id"] == "albez_door":
			door = o
	return Portal.open_links(gs, door["portal"]).map(func(l: Dictionary) -> String: return l["id"])


func test_the_inn_door_has_three_links_by_flag() -> void:
	var base := ["albez_door.at_wandering_inn", "erin.magical_grounds"]
	assert_eq(_links(_at("inn_interior", Vector2i(3, 12), base)), ["celum"])
	assert_eq(_links(_at("inn_interior", Vector2i(3, 12), base + [PALLASS])), ["celum", "pallass"])
	assert_eq(_links(_at("inn_interior", Vector2i(3, 12), base + [PALLASS, LISCOR])), ["celum", "pallass", "liscor"])


func test_the_door_leads_to_pallass_and_back() -> void:
	var gs := _at("inn_interior", Vector2i(3, 12),
			["albez_door.at_wandering_inn", "erin.magical_grounds", PALLASS])
	assert_eq(Commands.portal(gs, _db, "albez_door", "pallass"), "")
	assert_eq(gs.player.area, "pallass_door_street")
	assert_eq(gs.player.pos(), Vector2i(5, 2))
	Commands.settle(gs, _db)
	assert_true(_db.maps.objects_on("pallass_door_street").any(
			func(o: Dictionary) -> bool: return o["id"] == "albez_door_pallass"), "the Pallass end shows")
	assert_eq(Commands.portal(gs, _db, "albez_door_pallass"), "")
	assert_eq(gs.player.area, "inn_interior")
	assert_eq(gs.player.pos(), Vector2i(3, 12))


func test_the_pallass_end_is_hidden_until_its_anchor_is_there() -> void:
	_at("pallass_door_street", Vector2i(5, 2))
	assert_false(_db.maps.objects_on("pallass_door_street").any(
			func(o: Dictionary) -> bool: return o["id"] == "albez_door_pallass"))


func test_the_door_leads_to_liscors_west_wall() -> void:
	var gs := _at("inn_interior", Vector2i(3, 12),
			["albez_door.at_wandering_inn", "erin.magical_grounds", LISCOR])
	assert_eq(Commands.portal(gs, _db, "albez_door", "liscor"), "")
	assert_eq(gs.player.area, "liscor_watch")
	assert_eq(gs.player.pos(), Vector2i(5, 12))
	Commands.settle(gs, _db)
	assert_eq(Commands.portal(gs, _db, "albez_door_liscor"), "")
	assert_eq(gs.player.area, "inn_interior")
	# the wall end is on the street next to the city wall
	assert_eq(_db.maps.tile_at("liscor_watch", Vector2i(3, 12)), "city_wall")


func test_the_flood_covers_the_floodplains_but_not_the_inn_hill() -> void:
	var dry := _at("inn_hill", Vector2i(16, 12))
	assert_true(_db.maps.is_walkable("inn_hill", Vector2i(16, 18)), "dry ground before the flood")
	var wet := _at("inn_hill", Vector2i(16, 12), [FLOOD])
	Commands.settle(wet, _db)
	assert_false(_db.maps.is_walkable("inn_hill", Vector2i(16, 18)), "the south of the hill is water")
	assert_false(_db.maps.is_walkable("floodplains_south", Vector2i(10, 5)))
	assert_false(_db.maps.is_walkable("liscor_gate", Vector2i(10, 14)))
	assert_true(_db.maps.is_walkable("inn_hill", Vector2i(16, 12)), "the inn's door yard is dry")
	assert_true(_db.maps.is_walkable("inn_hill", Vector2i(2, 11)), "the way west to Wirclaw is dry")
	Commands.settle(dry, _db)
	assert_true(_db.maps.is_walkable("floodplains_south", Vector2i(10, 5)), "no flood flag: dry again")


func test_no_open_exit_lands_the_player_in_the_flood() -> void:
	var flags := {FLOOD: true}
	_db.maps.sync_flags(flags)
	var bad: Array[String] = []
	for from: String in _db.maps.areas:
		for e: Dictionary in _db.maps.areas[from]["exits"]:
			if not _db.maps.exit_on(from, e):
				continue
			var r := MapDb.rect_of(e["at"])
			for y in range(r.position.y, r.end.y):
				for x in range(r.position.x, r.end.x):
					var here := Vector2i(x, y)
					if not [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT].any(
							func(d: Vector2i) -> bool: return _db.maps.is_walkable(from, here + d) and _db.maps.raw_exit_at(from, here + d).is_empty()):
						continue  # an exit tile cut off by water: nobody can stand there
					var to := MapDb.arrival(e, Vector2i(x, y))
					if not _db.maps.is_walkable(e["to"], to):
						bad.append("%s -> %s %s" % [from, e["to"], to])
	_db.maps.sync_flags({})
	assert_eq(bad, [] as Array[String], "an exit that stays open must not arrive on water")


func test_the_flood_keeps_every_map_reachable_by_the_door() -> void:
	# the inn, Liscor's streets and the Pallass alley are dry in the flood
	_db.maps.sync_flags({FLOOD: true})
	for area: String in ["inn_interior", "liscor_watch", "liscor_plaza", "pallass_door_street"]:
		var any := false
		for y in range(_db.maps.size(area).y):
			for x in range(_db.maps.size(area).x):
				any = any or _db.maps.is_walkable(area, Vector2i(x, y))
		assert_true(any, area)
	_db.maps.sync_flags({})


func test_the_grand_theatre_opens_the_east_wall() -> void:
	assert_false(_db.maps.is_walkable("inn_interior", Vector2i(16, 2)))
	_at("inn_interior", Vector2i(10, 6), ["wandering_inn.grand_theatre"])
	assert_true(_db.maps.is_walkable("inn_interior", Vector2i(16, 2)))
	assert_true(_db.maps.objects_on("inn_interior").any(func(o: Dictionary) -> bool: return o["id"] == "theatre_stage"))
	_db.maps.sync_flags({})


func test_the_smashed_watchtower_closes_the_ladder() -> void:
	var gs := _at("inn_upper_floor", Vector2i(2, 5))
	assert_false(_db.maps.exit_at("inn_upper_floor", Vector2i(1, 5)).is_empty(), "the ladder works before")
	gs = _at("inn_upper_floor", Vector2i(2, 5), ["wandering_inn.watchtower_smashed"])
	assert_true(_db.maps.exit_at("inn_upper_floor", Vector2i(1, 5)).is_empty(), "the ladder is gone")
	assert_true(_db.maps.objects_on("inn_hill").any(func(o: Dictionary) -> bool: return o["id"] == "watchtower_rubble"))
	_db.maps.sync_flags({})


func test_the_moths_fly_and_leap() -> void:
	var moth: Dictionary = _db.combat.enemies["face_eater_moth"]
	assert_true(moth["tags"].has("moth"))
	assert_eq(moth["abilities"][0]["kind"], "leap")
	assert_true(CharacterSprite.has_sheet("face_eater_moth"), "drawn by tools/build_creatures.py")
	var swarm: Dictionary = _db.combat.enemies["moth_swarm"]
	assert_true(swarm["hp"] < moth["hp"], "a swarm group is weaker than a giant moth")
	assert_true(CharacterSprite.has_sheet(String(swarm.get("look", "moth_swarm"))))
	for s: Dictionary in _db.combat.spawns:
		assert_false(["face_eater_moth", "moth_swarm"].has(s["enemy"]), "the 5.07 stage brings the moths, not a spawn")


func test_book_7_records_load() -> void:
	assert_true(_db.canon.locations.has("pallass"), "the map's location exists")
	assert_eq(_db.maps.areas["pallass_door_street"]["location"], "pallass")
	var n7 := 0
	for id: String in _db.canon.npcs:
		if int(_db.canon.npcs[id].get("canon_ref", {}).get("book", 0)) == 7:
			n7 += 1
	assert_true(n7 >= 15, "Book 7 NPC records: %d" % n7)

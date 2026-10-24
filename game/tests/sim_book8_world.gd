extends GutTest
## M28.1 (ADR 0043) on the real data: the Book 8 world. The armoured and the
## awakened Raskghar, the Raskghar camp map with its three doorways, the
## Book 8 records, and Calruz alive. M28.9: Erin's door is the way in and out.

const CAMP := "raskghar_camp"
const NPCS := ["nokha", "pebblesnatch", "elirr", "vakk", "bevussa_slenderscale", "keldrass", "earlia",
	"nailren", "joiah_kellisman", "xess", "cassa", "fess", "rebat", "minerva", "jackal",
	"elia_arcsinger", "aaron_vanwell", "baiss", "teura"]
const PLACES := ["raskghar_camp", "dungeon_city", "cave_goblin_refuge", "lancrel"]

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])


func test_the_raskghar_come_in_three_strengths() -> void:
	var plain: Dictionary = _db.combat.enemies["not_gnoll"]  # the Raskghar of Book 5
	var armoured: Dictionary = _db.combat.enemies["raskghar_armoured"]
	var awake: Dictionary = _db.combat.enemies["awakened_raskghar"]
	assert_gt(int(armoured["hp"]), int(plain["hp"]))
	assert_gt(int(awake["hp"]), int(armoured["hp"]))
	assert_gt(int(armoured["armor"]), int(plain["armor"]))
	assert_gt(int(awake["damage"][1]), int(armoured["damage"][1]))
	for id: String in ["raskghar_armoured", "awakened_raskghar"]:
		assert_eq(int(_db.combat.enemies[id]["canon_ref"]["book"]), 8, id)


func test_the_new_raskghar_have_no_spawn() -> void:
	for s: Dictionary in _db.combat.spawns:
		assert_false(String(s["enemy"]) in ["raskghar_armoured", "awakened_raskghar"], s["id"])


func test_the_camp_map_has_three_doorways_and_no_exits() -> void:
	assert_true(_db.maps.areas.has(CAMP))
	assert_eq(_db.maps.areas[CAMP]["exits"], [])
	var doors := _db.maps.objects_on(CAMP).filter(func(o: Dictionary) -> bool: return o["kind"] == "door")
	assert_eq(doors.size(), 3)
	var seen := {}
	for d: Dictionary in doors:
		seen[d["id"]] = true
		var at := Vector2i(int(d["at"][0]), int(d["at"][1]))
		var near := false
		for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			near = near or _db.maps.is_walkable(CAMP, at + step)
		assert_true(near, "floor next to %s" % d["id"])
	assert_eq(seen.size(), 3, "three different doors")


## M28.9: the way in is a gated link of Erin's magic door, not a map exit; the way home is the north door.
func test_erins_door_is_the_gated_way_in_and_out() -> void:
	var link := {}
	for o: Dictionary in _db.maps.areas["inn_interior"]["objects"]:
		if o["id"] == "albez_door":
			for l: Dictionary in o["portal"]["links"]:
				if l["to"] == CAMP:
					link = l
	assert_false(link.is_empty(), "the inn door has a camp link")
	assert_eq(link.get("when_flags", []), ["raskghar.camp_raid_failed"])
	assert_eq(link.get("unless_flags", []), ["raskghar.broken"])
	assert_true(_db.maps.is_walkable(CAMP, Vector2i(int(link["pos"][0]), int(link["pos"][1]))))
	var home := {}
	for o: Dictionary in _db.maps.objects_on(CAMP):
		if o.has("portal"):
			home = o["portal"]
	assert_eq(home.get("to", ""), "inn_interior", "a door leads home")
	assert_eq(home.get("power_flags", ["x"]), [], "the way home never shuts")
	assert_true(_db.rules["combat"]["knockout"]["wake"].has(CAMP), "a knock-out wake spot")


func test_the_camp_map_is_one_open_hall() -> void:
	var start := Vector2i(16, 10)
	assert_true(_db.maps.is_walkable(CAMP, start))
	var reach := {start: true}
	var todo: Array[Vector2i] = [start]
	while not todo.is_empty():
		var p: Vector2i = todo.pop_back()
		for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var q := p + step
			if not reach.has(q) and _db.maps.is_walkable(CAMP, q):
				reach[q] = true
				todo.append(q)
	var floor_tiles := 0
	var size: Vector2i = _db.maps.size(CAMP)
	for y in size.y:
		for x in size.x:
			if _db.maps.is_walkable(CAMP, Vector2i(x, y)):
				floor_tiles += 1
	assert_eq(reach.size(), floor_tiles, "every floor tile can be reached")


func test_the_book8_records_exist() -> void:
	for id: String in NPCS:
		assert_true(_db.canon.npcs.has(id), id)
		assert_eq(int(_db.canon.npcs[id]["canon_ref"]["book"]), 8, id)
	for id: String in PLACES:
		assert_true(_db.canon.locations.has(id), id)
	assert_eq(_db.canon.npcs["nokha"]["race"], "Raskghar")
	assert_eq(_db.canon.npcs["cassa"]["race"], "Drake")
	# Greydath is Greybeard (4.39 G): one id, the name is a flag.
	assert_false(_db.canon.npcs.has("greydath"))
	assert_eq(_db.canon.events["b8.greydath_duels_garen"]["roles"]["old_goblin"]["prefer"], ["greybeard"])


func test_calruz_is_alive_in_book_8() -> void:
	var c: Dictionary = _db.canon.npcs["calruz"]
	assert_true(c["alive_at_start"])
	assert_string_contains(String(c["canon_ref"]["note"]), "Book 8")
	assert_has(c["tags"], "raskghar")

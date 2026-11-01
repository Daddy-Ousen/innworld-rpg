extends GutTest
## M36.1 (ADR 0047) on the real data: the Book 9 world. The Draug and the two
## door-thief gangs, the Book 9 records and places, the notes on old records,
## and Greydath kept as the one id `greybeard`.

const NPCS := ["eltistiman_verdue", "spiderslicer", "twofeather", "sir_vumat", "gilam", "lord_pellmia",
	"kilmet", "genviere", "erill_fienst", "jericha", "ieka_imarris", "gralton_radivaek", "laskaillia",
	"raekea_silversmith", "fashia_splitfur", "zassil", "rykhai"]
const PLACES := ["celum_meadow", "redfang_road_cave", "liscor_watch_cells"]
const ENEMIES := ["draug", "brothers_thug", "chell_sister"]

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])


func test_the_book9_folder_loads_with_no_loader_change() -> void:
	var c := CanonDb.load_root()
	assert_eq(c.errors, [] as Array[String])
	for id: String in NPCS:
		assert_true(c.npcs.has(id), id)
	for id: String in PLACES:
		assert_true(c.locations.has(id), id)


func test_the_book9_records_exist() -> void:
	for id: String in NPCS:
		var n: Dictionary = _db.canon.npcs[id]
		assert_eq(int(n["canon_ref"]["book"]), 9, id)
		assert_true(n["alive_at_start"], id)
	for id: String in PLACES:
		assert_eq(int(_db.canon.locations[id]["canon_ref"]["book"]), 9, id)
	assert_eq(_db.canon.npcs["laskaillia"]["race"], "Drake")
	assert_eq(_db.canon.npcs["raekea_silversmith"]["race"], "Gnoll")
	assert_eq(_db.canon.npcs["jericha"]["faction"], "house_veltras")
	assert_eq(_db.canon.locations["liscor_watch_cells"]["parent"], "liscor_watch_barracks")
	assert_eq(_db.canon.locations["redfang_road_cave"]["parent"], "high_passes")


## Conflict 8: Lord Erill is a new record, not Princess Erille of Book 6.
func test_lord_erill_is_not_princess_erille() -> void:
	assert_true(_db.canon.npcs.has("erille"))
	assert_ne(_db.canon.npcs["erill_fienst"]["name"], _db.canon.npcs["erille"]["name"])
	assert_eq(int(_db.canon.npcs["erille"]["canon_ref"]["book"]), 6)


## Conflict 7: Greydath is Greybeard (4.39 G, 5.50 G, 5.53). One id, no merge.
func test_greydath_stays_greybeard() -> void:
	assert_false(_db.canon.npcs.has("greydath"))
	assert_string_contains(String(_db.canon.npcs["greybeard"]["canon_ref"]["note"]), "Greydath")


## Conflicts 3 - 6 and the plan notes: Reiss is the Goblin Lord; the living stay alive.
func test_old_records_carry_the_book9_notes() -> void:
	assert_false(_db.canon.npcs.has("reiss"))
	assert_string_contains(String(_db.canon.npcs["goblin_lord"]["canon_ref"]["note"]), "Az'kerash")
	assert_string_contains(String(_db.canon.npcs["garen"]["canon_ref"]["note"]), "Halfseekers")
	assert_string_contains(String(_db.canon.npcs["osthia_blackwing"]["canon_ref"]["note"]), "False Death")
	var calruz := String(_db.canon.npcs["calruz"]["canon_ref"]["note"])
	assert_string_contains(calruz, "Book 8")
	assert_string_contains(calruz, "no verdict")
	for id: String in ["osthia_blackwing", "calruz", "numbtongue", "purple_smile"]:
		if _db.canon.npcs.has(id):
			assert_true(_db.canon.npcs[id]["alive_at_start"], id)


func test_the_new_enemies_are_book9_and_never_spawn() -> void:
	for id: String in ENEMIES:
		assert_true(_db.combat.enemies.has(id), id)
		assert_eq(int(_db.combat.enemies[id]["canon_ref"]["book"]), 9, id)
	for s: Dictionary in _db.combat.spawns:
		assert_false(String(s["enemy"]) in ENEMIES, s["id"])


func test_the_draug_is_a_big_undead_with_its_own_sheet() -> void:
	var draug: Dictionary = _db.combat.enemies["draug"]
	var zombie: Dictionary = _db.combat.enemies["zombie"]
	assert_has(draug["tags"], "undead")
	assert_gt(int(draug["hp"]), int(zombie["hp"]) * 3)
	assert_gt(int(draug["damage"][1]), int(zombie["damage"][1]))
	assert_eq(float(draug["flee_below"]), 0.0, "the dead never run")
	assert_false(draug.has("look"), "own art, not a borrowed look")
	assert_true(CharacterSprite.has_sheet("draug"))


func test_the_thieves_are_humans_one_gang_shoots() -> void:
	var thug: Dictionary = _db.combat.enemies["brothers_thug"]
	var sister: Dictionary = _db.combat.enemies["chell_sister"]
	for e: Dictionary in [thug, sister]:
		assert_has(e["tags"], "human")
		assert_eq(String(e["look"]), "celum_mugger")
		assert_gt(float(e["flee_below"]), 0.0, "hired thieves run when hurt")
	assert_false(thug.has("ranged"))
	assert_true(sister.has("ranged"))

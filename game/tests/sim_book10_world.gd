extends GutTest
## M37.1 — Book 10 (*The Wind Runner*) world and records.
## Checks that book10/npcs.json and book10/locations.json load cleanly
## alongside Books 1–9, and verifies the four M37.1 record checks.

const NPCS := [
	# Reizmelt (11)
	"fierre", "colfa", "himilt", "rivel", "bamer", "madain", "alber",
	"alime", "kelysta", "levil", "lord_beilkit",
	# Izril — Inn, Liscor, Celum, Pallass (19)
	"quelm", "elissa_slipscal", "kel", "nevvim", "lorent", "grimalkin",
	"maughin", "pelt", "xif", "melinni", "rufelt", "lasica",
	"saliss_of_lights", "rissa_inkscale", "jeckl", "lawes", "veel",
	"rudss", "bealt",
	# Baleros (7)
	"caroline", "blake", "eldima", "kiltem", "hastel", "rital", "kirana",
	# Chandrar (14)
	"ilhmet", "the_quarass", "vaitsha", "khalid", "calliope", "bezha",
	"silmak", "hesseif", "daiton", "chaita", "raelt", "orjin", "salii",
	"nsiia",
]

const PLACES := [
	# Izril — North (8)
	"reizmelt", "huntress_haven", "blaisefords_lookout",
	"gilliel_swamplands", "drakle_estate", "baepr", "lellisdam", "ambault",
	# Izril — Liscor / Pallass (6)
	"orefell", "goblin_graves_hill", "numbtongue_mana_cave",
	"drake_village_hut", "rissa_scribe_shop", "tails_and_scales",
	# Baleros (2)
	"talenqual", "cinfal",
	# Chandrar (6)
	"ger", "blalevault", "jecrass", "belchan", "pomle", "tiqr",
]

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()
	assert_eq(_db.errors, [] as Array[String])


func test_canon_root_loads_book10() -> void:
	var canon := CanonDb.load_root()
	assert_eq(canon.errors, [] as Array[String])


func test_new_npcs_exist_and_live_at_start() -> void:
	assert_eq(NPCS.size(), 51)
	for id: String in NPCS:
		assert_true(_db.canon.npcs.has(id), "missing npc: %s" % id)
		var rec: Dictionary = _db.canon.npcs.get(id, {})
		assert_eq(int(rec.get("canon_ref", {}).get("book", 0)), 10, id)
		assert_true(bool(rec.get("alive_at_start", false)), "%s alive_at_start" % id)


func test_new_places_exist() -> void:
	assert_eq(PLACES.size(), 22)
	for id: String in PLACES:
		assert_true(_db.canon.locations.has(id), "missing place: %s" % id)
		var rec: Dictionary = _db.canon.locations.get(id, {})
		assert_eq(int(rec.get("canon_ref", {}).get("book", 0)), 10, id)


func test_vampires_have_no_classes_and_distant_npcs_tagged() -> void:
	for id: String in ["fierre", "colfa", "himilt", "rivel", "bamer"]:
		var rec: Dictionary = _db.canon.npcs[id]
		assert_eq(String(rec.get("race", "")), "Vampire", id)
		assert_eq((rec.get("classes", []) as Array).size(), 0, "%s has no classes" % id)
	for id: String in [
		"caroline", "blake", "eldima", "kiltem", "hastel", "rital", "kirana",
		"ilhmet", "the_quarass", "vaitsha", "khalid", "calliope", "bezha",
		"silmak", "hesseif", "daiton", "chaita", "raelt", "orjin", "salii", "nsiia",
	]:
		var tags: Array = _db.canon.npcs[id].get("tags", [])
		assert_true(tags.has("distant"), "%s tagged distant" % id)


func test_book10_stated_levels_recorded() -> void:
	var maughin_classes: Array = _db.canon.npcs["maughin"].get("classes", [])
	assert_eq(String(maughin_classes[0].get("name", "")), "[Armorer]")
	assert_eq(int(maughin_classes[0].get("level", 0)), 35)
	var veel_classes: Array = _db.canon.npcs["veel"].get("classes", [])
	assert_eq(String(veel_classes[0].get("name", "")), "[Sword Captain]")
	assert_eq(int(veel_classes[0].get("level", 0)), 26)


func test_four_checks_and_no_false_merges() -> void:
	# Check 1: Shieldscale is Osthia Blackwing (one entity).
	assert_false(_db.canon.npcs.has("shieldscale"))
	assert_false(_db.canon.npcs.has("asrira_shieldscale"))
	assert_false(_db.canon.npcs.has("osthmissa_shieldscale"))
	var osthia_note := String(_db.canon.npcs["osthia_blackwing"]["canon_ref"]["note"])
	assert_string_contains(osthia_note, "False Death")
	assert_string_contains(osthia_note, "Shieldscale")
	# Check 2: Regrika Blackpaw is Venitra's disguise (one entity).
	assert_false(_db.canon.npcs.has("regrika_blackpaw"))
	var venitra_note := String(_db.canon.npcs["venitra"]["canon_ref"]["note"])
	assert_string_contains(venitra_note, "Regrika Blackpaw")
	# Check 3: Teres is Teresa Atwood (teresa in book2).
	assert_false(_db.canon.npcs.has("teres"))
	assert_false(_db.canon.npcs.has("teresa_atwood"))
	var teresa_note := String(_db.canon.npcs["teresa"]["canon_ref"]["note"])
	assert_string_contains(teresa_note, "Teres")
	assert_string_contains(teresa_note, "Teresa Atwood")
	# Check 4: Erin's [Warrior] 2 is in book2/chapters/2.07.json, not duplicated on npcs.json.
	assert_true(_db.canon.npcs.has("erin_solstice"))
	# Non-merges: Lawes (Drake spy) != Ylawes Byres; Quarass is one entity; Calruz note updated.
	assert_true(_db.canon.npcs.has("lawes"))
	assert_true(_db.canon.npcs.has("ylawes_byres"))
	assert_ne(_db.canon.npcs["lawes"]["name"], _db.canon.npcs["ylawes_byres"]["name"])
	assert_true(_db.canon.npcs.has("the_quarass"))
	assert_false(_db.canon.npcs.has("quarass"))
	var calruz_note := String(_db.canon.npcs["calruz"]["canon_ref"]["note"])
	assert_string_contains(calruz_note, "Book 8")
	assert_string_contains(calruz_note, "no verdict")
	assert_string_contains(calruz_note, "Book 10")

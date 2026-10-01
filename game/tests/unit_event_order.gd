extends GutTest
## M18.0 (ADR 0028): events on the same day follow the book number, then the
## chapter's "order" and the event's place in its file. A chapter with no
## "order" keeps the old tie-break (the id), so Books 1 – 5 do not change.

const ROOT := "user://test_event_order"


func after_each() -> void:
	_rm_tree(ROOT)


func _db(events: Dictionary, rank: Dictionary = {}) -> CanonDb:
	return CanonDb.from_dicts({}, {}, events, rank)


func test_no_rank_keeps_earliest_then_id() -> void:
	var c := _db({"e.zeta": ToyCanon.event(1, 1), "e.alpha": ToyCanon.event(1, 1), "e.day0": ToyCanon.event(0, 0)})
	assert_eq(c.errors, [] as Array[String])
	assert_eq(c.order, ["e.day0", "e.alpha", "e.zeta"] as Array[String])


func test_same_day_follows_chapter_order_then_place_in_file() -> void:
	var c := _db({
		"b6.zeta": ToyCanon.event(1, 1),
		"b6.alpha": ToyCanon.event(1, 1),
		"b6.mid": ToyCanon.event(1, 1),
	}, {"b6.mid": [6, 2, 1], "b6.alpha": [6, 1, 2], "b6.zeta": [6, 1, 1]})
	assert_eq(c.order, ["b6.zeta", "b6.alpha", "b6.mid"] as Array[String])


func test_book_number_comes_before_chapter_order() -> void:
	var c := _db({
		"b10.a_first_chapter": ToyCanon.event(1, 1),
		"b9.z_last_chapter": ToyCanon.event(1, 1),
		"b5.z_no_order": ToyCanon.event(1, 1),
	}, {"b10.a_first_chapter": [10, 1, 1], "b9.z_last_chapter": [9, 30, 4], "b5.z_no_order": [5, 0, 0]})
	assert_eq(c.order, ["b5.z_no_order", "b9.z_last_chapter", "b10.a_first_chapter"] as Array[String],
			"book 9 before book 10 (an id sort would not do that)")


func test_earliest_comes_before_rank() -> void:
	var c := _db({
		"b6.early_chapter_day2": ToyCanon.event(2, 2),
		"b6.late_chapter_day1": ToyCanon.event(1, 1),
	}, {"b6.early_chapter_day2": [6, 1, 1], "b6.late_chapter_day1": [6, 9, 1]})
	assert_eq(c.order, ["b6.late_chapter_day1", "b6.early_chapter_day2"] as Array[String])


func test_depends_on_comes_before_rank() -> void:
	var c := _db({
		"b6.first_in_book": ToyCanon.event(1, 1, {"depends_on": ["b6.later_in_book"]}),
		"b6.later_in_book": ToyCanon.event(1, 1),
	}, {"b6.first_in_book": [6, 1, 1], "b6.later_in_book": [6, 2, 1]})
	assert_eq(c.order, ["b6.later_in_book", "b6.first_in_book"] as Array[String])
	assert_eq(c.dependents["b6.later_in_book"], ["b6.first_in_book"])


func test_loader_reads_order_and_place_in_file() -> void:
	# Book 5: no "order"; the file lists z before a, but the id still decides.
	_write_book(5, {"5.00": {"events": {"b5.z_listed_first": ToyCanon.event(1, 1), "b5.a_listed_second": ToyCanon.event(1, 1)}}})
	# Book 6: file "a" is chapter 2 and file "b" is chapter 1; inside a file the
	# listing decides, not the id.
	_write_book(6, {
		"a": {"order": 2, "events": {"b6.c_chapter2": ToyCanon.event(1, 1)}},
		"b": {"order": 1, "events": {"b6.z_chapter1_first": ToyCanon.event(1, 1),
				"b6.a_chapter1_second": ToyCanon.event(1, 1)}},
	})
	var c := CanonDb.load_root(ROOT)
	assert_eq(c.errors, [] as Array[String])
	assert_eq(c.rank["b5.z_listed_first"], [5, 0, 0], "no order: no place")
	assert_eq(c.rank["b6.a_chapter1_second"], [6, 1, 2])
	assert_eq(c.rank["b6.c_chapter2"], [6, 2, 1])
	assert_eq(c.order, ["b5.a_listed_second", "b5.z_listed_first",
			"b6.z_chapter1_first", "b6.a_chapter1_second", "b6.c_chapter2"] as Array[String])


func test_a_bad_order_is_a_load_error() -> void:
	_write_book(6, {"a": {"order": "two", "events": {"b6.x": ToyCanon.event(1, 1)}}})
	var c := CanonDb.load_root(ROOT)
	assert_string_contains("\n".join(c.errors), "order must be a whole number")
	assert_eq(c.rank["b6.x"], [6, 0, 0], "a bad order counts as none")


func test_books_without_order_keep_the_old_order() -> void:
	var c := CanonDb.load_root()
	assert_eq(c.errors, [] as Array[String])
	var old := CanonDb.from_dicts(c.npcs, c.locations, c.events)
	var unordered := func(id: String) -> bool: return int(c.rank[id][1]) == 0
	var now: Array = c.order.filter(unordered)
	var before: Array = old.order.filter(unordered)
	assert_gte(now.size(), 700)
	assert_eq(now, before, "earliest, then book, then id = earliest, then id, for b<N>. ids")


## Writes ROOT/book<n>/ with empty npcs and locations and one file per chapter.
## `chapters`: file stem → {"order"?: Variant, "events": {id: event}}.
func _write_book(n: int, chapters: Dictionary) -> void:
	var dir := ROOT.path_join("book%d" % n)
	DirAccess.make_dir_recursive_absolute(dir.path_join("chapters"))
	_write(dir.path_join("npcs.json"), {"schema_version": 1, "npcs": {}})
	_write(dir.path_join("locations.json"), {"schema_version": 1, "locations": {}})
	for stem: String in chapters:
		var spec: Dictionary = chapters[stem]
		var doc := {"schema_version": 1, "book": n, "chapter": stem}
		if spec.has("order"):
			doc["order"] = spec["order"]
		doc["events"] = spec["events"]
		doc["system"] = []
		_write(dir.path_join("chapters").path_join(stem + ".json"), doc)


func _write(path: String, data: Dictionary) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "\t", false))  # false: keep key order (place in file)
	f.close()


func _rm_tree(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for sub: String in DirAccess.get_directories_at(path):
		_rm_tree(path.path_join(sub))
	for file: String in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file))
	DirAccess.remove_absolute(path)

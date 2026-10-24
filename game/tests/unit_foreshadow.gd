extends GutTest
## Signposts (M31.0, ADR 0044 "M31.0"): talk of the town before a canon event.
## Toy event "e.raid" (day 3) stages a Goblin in the field at 18–23 with the
## farmer alive; its foreshadow shows from day 2 (days_before 1).

const EV := "e.raid"
const TEXT := "Goblin tracks were seen near the field."

var _db: DataDb


func _raid(foreshadow: Dictionary = {}, stage_extra: Dictionary = {}) -> Dictionary:
	if foreshadow.is_empty():
		foreshadow = {"days_before": 1, "text": TEXT}
	var st := {"area": "field", "hours": [18, 23], "foes": [{"enemy": "goblin", "pos": [3, 2]}]}
	st.merge(stage_extra, true)
	return {EV: ToyCanon.event(3, 3, {"requires": ToyCanon.req(["farmer"]), "stage": st,
		"foreshadow": foreshadow})}


func _make(events: Dictionary = {}) -> GameState:
	_db = ToyNpcs.combat_db(events if not events.is_empty() else _raid())
	ToyCombat.freeze(_db)
	return ToyNpcs.new_game(_db)


## Sleeps until the morning of `day`.
func _to_day(gs: GameState, day: int) -> void:
	ToyCanon.sleep_through(gs, _db, day - 1)
	assert_eq(gs.clock.day(), day)


func _events_of(list: Array[Dictionary]) -> Array:
	return list.map(func(e: Dictionary) -> String: return e["event"])


func test_toy_data_is_valid() -> void:
	_make()
	assert_eq(_db.canon.errors, [] as Array[String])
	assert_eq(_db.combat.errors, [] as Array[String])
	assert_eq(_db.canon.foreshadows, [EV] as Array[String])


func test_the_signpost_shows_from_days_before_to_the_window_end() -> void:
	var gs := _make()
	assert_eq(Foreshadow.coming(gs, _db), [] as Array[Dictionary], "day 1: too early")
	_to_day(gs, 2)
	var list := Foreshadow.coming(gs, _db)
	assert_eq(_events_of(list), [EV])
	assert_eq(list[0]["text"], TEXT)
	assert_eq(list[0]["day"], 3)
	_to_day(gs, 3)
	assert_eq(_events_of(Foreshadow.coming(gs, _db)), [EV], "still on the day itself")
	_to_day(gs, 4)
	assert_eq(Foreshadow.coming(gs, _db), [] as Array[Dictionary], "the event ran")


func test_where_and_hours_come_from_the_stage() -> void:
	var gs := _make()
	_to_day(gs, 2)
	var e: Dictionary = Foreshadow.coming(gs, _db)[0]
	assert_eq(e["where"], "field")
	assert_eq(e["hours"], [18, 23])


func test_where_and_hours_can_be_given() -> void:
	var gs := _make(_raid({"days_before": 2, "text": TEXT, "where": "town", "hours": [20, 24]}))
	assert_eq(_db.canon.errors, [] as Array[String])
	var e: Dictionary = Foreshadow.coming(gs, _db)[0]
	assert_eq(e["where"], "town")
	assert_eq(e["hours"], [20, 24])


func test_a_dead_required_npc_drops_the_signpost() -> void:
	var gs := _make()
	_to_day(gs, 2)
	gs.world.set_alive("farmer", false)
	assert_eq(Foreshadow.coming(gs, _db), [] as Array[Dictionary])


func test_a_staged_event_drops_the_signpost() -> void:
	var gs := _make()
	_to_day(gs, 2)
	gs.world.staged[EV] = 2
	assert_eq(Foreshadow.coming(gs, _db), [] as Array[Dictionary])


func test_a_set_unless_flag_drops_the_signpost() -> void:
	var gs := _make(_raid({}, {"unless_flags": ["field.fenced"]}))
	_to_day(gs, 2)
	assert_eq(Foreshadow.coming(gs, _db).size(), 1)
	gs.flags["field.fenced"] = true
	assert_eq(Foreshadow.coming(gs, _db), [] as Array[Dictionary])


func test_the_morning_page_has_the_talk_in_town() -> void:
	var gs := _make()
	_to_day(gs, 2)
	var pages := SystemMessages.pages({}, gs, _db)
	var town := pages.filter(func(p: Dictionary) -> bool: return p["kind"] == SystemMessages.TOWN)
	assert_eq(town.size(), 1)
	var text := "\n".join(town[0]["lines"])
	assert_string_contains(text, TEXT)
	assert_string_contains(text, "tomorrow")
	assert_string_contains(text, String(_db.maps.areas["field"]["name"]))
	assert_string_contains(text, "18:00 – 23:00")
	_to_day(gs, 3)
	var today := SystemMessages.pages({}, gs, _db).filter(
		func(p: Dictionary) -> bool: return p["kind"] == SystemMessages.TOWN)
	assert_string_contains("\n".join(today[0]["lines"]), "today")


func test_no_talk_page_without_a_signpost() -> void:
	var gs := _make()
	var pages := SystemMessages.pages({}, gs, _db)
	assert_false(pages.any(func(p: Dictionary) -> bool: return p["kind"] == SystemMessages.TOWN))


func test_the_journal_lists_what_is_coming_up() -> void:
	var gs := _make()
	var lines := Journal.lines(gs, _db)
	assert_has(lines, "Coming up:")
	assert_has(lines, Journal.NOTHING_COMING)
	_to_day(gs, 2)
	lines = Journal.lines(gs, _db)
	var day := Clock.player_day(3, _db.rules["clock"])
	assert_has(lines, "  Day %d, 18:00 – 23:00, %s: %s" % [day, _db.maps.areas["field"]["name"], TEXT])


func test_hours_text_wraps_midnight() -> void:
	assert_eq(Foreshadow.hours_text([18, 23]), "18:00 – 23:00")
	assert_eq(Foreshadow.hours_text([20, 24]), "20:00 – 00:00")
	assert_eq(Foreshadow.hours_text([22, 2]), "22:00 – 02:00")


func test_canon_db_checks_the_foreshadow_shape() -> void:
	var no_stage := ToyCanon.event(1, 1, {"foreshadow": {"days_before": 1, "text": TEXT}})
	var bad := {
		"e.not_object": ToyCanon.event(1, 1, {"foreshadow": "soon"}),
		"e.bad_days": ToyCanon.event(1, 1, {"foreshadow": {"days_before": -1, "text": TEXT,
			"where": "town", "hours": [6, 12]}}),
		"e.no_text": ToyCanon.event(1, 1, {"foreshadow": {"days_before": 1, "where": "town",
			"hours": [6, 12]}}),
		"e.extra_key": ToyCanon.event(1, 1, {"foreshadow": {"days_before": 1, "text": TEXT,
			"where": "town", "hours": [6, 12], "outcome": "x"}}),
		"e.bad_hours": ToyCanon.event(1, 1, {"foreshadow": {"days_before": 1, "text": TEXT,
			"where": "town", "hours": [6, 6]}}),
		"e.no_stage": no_stage,
	}
	var canon := CanonDb.from_dicts(ToyNpcs.npcs(), {}, bad)
	var text := "\n".join(canon.errors)
	assert_string_contains(text, "event 'e.not_object' foreshadow: must be an object.")
	assert_string_contains(text, "event 'e.bad_days' foreshadow: days_before must be a whole number >= 0.")
	assert_string_contains(text, "event 'e.no_text' foreshadow: text must be a non-empty string.")
	assert_string_contains(text, "event 'e.extra_key' foreshadow: unknown key 'outcome'.")
	assert_string_contains(text, "event 'e.bad_hours' foreshadow: hours must be")
	assert_string_contains(text, "event 'e.no_stage' foreshadow: needs 'where' and 'hours' (no stage).")


func test_combat_db_checks_the_foreshadow_map() -> void:
	_make(_raid({"days_before": 1, "text": TEXT, "where": "moon"}))
	assert_string_contains("\n".join(_db.combat.errors), "event 'e.raid' foreshadow: unknown map 'moon'.")


# --- M31.1: the real canon data

## The key scenes a reader will want to see (docs/plans/m31.md "M31.1").
const KEY_SCENES := ["b2.erin_iphone_concert_night", "b2.frost_faeries_accept_the_banquet",
	"b3.erin_stages_romeo_and_juliet", "b3.erin_stages_frozen", "b5.zzzzf_brunkrs_feast_at_the_inn",
	"b5.zzzzz_liscor_burns_brunkr_and_ulrien", "b6.the_goblin_party_at_the_inn",
	"b6.the_silver_swords_arrive_into_a_cake_fight", "b7.players_of_celum_perform_at_the_inn",
	"b7.zel_funeral_in_the_plaza"]


func test_every_fight_stage_and_key_scene_has_a_signpost() -> void:
	var db := DataDb.load_dir()
	assert_eq(db.canon.errors, [] as Array[String])
	var fights := 0
	for id: String in db.canon.events:
		var st: Dictionary = db.canon.events[id].get("stage", {})
		if not st.is_empty() and st.get("kind", "fight") == "fight":
			fights += 1
			assert_true(db.canon.foreshadows.has(id), "fight stage %s has a foreshadow" % id)
	assert_eq(fights, 25, "the 25 fight stages of Books 1 – 8")
	for id: String in KEY_SCENES:
		assert_true(db.canon.foreshadows.has(id), "key scene %s has a foreshadow" % id)


func test_a_burial_signpost_never_shows_before_the_death() -> void:
	# Brunkr and Ulrien die on day 112; their burning (day 113) must not be talked of on 112.
	var db := DataDb.load_dir()
	var ev: Dictionary = db.canon.events["b5.zzzzz_liscor_burns_brunkr_and_ulrien"]
	var regrika: Dictionary = db.canon.events["b5.zzzzq_regrika_kills_ulrien_in_the_inn"]
	assert_gt(int(ev["window"]["earliest"]) - int(ev["foreshadow"]["days_before"]),
		int(regrika["window"]["latest"]))

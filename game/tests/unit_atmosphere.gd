extends GutTest
## M11.5 atmosphere: the day/night tint, fire light and snow (world/atmosphere.gd).

const NOON := 720
const MIDNIGHT := 0
const DUSK := 1170


func _db() -> DataDb:
	var d := ToyMaps.db()
	d.maps.areas["town"]["objects"][0]["kind"] = "stove"
	d.maps._indoor["shop"] = true
	return d


func _view(d: DataDb, winter_flag: String = "") -> WorldView:
	var v: WorldView = add_child_autofree(load("res://world/world_view.tscn").instantiate())
	v.setup(d.maps, {}, {}, {}, winter_flag)
	v.object_art = {"stove": {"light": {"color": "#ff9a40", "radius": 2.5, "flicker": true}}}
	return v


func _at(gs: GameState, minute: int) -> void:
	gs.clock.total_minutes = gs.clock.total_minutes - gs.clock.minute() + minute


func test_sky_is_white_by_day_and_blue_at_night() -> void:
	assert_eq(Atmosphere.sky_tint(NOON), Color.WHITE)
	assert_eq(Atmosphere.sky_tint(MIDNIGHT), Atmosphere.NIGHT)
	assert_eq(Atmosphere.darkness(NOON), 0.0)
	assert_almost_eq(Atmosphere.darkness(MIDNIGHT), 1.0, 0.001)
	var dusk := Atmosphere.darkness(DUSK)
	assert_between(dusk, 0.05, 0.95, "dusk is part dark")


func test_sky_changes_smoothly_through_the_day() -> void:
	var last := Atmosphere.sky_tint(0)
	for m in range(0, Clock.MINUTES_PER_DAY + 10, 10):
		var c := Atmosphere.sky_tint(m)
		assert_lt(absf(c.get_luminance() - last.get_luminance()), 0.1, "no jump at minute %d" % m)
		last = c


func test_rooms_are_lit_at_night_but_dimmer() -> void:
	assert_gt(Atmosphere.room_tint(MIDNIGHT).get_luminance(), Atmosphere.sky_tint(MIDNIGHT).get_luminance())
	assert_lt(Atmosphere.room_tint(MIDNIGHT).get_luminance(), Atmosphere.room_tint(NOON).get_luminance())


func test_light_of_reads_and_rejects() -> void:
	var l := Atmosphere.light_of({"light": {"color": "#ff8000", "radius": 3, "flicker": true}})
	assert_eq(l["color"], Color.html("#ff8000"))
	assert_eq(l["radius"], 3.0)
	assert_eq(l["energy"], 1.0)
	assert_true(l["flicker"])
	assert_eq(Atmosphere.light_of({"sheet": "x"}), {})
	assert_eq(Atmosphere.light_of({"light": {"color": "nope", "radius": 3}}), {})
	assert_eq(Atmosphere.light_of({"light": {"color": "#ffffff", "radius": 0}}), {})
	assert_eq(Atmosphere.light_of(null), {})


func test_game_fires_have_valid_light() -> void:
	var kinds := WorldView.load_object_art()
	for k in ["campfire", "brazier", "hearth", "stove"]:
		assert_false(Atmosphere.light_of(kinds[k]).is_empty(), k)
	for k: String in kinds:
		if (kinds[k] as Dictionary).has("light"):
			assert_false(Atmosphere.light_of(kinds[k]).is_empty(), "%s light is valid" % k)


func test_view_tints_by_the_clock() -> void:
	var d := _db()
	var v := _view(d)
	var gs := ToyMaps.new_game(d)
	_at(gs, NOON)
	v.refresh(gs)
	assert_eq(v.atmosphere.tint.color, Color.WHITE)
	_at(gs, MIDNIGHT)
	v.refresh(gs)
	assert_eq(v.atmosphere.tint.color, Atmosphere.NIGHT)


func test_fire_lights_up_at_night_only_outdoors() -> void:
	var d := _db()
	var v := _view(d)
	var gs := ToyMaps.new_game(d)
	_at(gs, NOON)
	v.refresh(gs)
	assert_eq(v.atmosphere.lights.get_child_count(), 1)
	var p: PointLight2D = v.atmosphere.lights.get_child(0)
	assert_eq(p.position, WorldView.cell_center(Vector2i(2, 3)))
	assert_false(p.enabled, "no fire light at noon outdoors")
	_at(gs, MIDNIGHT)
	v.refresh(gs)
	assert_true(p.enabled)
	assert_gt(p.energy, 0.5)


func test_indoors_uses_the_room_light_and_no_snow() -> void:
	var d := _db()
	var v := _view(d, "winter")
	var gs := ToyMaps.new_game(d)
	gs.flags["winter"] = true
	_at(gs, NOON)
	v.refresh(gs)
	assert_true(v.atmosphere.snow.emitting, "snow outdoors in winter")
	gs.player.place("shop", Vector2i(1, 1))
	v.refresh(gs)
	assert_eq(v.atmosphere.tint.color, Atmosphere.ROOM_DAY)
	assert_false(v.atmosphere.snow.emitting, "no snow indoors")
	assert_eq(v.atmosphere.lights.get_child_count(), 0, "the shop has no fire")


func test_no_snow_before_winter() -> void:
	var d := _db()
	var v := _view(d, "winter")
	var gs := ToyMaps.new_game(d)
	v.refresh(gs)
	assert_false(v.atmosphere.snow.emitting)


func test_indoor_fire_glows_by_day() -> void:
	var a: Atmosphere = autofree(Atmosphere.new())
	a.show_area(true, [{"cell": Vector2i(1, 1), "light": Atmosphere.light_of({"light": {"color": "#fff", "radius": 2}})}])
	a.set_time(NOON, false)
	var p: PointLight2D = a.lights.get_child(0)
	assert_true(p.enabled)
	assert_almost_eq(p.energy, Atmosphere.ROOM_GLOW, 0.001)
	a.set_time(MIDNIGHT, false)
	assert_almost_eq(p.energy, 1.0, 0.001)

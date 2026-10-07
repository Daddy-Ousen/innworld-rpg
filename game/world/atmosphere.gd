## M11.5 atmosphere (ADR 0018): the light of the time of day, fire light and
## falling snow over the world view. A child of WorldView.
## - Tint: a CanvasModulate colours the whole map by the clock (sky_tint).
##   Indoor maps get a warm room light that dims at night (room_tint). The
##   HUD and menus are on their own CanvasLayers, so they keep their colours.
## - Lights: a map object whose kind has "light" in data/objects.json
##   ({"color", "radius" in cells, "energy"?, "flicker"?}) gets a
##   PointLight2D. Outdoors it shows only as the day darkens; indoors it
##   always glows a little. A flickering light wobbles by a fixed wave (no
##   randomness; the phase comes from its cell).
## - Snow: in winter, outdoors, flakes fall over the camera's view.
## - Rain (M19.0): while the rains fall, outdoors, streaks fall over the view
##   (faster and steeper than snow; Rains).
## Presentation only: reads what the view gives it, never changes GameState.
class_name Atmosphere
extends Node2D

## Sky colour keyframes: [minute of the day, colour]. Between two keys the
## colour is mixed; the list wraps at midnight.
const SKY := [
	[0, Color(0.44, 0.50, 0.74)],
	[300, Color(0.44, 0.50, 0.74)],
	[390, Color(0.92, 0.72, 0.66)],
	[480, Color(1, 1, 1)],
	[1050, Color(1, 1, 1)],
	[1140, Color(0.96, 0.70, 0.56)],
	[1230, Color(0.44, 0.50, 0.74)],
]
const NIGHT := Color(0.44, 0.50, 0.74)
const ROOM_DAY := Color(0.96, 0.92, 0.86)
const ROOM_NIGHT := Color(0.64, 0.58, 0.56)
## Indoor fires glow at least this much of their energy by day.
const ROOM_GLOW := 0.45
const LIGHT_TEXTURE_SIZE := 128
const FLICKER := 0.08
const FLICKER_SPEED := 7.0
const SNOW_AMOUNT := 320
const SNOW_LIFE := 9.0
const SNOW_SPEED := Vector2(14, 60)
const RAIN_AMOUNT := 420
const RAIN_LIFE := 1.1
const RAIN_SPEED := Vector2(90, 420)

var tile := 32
var indoor := false
var winter := false
var raining := false
var minute := 720
## 0 by day, 1 at full night (see darkness).
var dark := 0.0

var tint: CanvasModulate
var snow: CPUParticles2D
var rain: CPUParticles2D
var lights: Node2D
var _time := 0.0
static var _light_texture: Texture2D


func _init() -> void:
	name = "Atmosphere"
	tint = CanvasModulate.new()
	tint.name = "Tint"
	add_child(tint)
	lights = Node2D.new()
	lights.name = "Lights"
	add_child(lights)
	snow = _make_snow()
	add_child(snow)
	rain = _make_rain()
	add_child(rain)


## The sky colour at a minute of the day (0–1439).
static func sky_tint(at: int) -> Color:
	var m := posmod(at, Clock.MINUTES_PER_DAY)
	for i in SKY.size():
		var a: Array = SKY[i]
		var b: Array = SKY[(i + 1) % SKY.size()]
		var end := int(b[0]) if i + 1 < SKY.size() else Clock.MINUTES_PER_DAY
		if m >= int(a[0]) and m < end:
			return (a[1] as Color).lerp(b[1], float(m - int(a[0])) / float(end - int(a[0])))
	return Color.WHITE


## How dark the sky is: 0 at full day, 1 at full night.
static func darkness(at: int) -> float:
	var c := sky_tint(at)
	return clampf((1.0 - c.get_luminance()) / (1.0 - NIGHT.get_luminance()), 0.0, 1.0)


## The colour of a room (an indoor map) at a minute of the day.
static func room_tint(at: int) -> Color:
	return ROOM_DAY.lerp(ROOM_NIGHT, darkness(at))


## The light of an object kind's art ({"color": Color, "radius": cells,
## "energy", "flicker"}), or {} when it has none or it is broken.
static func light_of(art: Variant) -> Dictionary:
	if not art is Dictionary or not (art as Dictionary).get("light") is Dictionary:
		return {}
	var l: Dictionary = art["light"]
	var color := String(l.get("color", ""))
	var radius: Variant = l.get("radius")
	if not Color.html_is_valid(color) or not (radius is float or radius is int) or float(radius) <= 0.0:
		return {}
	return {"color": Color.html(color), "radius": float(radius),
		"energy": float(l.get("energy", 1.0)), "flicker": bool(l.get("flicker", false))}


## A new map: drops the old lights and adds one per entry of `sources`
## ([{"cell": Vector2i, "light": light_of(...)}]).
func show_area(is_indoor: bool, sources: Array) -> void:
	indoor = is_indoor
	for child in lights.get_children():
		lights.remove_child(child)
		child.queue_free()
	for s: Dictionary in sources:
		var l: Dictionary = s["light"]
		var cell: Vector2i = s["cell"]
		var p := PointLight2D.new()
		p.texture = _texture()
		p.texture_scale = l["radius"] * tile * 2.0 / LIGHT_TEXTURE_SIZE
		p.color = l["color"]
		p.position = (Vector2(cell) + Vector2(0.5, 0.5)) * tile
		p.set_meta("energy", l["energy"])
		p.set_meta("flicker", l["flicker"])
		p.set_meta("phase", float(cell.x * 7 + cell.y * 13))
		lights.add_child(p)
	_apply()


## The time of day and the weather. Called on every refresh.
func set_time(at: int, is_winter: bool, is_raining: bool = false) -> void:
	minute = at
	winter = is_winter
	raining = is_raining
	_apply()


## How strong the lights are now (before flicker): 0..1.
func glow() -> float:
	return lerpf(ROOM_GLOW, 1.0, dark) if indoor else dark


func _apply() -> void:
	dark = darkness(minute)
	tint.color = room_tint(minute) if indoor else sky_tint(minute)
	snow.emitting = winter and not indoor
	snow.visible = snow.emitting
	rain.emitting = raining and not indoor
	rain.visible = rain.emitting
	_set_energy()


func _set_energy() -> void:
	var g := glow()
	for p: PointLight2D in lights.get_children():
		var wobble := 1.0
		if bool(p.get_meta("flicker")):
			var ph := float(p.get_meta("phase"))
			wobble += FLICKER * sin(_time * FLICKER_SPEED + ph) + FLICKER * 0.5 * sin(_time * FLICKER_SPEED * 2.3 + ph * 0.5)
		p.energy = float(p.get_meta("energy")) * g * wobble
		p.enabled = g > 0.0


func _process(delta: float) -> void:
	_time += delta
	if lights.get_child_count() > 0:
		_set_energy()
	if snow.emitting or rain.emitting:
		var cam := get_viewport().get_camera_2d() if get_viewport() != null else null
		if cam != null:
			var view := get_viewport_rect().size / cam.zoom
			for p: CPUParticles2D in [snow, rain]:
				p.global_position = cam.get_screen_center_position() - Vector2(0, view.y / 2.0 + tile)
				p.emission_rect_extents = Vector2(view.x / 2.0 + tile * 2, tile)


func _make_snow() -> CPUParticles2D:
	var s := CPUParticles2D.new()
	s.name = "Snow"
	s.amount = SNOW_AMOUNT
	s.lifetime = SNOW_LIFE
	s.preprocess = SNOW_LIFE
	s.local_coords = false
	s.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	s.emission_rect_extents = Vector2(640, 32)
	s.direction = SNOW_SPEED.normalized()
	s.spread = 12.0
	s.gravity = Vector2.ZERO
	s.initial_velocity_min = SNOW_SPEED.length() * 0.7
	s.initial_velocity_max = SNOW_SPEED.length() * 1.3
	s.scale_amount_min = 1.5
	s.scale_amount_max = 3.0
	s.color = Color(1, 1, 1, 0.85)
	s.emitting = false
	s.visible = false
	s.z_index = 50
	return s


func _make_rain() -> CPUParticles2D:
	var r := CPUParticles2D.new()
	r.name = "Rain"
	r.amount = RAIN_AMOUNT
	r.lifetime = RAIN_LIFE
	r.preprocess = RAIN_LIFE
	r.local_coords = false
	r.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	r.emission_rect_extents = Vector2(640, 32)
	var img := Image.create(2, 10, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	r.texture = ImageTexture.create_from_image(img)
	r.particle_flag_align_y = true
	r.direction = RAIN_SPEED.normalized()
	r.spread = 4.0
	r.gravity = Vector2.ZERO
	r.initial_velocity_min = RAIN_SPEED.length() * 0.9
	r.initial_velocity_max = RAIN_SPEED.length() * 1.1
	r.color = Color(0.72, 0.8, 0.95, 0.55)
	r.emitting = false
	r.visible = false
	r.z_index = 50
	return r


## One soft round light shape, shared by every light.
static func _texture() -> Texture2D:
	if _light_texture == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.5, Color(1, 1, 1, 0.45))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.width = LIGHT_TEXTURE_SIZE
		t.height = LIGHT_TEXTURE_SIZE
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		_light_texture = t
	return _light_texture

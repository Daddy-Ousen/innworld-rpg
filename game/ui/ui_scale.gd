## The size of menus, text and the HUD (M20.3, ADR 0033): the root window's
## content_scale_factor. A user preference, not game state: saved in
## user://settings.cfg (section "display", key "ui_scale") next to the text
## size, so a load does not change it. Auto picks BIG on a phone (a touch
## screen with a short side under PHONE_INCHES), else 1. The map and the touch
## pad keep their size under a bigger UI (user, 2026-10-05): the camera zoom
## and the pad's sizes are divided by the factor. M34.4: on a phone they grow
## to a size in dp instead (map_grow, touch_grow). Pure except for `fit`,
## `keep_fit`, the screen dpi and the window read in `Session`.
class_name UiScale
extends RefCounted

const PATH := "user://settings.cfg"
const SECTION := "display"
const AUTO := "auto"
## Modes in Options order: Auto, then fixed factors.
const MODES: Array[String] = [AUTO, "1", "1.5", "2"]
const BIG := 2.0
## Auto on a phone or tablet OS (Android, iOS, or a browser on them): a bit
## bigger than BIG, whatever the reported dpi says (user, 2026-10-08).
const MOBILE := 2.5
## Alpha of panel, button and list boxes on mobile: the map shows through.
const MOBILE_ALPHA := 0.78
const PHONE_INCHES := 5.0
## The world camera's zoom at factor 1 (world_view.tscn).
const CAMERA_ZOOM := 2.0
## Space kept around a panel that is cut to fit a small view.
const MARGIN := 8.0
## M34.4 (ADR 0045, user pick 2026-10-21): on a phone or tablet OS the touch
## pad, the map and the menu buttons grow to a size in dp (density-independent
## pixels, DP_PER_INCH to the inch, the screen's dpi): a touch button at least
## TOUCH_DP, a map tile about TILE_DP. A desktop keeps the sizes of M20.3.
const DP_PER_INCH := 160.0
const TOUCH_DP := 48.0
const TILE_DP := 40.0
## The smallest touch pad button (TouchControls.SIZE) and a map tile (ViewArt.TILE)
## at camera zoom CAMERA_ZOOM, in screen pixels at factor 1.
const PAD_PX := 64.0
const TILE_PX := 32.0

## Renders and tests set these: dpi (0 = the screen's), mobile (-1 = the OS, 0 = no, 1 = yes).
static var dpi_override := 0.0
static var mobile_override := -1

var mode := AUTO


## The settings in `path`, or Auto when there is none. A bad value reads as Auto.
static func load_file(path: String = PATH) -> UiScale:
	var s := UiScale.new()
	var cfg := ConfigFile.new()
	if cfg.load(path) == OK:
		s.set_mode(String(cfg.get_value(SECTION, "ui_scale", AUTO)))
	return s


func save(path: String = PATH) -> Error:
	var cfg := ConfigFile.new()
	cfg.load(path)  # keep other sections
	cfg.set_value(SECTION, "ui_scale", mode)
	return cfg.save(path)


func set_mode(m: String) -> void:
	mode = m if MODES.has(m) else AUTO


## The factor for this mode. `short_px`: the short side of the window in
## pixels; `dpi`: the screen's dots per inch; `touch`: a touch screen.
func factor(short_px: float, dpi: float, touch: bool, mobile := false) -> float:
	if mode != AUTO:
		return float(mode)
	return MOBILE if mobile else auto_factor(short_px, dpi, touch)


## BIG on a touch screen whose short side is under PHONE_INCHES, else 1.
## Without touch it is always 1, so a small desktop window never jumps.
## (Web: dpi is 96 x devicePixelRatio, so a phone reads about 4 in.)
static func auto_factor(short_px: float, dpi: float, touch: bool) -> float:
	if not touch or dpi <= 0.0:
		return 1.0
	return BIG if short_px / dpi < PHONE_INCHES else 1.0


## True on a phone or tablet OS, in the app or in a browser on it.
static func is_mobile_os() -> bool:
	if mobile_override >= 0:
		return mobile_override == 1
	return OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")


## Screen pixels in one dp (M34.4).
static func px_per_dp() -> float:
	var dpi := dpi_override if dpi_override > 0.0 else float(DisplayServer.screen_get_dpi())
	return maxf(dpi, 1.0) / DP_PER_INCH


## How much the touch pad grows on a phone so its smallest button is TOUCH_DP (1 on a desktop).
static func touch_grow() -> float:
	return maxf(px_per_dp() * TOUCH_DP / PAD_PX, 1.0) if is_mobile_os() else 1.0


## How much the map grows on a phone so a tile is about TILE_DP (1 on a desktop).
static func map_grow() -> float:
	return maxf(px_per_dp() * TILE_DP / (TILE_PX * CAMERA_ZOOM), 1.0) if is_mobile_os() else 1.0


## The smallest height of a menu button in UI pixels at factor `f`: TOUCH_DP on a
## phone, else 0 (the menu's own size holds).
static func touch_ui_px(f: float) -> float:
	return TOUCH_DP * px_per_dp() / maxf(f, 0.1) if is_mobile_os() else 0.0


## Sets the alpha of every flat box in `theme` that has a fill: `alpha` x its
## first (opaque) alpha, or the first alpha again when `alpha` is 1. Remembers the
## first alpha in the box's metadata, so it can be called again and again.
static func set_box_alpha(theme: Theme, alpha: float) -> void:
	if theme == null:
		return
	var seen := {}
	for type_name in theme.get_stylebox_type_list():
		for style_name in theme.get_stylebox_list(type_name):
			var box := theme.get_stylebox(style_name, type_name) as StyleBoxFlat
			if box == null or not box.draw_center or seen.has(box):
				continue
			seen[box] = true
			if not box.has_meta("base_alpha"):
				box.set_meta("base_alpha", box.bg_color.a)
			var c := box.bg_color
			c.a = float(box.get_meta("base_alpha")) * alpha
			box.bg_color = c


## The world camera's zoom at `f`: the map keeps its size on the screen
## (M34.4: on a phone it grows to map_grow).
static func camera_zoom(f: float) -> float:
	return CAMERA_ZOOM * map_grow() / f


## The size of a panel designed at `design` in a view of `view`: the design
## size, but at most the view minus MARGIN on each side.
static func fitted(design: Vector2, view: Vector2) -> Vector2:
	return design.min(view - Vector2(MARGIN, MARGIN) * 2.0).max(Vector2.ZERO)


## Centres `panel` (anchored in the middle) at its fitted size.
static func fit(panel: Control, design: Vector2) -> void:
	var s := fitted(design, panel.get_viewport_rect().size) / 2.0
	panel.offset_left = -s.x
	panel.offset_right = s.x
	panel.offset_top = -s.y
	panel.offset_bottom = s.y


## Fits `panel` now and again when it shows, the window resizes or the scale
## changes. `after` (optional) runs after each fit.
static func keep_fit(panel: Control, design: Vector2, after := Callable()) -> void:
	var refit := func() -> void:
		fit(panel, design)
		if after.is_valid():
			after.call()
	refit.call()
	panel.visibility_changed.connect(refit)
	# The viewport and Session outlive the panel: let go of them when it leaves.
	var sources: Array[Signal] = [panel.get_viewport().size_changed]
	var session := panel.get_node_or_null("/root/Session")
	if session != null:
		sources.append(session.ui_scale_changed)
	for sig: Signal in sources:
		sig.connect(refit)
	panel.tree_exiting.connect(func() -> void:
		for sig: Signal in sources:
			if sig.is_connected(refit):
				sig.disconnect(refit), CONNECT_ONE_SHOT)

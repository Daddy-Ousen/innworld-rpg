## The journal (J, M6.1): the day, the news of the last days, what the player
## changed in the story and the drift (M6.4), and how to play.
## The focus picker was removed from the screen (2026-10-11); `focus_choices`,
## `focus_name` and `main_tags` stay for the character sheet, console and tests.
## The screen never shows XP numbers (M15.3). Presentation only; `lines` is static
## and headless, so tests can check it.
class_name Journal
extends PanelContainer

## A class tag is a main tag for a focus at this weight or more.
const FOCUS_MIN_WEIGHT := 0.5
## News from this many days (today included).
const NEWS_DAYS := 7

var _gs: GameState
var _db: DataDb

## The panel's size (the .tscn offsets) when the view has room (M20.3).
const DESIGN_SIZE := Vector2(600, 600)
@onready var _text: Label = %Text
@onready var _scroll: ScrollContainer = %Scroll


func _ready() -> void:
	hide()
	UiScale.keep_fit(self, DESIGN_SIZE)  # M20.3: cut to a small view


func open(gs: GameState, db: DataDb) -> void:
	_gs = gs
	_db = db
	_text.text = "\n".join(lines(gs, db))
	_scroll.scroll_vertical = 0
	show()


func close() -> void:
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var down := event.is_action_pressed(&"page_down", true)
	if down or event.is_action_pressed(&"page_up", true):
		var page := int(_scroll.size.y * 0.8)
		_scroll.scroll_vertical += page if down else -page
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"back") or event.is_action_pressed(&"journal"):
		close()
		get_viewport().set_input_as_handled()


## "No focus", then one entry per class the player can aim for: not a
## consolidation, no class prereqs, not declined. Data order.
static func focus_choices(gs: GameState, db: DataDb) -> Array[Dictionary]:
	var out: Array[Dictionary] = [{"name": "No focus", "tags": [] as Array[String]}]
	for id: String in db.classes:
		var c: Dictionary = db.classes[id]
		if c["consolidation"] != null or not (c["prereqs"].get("classes", []) as Array).is_empty() \
				or gs.progression.declined.has(id):
			continue
		out.append({"name": "Become %s" % c["name"], "tags": main_tags(c)})
	return out


## The class's tags at FOCUS_MIN_WEIGHT or more, strongest first.
static func main_tags(class_data: Dictionary) -> Array[String]:
	var weights: Dictionary = class_data["tag_weights"]
	var out: Array[String] = []
	for tag: String in weights:
		if float(weights[tag]) >= FOCUS_MIN_WEIGHT:
			out.append(tag)
	out.sort_custom(func(a: String, b: String) -> bool: return float(weights[a]) > float(weights[b]))
	return out


## The focus as the player picked it ("Become [Innkeeper]"), else its tags.
static func focus_name(gs: GameState, db: DataDb) -> String:
	if gs.focus_tags.is_empty():
		return "none"
	for c: Dictionary in focus_choices(gs, db):
		if _same(c["tags"], gs.focus_tags):
			return c["name"]
	return ", ".join(gs.focus_tags)


static func lines(gs: GameState, db: DataDb) -> Array[String]:
	var out: Array[String] = [
		"Day %d, %s." % [_pday(gs.clock.day(), db), gs.clock.time_string()],
		"",
		"Your mark on the story:",
	]
	var marks := changes(gs, db)
	if marks.is_empty():
		out.append("  Nothing yet.")
	for m: String in marks:
		out.append("  " + m)
	out.append(drift_line(gs, db))
	out.append("")
	out.append("News:")
	var news := gs.world.news_since(gs.clock.day() - NEWS_DAYS + 1)
	if news.is_empty():
		out.append("  No news yet.")
	for n: Dictionary in news:
		out.append("  Day %d: %s%s" % [_pday(int(n["day"]), db),
				"Rumor: " if n["kind"] == Director.RUMOR else "", n["text"]])
	out.append("")
	out.append("How to play:")
	for h: String in SystemMessages.HINTS:
		out.append("  " + h)
	return out


## What the player changed in canon, oldest first: "Day 11: <hook news>"
## for each hook result, "Day 9: You killed <name>." for each kill.
static func changes(gs: GameState, db: DataDb) -> Array[String]:
	var out: Array[String] = []
	for h: Dictionary in gs.world.history:
		if h["event"] == "player.kill":
			var npc: String = h["roles"]["victim"]
			out.append("Day %d: You killed %s." % [_pday(int(h["day"]), db),
					db.canon.npcs.get(npc, {}).get("name", npc)])
		elif h.get("by", "") == Director.BY_PLAYER:
			out.append("Day %d: %s" % [_pday(int(h["day"]), db), _hook_text(db, h)])
	return out


## A calendar day as the player counts it (M15.1).
static func _pday(canon_day: int, db: DataDb) -> int:
	return Clock.player_day(canon_day, db.rules["clock"])


## The hook's news, else a plain line.
static func _hook_text(db: DataDb, h: Dictionary) -> String:
	for hook: Dictionary in db.canon.events.get(h["event"], {}).get("hooks", []):
		if hook["id"] == h["hook"] and hook.get("news", "") != "":
			return hook["news"]
	return "You changed what happened."


static func drift_line(gs: GameState, db: DataDb) -> String:
	var d := gs.world.drift
	if d <= 0.0:
		return "Drift: 0. The story runs as you know it."
	if d >= float(db.rules["director"]["unreliable_at"]):
		return "Drift: %.2f. %s" % [d, Director.UNRELIABLE_LINE]
	return "Drift: %.2f. The story has started to change." % d


static func _same(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for x: Variant in a:
		if not b.has(x):
			return false
	return true

## Heads-up display: day, time, place, HP and the held item, a tiredness
## warning, and a short log of what just happened. Presentation only.
class_name Hud
extends Control

const LOG_LINES := 6
## Warn when this many awake minutes are left before a collapse.
const WARN_BEFORE := 360
## HP at or below this share of max HP is shown in the warning colour.
const LOW_HP := 0.25
const WARN_COLOR := Color(1, 0.55, 0.4, 1)

var _log: Array[String] = []

@onready var _status: Label = %Status
@onready var _health: Label = %Health
@onready var _warning: Label = %Warning
@onready var _log_label: Label = %Log


func refresh(gs: GameState, db: DataDb) -> void:
	var place := ""
	if gs.player.is_placed() and db.maps.areas.has(gs.player.area):
		var loc := Movement.location_at(gs, db)
		place = "%s · %s" % [db.maps.areas[gs.player.area]["name"],
				db.canon.locations.get(loc, {}).get("name", loc)]
	_status.text = "Day %d  %s    %s" % [gs.clock.day(), gs.clock.time_string(), place]
	var p := purse(gs, db)
	if p != "":
		_status.text += "    " + p
	_health.text = health(gs, db)
	if is_low(gs, db):
		_health.add_theme_color_override("font_color", WARN_COLOR)
	else:
		_health.remove_theme_color_override("font_color")
	_warning.text = warning(gs, db)
	_warning.visible = _warning.text != ""


## "HP 14/20 · Held: Chair" (or "Held: nothing"); in a staged fight
## (M7.B) also " · Foes left: 23" (on the map and in the waves to come);
## in winter (M8.W) " · Cold" outdoors away from a fire, and " · Slowed"
## under fairy snow.
static func health(gs: GameState, db: DataDb) -> String:
	var held := "nothing"
	if gs.player.held != "":
		held = String(db.combat.items.get(gs.player.held, {}).get("name", gs.player.held))
	var out := "HP %d/%d · Held: %s" % [Combat.hp(gs, db), Stats.max_hp(gs, db), held]
	var left := Stage.foes_left(gs, db)
	if left >= 0:
		out += " · Foes left: %d" % left
	if Winter.status(gs, db) == "cold":
		out += " · Cold"
	if gs.winter.slowed > 0:
		out += " · Slowed"
	return out


## "Coins 1s 4c" (M8.6), plus " · Hungry" after a hungry night; "" with no
## economy rules (toy dbs).
static func purse(gs: GameState, db: DataDb) -> String:
	if not Economy.on(db):
		return ""
	var out := "Coins %s" % Economy.format(db, gs.economy.coins)
	if gs.economy.hunger > 0:
		out += " · Hungry"
	return out


## True at or below LOW_HP of max HP.
static func is_low(gs: GameState, db: DataDb) -> bool:
	return Combat.hp(gs, db) <= Stats.max_hp(gs, db) * LOW_HP


## "" or a line about how close a collapse is.
@warning_ignore("integer_division")
static func warning(gs: GameState, db: DataDb) -> String:
	var left := int(db.rules["clock"]["collapse_after_awake"]) - gs.clock.awake_minutes
	if left <= 0:
		return "You cannot stay awake any longer."
	if left <= WARN_BEFORE:
		return "You are very tired. You will collapse in %dh %02dm." % [left / 60, left % 60]
	return ""


func add_lines(lines: Array) -> void:
	for line: Variant in lines:
		_log.append(str(line))
	if _log.size() > LOG_LINES:
		_log = _log.slice(_log.size() - LOG_LINES)
	_log_label.text = "\n".join(_log)

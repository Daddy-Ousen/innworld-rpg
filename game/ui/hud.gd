## Heads-up display: day, time, place, a tiredness warning, and a short
## log of what just happened. Presentation only.
class_name Hud
extends Control

const LOG_LINES := 4
## Warn when this many awake minutes are left before a collapse.
const WARN_BEFORE := 360

var _log: Array[String] = []

@onready var _status: Label = %Status
@onready var _warning: Label = %Warning
@onready var _log_label: Label = %Log


func refresh(gs: GameState, db: DataDb) -> void:
	var place := ""
	if gs.player.is_placed() and db.maps.areas.has(gs.player.area):
		var loc := Movement.location_at(gs, db)
		place = "%s · %s" % [db.maps.areas[gs.player.area]["name"],
				db.canon.locations.get(loc, {}).get("name", loc)]
	_status.text = "Day %d  %s    %s" % [gs.clock.day(), gs.clock.time_string(), place]
	_warning.text = warning(gs, db)
	_warning.visible = _warning.text != ""


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

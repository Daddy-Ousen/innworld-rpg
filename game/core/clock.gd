## Game time. One counter of minutes since the start; it never goes back.
## Day and time of day are derived from it. Rules come from data/rules.json "clock".
class_name Clock
extends RefCounted

const MINUTES_PER_DAY := 1440

var total_minutes: int = 0
var awake_minutes: int = 0
## True if the last sleep was a forced collapse. The night pipeline reads it.
var last_sleep_collapsed: bool = false


func _init(start_minute: int = 0) -> void:
	total_minutes = start_minute


## Calendar day, starting at 1.
func day() -> int:
	@warning_ignore("integer_division")
	return total_minutes / MINUTES_PER_DAY + 1


## Minute of the current calendar day (0–1439).
func minute() -> int:
	return total_minutes % MINUTES_PER_DAY


func time_string() -> String:
	@warning_ignore("integer_division")
	return "%02d:%02d" % [minute() / 60, minute() % 60]


func advance(minutes: int) -> void:
	if minutes < 0:
		push_error("Clock cannot advance by a negative amount (%d)." % minutes)
		return
	total_minutes += minutes
	awake_minutes += minutes


func is_collapse_due(rules: Dictionary) -> bool:
	return awake_minutes >= int(rules["collapse_after_awake"])


## Sleeps until the next wake time (at least min_sleep_minutes), or for
## collapse_sleep_minutes after a collapse. Returns calendar days passed.
func sleep(rules: Dictionary, collapsed: bool = false) -> int:
	var before := day()
	total_minutes += sleep_length(rules, collapsed)
	awake_minutes = 0
	last_sleep_collapsed = collapsed
	return day() - before


## Minutes a sleep (or collapse) starting now would last.
func sleep_length(rules: Dictionary, collapsed: bool = false) -> int:
	if collapsed:
		return int(rules["collapse_sleep_minutes"])
	var length := posmod(int(rules["wake_minute"]) - minute(), MINUTES_PER_DAY)
	return maxi(length, int(rules["min_sleep_minutes"]))


## Calendar day the player wakes on after a sleep starting now.
@warning_ignore("integer_division")
func wake_day(rules: Dictionary, collapsed: bool = false) -> int:
	return (total_minutes + sleep_length(rules, collapsed)) / MINUTES_PER_DAY + 1


func to_dict() -> Dictionary:
	return {
		"total_minutes": total_minutes,
		"awake_minutes": awake_minutes,
		"last_sleep_collapsed": last_sleep_collapsed,
	}


static func from_dict(d: Dictionary) -> Clock:
	var c := Clock.new(int(d["total_minutes"]))
	c.awake_minutes = int(d["awake_minutes"])
	c.last_sleep_collapsed = bool(d["last_sleep_collapsed"])
	return c

## The panels of the game screen (M26.0, split from main.gd): which panel has
## the keyboard, the debug console, the use menu and the bag, the touch pad and
## the UI scale (M20.1, M20.3), the message history, the night pages, and the
## autosave each time the System dialog closes (each morning).
## Presentation only (CLAUDE.md rule 1).
class_name MainPanels
extends RefCounted

## The MainScreen (untyped: a typed back link makes a script cycle that leaks at exit).
var _m
## M34.2: the place and time the context button's targets were read at.
var _context_key := ""


func _init(screen: Node) -> void:
	_m = screen


## True while a menu, the sheet, the journal, the bag, the System dialog or
## the console has the keyboard.
func is_busy() -> bool:
	return _m.console_layer.visible or panel_open() or _m.dialog.visible or _m.travel.visible \
			or _m.view.is_replaying()


## True while a menu or page panel is open (not the dialog or the console).
func panel_open() -> bool:
	return _m.menu.visible or _m.shop.visible or _m.sheet.visible or _m.journal.visible or _m.bag.visible \
			or _m.pause.visible or _m.message_log.visible or _m.help.visible


## The UI scale factor changed (M20.3): the map and the touch pad keep their
## size on the screen (user, 2026-10-05); on a phone they grow to a size in dp
## (M34.4, UiScale.map_grow / touch_grow).
func apply_ui_scale() -> void:
	var f: float = _m.get_window().content_scale_factor
	_m.view.camera.zoom = Vector2.ONE * UiScale.camera_zoom(f)
	_m.touch.set_factor(f / UiScale.touch_grow())  # M34.4: 48 dp buttons on a phone


## Shows the touch controls that fit now (M20.1) and makes room for the pad
## in the HUD.
func sync_touch() -> void:
	var shown: bool = Session.touch_shown()
	_m.touch.sync(shown, panel_open(), _m.dialog.visible or _m.console_layer.visible,
			_m.aim.armed != "" or _m.aim.walking() or _m.tapper.walking(), Encounter.is_player_turn(Session.gs))
	_m.hud.make_room_left(_m.touch.pad_width() if shown else 0.0)
	if shown:
		_m.touch.set_top_room(_m.hud.top_bottom())
		refresh_context()


## M34.2: the targets near for the context button and its chips. Read again
## only when the place, the time (people move), the flags or the game changed.
func refresh_context() -> void:
	var gs: GameState = Session.gs
	var key := "%d|%s|%s|%d|%d" % [gs.get_instance_id(), gs.player.area, gs.player.pos(),
			gs.clock.total_minutes, gs.flags.size()]
	if key == _context_key:
		return
	_context_key = key
	var targets: Array[Dictionary] = []
	if gs.player.is_placed():
		targets = InteractMenu.targets(Interact.options(gs, Session.db), Session.db, gs)
	_m.touch.set_targets(targets)


## The context button or a chip (M34.2): the card of `object_id`, or the target list ("").
func open_target(object_id: String) -> void:
	var options := Interact.options(Session.gs, Session.db)
	var ok: bool = _m.menu.open(options, Session.db) if object_id == "" \
			else _m.menu.open_on(options, Session.db, object_id)
	if not ok:
		_m.hud.add_lines(["There is nothing to use here."])


func toggle_console() -> void:
	var layer: CanvasLayer = _m.console_layer
	layer.visible = not layer.visible
	if layer.visible:
		_m.menu.close()
		_m.shop.close()
		_m.sheet.close()
		_m.journal.close()
		_m.bag.close()
		_m.pause.close()
		_m.console_input.grab_focus()
	else:
		_m.console_input.release_focus()


func open_use_menu() -> void:
	if not _m.menu.open(Interact.options(Session.gs, Session.db), Session.db):
		_m.hud.add_lines(["There is nothing to use here."])


## The Shop button on a shop's card (M34.1): the shop screen.
func open_shop(option: Dictionary) -> void:
	_m.shop.open(option, Session.db, Session.gs)


## A deal on the shop screen: runs it like a use-menu pick, then shows the shop
## again with the new prices and counts and what the deal did (not when the
## player went down or the day ended).
func use_from_shop(object_id: String, action_id: String) -> void:
	_m.use(object_id, action_id)
	var o := _option(object_id)
	if Combat.is_down(Session.gs) or _m.dialog.visible or not _m.shop.open(o, Session.db, Session.gs):
		_m.shop.close()
		return
	var lines: Array[String] = _m.hud.history()
	_m.shop.note(lines[-1] if not lines.is_empty() else "")


## Back on the shop screen: the shop's card again.
func shop_back(object_id: String) -> void:
	if not _m.menu.open_on(Interact.options(Session.gs, Session.db), Session.db, object_id):
		_m.hud.add_lines(["There is nothing to use here."])


## The Interact option with id `object_id` near the player now, or {}.
func _option(object_id: String) -> Dictionary:
	for o: Dictionary in Interact.options(Session.gs, Session.db):
		if o["id"] == object_id:
			return o
	return {}


## The bag (F): eat or drink something you carry.
func open_bag() -> void:
	if not _m.menu.open_bag(Session.gs, Session.db):
		_m.hud.add_lines(["You have nothing to eat or drink. (Coins: %s)" % Economy.format(Session.db,
				Session.gs.economy.coins)])


## A pick on the bag screen: runs it like a use-menu pick, then shows the
## bag again (not when the player went down or the day ended).
func use_from_bag(action_id: String) -> void:
	_m.use("bag", action_id)
	if not Combat.is_down(Session.gs) and not _m.dialog.visible:
		_m.bag.open(Session.gs, Session.db)


## The message history, newest first (the L page).
func history_lines() -> Array:
	var lines: Array = _m.hud.history()
	lines.reverse()
	return lines


## "Day 3, 06:00." with the day counted from the player's arrival (M15.1).
func day_line() -> String:
	return "Day %d, %s." % [Clock.player_day(Session.gs.clock.day(), Session.db.rules["clock"]),
			Session.gs.clock.time_string()]


## The night (a sleep, a collapse or a knock-out) in the System dialog.
func show_night(night: Dictionary) -> void:
	var what := "You sleep."
	if night["knocked_out"]:
		what = "Everything goes dark."
	elif night["collapsed"]:
		what = "You collapse."
	_m.hud.add_lines([what])
	Session.changed()
	_m.dialog.open(SystemMessages.pages(night, Session.gs, Session.db), Session.gs, Session.db)


## The System dialog closed: the day line, then the autosave.
func on_dialog_closed() -> void:
	_m.hud.add_lines([day_line()])
	if Session.autosave() != OK:
		_m.hud.add_lines(["Autosave failed."])
	Session.changed()

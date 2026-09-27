## Plays music, sound effects and UI sounds (autoload "Audio", M12,
## ADR 0019). Buses come from res://default_bus_layout.tres: Music,
## Ambience, SFX and UI under Master.
## - What plays comes from data/audio.json (AudioDb). A cue names a sound
##   with one or more variant files. Variants play in a fixed round-robin
##   order and the pitch changes by a fixed table, so there is no randomness
##   (rule 3).
## - Music cross-fades: the new track fades in while the old one fades out.
## - Volumes are the player's settings (AudioSettings, user://settings.cfg).
## - A missing cue or file is silent and warns once.
## - Every button in the game ticks when the keys move the focus to it and
##   plays the "confirm" UI cue when pressed ("back" for a Back or Cancel
##   button).
## Presentation only: never reads or changes GameState.
extends Node

## Effect players that can sound at the same time.
const POOL_SIZE := 8
## The pitch of the n-th play of a cue is PITCH[n % size]. UI sounds keep
## their pitch.
const PITCH := [1.0, 1.04, 0.97, 1.02, 0.95, 1.01]
## Seconds of a music cross-fade.
const FADE := 1.5
## A fading track starts or ends at this volume.
const SILENT_DB := -60.0

var db: AudioDb
var settings: AudioSettings
## Tests point this at a test file.
var settings_path := AudioSettings.PATH
## How many times each cue has played (picks the variant and the pitch).
var plays := {}
## The track playing now ("" = none).
var track := ""
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _ui: AudioStreamPlayer
## Two music players; `_active` is the one playing `track`.
var _music: Array[AudioStreamPlayer] = []
var _active := 0
var _fade: Tween
var _warned := {}


func _ready() -> void:
	for i in POOL_SIZE:
		_pool.append(_player("SFX"))
	_ui = _player("UI")
	_music = [_player("Music"), _player("Music")]
	db = AudioDb.load_file()
	for e in db.validate():
		_warn("audio.json: " + e)
	load_settings()
	get_tree().node_added.connect(_on_node_added)


func _player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


func load_settings() -> void:
	settings = AudioSettings.load_file(settings_path)
	settings.apply()


## Sets one bus's volume (0..1), applies it and saves the settings.
func set_volume(bus: String, linear: float) -> void:
	settings.set_volume(bus, linear)
	settings.apply()
	settings.save(settings_path)


func set_muted(on: bool) -> void:
	settings.muted = on
	settings.apply()
	settings.save(settings_path)


func _on_node_added(node: Node) -> void:
	var b := node as BaseButton
	if b == null:
		return
	b.focus_entered.connect(func() -> void:
		if Input.is_anything_pressed():  # moved by keys, not by a menu opening
			play_key("ui", "move"))
	b.pressed.connect(func() -> void:
		play_key("ui", "back" if is_back(b) else "confirm"))


static func is_back(b: BaseButton) -> bool:
	var words := [String(b.name).to_lower()]
	if b is Button:
		words.append((b as Button).text.to_lower())
	return words.has("back") or words.has("cancel")


## Plays each cue in `cues` ("" is skipped).
func play_cues(cues: Array) -> void:
	for c: String in cues:
		if c != "":
			play(c)


## Plays the cue that `section` maps `key` to (for example "ui", "move").
func play_key(section: String, key: String) -> bool:
	var c := db.cue(section, key)
	return c != "" and play(c)


## Plays one cue. False if it is unknown or its file is missing.
func play(cue: String) -> bool:
	var def := db.sound(cue)
	if def.is_empty():
		_warn("unknown sound cue: " + cue)
		return false
	var n := int(plays.get(cue, 0))
	plays[cue] = n + 1
	var stream := _load(AudioDb.path_of(variant(def["files"], n)))
	if stream == null:
		return false
	var ui := String(def["bus"]) == "UI"
	var p := _ui if ui else _pool[_next]
	if not ui:
		_next = (_next + 1) % _pool.size()
	p.bus = String(def["bus"])
	p.stream = stream
	p.volume_db = float(def.get("volume_db", 0.0))
	p.pitch_scale = 1.0 if ui else pitch(n)
	p.play()
	return true


## Cross-fades to the track `id` over `fade` seconds ("" fades the music
## out; 0 switches at once). The same track keeps playing.
func music(id: String, fade: float = FADE) -> void:
	if id == track:
		return
	var stream: AudioStream = null
	var target := 0.0
	if id != "":
		var t := db.track(id)
		if t.is_empty():
			_warn("unknown music track: " + id)
		else:
			stream = _load(AudioDb.path_of(String(t["file"])))
			target = float(t.get("volume_db", 0.0))
	track = id
	if _fade != null:
		_fade.kill()
		_fade = null
	var old := _music[_active]
	_active = 1 - _active
	var next := _music[_active]
	next.stop()
	if stream != null:
		next.stream = stream
		next.volume_db = SILENT_DB if fade > 0.0 else target
		next.play()
	if fade <= 0.0:
		old.stop()
		return
	_fade = create_tween().set_parallel(true)
	_fade.tween_property(old, "volume_db", SILENT_DB, fade)
	if stream != null:
		_fade.tween_property(next, "volume_db", target, fade)
	_fade.chain().tween_callback(old.stop)


## The player of the track playing now.
func music_player() -> AudioStreamPlayer:
	return _music[_active]


## The file for the n-th play of a cue with these variants.
static func variant(files: Array, n: int) -> String:
	return String(files[n % files.size()])


static func pitch(n: int) -> float:
	return PITCH[n % PITCH.size()]


func _load(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		_warn("missing audio file: " + path)
		return null
	return load(path) as AudioStream


func _warn(text: String) -> void:
	if not _warned.has(text):
		_warned[text] = true
		push_warning(text)

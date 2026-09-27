## Plays music, sound effects and UI sounds (autoload "Audio", M12,
## ADR 0019). Buses come from res://default_bus_layout.tres: Music,
## Ambience, SFX and UI under Master.
## - A cue names a sound with one or more variant files. Variants play in a
##   fixed round-robin order and the pitch changes by a fixed table, so
##   there is no randomness (rule 3).
## - A missing cue or file is silent and warns once.
## - Every button in the game ticks when the keys move the focus to it and
##   plays ui_ok when pressed (ui_back for a "Back" or "Cancel" button).
## Presentation only: never reads or changes GameState.
## M12.0 spike: CUES and TRACKS are temporary; M12.1 moves them to
## data/audio.json (rule 4).
extends Node

const SFX_DIR := "res://assets/audio/sfx/"
const UI_DIR := "res://assets/audio/ui/"
const MUSIC_DIR := "res://assets/audio/music/"
## Effect players that can sound at the same time.
const POOL_SIZE := 8
## The pitch of the n-th play of a cue is PITCH[n % size]. UI sounds keep
## their pitch.
const PITCH := [1.0, 1.04, 0.97, 1.02, 0.95, 1.01]

const CUES := {
	"step_grass": {"bus": "SFX", "volume_db": -12.0, "files": [
		"footstep_grass_000.ogg", "footstep_grass_001.ogg", "footstep_grass_002.ogg",
		"footstep_grass_003.ogg", "footstep_grass_004.ogg"]},
	"step_wood": {"bus": "SFX", "volume_db": -12.0, "files": [
		"footstep_wood_000.ogg", "footstep_wood_001.ogg", "footstep_wood_002.ogg",
		"footstep_wood_003.ogg", "footstep_wood_004.ogg"]},
	"step_snow": {"bus": "SFX", "volume_db": -10.0, "files": [
		"footstep_snow_000.ogg", "footstep_snow_001.ogg", "footstep_snow_002.ogg",
		"footstep_snow_003.ogg", "footstep_snow_004.ogg"]},
	"step_stone": {"bus": "SFX", "volume_db": -12.0, "files": [
		"footstep_concrete_000.ogg", "footstep_concrete_001.ogg", "footstep_concrete_002.ogg",
		"footstep_concrete_003.ogg", "footstep_concrete_004.ogg"]},
	"hit": {"bus": "SFX", "volume_db": -4.0, "files": [
		"impactPunch_medium_000.ogg", "impactPunch_medium_001.ogg", "impactPunch_medium_002.ogg",
		"impactPunch_medium_003.ogg", "impactPunch_medium_004.ogg"]},
	"ui_move": {"bus": "UI", "volume_db": -14.0, "files": ["ui_move.wav"]},
	"ui_ok": {"bus": "UI", "volume_db": -8.0, "files": ["ui_ok.wav"]},
	"ui_back": {"bus": "UI", "volume_db": -8.0, "files": ["ui_back.wav"]},
	"chime": {"bus": "UI", "volume_db": -8.0, "files": ["chime.wav"]},
}
const TRACKS := {
	"title": {"file": "old_tower_inn.mp3", "volume_db": -10.0},
}

## How many times each cue has played (picks the variant and the pitch).
var plays := {}
## The track playing now ("" = none).
var track := ""
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _ui: AudioStreamPlayer
var _music: AudioStreamPlayer
var _warned := {}


func _ready() -> void:
	for i in POOL_SIZE:
		_pool.append(_player("SFX"))
	_ui = _player("UI")
	_music = _player("Music")
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	var b := node as BaseButton
	if b == null:
		return
	b.focus_entered.connect(func() -> void:
		if Input.is_anything_pressed():  # moved by keys, not by a menu opening
			play("ui_move"))
	b.pressed.connect(func() -> void:
		play("ui_back" if is_back(b) else "ui_ok"))


static func is_back(b: BaseButton) -> bool:
	var words := [String(b.name).to_lower()]
	if b is Button:
		words.append((b as Button).text.to_lower())
	return words.has("back") or words.has("cancel")


func _player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


## Plays each cue in `cues` ("" is skipped).
func play_cues(cues: Array) -> void:
	for c: String in cues:
		if c != "":
			play(c)


## Plays one cue. False if it is unknown or its file is missing.
func play(cue: String) -> bool:
	if not CUES.has(cue):
		_warn("unknown sound cue: " + cue)
		return false
	var def: Dictionary = CUES[cue]
	var n := int(plays.get(cue, 0))
	plays[cue] = n + 1
	var ui := String(def["bus"]) == "UI"
	var path := (UI_DIR if ui else SFX_DIR) + String(variant(def["files"], n))
	var stream := _load(path)
	if stream == null:
		return false
	var p := _ui if ui else _pool[_next]
	if not ui:
		_next = (_next + 1) % _pool.size()
	p.stream = stream
	p.volume_db = float(def.get("volume_db", 0.0))
	p.pitch_scale = 1.0 if ui else pitch(n)
	p.play()
	return true


## Starts `id` from TRACKS, looping ("" stops the music). The same track
## keeps playing.
func music(id: String) -> void:
	if id == track:
		return
	track = id
	_music.stop()
	if id == "":
		return
	if not TRACKS.has(id):
		_warn("unknown music track: " + id)
		return
	var stream := _load(MUSIC_DIR + String(TRACKS[id]["file"]))
	if stream == null:
		return
	_music.stream = stream
	_music.volume_db = float(TRACKS[id].get("volume_db", 0.0))
	_music.play()


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

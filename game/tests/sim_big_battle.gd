extends GutTest
## M7.B (ADR 0013): a big toy battle in the ToyCombat arena: 40 Goblins in
## 4 waves against the player, 3 NPC allies pulled in from other areas and
## 3 helpers. Checks that it plays out the same with the same seed and
## stays fast (time per command, printed).

const EV := "e.big"
## Generous: a command here takes a few ms on a normal PC.
const MAX_MS_PER_COMMAND := 60.0

var _db: DataDb


func before_each() -> void:
	var foes: Array = []
	for y in range(0, 8):
		foes.append({"enemy": "goblin", "pos": [12, y]})
	var waves := [
		{"after_seconds": 30, "from": [13, 4], "foes": _goblins(10), "allies": ["guard", "baker", "farmer"]},
		{"after_seconds": 60, "from": [13, 4], "foes": _goblins(10), "helpers": ["hound", "hound", "hound"]},
		{"after_seconds": 90, "from": [13, 4], "foes": _goblins(12)},
	]
	var events := {EV: ToyCanon.event(1, 2, {
		"stage": {"area": "arena", "hours": [6, 22], "foes": foes, "waves": waves}})}
	_db = ToyNpcs.combat_db(events)
	var areas := ToyMaps.areas()
	areas["arena"] = ToyMaps.area("arena", "toy_field", ToyCombat.ARENA, {}, [
		{"at": [0, 8], "to": "town", "arrive": [1, 1], "minutes": 0},
	], [])
	_db.maps = MapDb.from_dicts(ToyMaps.tiles(), areas)
	_db.maps.validate(_db)
	var enemies := ToyCombat.enemies()
	enemies["goblin"]["lose_radius"] = 99
	enemies["goblin"]["chase_turns"] = 999
	enemies["goblin"]["flee_below"] = 0.0
	enemies["hound"] = (enemies["goblin"] as Dictionary).duplicate(true)
	enemies["hound"]["name"] = "Hound"
	_db.combat = CombatDb.from_dicts(enemies, ToyCombat.items())
	_db.combat.validate(_db)
	_db.rules["combat"]["hp_base"] = 5000  # the player outlasts the battle


func _goblins(n: int) -> Array:
	var out := []
	for i in n:
		out.append("goblin")
	return out


## The player's turn: hit a foe side by side, else wait.
func _turn(gs: GameState) -> void:
	for dir: String in ["n", "e", "s", "w"]:
		var id := gs.combat.at("arena", gs.player.pos() + (PlayerState.DIRS[dir] as Vector2i))
		if id != "" and gs.combat.monsters[id]["state"] == CombatState.HOSTILE:
			Commands.attack(gs, _db, dir)
			return
	Commands.wait(gs, _db, 6)


## Plays up to `commands` player turns in the arena. Returns {"gs", "ms", "done", "allies", "helpers"}.
func _battle(seed_value: int, commands: int) -> Dictionary:
	var gs := ToyNpcs.new_game(_db, seed_value)
	gs.player.place("arena", Vector2i(2, 4))
	Commands.wait(gs, _db, 6)
	var allies := 0
	var helpers := 0
	var start := Time.get_ticks_usec()
	var n := 0
	for i in commands:
		if not gs.combat.has_fight():
			break
		_turn(gs)
		n += 1
		allies = maxi(allies, gs.npcs.in_area("arena").size())
		helpers = maxi(helpers, gs.combat.in_state(CombatState.ALLY).size())
	var ms := (Time.get_ticks_usec() - start) / 1000.0 / maxi(n, 1)
	return {"gs": gs, "ms": ms, "done": not gs.combat.has_fight(), "allies": allies, "helpers": helpers}


func test_the_toy_battle_data_is_valid() -> void:
	assert_eq(_db.canon.errors, [] as Array[String])
	assert_eq(_db.combat.errors, [] as Array[String])


func test_forty_foes_with_allies_and_helpers_stay_fast_and_the_same() -> void:
	var a := _battle(7, 400)
	var b := _battle(7, 400)
	gut.p("big battle: %.2f ms per command, done %s" % [a["ms"], a["done"]])
	assert_eq((a["gs"] as GameState).to_json(), (b["gs"] as GameState).to_json(), "same seed, same battle")
	assert_eq(a["allies"], 3, "three allies pulled in")
	assert_eq(a["helpers"], 3, "three helpers")
	assert_true(a["done"], "the battle ends")
	assert_lt(a["ms"], MAX_MS_PER_COMMAND)

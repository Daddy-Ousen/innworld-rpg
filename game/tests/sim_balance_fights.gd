extends GutTest
## M14.8 probe (ADR 0021): how hard are the fights a player meets, with the real
## hit rules and nothing frozen? Two parts.
## 1. Duels: the player (bare fists, a level-0 and a level-5 worker) against the
##    everyday spawns of the Floodplains: a Goblin pack, a Razorbeak, a Rock Crab.
##    Logs win, HP left and turns; loose asserts.
## 2. The Goblin raid (day 21, 40 Goblins): the player holds Erin's side and hits
##    what comes next to them. Logged only, no win assert: with the real rules the
##    raid is not winnable by one player (ADR 0021, M14.8): Erin falls in three
##    turns and the max_on_map gate keeps Klbkch outside.
## Set BALANCE_LOG to a file path to get the table.

const AREA := "floodplains_south"
const SPOT := Vector2i(10, 10)
const INN_SPOT := Vector2i(6, 8)
const SEEDS := [1, 2, 3]
## Total class level at day 21 (see sim_balance_progress: 5 to 6).
const LEVEL := 5
const LOW_HP := 8
const MAX_TURNS := 400

var _db: DataDb


func before_all() -> void:
	_db = DataDb.load_dir()


## A new game with `level` levels of [Innkeeper] (only the HP bonus counts) and full HP.
func _game(seed_: int, level: int) -> GameState:
	var gs := GameState.new_game(seed_, _db)
	if level > 0:
		gs.progression.classes["innkeeper"] = {"level": level, "xp": 0, "day": 1}
	Combat.set_hp(gs, _db, 9999)
	return gs


## Attacks a hostile next to the player. False when there is none.
func _hit_adjacent(gs: GameState) -> bool:
	for dir: String in PlayerState.DIRS:
		var id := gs.combat.at(gs.player.area, gs.player.pos() + (PlayerState.DIRS[dir] as Vector2i))
		if id != "" and gs.combat.monsters[id]["state"] == CombatState.HOSTILE:
			Commands.attack(gs, _db, dir)
			return true
	return false


## The player against `count` of `enemy`, placed next to them. Returns
## {"won", "hp", "max_hp", "turns"}.
func _duel(seed_: int, level: int, enemy: String, count: int) -> Dictionary:
	var gs := _game(seed_, level)
	gs.player.place(AREA, SPOT)
	Commands.settle(gs, _db)
	var placed := 0
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if placed < count and _db.maps.is_walkable(AREA, SPOT + d):
			Combat.add_monster(gs, _db, enemy, SPOT + d, CombatState.HOSTILE, "", "duel")
			placed += 1
	var turns := 0
	while gs.combat.has_fight() and turns < MAX_TURNS and not Combat.is_down(gs):
		if Combat.hp(gs, _db) <= LOW_HP:
			Commands.block(gs, _db)
		elif not _hit_adjacent(gs):
			Commands.wait(gs, _db, 6)
		turns += 1
	return {"won": not gs.combat.has_fight() and not Combat.is_down(gs), "hp": Combat.hp(gs, _db),
			"max_hp": Stats.max_hp(gs, _db), "turns": turns}


## The raid on day 21: waits for the raiders at Erin's side, then holds and hits.
## Returns {"down", "turns"}.
func _raid(seed_: int, level: int) -> Dictionary:
	var gs := GameState.new_game(seed_, _db)
	ToyCanon.sleep_through(gs, _db, 20)
	gs.economy.hunger = 0  # the skipped nights were not hungry ones
	if level > 0:
		gs.progression.classes["innkeeper"] = {"level": level, "xp": 0, "day": 1}
	Combat.set_hp(gs, _db, 9999)
	gs.player.place("inn_interior", INN_SPOT)
	Commands.settle(gs, _db)
	for i in 480:
		if not gs.world.staged.is_empty():
			break
		Commands.wait(gs, _db, 60)
	var turns := 0
	while gs.combat.has_fight() and turns < MAX_TURNS and not Combat.is_down(gs):
		if Combat.hp(gs, _db) <= LOW_HP or not _hit_adjacent(gs):
			Commands.block(gs, _db)
		turns += 1
	return {"down": Combat.is_down(gs), "turns": turns}


func test_everyday_fights_are_winnable_at_level_five() -> void:
	var lines: Array[String] = []
	var cases := [["goblin_grunt", 3], ["goblin_grunt", 2], ["razorbeak", 1], ["goblin_grunt", 1], ["rock_crab", 1]]
	for c: Array in cases:
		for level: int in [0, LEVEL]:
			var wins := 0
			for s: int in SEEDS:
				var r := _duel(s, level, c[0], c[1])
				lines.append("duel %d x %s, level %d, seed %d: won %s, hp %d/%d, turns %d" % [c[1], c[0],
						level, s, r["won"], r["hp"], r["max_hp"], r["turns"]])
				wins += 1 if r["won"] else 0
			# A pack of three Goblins or one Razorbeak is an everyday fight.
			if level == LEVEL and c[0] != "rock_crab":
				assert_eq(wins, SEEDS.size(), "level %d beats %d x %s on every seed" % [level, c[1], c[0]])
	_write(lines, false)


func test_the_raid_is_logged_and_levels_help() -> void:
	var lines: Array[String] = []
	for s: int in SEEDS:
		var a := _raid(s, 0)
		var b := _raid(s, LEVEL)
		lines.append("raid seed %d: level 0 down %s after %d turns; level %d down %s after %d turns" % [s,
				a["down"], a["turns"], LEVEL, b["down"], b["turns"]])
		assert_gte(int(b["turns"]), int(a["turns"]), "seed %d: the higher level lasts at least as long" % s)
	_write(lines, true)


func _write(lines: Array[String], append: bool) -> void:
	gut.p("\n".join(lines))
	var path := OS.get_environment("BALANCE_LOG")
	if path == "":
		return
	var f := FileAccess.open(path, FileAccess.READ_WRITE if append and FileAccess.file_exists(path) \
			else FileAccess.WRITE)
	if append:
		f.seek_end()
	f.store_string("\n".join(lines) + "\n")

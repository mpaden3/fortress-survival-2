class_name UnitSystem
extends RefCounted
## Trained player units: training at buildings, orders, and their own behaviour.
##
## Fighters attack enemies in range. Idle, they guard their spot: they chase enemies they see
## but not farther than their leash from it, then walk back. Attack-move fights on the way;
## move ignores enemies; hold never moves. Repairmen, idle, walk to the nearest damaged own
## building they see and repair it for free. Units are few, so they're plain entities.

## Ticks between path recomputations while chasing or approaching something.
const REPATH_TICKS := 10
## How close (cells) a repairman must be to a building's edge to repair it.
const REPAIR_REACH := 1.2
## Idle units farther than this (cells) from their guard spot walk back to it.
const HOME_SLACK := 1.5

## Microseconds the last update took.
var update_usec := 0

var _units: Array[UnitState] = []
var _training: Array[BuildingState] = []


func register(world: World) -> void:
	world.register_command(Commands.TRAIN_UNIT, _train_command)
	world.register_command(Commands.ORDER_UNITS, _order_command)
	world.entity_removed.connect(_on_entity_removed)


func living() -> Array[UnitState]:
	return _units


func any_in_rect(rect: Rect2i) -> bool:
	for unit in _units:
		if rect.has_point(unit.cell()):
			return true
	return false


## Creates a unit for `player_id` standing at `position` (cell units).
func spawn(world: World, player_id: int, def_id: StringName, position: Vector2) -> UnitState:
	var unit := UnitState.new()
	unit.owner = player_id
	unit.def = world.defs.unit(def_id)
	unit.position = position
	unit.previous_position = position
	unit.home = position
	unit.hp = unit.def.max_hp
	world.add_entity(unit)
	_units.append(unit)
	if DebugLog.on(&"units"):
		DebugLog.event(&"units", {"unit_spawned": unit.id, "def": def_id, "player": player_id, "pos": position})
	return unit


## Damages a unit; returns true if that killed it (it's removed immediately).
func damage(world: World, unit: UnitState, amount: float) -> bool:
	if not world.entities.has(unit.id):
		return false
	unit.hp -= amount
	if unit.hp > 0.0:
		return false
	if DebugLog.on(&"combat"):
		DebugLog.event(&"combat", {"unit_killed": unit.id, "def": unit.def.id, "pos": unit.position})
	world.events.add(SimEvents.Kind.UNIT_KILLED, unit.position, unit.def.id, unit.id)
	world.remove_entity(unit.id)
	return true


func update(world: World) -> void:
	var started := Time.get_ticks_usec()
	_train(world)
	world.pathing.paths.sync(world)
	world.enemies.begin_batch()
	for unit in _units:
		unit.previous_position = unit.position
		if unit.attack_cooldown > 0:
			unit.attack_cooldown -= 1
		_act(world, unit)
	world.enemies.end_batch()
	_separate(world)
	update_usec = Time.get_ticks_usec() - started


# --- Training -------------------------------------------------------------------------------

func _train_command(world: World, command: Dictionary) -> String:
	var building := world.entities.get(command["building"]) as BuildingState
	if building == null:
		return "unknown_building"
	if building.owner != command["player"]:
		return "not_owner"
	var def := world.defs.unit(command["def"])
	if def == null or not building.def.trains.has(def.id):
		return "cannot_train"
	if building.constructing:
		return "not_built"
	if building.train_queue.size() >= world.defs.rules.max_train_queue:
		return "queue_full"
	var player := world.players[building.owner]
	if player.resource < def.cost:
		return "not_enough_resource"
	player.resource -= def.cost
	building.train_queue.append(def.id)
	if not _training.has(building):
		_training.append(building)
	if DebugLog.on(&"build"):
		DebugLog.event(&"build", {"train_queued": def.id, "at": building.id, "queue": building.train_queue.size(),
			"resource_left": player.resource})
	return ""


func _train(world: World) -> void:
	for i in range(_training.size() - 1, -1, -1):
		var building := _training[i]
		if building.upgrading_to != null:
			continue  # paused while upgrading
		var def := world.defs.unit(building.train_queue[0])
		if building.train_progress < def.train_ticks():
			building.train_progress += 1
		if building.train_progress < def.train_ticks():
			continue
		# Done: step out next to the building (waits if it's boxed in).
		var exit := GridPaths.free_cell_around(world, building.rect, building.centre() + Vector2(0.0, building.rect.size.y))
		if exit.x < 0:
			continue
		spawn(world, building.owner, def.id, Vector2(exit) + Vector2(0.5, 0.5))
		building.train_queue.pop_front()
		building.train_progress = 0
		if building.train_queue.is_empty():
			_training.remove_at(i)


# --- Orders ---------------------------------------------------------------------------------

func _order_command(world: World, command: Dictionary) -> String:
	var kind: String = command["order"]
	if not kind in ["move", "attack_move", "stop", "hold"]:
		return "unknown_order"
	var ordered := 0
	for unit_id: int in command["units"]:
		var unit := world.entities.get(unit_id) as UnitState
		if unit == null or unit.owner != command["player"]:
			continue
		ordered += 1
		match kind:
			"stop", "hold":
				unit.orders.clear()
				unit.path.clear()
				unit.walk_goal = Vector2i(-1, -1)
				unit.target_enemy = 0
				unit.target_building = 0
				unit.holding = kind == "hold"
				unit.home = unit.position
			_:
				if not command.get("queue", false):
					unit.orders.clear()
					unit.path.clear()
					unit.walk_goal = Vector2i(-1, -1)
					unit.target_enemy = 0
					unit.target_building = 0
				unit.holding = false
				unit.orders.append({"kind": kind, "cell": command["cell"]})
	return "" if ordered > 0 else "no_units"


# --- Behaviour ------------------------------------------------------------------------------

func _act(world: World, unit: UnitState) -> void:
	var order: Dictionary = unit.orders[0] if not unit.orders.is_empty() else {}
	var kind: String = order.get("kind", "")
	if kind == "move":
		if _walk_to(world, unit, order["cell"]):
			_finish(unit)
		return
	if unit.def.is_fighter() and _fight(world, unit, kind == ""):
		return
	if kind == "attack_move":
		if _walk_to(world, unit, order["cell"]):
			_finish(unit)
		return
	if unit.holding:
		return
	if unit.def.is_repairer() and _repair(world, unit):
		return
	if unit.position.distance_to(unit.home) > HOME_SLACK:
		_walk_to(world, unit, Vector2i(floori(unit.home.x), floori(unit.home.y)))


## Engages an enemy: attacks it in range, otherwise chases it (unless holding). Returns false
## if there's nothing to fight. `guarding` = idle: only enemies within the leash of home.
func _fight(world: World, unit: UnitState, guarding: bool) -> bool:
	var enemies := world.enemies
	var def := unit.def
	var leash := def.leash_range
	var index := enemies.index_of(unit.target_enemy)
	if not enemies.is_alive(index) or (guarding and enemies.positions[index].distance_to(unit.home) > leash) \
			or (unit.holding and enemies.positions[index].distance_to(unit.position) > def.attack_range):
		index = -1
		unit.target_enemy = 0
	if index < 0:
		index = enemies.nearest_in_range(unit.position, def.attack_range if unit.holding else def.sight_range)
		if index >= 0 and guarding and enemies.positions[index].distance_to(unit.home) > leash:
			index = -1
		if index < 0:
			return false
		unit.target_enemy = enemies.ids[index]
		_halt(unit)
	var target_pos := enemies.positions[index]
	if unit.position.distance_to(target_pos) <= def.attack_range:
		_halt(unit)
		if unit.attack_cooldown == 0:
			unit.attack_cooldown = def.cooldown_ticks()
			var amount := def.attack_damage * world.defs.damage_vs_enemies(def.damage_type)[enemies.types[index]]
			var enemy_def := world.defs.enemy_list[enemies.types[index]]
			world.events.add(SimEvents.Kind.UNIT_ATTACK, target_pos, def.id, unit.id)
			if DebugLog.on(&"combat"):
				DebugLog.event(&"combat", {"unit": unit.id, "hits_enemy": unit.target_enemy, "damage": amount})
			if enemies.damage(index, amount):
				world.events.add(SimEvents.Kind.ENEMY_KILLED, target_pos, enemy_def.id, unit.target_enemy)
		return true
	if unit.holding:
		return true
	_chase(world, unit, Vector2i(floori(target_pos.x), floori(target_pos.y)))
	return true


## Idle repairman: works on the nearest damaged own building in sight. Returns false if none.
func _repair(world: World, unit: UnitState) -> bool:
	var building := world.entities.get(unit.target_building) as BuildingState
	if building == null or building.constructing or building.hp >= building.def.max_hp:
		building = _damaged_building_near(world, unit)
		unit.target_building = building.id if building else 0
		unit.repair_goal = Vector2i(-1, -1)
		_halt(unit)
		if building == null:
			return false
	if GridPaths.distance_to_rect(unit.position, building.rect) <= REPAIR_REACH:
		_halt(unit)
		unit.repair_carry += unit.def.repair_rate / SimConstants.TICK_RATE
		var whole := floorf(unit.repair_carry)
		if whole >= 1.0:
			world.buildings.repair(building, whole)
			unit.repair_carry -= whole
		return true
	var paths := world.pathing.paths
	if unit.repair_goal_version != paths.version or unit.repair_goal.x < 0:
		unit.repair_goal = paths.reachable_cell_around(world, building.rect, unit.position)
		unit.repair_goal_version = paths.version
	if unit.repair_goal.x < 0:
		unit.unreachable_building = building.id
		unit.unreachable_version = paths.version
		unit.target_building = 0
		return false
	_walk_to(world, unit, unit.repair_goal)
	return true


func _damaged_building_near(world: World, unit: UnitState) -> BuildingState:
	var best: BuildingState = null
	var best_distance := unit.def.sight_range
	for entity: SimEntity in world.entities.values():
		var building := entity as BuildingState
		if building == null or building.owner != unit.owner or building.constructing \
				or building.hp >= building.def.max_hp:
			continue
		if building.id == unit.unreachable_building and unit.unreachable_version == world.pathing.paths.version:
			continue
		var distance := GridPaths.distance_to_rect(unit.position, building.rect)
		if distance <= best_distance:
			best_distance = distance
			best = building
	return best


## Walks toward `cell`, re-pathing when the goal or the walkable grid changed. Returns true
## once the path is used up (there, or as close as it gets).
func _walk_to(world: World, unit: UnitState, cell: Vector2i) -> bool:
	var paths := world.pathing.paths
	# Also re-path if the path was used up or cleared short of the goal (throttled, in case
	# the goal can't be reached and the path keeps ending early).
	var short := unit.path.is_empty() and unit.cell() != cell and world.tick >= unit.repath_tick
	if unit.walk_goal != cell or unit.walk_version != paths.version or short:
		unit.walk_goal = cell
		unit.walk_version = paths.version
		unit.path = paths.find_path(world, unit.cell(), cell)
		unit.repath_tick = world.tick + REPATH_TICKS
	return GridPaths.walk(unit, _step(unit))


## Follows something that moves or was just picked: a fresh path every REPATH_TICKS.
func _chase(world: World, unit: UnitState, cell: Vector2i) -> void:
	if unit.walk_goal != Vector2i(-1, -1) or unit.path.is_empty() or world.tick >= unit.repath_tick:
		unit.walk_goal = Vector2i(-1, -1)
		unit.path = world.pathing.paths.find_path(world, unit.cell(), cell)
		unit.repath_tick = world.tick + REPATH_TICKS
	GridPaths.walk(unit, _step(unit))


## Stops walking; the next walk computes a fresh path.
func _halt(unit: UnitState) -> void:
	unit.path.clear()
	unit.walk_goal = Vector2i(-1, -1)


func _finish(unit: UnitState) -> void:
	unit.orders.pop_front()
	unit.path.clear()
	unit.walk_goal = Vector2i(-1, -1)
	unit.home = unit.position


func _step(unit: UnitState) -> float:
	return unit.def.speed / SimConstants.CELL_SIZE / SimConstants.TICK_RATE


## Pushes overlapping units apart (few units: pairwise), never into blocked cells.
func _separate(world: World) -> void:
	var blocked := world.grid.blocked
	var width := world.map.size.x
	for a in _units.size():
		for b in range(a + 1, _units.size()):
			var ua := _units[a]
			var ub := _units[b]
			var min_dist := (ua.def.radius + ub.def.radius) / SimConstants.CELL_SIZE
			var offset := ua.position - ub.position
			var dist_sq := offset.length_squared()
			if dist_sq >= min_dist * min_dist:
				continue
			var push := Vector2(0.01, 0.0) if dist_sq < 0.000001 else offset * ((min_dist - sqrt(dist_sq)) / sqrt(dist_sq) * 0.5)
			_nudge(ua, push, blocked, width)
			_nudge(ub, -push, blocked, width)


static func _nudge(unit: UnitState, push: Vector2, blocked: PackedByteArray, width: int) -> void:
	var moved := unit.position + push
	var cell := Vector2i(floori(moved.x), floori(moved.y))
	if cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y * width + cell.x < blocked.size() \
			and blocked[cell.y * width + cell.x] == 0:
		unit.position = moved


func _on_entity_removed(entity: SimEntity) -> void:
	if entity is UnitState:
		_units.erase(entity)
	elif entity is BuildingState:
		_training.erase(entity)

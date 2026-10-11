class_name SurvivorSystem
extends RefCounted
## Survivors: orders (move, build, repair), A* movement, Blink, Haste, damage and defeat.
## Each Survivor is a hunt target: its flow field follows it as it moves (throttled).

## A hunt field follows a moving Survivor at most this often: a rebuild costs tens of ms on
## the full map, and enemies close to the Survivor chase it directly anyway.
const RETARGET_TICKS := 15

var _by_player: Dictionary[int, SurvivorState] = {}
var _astar := AStarGrid2D.new()
var _astar_ready := false
var _dirty_rects: Array[Rect2i] = []
var _field_cell: Dictionary[int, Vector2i] = {}
var _last_retarget: Dictionary[int, int] = {}
var _repair_carry: Dictionary[int, float] = {}


func register(world: World) -> void:
	world.register_command(Commands.MOVE_SURVIVOR, _move)
	world.register_command(Commands.REPAIR, _repair)
	world.register_command(Commands.BLINK, _blink)
	world.register_command(Commands.HASTE, _haste)
	world.entity_added.connect(_on_entity_changed)
	world.entity_removed.connect(_on_entity_changed)


func spawn(world: World, player_id: int, cell: Vector2i) -> SurvivorState:
	var survivor := SurvivorState.new()
	survivor.owner = player_id
	survivor.def = world.defs.survivor
	survivor.position = Vector2(cell) + Vector2(0.5, 0.5)
	survivor.hp = survivor.def.max_hp
	world.add_entity(survivor)
	_by_player[player_id] = survivor
	_field_cell[player_id] = cell
	_last_retarget[player_id] = world.tick
	world.pathing.set_target(survivor.target_key(), [cell] as Array[Vector2i])
	if DebugLog.on(&"units"):
		DebugLog.event(&"units", {"survivor_spawned": survivor.id, "player": player_id, "cell": cell})
	return survivor


func survivor_of(player_id: int) -> SurvivorState:
	return _by_player.get(player_id)


func living() -> Array[SurvivorState]:
	var out: Array[SurvivorState] = []
	for survivor in _by_player.values():
		if survivor.alive:
			out.append(survivor)
	return out


func by_target_key(key: StringName) -> SurvivorState:
	for survivor in _by_player.values():
		if survivor.target_key() == key:
			return survivor
	return null


func any_in_rect(rect: Rect2i) -> bool:
	for survivor in _by_player.values():
		if survivor.alive and rect.has_point(survivor.cell()):
			return true
	return false


func order_build(survivor: SurvivorState, def_id: StringName, origin: Vector2i, queue: bool) -> void:
	_order(survivor, {"kind": "build", "def": def_id, "cell": origin}, queue)


## Damages a Survivor; returns true if that killed it (its player is defeated).
func damage(world: World, survivor: SurvivorState, amount: float) -> bool:
	if not survivor.alive:
		return false
	survivor.hp -= amount
	if survivor.hp > 0.0:
		return false
	survivor.hp = 0.0
	survivor.alive = false
	survivor.orders.clear()
	survivor.path.clear()
	world.pathing.remove_target(survivor.target_key())
	world.players[survivor.owner].alive = false
	if DebugLog.on(&"state"):
		DebugLog.event(&"state", {"survivor_died": survivor.id, "player": survivor.owner, "defeated": true})
	world.enemies.retarget_from(world, survivor.target_key())
	world.player_defeated.emit(survivor.owner)
	return true


func update(world: World) -> void:
	_sync_astar(world)
	for survivor in living():
		_work(world, survivor)
		_follow_with_field(world, survivor)


func _work(world: World, survivor: SurvivorState) -> void:
	if survivor.orders.is_empty():
		return
	var order := survivor.orders[0]
	match order["kind"]:
		"move":
			if _walk(world, survivor, order, order["cell"]):
				_finish(survivor)
		"build":
			var def := world.defs.building(order["def"])
			var rect := Rect2i(order["cell"], def.footprint)
			if _distance_to_rect(survivor.position, rect) <= survivor.def.work_reach:
				world.buildings.start_construction(world, survivor.owner, order["def"], order["cell"])
				_finish(survivor)
			elif not _approach(world, survivor, order, rect):
				_log_order_failed(survivor, order, "unreachable")
				_finish(survivor)
		"repair":
			var building := world.entities.get(order["building"]) as BuildingState
			if building == null or (not building.constructing and building.hp >= building.def.max_hp):
				_finish(survivor)
			elif _distance_to_rect(survivor.position, building.rect) <= survivor.def.work_reach:
				# HP is whole numbers; carry the fractional repair over to the next tick.
				var carry: float = _repair_carry.get(survivor.id, 0.0) + survivor.def.repair_rate / SimConstants.TICK_RATE
				var whole := floorf(carry)
				if whole >= 1.0:
					world.buildings.repair(building, whole)
					carry -= whole
				_repair_carry[survivor.id] = carry
				if building.constructing:
					_finish(survivor)
			elif not _approach(world, survivor, order, building.rect):
				_log_order_failed(survivor, order, "unreachable")
				_finish(survivor)


## Walks toward a free cell next to `rect`. Returns false if none is reachable.
func _approach(world: World, survivor: SurvivorState, order: Dictionary, rect: Rect2i) -> bool:
	if not order.has("goal"):
		var best := Vector2i(-1, -1)
		var best_distance := INF
		var ring := rect.grow(1)
		for z in range(ring.position.y, ring.end.y):
			for x in range(ring.position.x, ring.end.x):
				var cell := Vector2i(x, z)
				if rect.has_point(cell) or not _free(world, cell):
					continue
				var distance := survivor.position.distance_squared_to(Vector2(cell) + Vector2(0.5, 0.5))
				if distance < best_distance:
					best_distance = distance
					best = cell
		if best.x < 0:
			return false
		order["goal"] = best
	_walk(world, survivor, order, order["goal"])
	return true


## Follows a path to `goal`, computing it on demand. Returns true once there (or stuck).
func _walk(world: World, survivor: SurvivorState, order: Dictionary, goal: Vector2i) -> bool:
	if not order.get("pathed", false):
		order["pathed"] = true
		survivor.path.clear()
		var from := survivor.cell()
		var to := goal.clamp(Vector2i.ZERO, world.map.size - Vector2i.ONE)
		for cell in _astar.get_id_path(from, to, true):
			if cell != from:
				survivor.path.append(Vector2(cell) + Vector2(0.5, 0.5))
	var speed := survivor.def.speed
	if world.tick < survivor.haste_until_tick:
		speed *= survivor.def.haste_multiplier
	var step := speed / SimConstants.CELL_SIZE / SimConstants.TICK_RATE
	while step > 0.0 and not survivor.path.is_empty():
		var offset := survivor.path[0] - survivor.position
		var length := offset.length()
		if length <= step:
			survivor.position = survivor.path[0]
			survivor.path.remove_at(0)
			step -= length
		else:
			survivor.position += offset / length * step
			step = 0.0
	return survivor.path.is_empty()


## Moves this Survivor's hunt field to its current cell, at most every RETARGET_TICKS.
func _follow_with_field(world: World, survivor: SurvivorState) -> void:
	var cell := survivor.cell()
	if cell == _field_cell[survivor.owner] or world.tick - _last_retarget[survivor.owner] < RETARGET_TICKS:
		return
	_field_cell[survivor.owner] = cell
	_last_retarget[survivor.owner] = world.tick
	world.pathing.set_target(survivor.target_key(), [cell] as Array[Vector2i])


func _move(world: World, command: Dictionary) -> String:
	var survivor := _commandable(world, command)
	if survivor == null:
		return "no_survivor"
	_order(survivor, {"kind": "move", "cell": command["cell"]}, command.get("queue", false))
	return ""


func _repair(world: World, command: Dictionary) -> String:
	var survivor := _commandable(world, command)
	if survivor == null:
		return "no_survivor"
	var building := world.entities.get(command["building"]) as BuildingState
	if building == null:
		return "unknown_building"
	if building.owner != survivor.owner:
		return "not_owner"
	_order(survivor, {"kind": "repair", "building": building.id}, command.get("queue", false))
	return ""


func _blink(world: World, command: Dictionary) -> String:
	var survivor := _commandable(world, command)
	if survivor == null:
		return "no_survivor"
	if world.tick < survivor.blink_ready_tick:
		return "cooldown"
	var cell: Vector2i = command["cell"]
	var destination := Vector2(cell) + Vector2(0.5, 0.5)
	if survivor.position.distance_to(destination) > survivor.def.blink_range:
		return "out_of_range"
	if not _free(world, cell):
		return "blocked"
	if DebugLog.on(&"units"):
		DebugLog.event(&"units", {"blink": survivor.id, "from": survivor.position, "to": destination})
	survivor.position = destination
	survivor.orders.clear()
	survivor.path.clear()
	survivor.blink_ready_tick = world.tick + roundi(survivor.def.blink_cooldown * SimConstants.TICK_RATE)
	return ""


func _haste(world: World, command: Dictionary) -> String:
	var survivor := _commandable(world, command)
	if survivor == null:
		return "no_survivor"
	if world.tick < survivor.haste_ready_tick:
		return "cooldown"
	survivor.haste_until_tick = world.tick + roundi(survivor.def.haste_duration * SimConstants.TICK_RATE)
	survivor.haste_ready_tick = world.tick + roundi(survivor.def.haste_cooldown * SimConstants.TICK_RATE)
	if DebugLog.on(&"units"):
		DebugLog.event(&"units", {"haste": survivor.id, "until_tick": survivor.haste_until_tick})
	return ""


func _commandable(world: World, command: Dictionary) -> SurvivorState:
	var survivor := survivor_of(command["player"])
	return survivor if survivor and survivor.alive else null


func _order(survivor: SurvivorState, order: Dictionary, queue: bool) -> void:
	if not queue:
		survivor.orders.clear()
		survivor.path.clear()
	survivor.orders.append(order)


func _finish(survivor: SurvivorState) -> void:
	survivor.orders.pop_front()
	survivor.path.clear()


func _log_order_failed(survivor: SurvivorState, order: Dictionary, reason: String) -> void:
	if DebugLog.on(&"units"):
		DebugLog.event(&"units", {"survivor": survivor.id, "order_failed": order["kind"], "reason": reason})


func _free(world: World, cell: Vector2i) -> bool:
	return world.map.in_bounds(cell) and world.grid.blocked[cell.y * world.map.size.x + cell.x] == 0


static func _distance_to_rect(position: Vector2, rect: Rect2i) -> float:
	var closest := Vector2(clampf(position.x, rect.position.x, rect.end.x), clampf(position.y, rect.position.y, rect.end.y))
	return position.distance_to(closest)


## A* grid mirrors grid.blocked; buildings change it, so changed rects are re-synced.
func _sync_astar(world: World) -> void:
	if not _astar_ready:
		_astar.region = Rect2i(Vector2i.ZERO, world.map.size)
		_astar.cell_size = Vector2.ONE
		_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
		_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
		_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
		_astar.update()
		_dirty_rects = [Rect2i(Vector2i.ZERO, world.map.size)]
		_astar_ready = true
	if _dirty_rects.is_empty():
		return
	for rect in _dirty_rects:
		for z in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				_astar.set_point_solid(Vector2i(x, z), world.grid.blocked[z * world.map.size.x + x] != 0)
	_dirty_rects.clear()
	# Paths may now cross a new building or miss a shortcut: recompute them.
	for survivor in _by_player.values():
		if not survivor.orders.is_empty():
			survivor.orders[0].erase("pathed")
			survivor.orders[0].erase("goal")


func _on_entity_changed(entity: SimEntity) -> void:
	var building := entity as BuildingState
	if building:
		_dirty_rects.append(building.rect)

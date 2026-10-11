class_name DefenceBot
extends RefCounted
## A scripted player for balance runs (and later, stand-in co-op players). It plays only
## through commands, like a human: walks its Survivor into a plot, walls the plot's entrances,
## then spends its resource by a fixed priority list (repairs, mills, towers just behind the
## walls, a barracks and units, tower and wall upgrades). Deterministic.

## Ticks between decisions.
const THINK_TICKS := 15
## The Survivor gets a new order only while it has fewer than this queued.
const MAX_QUEUED := 2
## Repair buildings below this share of max HP.
const REPAIR_BELOW := 0.6
## Towers stand at least this far (cells) behind the entrance walls.
const TOWER_SETBACK := 2

var player_id := 0
var plot: MapLayout.Plot
var _area := {}
var _entrance_cells: Array[Vector2i] = []
## Cells of the plot ordered from the entrances inward (walking distance from them).
var _inner_order: Array[Vector2i] = []
var _depth := {}
var _branch := 0


func _init(world: World, bot_player: int, plot_id := "") -> void:
	player_id = bot_player
	plot = world.map.get_plot(plot_id) if plot_id else _pick_plot(world)
	_area = MapAnalysis.area_cells(plot.rects)
	for entrance in MapAnalysis.entrances(world.map, plot.rects):
		for cell: Vector2i in entrance["cells"]:
			_entrance_cells.append(cell)
	_entrance_cells.sort()
	var distances := MapAnalysis.walk_distances(world.map, _entrance_cells)
	for cell: Vector2i in _area:
		var d := distances[cell.y * world.map.size.x + cell.x]
		if d >= 0 and world.map.is_buildable(cell):
			_depth[cell] = d
			_inner_order.append(cell)
	_inner_order.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return _depth[a] < _depth[b] if _depth[a] != _depth[b] else (a.y < b.y if a.y != b.y else a.x < b.x))


## Most defensible plot: enough room, the fewest entrance cells, then nearest the start.
static func _pick_plot(world: World) -> MapLayout.Plot:
	var best: MapLayout.Plot = null
	var best_score := INF
	for candidate in world.map.plots:
		if MapAnalysis.buildable_cells(world.map, candidate.rects) < 60:
			continue
		var width := 0
		for w in MapAnalysis.entrance_widths(world.map, candidate.rects):
			width += w
		var centre := Vector2(candidate.rects[0].get_center())
		var score := width * 100.0 + centre.distance_to(Vector2(world.map.start))
		if score < best_score:
			best_score = score
			best = candidate
	return best


func update(world: World) -> void:
	if world.tick % THINK_TICKS != 0:
		return
	var survivor := world.survivors.survivor_of(player_id)
	if survivor == null or not survivor.alive:
		return
	_command_units(world)
	if survivor.orders.size() >= MAX_QUEUED:
		return
	if not _area.has(survivor.cell()):
		if survivor.orders.is_empty():
			world.submit(Commands.move_survivor(player_id, _inner_order[_inner_order.size() - 1]))
		return
	if _repair(world, survivor) or _wall_entrances(world):
		return
	_spend(world)


func _repair(world: World, survivor: SurvivorState) -> bool:
	var worst: BuildingState = null
	for building in _own_buildings(world):
		if not building.constructing and building.hp < building.def.max_hp * REPAIR_BELOW \
				and (worst == null or building.hp * worst.def.max_hp < worst.hp * building.def.max_hp):
			worst = building
	if worst == null:
		return false
	for order in survivor.orders:
		if order.get("building", 0) == worst.id:
			return true
	world.submit(Commands.repair(player_id, worst.id))
	return true


func _wall_entrances(world: World) -> bool:
	for cell in _entrance_cells:
		if world.grid.occupant(cell) == BuildGrid.NONE:
			if _can_afford(world, &"wall") and world.buildings.validate(world, player_id, &"wall", cell).is_empty():
				world.submit(Commands.place_building(player_id, &"wall", cell, true))
			return true
	return false


func _spend(world: World) -> void:
	var minute := world.match_system.elapsed(world) / 60.0 if world.match_system.active else world.tick / 1800.0
	var counts := {}
	for building in _own_buildings(world):
		var root := _root_of(world, building.def.id)
		counts[root] = counts.get(root, 0) + 1
	var towers: int = counts.get(&"basic_tower", 0)
	var mills: int = counts.get(&"mill", 0)
	if mills < 2:
		_build(world, &"mill", false)
	elif towers < 4:
		_build(world, &"basic_tower", true)
	elif mills < 4 and minute >= 3.0:
		_build(world, &"mill", false)
	elif counts.get(&"barracks", 0) == 0 and minute >= 4.0:
		_build(world, &"barracks", false)
	elif _train(world):
		pass
	elif _upgrade(world, [&"basic_tower"]):
		pass
	elif _upgrade(world, [&"arrow_tower", &"cannon_tower", &"frost_tower", &"mill"]):
		pass
	elif _upgrade(world, [&"wall", &"wall_reinforced"]):
		pass
	elif towers < 4 + roundi(minute * 1.5):
		_build(world, &"basic_tower", true)


## Places `def_id` on the free spot nearest the entrances (front) or deepest inside (back).
func _build(world: World, def_id: StringName, front: bool) -> void:
	if not _can_afford(world, def_id):
		return
	var def := world.defs.building(def_id)
	var count := _inner_order.size()
	for k in count:
		var cell := _inner_order[k] if front else _inner_order[count - 1 - k]
		if front and _depth[cell] < TOWER_SETBACK:
			continue
		if _fits(world, Rect2i(cell, def.footprint)):
			world.submit(Commands.place_building(player_id, def_id, cell, true))
			return


func _fits(world: World, rect: Rect2i) -> bool:
	for z in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if not _area.has(Vector2i(x, z)) or _depth.get(Vector2i(x, z), 0) < 1:
				return false
	return world.grid.check(rect).is_empty() and not world.survivors.any_in_rect(rect) \
		and not world.units.any_in_rect(rect)


## Keeps about one fighter per two minutes (and a repairman per three fighters) queued.
func _train(world: World) -> bool:
	for building in _own_buildings(world):
		if building.def.trains.is_empty() or building.constructing or not building.train_queue.is_empty():
			continue
		var units := 0
		var repairmen := 0
		for unit in world.units.living():
			if unit.owner == player_id:
				units += 1
				repairmen += 1 if unit.def.is_repairer() else 0
		if units >= 12:
			return false
		var def_id := &"repairman" if repairmen * 3 < units - repairmen else &"fighter"
		if _can_afford(world, def_id, true):
			world.submit(Commands.train_unit(player_id, building.id, def_id))
			return true
	return false


## Upgrades the first own building whose def is in `from`; basic towers rotate their branch.
func _upgrade(world: World, from: Array) -> bool:
	for building in _own_buildings(world):
		if not building.def.id in from or building.constructing or building.upgrading_to != null:
			continue
		if building.def.upgrades.is_empty():
			continue
		var target := building.def.upgrades[_branch % building.def.upgrades.size()]
		if not _can_afford(world, target):
			return true  # save up for it
		world.submit(Commands.upgrade_building(player_id, building.id, target))
		_branch += 1
		return true
	return false


## Units defend the plot: they stand just behind the entrance walls.
func _command_units(world: World) -> void:
	if _entrance_cells.is_empty():
		return
	for unit in world.units.living():
		if unit.owner != player_id or not unit.orders.is_empty() or unit.def.is_repairer():
			continue
		var post := _inner_order[mini(unit.id % 8, _inner_order.size() - 1)]
		if unit.cell().distance_to(post) > 2.0 and unit.position.distance_to(unit.home) < 1.5 \
				and not _area.has(unit.cell()):
			world.submit(Commands.order_units(player_id, [unit.id] as Array[int], "move", post))


func _can_afford(world: World, def_id: StringName, unit := false) -> bool:
	var cost := world.defs.unit(def_id).cost if unit else world.defs.building(def_id).cost
	return world.players[player_id].resource >= cost


func _own_buildings(world: World) -> Array[BuildingState]:
	var out: Array[BuildingState] = []
	for entity: SimEntity in world.entities.values():
		var building := entity as BuildingState
		if building and building.owner == player_id:
			out.append(building)
	return out


## The root of the upgrade tree `def_id` belongs to.
func _root_of(world: World, def_id: StringName) -> StringName:
	for def: BuildingDef in world.defs.buildings.values():
		if def_id in def.upgrades:
			return _root_of(world, def.id)
	return def_id

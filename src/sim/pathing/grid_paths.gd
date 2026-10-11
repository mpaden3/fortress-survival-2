class_name GridPaths
extends RefCounted
## A* paths for the player's movers (Survivors, units) over `grid.blocked`. The A* grid
## mirrors it and re-syncs the rects of buildings that appeared or disappeared; `version`
## goes up then so movers know to re-path.

## Bumped whenever the walkable grid changed.
var version := 0

var _astar := AStarGrid2D.new()
var _ready := false
var _dirty_rects: Array[Rect2i] = []


func register(world: World) -> void:
	world.entity_added.connect(_on_entity_changed)
	world.entity_removed.connect(_on_entity_changed)


## Cell centres (cell units) from `from` toward `to`, excluding the start cell. If `to` can't
## be reached, the path ends at the closest reachable cell.
func find_path(world: World, from: Vector2i, to: Vector2i) -> PackedVector2Array:
	sync(world)
	var out := PackedVector2Array()
	var size := world.map.size
	var start := from.clamp(Vector2i.ZERO, size - Vector2i.ONE)
	for cell in _astar.get_id_path(start, to.clamp(Vector2i.ZERO, size - Vector2i.ONE), true):
		if cell != start:
			out.append(Vector2(cell) + Vector2(0.5, 0.5))
	return out


func sync(world: World) -> void:
	if not _ready:
		_astar.region = Rect2i(Vector2i.ZERO, world.map.size)
		_astar.cell_size = Vector2.ONE
		_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
		_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
		_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
		_astar.update()
		_dirty_rects = [Rect2i(Vector2i.ZERO, world.map.size)]
		_ready = true
	if _dirty_rects.is_empty():
		return
	var width := world.map.size.x
	for rect in _dirty_rects:
		for z in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				_astar.set_point_solid(Vector2i(x, z), world.grid.blocked[z * width + x] != 0)
	_dirty_rects.clear()
	version += 1


## The free cell around `rect` (touching it, diagonals included) closest to `from`, or
## (-1, -1) if there's none. Where a mover stands to work on a building or leave it.
static func free_cell_around(world: World, rect: Rect2i, from: Vector2) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_distance := INF
	var ring := rect.grow(1)
	var width := world.map.size.x
	for z in range(ring.position.y, ring.end.y):
		for x in range(ring.position.x, ring.end.x):
			var cell := Vector2i(x, z)
			if rect.has_point(cell) or not world.map.in_bounds(cell) or world.grid.blocked[z * width + x] != 0:
				continue
			var distance := from.distance_squared_to(Vector2(cell) + Vector2(0.5, 0.5))
			if distance < best_distance:
				best_distance = distance
				best = cell
	return best


## Like free_cell_around(), but only cells A* can reach from `from`: nearest first, skipping
## free cells sealed off from it (e.g. a pocket on the far side of a ridge). (-1, -1) if none.
func reachable_cell_around(world: World, rect: Rect2i, from: Vector2) -> Vector2i:
	var start := Vector2i(floori(from.x), floori(from.y))
	var candidates: Array[Vector2i] = []
	var ring := rect.grow(1)
	var width := world.map.size.x
	for z in range(ring.position.y, ring.end.y):
		for x in range(ring.position.x, ring.end.x):
			var cell := Vector2i(x, z)
			if not rect.has_point(cell) and world.map.in_bounds(cell) and world.grid.blocked[z * width + x] == 0:
				candidates.append(cell)
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var da := from.distance_squared_to(Vector2(a) + Vector2(0.5, 0.5))
		var db := from.distance_squared_to(Vector2(b) + Vector2(0.5, 0.5))
		return da < db if da != db else (a.y < b.y if a.y != b.y else a.x < b.x))
	for cell in candidates:
		if cell == start:
			return cell
		var path := find_path(world, start, cell)
		if not path.is_empty() and path[path.size() - 1] == Vector2(cell) + Vector2(0.5, 0.5):
			return cell
	return Vector2i(-1, -1)


## Distance (cells) from a point to the nearest point of a rect.
static func distance_to_rect(position: Vector2, rect: Rect2i) -> float:
	var closest := Vector2(clampf(position.x, rect.position.x, rect.end.x), clampf(position.y, rect.position.y, rect.end.y))
	return position.distance_to(closest)


## Moves `mover` (anything with `position` and `path`) along its path by `step` cells.
## Returns true once the path is used up.
static func walk(mover: Object, step: float) -> bool:
	while step > 0.0 and not mover.path.is_empty():
		var offset: Vector2 = mover.path[0] - mover.position
		var length := offset.length()
		if length <= step:
			mover.position = mover.path[0]
			mover.path.remove_at(0)
			step -= length
		else:
			mover.position += offset / length * step
			step = 0.0
	return mover.path.is_empty()


func _on_entity_changed(entity: SimEntity) -> void:
	var building := entity as BuildingState
	if building:
		_dirty_rects.append(building.rect)

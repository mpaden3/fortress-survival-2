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


## A natural walking route (cell units) from the exact position `from` to the exact point `to`
## for a body of `radius` cells: A* over the grid, then straightened. Waypoints remain only
## where the body must turn around something; every leg is either checked to keep `radius`
## clear of blocked cells or a single A* step. Ends at `to` (nudged off any wall it would
## overlap); if `to` can't be reached, at the closest reachable cell.
func find_route(world: World, from: Vector2, to: Vector2, radius: float) -> PackedVector2Array:
	var start := Vector2i(floori(from.x), floori(from.y))
	var goal := Vector2i(floori(to.x), floori(to.y)).clamp(Vector2i.ZERO, world.map.size - Vector2i.ONE)
	var cells := find_path(world, start, goal)
	# Candidate waypoints, each a safe step from the one before: into the own cell's centre,
	# the A* cell centres, then within the goal cell to the exact point.
	var points := PackedVector2Array()
	var start_centre := Vector2(start) + Vector2(0.5, 0.5)
	if not from.is_equal_approx(start_centre):
		points.append(start_centre)
	points.append_array(cells)
	var reached := start if cells.is_empty() else Vector2i(floori(cells[cells.size() - 1].x), floori(cells[cells.size() - 1].y))
	if reached == goal:
		points.append(_clear_point(world, goal, to, radius))
	# String pulling: from each anchor, head straight for the farthest waypoint in clear view
	# (found by doubling, then bisecting). Falling back to the next waypoint is always safe.
	var route := PackedVector2Array()
	var anchor := from
	var n := points.size()
	var i := 0
	while i < n:
		var best := i
		var span := 1
		while i + span < n and segment_clear(world, anchor, points[i + span], radius):
			best = i + span
			span *= 2
		var bad := mini(i + span, n)
		while bad - best > 1:
			var mid := (best + bad) / 2
			if segment_clear(world, anchor, points[mid], radius):
				best = mid
			else:
				bad = mid
		route.append(points[best])
		anchor = points[best]
		i = best + 1
	_hug_corners(world, from, route, radius)
	return route


## Turn points are cell centres, half a cell off the obstacle. Each turn may instead use a
## spot just off a nearby obstacle corner (set back by the body's radius on both axes, so it
## keeps clear). A shortest-path pass over the turns' candidates picks the best combination
## whose legs are all clear, so the route hugs corners. If none is clear, it stays as it was.
func _hug_corners(world: World, from: Vector2, route: PackedVector2Array, radius: float) -> void:
	var turns := route.size() - 1
	if turns < 1:
		return
	# layers[0] = start, layers[1..turns] = candidates per turn, last = the destination.
	var layers: Array[PackedVector2Array] = [PackedVector2Array([from])]
	for k in turns:
		layers.append(_turn_candidates(world, route[k], radius))
	layers.append(PackedVector2Array([route[turns]]))
	var cost: Array[PackedFloat32Array] = []
	var back: Array[PackedInt32Array] = []
	for layer in layers:
		var c := PackedFloat32Array()
		c.resize(layer.size())
		c.fill(INF)
		cost.append(c)
		var b := PackedInt32Array()
		b.resize(layer.size())
		back.append(b)
	cost[0][0] = 0.0
	for l in range(1, layers.size()):
		for a in layers[l - 1].size():
			if cost[l - 1][a] == INF:
				continue
			for b in layers[l].size():
				var total := cost[l - 1][a] + layers[l - 1][a].distance_to(layers[l][b])
				if total < cost[l][b] and segment_clear(world, layers[l - 1][a], layers[l][b], radius):
					cost[l][b] = total
					back[l][b] = a
	if cost[layers.size() - 1][0] == INF:
		return
	var pick := 0
	for l in range(layers.size() - 1, 1, -1):
		pick = back[l][pick]
		route[l - 2] = layers[l - 1][pick]


## The turn itself, plus spots just off the corners of the cells around it that touch a
## blocked cell and leave room for the body.
func _turn_candidates(world: World, turn: Vector2, radius: float) -> PackedVector2Array:
	var out := PackedVector2Array([turn])
	var offset := radius * 1.01
	var cx := floori(turn.x)
	var cz := floori(turn.y)
	for z in range(cz - 1, cz + 2):
		for x in range(cx - 1, cx + 2):
			if not _open(world, x, z):
				continue
			for corner: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
				var q := Vector2i(x, z) + corner
				# Only corners of an obstacle: one of the four cells meeting there is blocked.
				if _open(world, q.x - 1, q.y - 1) and _open(world, q.x, q.y - 1) \
						and _open(world, q.x - 1, q.y) and _open(world, q.x, q.y):
					continue
				var inward := Vector2(1 - corner.x * 2, 1 - corner.y * 2)
				var spot := Vector2(q) + inward * offset
				if point_clear(world, spot, radius) and not out.has(spot):
					out.append(spot)
	return out


## True if a body of `radius` cells standing at `point` overlaps no blocked cell.
func point_clear(world: World, point: Vector2, radius: float) -> bool:
	var cx := floori(point.x)
	var cz := floori(point.y)
	for z in range(cz - 1, cz + 2):
		for x in range(cx - 1, cx + 2):
			if _open(world, x, z):
				continue
			var closest := Vector2(clampf(point.x, x, x + 1), clampf(point.y, z, z + 1))
			if point.distance_squared_to(closest) < radius * radius:
				return false
	return true


## True if a body of `radius` cells can move straight from `a` to `b` without overlapping a
## blocked cell: the centre line and both side lines `radius` away must cross only open cells.
func segment_clear(world: World, a: Vector2, b: Vector2, radius: float) -> bool:
	var along := b - a
	if along.length_squared() < 0.000001:
		return true
	var side := along.normalized().orthogonal() * radius
	return _line_clear(world, a, b) and _line_clear(world, a + side, b + side) and _line_clear(world, a - side, b - side)


## Walks every cell the line from `a` to `b` passes through (Amanatides-Woo traversal).
func _line_clear(world: World, a: Vector2, b: Vector2) -> bool:
	var width := world.map.size.x
	var height := world.map.size.y
	var blocked := world.grid.blocked
	var x := floori(a.x)
	var z := floori(a.y)
	var end_x := floori(b.x)
	var end_z := floori(b.y)
	var d := b - a
	var step_x := 1 if d.x > 0.0 else -1
	var step_z := 1 if d.y > 0.0 else -1
	var t_delta_x := absf(1.0 / d.x) if d.x != 0.0 else INF
	var t_delta_z := absf(1.0 / d.y) if d.y != 0.0 else INF
	var t_max_x := ((x + 1 - a.x) if d.x > 0.0 else (a.x - x)) * t_delta_x if d.x != 0.0 else INF
	var t_max_z := ((z + 1 - a.y) if d.y > 0.0 else (a.y - z)) * t_delta_z if d.y != 0.0 else INF
	for guard in width + height + 4:
		if x < 0 or z < 0 or x >= width or z >= height or blocked[z * width + x] != 0:
			return false
		if x == end_x and z == end_z:
			return true
		# Through a corner exactly: both neighbours are touched, so check both.
		if absf(t_max_x - t_max_z) < 0.000001:
			if not _open(world, x + step_x, z) or not _open(world, x, z + step_z):
				return false
			x += step_x
			z += step_z
			t_max_x += t_delta_x
			t_max_z += t_delta_z
		elif t_max_x < t_max_z:
			x += step_x
			t_max_x += t_delta_x
		else:
			z += step_z
			t_max_z += t_delta_z
	return true


func _open(world: World, x: int, z: int) -> bool:
	return x >= 0 and z >= 0 and x < world.map.size.x and z < world.map.size.y \
		and world.grid.blocked[z * world.map.size.x + x] == 0


## `point` kept inside `cell`, at least `radius` away from each blocked neighbour side.
func _clear_point(world: World, cell: Vector2i, point: Vector2, radius: float) -> Vector2:
	var lo := Vector2(cell)
	var hi := Vector2(cell) + Vector2.ONE
	var x := clampf(point.x, lo.x, hi.x)
	var z := clampf(point.y, lo.y, hi.y)
	if not _open(world, cell.x - 1, cell.y):
		x = maxf(x, lo.x + radius)
	if not _open(world, cell.x + 1, cell.y):
		x = minf(x, hi.x - radius)
	if not _open(world, cell.x, cell.y - 1):
		z = maxf(z, lo.y + radius)
	if not _open(world, cell.x, cell.y + 1):
		z = minf(z, hi.y - radius)
	# A blocked diagonal neighbour only reaches into the cell's corner.
	for corner: Vector2i in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
		if _open(world, cell.x + corner.x, cell.y + corner.y):
			continue
		var tip := Vector2(lo.x if corner.x < 0 else hi.x, lo.y if corner.y < 0 else hi.y)
		var away := Vector2(x, z) - tip
		if away.length() < radius:
			var pushed := tip + (away.normalized() if away.length() > 0.0001 else -Vector2(corner).normalized()) * radius
			x = pushed.x
			z = pushed.y
	return Vector2(x, z)


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


## `point` if it lies in `cell`, else the cell's centre (commands may omit the exact point).
static func point_in(cell: Vector2i, point: Vector2) -> Vector2:
	return point if Rect2(Vector2(cell), Vector2.ONE).has_point(point) else Vector2(cell) + Vector2(0.5, 0.5)


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

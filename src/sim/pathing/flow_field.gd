class_name FlowField
extends RefCounted
## Cost-to-target for every cell plus the direction to walk from it, toward one target.
## Built with Dijkstra from the target outward. Buildings are passable at an extra cost
## (their "break cost"), so when everything is walled off the cheapest wall wins.
## Shared by all enemies with this target: cost doesn't depend on enemy count.
##
## Step costs are small integers, so the queue is a bucket queue (Dial's algorithm) instead
## of a heap. A build can be spread over several ticks: begin(), then advance() with a cell
## budget each tick; `cost` and `direction` keep the previous field until the new one is done.

const STRAIGHT := 10
const DIAGONAL := 14
const UNREACHABLE := 1 << 30
## Per-cell extra cost marker for impassable terrain.
const IMPASSABLE := -1
const INDEX_BITS := 21
const INDEX_MASK := (1 << INDEX_BITS) - 1
## Straight neighbours first, then diagonals.
const OFFSETS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1),
]
const _OX: Array[int] = [1, -1, 0, 0, 1, -1, 1, -1]
const _OZ: Array[int] = [0, 0, 1, -1, 1, 1, -1, -1]
## Direction stored on a cell reached through OFFSETS[k]: back toward where it came from.
const _BACK: Array[Vector2] = [
	Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1),
	Vector2(-0.70710677, -0.70710677), Vector2(0.70710677, -0.70710677),
	Vector2(-0.70710677, 0.70710677), Vector2(0.70710677, 0.70710677),
]

var size: Vector2i
var targets: Array[Vector2i] = []
## Cost from each cell to the target (UNREACHABLE if none).
var cost := PackedInt32Array()
## Unit direction (x, z) from each cell toward its best neighbour; ZERO at the target.
var direction := PackedVector2Array()
## Microseconds the last completed build took in total (all its slices).
var build_usec := 0
## Microseconds the last advance() took (one tick's slice).
var advance_usec := 0
## Builds completed so far.
var builds := 0

# The build in progress (the "next" field) and its bucket queue: per bucket a linked list of
# nodes, each node a cell index. Bucket b holds cells whose tentative cost % bucket count == b.
var _building := false
var _extra := PackedInt32Array()
var _next_cost := PackedInt32Array()
var _next_direction := PackedVector2Array()
var _head := PackedInt32Array()
var _node_cell := PackedInt32Array()
var _node_next := PackedInt32Array()
var _queued := 0
var _current := 0
var _usec := 0


## Builds the whole field now.
func build(grid_size: Vector2i, extra: PackedInt32Array, target_cells: Array[Vector2i]) -> void:
	begin(grid_size, extra, target_cells)
	advance(1 << 30)


## Starts a new build toward `target_cells`. `extra[i]`: IMPASSABLE, 0 for open ground, or
## the break cost of a building cell. The array is kept as it is now, even if the caller
## changes it later (packed arrays are copy-on-write). Pass `max_extra` (the largest value in
## `extra`) when known, to skip scanning for it.
func begin(grid_size: Vector2i, extra: PackedInt32Array, target_cells: Array[Vector2i], max_extra := -1) -> void:
	var started := Time.get_ticks_usec()
	_building = true
	size = grid_size
	targets = target_cells
	_extra = extra
	var count := size.x * size.y
	_next_cost.resize(count)
	_next_cost.fill(UNREACHABLE)
	_next_direction.resize(count)
	_next_direction.fill(Vector2.ZERO)
	if max_extra < 0:
		for value in extra:
			max_extra = maxi(max_extra, value)
	# Any queued cost lies within [current, current + biggest step], so this many buckets suffice.
	_head.resize(DIAGONAL + max_extra + 1)
	_head.fill(-1)
	_node_cell.clear()
	_node_next.clear()
	_queued = 0
	_current = 0
	for cell in target_cells:
		if cell.x < 0 or cell.y < 0 or cell.x >= size.x or cell.y >= size.y:
			continue
		var index := cell.y * size.x + cell.x
		if extra[index] != IMPASSABLE and _next_cost[index] != 0:
			_next_cost[index] = 0
			_node_cell.append(index)
			_node_next.append(_head[0])
			_head[0] = _node_cell.size() - 1
			_queued += 1
	_usec = Time.get_ticks_usec() - started


func is_building() -> bool:
	return _building


## Settles up to `budget` cells of the build in progress. When it completes, the new field
## replaces `cost` and `direction`; returns true then.
func advance(budget: int) -> bool:
	if not _building:
		return true
	var started := Time.get_ticks_usec()
	# Work on locals; the members are emptied meanwhile so writes don't copy the arrays.
	var extra := _extra
	var costs := _next_cost
	var dirs := _next_direction
	var head := _head
	var node_cell := _node_cell
	var node_next := _node_next
	_next_cost = PackedInt32Array()
	_next_direction = PackedVector2Array()
	_head = PackedInt32Array()
	_node_cell = PackedInt32Array()
	_node_next = PackedInt32Array()
	var width := size.x
	var height := size.y
	var buckets := head.size()
	var current := _current
	var queued := _queued
	var settled := 0
	while queued > 0 and settled < budget:
		var bucket := current % buckets
		var node := head[bucket]
		if node < 0:
			current += 1
			continue
		head[bucket] = node_next[node]
		queued -= 1
		var index := node_cell[node]
		if costs[index] != current:
			continue  # reached more cheaply since it was queued
		settled += 1
		var x := index % width
		var z := index / width
		# Moving from a neighbour into this cell means breaking it if it's a building.
		var enter := current + extra[index]
		for k in 8:
			var nx := x + _OX[k]
			var nz := z + _OZ[k]
			if nx < 0 or nz < 0 or nx >= width or nz >= height:
				continue
			var next_index := nz * width + nx
			if extra[next_index] == IMPASSABLE:
				continue
			var candidate := enter + STRAIGHT
			if k >= 4:
				# No diagonal corner-cutting past terrain or buildings.
				if extra[index + _OX[k]] != 0 or extra[index + _OZ[k] * width] != 0:
					continue
				candidate = enter + DIAGONAL
			if candidate < costs[next_index]:
				costs[next_index] = candidate
				dirs[next_index] = _BACK[k]
				var b := candidate % buckets
				node_cell.append(next_index)
				node_next.append(head[b])
				head[b] = node_cell.size() - 1
				queued += 1
	_current = current
	_queued = queued
	advance_usec = Time.get_ticks_usec() - started
	_usec += advance_usec
	if queued > 0:
		_next_cost = costs
		_next_direction = dirs
		_head = head
		_node_cell = node_cell
		_node_next = node_next
		return false
	cost = costs
	direction = dirs
	_head = head
	_extra = PackedInt32Array()
	_building = false
	build_usec = _usec
	builds += 1
	return true


func cost_at(cell: Vector2i) -> int:
	return cost[_index(cell)] if _inside(cell) else UNREACHABLE


func direction_at(cell: Vector2i) -> Vector2:
	return direction[_index(cell)] if _inside(cell) else Vector2.ZERO


## Smooth direction at a continuous position (cell units): bilinear blend of the four nearest
## cell directions, ignoring cells without one. Avoids grid-aligned zig-zag movement.
func sample(position: Vector2) -> Vector2:
	var fx := position.x - 0.5
	var fz := position.y - 0.5
	var x0 := floori(fx)
	var z0 := floori(fz)
	var tx := fx - x0
	var tz := fz - z0
	var blended := Vector2.ZERO
	var weight := 0.0
	for corner in 4:
		var cx := x0 + (corner & 1)
		var cz := z0 + (corner >> 1)
		if cx < 0 or cz < 0 or cx >= size.x or cz >= size.y:
			continue
		var d := direction[cz * size.x + cx]
		if d == Vector2.ZERO:
			continue
		var w := (tx if corner & 1 else 1.0 - tx) * (tz if corner >> 1 else 1.0 - tz)
		blended += d * w
		weight += w
	if weight <= 0.0001 or blended.length_squared() < 0.0001:
		return direction_at(Vector2i(floori(position.x), floori(position.y)))
	return blended.normalized()


func _inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y


func _index(cell: Vector2i) -> int:
	return cell.y * size.x + cell.x


## Binary min-heap of (key << INDEX_BITS | index) entries, shared with other grid searches.
static func heap_push(heap: PackedInt64Array, key: int, index: int) -> void:
	heap.append((key << INDEX_BITS) | index)
	var i := heap.size() - 1
	while i > 0:
		var parent := (i - 1) >> 1
		if heap[parent] <= heap[i]:
			break
		var swap := heap[parent]
		heap[parent] = heap[i]
		heap[i] = swap
		i = parent


static func heap_pop(heap: PackedInt64Array) -> int:
	var top := heap[0]
	var last := heap[heap.size() - 1]
	heap.resize(heap.size() - 1)
	if heap.is_empty():
		return top
	heap[0] = last
	var i := 0
	var n := heap.size()
	while true:
		var left := 2 * i + 1
		if left >= n:
			break
		var child := left
		if left + 1 < n and heap[left + 1] < heap[left]:
			child = left + 1
		if heap[i] <= heap[child]:
			break
		var swap := heap[child]
		heap[child] = heap[i]
		heap[i] = swap
		i = child
	return top

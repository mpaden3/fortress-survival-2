class_name FlowField
extends RefCounted
## Cost-to-target for every cell plus the direction to walk from it, toward one target.
## Built with Dijkstra from the target outward. Buildings are passable at an extra cost
## (their "break cost"), so when everything is walled off the cheapest wall wins.
## Shared by all enemies with this target: cost doesn't depend on enemy count.

const STRAIGHT := 10
const DIAGONAL := 14
const UNREACHABLE := 1 << 40
## Per-cell extra cost marker for impassable terrain.
const IMPASSABLE := -1
const INDEX_BITS := 21
const INDEX_MASK := (1 << INDEX_BITS) - 1
const OFFSETS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1),
]

var size: Vector2i
var targets: Array[Vector2i] = []
## Cost from each cell to the target (UNREACHABLE if none).
var cost := PackedInt64Array()
## Unit direction (x, z) from each cell toward its best neighbour; ZERO at the target.
var direction := PackedVector2Array()
## Microseconds the last build took.
var build_usec := 0


## `extra[i]`: IMPASSABLE, 0 for open ground, or the break cost of a building cell.
func build(grid_size: Vector2i, extra: PackedInt32Array, target_cells: Array[Vector2i]) -> void:
	var started := Time.get_ticks_usec()
	size = grid_size
	targets = target_cells
	var count := size.x * size.y
	cost.resize(count)
	cost.fill(UNREACHABLE)
	direction.resize(count)
	direction.fill(Vector2.ZERO)
	var heap := PackedInt64Array()
	for cell in target_cells:
		if _inside(cell) and extra[_index(cell)] != IMPASSABLE:
			cost[_index(cell)] = 0
			heap_push(heap, 0, _index(cell))
	while not heap.is_empty():
		var top := heap_pop(heap)
		var index := top & INDEX_MASK
		var current := top >> INDEX_BITS
		if current > cost[index]:
			continue
		var cell := Vector2i(index % size.x, index / size.x)
		# Moving from a neighbour into `cell` means breaking `cell` if it's a building.
		var enter := extra[index]
		for k in 8:
			var offset := OFFSETS[k]
			var next := cell + offset
			if not _inside(next):
				continue
			var next_index := next.y * size.x + next.x
			if extra[next_index] == IMPASSABLE:
				continue
			var step := STRAIGHT
			if k >= 4:
				# No diagonal corner-cutting past terrain or buildings.
				if extra[index + offset.x] != 0 or extra[index + offset.y * size.x] != 0:
					continue
				step = DIAGONAL
			var candidate := current + step + enter
			if candidate < cost[next_index]:
				cost[next_index] = candidate
				direction[next_index] = Vector2(-offset).normalized()
				heap_push(heap, candidate, next_index)
	build_usec = Time.get_ticks_usec() - started


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

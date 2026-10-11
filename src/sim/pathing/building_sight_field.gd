class_name BuildingSightField
extends RefCounted
## Walking distance from every cell to the nearest building, up to a range, with the direction
## toward it and its id. Enemies whose Survivor is out of sight use it to go for the buildings
## they see. It spreads over open ground only, never through terrain or buildings, so from
## outside a fortification only its outer layer is seen.

## Cost of cells beyond the range.
const UNSEEN := -1

var size: Vector2i
## Cost (FlowField units: 10 per straight step) to the nearest building; 0 on building cells.
var cost := PackedInt32Array()
## Unit direction (x, z) toward the nearest building; ZERO on building cells and unseen cells.
var direction := PackedVector2Array()
## Entity id of the nearest building, 0 if unseen.
var building := PackedInt32Array()
## Microseconds the last build took.
var build_usec := 0


## `extra`: per-cell PathingSystem costs (IMPASSABLE terrain, 0 open, > 0 building).
## `occupants`: building id per cell. Spreads at most `max_cost` from each building.
func build(grid_size: Vector2i, extra: PackedInt32Array, occupants: PackedInt32Array, max_cost: int) -> void:
	var started := Time.get_ticks_usec()
	size = grid_size
	var count := size.x * size.y
	cost.resize(count)
	cost.fill(UNSEEN)
	direction.resize(count)
	direction.fill(Vector2.ZERO)
	building.resize(count)
	building.fill(0)
	var heap := PackedInt64Array()
	for index in count:
		if extra[index] > 0:
			cost[index] = 0
			building[index] = occupants[index]
			FlowField.heap_push(heap, 0, index)
	while not heap.is_empty():
		var top := FlowField.heap_pop(heap)
		var index := top & FlowField.INDEX_MASK
		var current := top >> FlowField.INDEX_BITS
		if current > cost[index]:
			continue
		var cell := Vector2i(index % size.x, index / size.x)
		for k in 8:
			var offset := FlowField.OFFSETS[k]
			var next := cell + offset
			if next.x < 0 or next.y < 0 or next.x >= size.x or next.y >= size.y:
				continue
			var next_index := next.y * size.x + next.x
			if extra[next_index] != 0:
				continue
			var step := FlowField.STRAIGHT
			if k >= 4:
				# No corner cutting; a building corner is reached straight from its side anyway.
				if extra[index + offset.x] != 0 or extra[index + offset.y * size.x] != 0:
					continue
				step = FlowField.DIAGONAL
			var candidate := current + step
			if candidate > max_cost:
				continue
			if cost[next_index] == UNSEEN or candidate < cost[next_index]:
				cost[next_index] = candidate
				direction[next_index] = Vector2(-offset).normalized()
				building[next_index] = building[index]
				FlowField.heap_push(heap, candidate, next_index)
	build_usec = Time.get_ticks_usec() - started


func cost_at(cell: Vector2i) -> int:
	return cost[cell.y * size.x + cell.x]


func building_at(cell: Vector2i) -> int:
	return building[cell.y * size.x + cell.x]

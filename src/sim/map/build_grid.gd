class_name BuildGrid
extends RefCounted
## Which building occupies each build cell, on top of the map's static terrain.

const NONE := 0

var map: MapLayout
var _occupant := PackedInt32Array()


func _init(map_layout: MapLayout) -> void:
	map = map_layout
	_occupant.resize(map.size.x * map.size.y)


## Empty string if `rect` can be built on, otherwise the reason it can't.
func check(rect: Rect2i) -> String:
	for z in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var cell := Vector2i(x, z)
			if not map.in_bounds(cell):
				return "out_of_bounds"
			if not map.is_buildable(cell):
				return "terrain"
			if _occupant[z * map.size.x + x] != NONE:
				return "occupied"
	return ""


func occupy(rect: Rect2i, entity_id: int) -> void:
	_fill(rect, entity_id)


func release(rect: Rect2i) -> void:
	_fill(rect, NONE)


func occupant(cell: Vector2i) -> int:
	return _occupant[cell.y * map.size.x + cell.x] if map.in_bounds(cell) else NONE


func _fill(rect: Rect2i, value: int) -> void:
	for z in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			_occupant[z * map.size.x + x] = value

class_name VisibilitySystem
extends RefCounted
## Fog-of-war hook: what each player can see. With GameRules.fog_of_war off (the default)
## everything is visible and mask() is empty. With it on, every REFRESH_TICKS a team mask marks
## the cells within vision of any player's living Survivor, units and buildings (co-op allies
## share vision). Views ask this instead of assuming full vision.

const REFRESH_TICKS := 10

## 1 = visible, per cell; empty while everything is visible.
var _mask := PackedByteArray()


## Visibility per cell for `player_id` (row-major), or an empty array if everything is visible.
func mask(_player_id: int) -> PackedByteArray:
	return _mask


func can_see(player_id: int, world: World, cell: Vector2i) -> bool:
	var visible := mask(player_id)
	return visible.is_empty() or (world.map.in_bounds(cell) and visible[cell.y * world.map.size.x + cell.x] == 1)


## Whether a point (cell units) is visible in `visible` (from mask()); always true if empty.
static func shown(visible: PackedByteArray, width: int, point: Vector2) -> bool:
	if visible.is_empty():
		return true
	var index := floori(point.y) * width + floori(point.x)
	return index >= 0 and index < visible.size() and visible[index] == 1


func update(world: World) -> void:
	var rules := world.defs.rules
	if not rules.fog_of_war:
		_mask = PackedByteArray()
		return
	if not _mask.is_empty() and world.tick % REFRESH_TICKS != 0:
		return
	var size := world.map.size
	var visible := PackedByteArray()
	visible.resize(size.x * size.y)
	for entity: SimEntity in world.entities.values():
		if entity is SurvivorState and entity.alive:
			_reveal(visible, size, entity.position, rules.survivor_vision)
		elif entity is UnitState:
			_reveal(visible, size, entity.position, entity.def.sight_range)
		elif entity is BuildingState:
			_reveal(visible, size, entity.centre(), rules.building_vision + Vector2(entity.rect.size).length() * 0.5)
	_mask = visible


static func _reveal(visible: PackedByteArray, size: Vector2i, centre: Vector2, radius: float) -> void:
	var r_sq := radius * radius
	for z in range(maxi(floori(centre.y - radius), 0), mini(ceili(centre.y + radius), size.y)):
		for x in range(maxi(floori(centre.x - radius), 0), mini(ceili(centre.x + radius), size.x)):
			if Vector2(x + 0.5, z + 0.5).distance_squared_to(centre) <= r_sq:
				visible[z * size.x + x] = 1

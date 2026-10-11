class_name PathingSystem
extends RefCounted
## Owns one FlowField per hunt target (e.g. each living Survivor) and rebuilds them when
## buildings appear or disappear, or when a target moves to another cell.

var fields: Dictionary[StringName, FlowField] = {}
var _target_cells: Dictionary[StringName, Array] = {}
var _dirty: Dictionary[StringName, bool] = {}
var _extra := PackedInt32Array()
var _extra_dirty := true


func register(world: World) -> void:
	world.entity_added.connect(_on_building_changed)
	world.entity_removed.connect(_on_building_changed)
	world.entity_changed.connect(_on_building_changed)


## Sets (or moves) a target. Rebuilds next update only if its cells changed.
func set_target(key: StringName, cells: Array[Vector2i]) -> void:
	if _target_cells.get(key, []) == cells:
		return
	_target_cells[key] = cells
	_dirty[key] = true
	if not fields.has(key):
		fields[key] = FlowField.new()


func remove_target(key: StringName) -> void:
	fields.erase(key)
	_target_cells.erase(key)
	_dirty.erase(key)


func field(key: StringName) -> FlowField:
	return fields.get(key)


func update(world: World) -> void:
	if _extra_dirty:
		_rebuild_extra(world)
		for key in fields:
			_dirty[key] = true
	for key in _dirty:
		var flow := fields[key]
		var cells: Array[Vector2i] = []
		cells.assign(_target_cells[key])
		flow.build(world.map.size, _extra, cells)
		if DebugLog.on(&"pathing"):
			DebugLog.event(&"pathing", {"field": key, "targets": cells.size(), "build_ms": flow.build_usec / 1000.0})
	_dirty.clear()


## Per-cell extra cost: terrain IMPASSABLE, building cells their break cost.
func _rebuild_extra(world: World) -> void:
	var map := world.map
	_extra.resize(map.size.x * map.size.y)
	for z in map.size.y:
		for x in map.size.x:
			_extra[z * map.size.x + x] = 0 if map.is_walkable(Vector2i(x, z)) else FlowField.IMPASSABLE
	var per_hp := world.defs.rules.path_cost_per_building_hp
	for entity: SimEntity in world.entities.values():
		var building := entity as BuildingState
		if building == null:
			continue
		var break_cost := maxi(1, roundi(building.def.max_hp * per_hp))
		for z in range(building.rect.position.y, building.rect.end.y):
			for x in range(building.rect.position.x, building.rect.end.x):
				_extra[z * map.size.x + x] = break_cost
	_extra_dirty = false


func _on_building_changed(entity: SimEntity) -> void:
	if entity is BuildingState:
		_extra_dirty = true

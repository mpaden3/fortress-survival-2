class_name PathingSystem
extends RefCounted
## Owns one FlowField per hunt target (e.g. each living Survivor) and rebuilds them when
## buildings appear or disappear, or when a target moves to another cell. Also keeps the
## BuildingSightField that enemies use to go for the buildings they see.

## Cells a field rebuild may settle per tick (~2.5 ms). A full rebuild on the MVP map (~11k
## open cells) is spread over ~6 ticks so it never stalls a frame; enemies follow the old field
## meanwhile. Counted in cells, not time, so the simulation stays deterministic.
const CELLS_PER_TICK := 2048

var fields: Dictionary[StringName, FlowField] = {}
var sight := BuildingSightField.new()
## A* for the player's movers (Survivors, units).
var paths := GridPaths.new()
var _target_cells: Dictionary[StringName, Array] = {}
var _dirty: Dictionary[StringName, bool] = {}
var _extra := PackedInt32Array()
var _terrain := PackedInt32Array()
var _max_extra := 0
var _extra_dirty := true


func register(world: World) -> void:
	world.entity_added.connect(_on_building_changed)
	world.entity_removed.connect(_on_building_changed)
	world.entity_changed.connect(_on_building_changed)
	paths.register(world)


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
		_rebuild_sight(world)
		for key in fields:
			_dirty[key] = true
	# A field already rebuilding finishes first; it starts again afterwards if still dirty.
	for key: StringName in _dirty.keys():
		var flow := fields[key]
		if flow.is_building():
			continue
		var cells: Array[Vector2i] = []
		cells.assign(_target_cells[key])
		flow.begin(world.map.size, _extra, cells, _max_extra)
		_dirty.erase(key)
	for key in fields:
		var flow := fields[key]
		if not flow.is_building():
			continue
		# The first field is needed right away; later ones keep the old field until done.
		if flow.advance(CELLS_PER_TICK if flow.builds > 0 else 1 << 30) and DebugLog.on(&"pathing"):
			DebugLog.event(&"pathing", {"field": key, "targets": flow.targets.size(), "build_ms": flow.build_usec / 1000.0})


## Per-cell extra cost: terrain IMPASSABLE, building cells their break cost. Terrain never
## changes, so it's computed once and copied (natively) before stamping the buildings.
func _rebuild_extra(world: World) -> void:
	var map := world.map
	if _terrain.size() != map.size.x * map.size.y:
		_terrain.resize(map.size.x * map.size.y)
		for z in map.size.y:
			for x in map.size.x:
				_terrain[z * map.size.x + x] = 0 if map.is_walkable(Vector2i(x, z)) else FlowField.IMPASSABLE
	_extra = _terrain.duplicate()
	var per_hp := world.defs.rules.path_cost_per_building_hp
	_max_extra = 0
	for entity: SimEntity in world.entities.values():
		var building := entity as BuildingState
		if building == null:
			continue
		var break_cost := maxi(1, roundi(building.def.max_hp * per_hp))
		_max_extra = maxi(_max_extra, break_cost)
		for z in range(building.rect.position.y, building.rect.end.y):
			for x in range(building.rect.position.x, building.rect.end.x):
				_extra[z * map.size.x + x] = break_cost
	_extra_dirty = false


## Spreads as far as the farthest-seeing enemy type.
func _rebuild_sight(world: World) -> void:
	var max_sight := 0.0
	for def in world.defs.enemy_list:
		max_sight = maxf(max_sight, def.sight_range)
	var max_cost := ceili(max_sight / SimConstants.CELL_SIZE * FlowField.STRAIGHT)
	sight.build(world.map.size, _extra, world.grid.occupants(), max_cost)
	if DebugLog.on(&"pathing"):
		DebugLog.event(&"pathing", {"sight_field_ms": sight.build_usec / 1000.0, "max_cost": max_cost})


func _on_building_changed(entity: SimEntity) -> void:
	if entity is BuildingState:
		_extra_dirty = true

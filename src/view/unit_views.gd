class_name UnitViews
extends Node3D
## One capsule per trained unit (placeholder art), coloured by type (SelectionViews draws
## the selection rings). Interpolated between the last two ticks by `alpha` (set by Game each frame).

const COLOURS := {
	"fighter": Color(0.85, 0.85, 0.90),
	"repairman": Color(0.95, 0.65, 0.20),
}

var alpha := 1.0
var _world: World
var _views: Dictionary[int, Node3D] = {}


func attach(world: World) -> void:
	_world = world
	world.entity_added.connect(_on_entity_added)
	for entity: SimEntity in world.entities.values():  # already there (a loaded save, a client)
		_on_entity_added(entity)
	world.entity_removed.connect(_on_entity_removed)


func view_count() -> int:
	return _views.size()


func _on_entity_added(entity: SimEntity) -> void:
	var unit := entity as UnitState
	if unit == null:
		return
	var root := Node3D.new()
	root.name = "Unit%d" % unit.id
	var capsule := CapsuleMesh.new()
	capsule.radius = unit.def.radius
	capsule.height = 1.4
	var body := MeshInstance3D.new()
	body.mesh = capsule
	body.position.y = 0.7
	body.material_override = PlaceholderStyle.material(COLOURS.get(String(unit.def.id), Color.MAGENTA))
	root.add_child(body)
	add_child(root)
	_views[unit.id] = root


func _on_entity_removed(entity: SimEntity) -> void:
	var view: Node3D = _views.get(entity.id)
	if view:
		view.queue_free()
		_views.erase(entity.id)


func _process(_delta: float) -> void:
	if _world == null:
		return
	for unit_id in _views:
		var unit := _world.entities.get(unit_id) as UnitState
		if unit == null:
			continue
		var at := unit.position_at(alpha)
		var view := _views[unit_id]
		view.position = Vector3(at.x * Coords.CELL, 0.0, at.y * Coords.CELL)

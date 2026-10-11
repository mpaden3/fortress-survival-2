class_name SurvivorViews
extends Node3D
## One capsule per Survivor (placeholder art). Glows while hasted; turns grey when dead.
## Interpolated between the last two ticks by `alpha` (set by Game each frame).

const ALIVE := Color(0.20, 0.45, 0.95)
const HASTED := Color(0.35, 0.90, 1.00)
const DEAD := Color(0.35, 0.35, 0.38)

var alpha := 1.0
var _world: World
var _views: Dictionary[int, MeshInstance3D] = {}


func attach(world: World) -> void:
	_world = world
	world.entity_added.connect(_on_entity_added)
	for entity: SimEntity in world.entities.values():  # already there (a loaded save, a client)
		_on_entity_added(entity)


func _on_entity_added(entity: SimEntity) -> void:
	var survivor := entity as SurvivorState
	if survivor == null:
		return
	var capsule := CapsuleMesh.new()
	capsule.radius = survivor.def.radius
	capsule.height = 1.8
	var view := MeshInstance3D.new()
	view.name = "Survivor%d" % survivor.owner
	view.mesh = capsule
	view.material_override = PlaceholderStyle.material(ALIVE)
	add_child(view)
	_views[survivor.id] = view


func _process(_delta: float) -> void:
	if _world == null:
		return
	for entity_id in _views:
		var survivor := _world.entities.get(entity_id) as SurvivorState
		var view := _views[entity_id]
		var at := survivor.position_at(alpha)
		view.position = Vector3(at.x * Coords.CELL, 0.9, at.y * Coords.CELL)
		var mat := view.material_override as StandardMaterial3D
		if not survivor.alive:
			mat.albedo_color = DEAD
			view.rotation_degrees.x = 90.0
			view.position.y = survivor.def.radius
		else:
			mat.albedo_color = HASTED if _world.tick < survivor.haste_until_tick else ALIVE

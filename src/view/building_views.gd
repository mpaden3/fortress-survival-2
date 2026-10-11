class_name BuildingViews
extends Node3D
## One placeholder box per BuildingState in the World. Observes only: never changes the sim.

var _world: World
## Per building: a pivot at ground level (scaled while constructing) holding the box mesh.
var _views: Dictionary[int, Node3D] = {}
var _selected := 0


func attach(world: World) -> void:
	_world = world
	world.entity_added.connect(_on_entity_added)
	world.entity_removed.connect(_on_entity_removed)
	world.entity_changed.connect(_on_entity_changed)


func view_count() -> int:
	return _views.size()


func set_selected(entity_id: int) -> void:
	_selected = entity_id


func _process(_delta: float) -> void:
	if _world == null:
		return
	for entity_id in _views:
		var building := _world.entities.get(entity_id) as BuildingState
		var view := _views[entity_id]
		var progress := 1.0
		if building.constructing:
			progress = float(building.build_progress) / building.def.build_ticks()
		elif building.upgrading_to:
			# Pulse while upgrading.
			progress = 0.9 + 0.1 * sin(_world.tick * 0.4)
		view.scale.y = lerpf(0.15, 1.0, progress)
		var mat := (view.get_child(0) as MeshInstance3D).material_override as StandardMaterial3D
		var colour: Color = PlaceholderStyle.building(building.def.id)[0]
		if building.constructing:
			colour = colour.lerp(Color.WHITE, 0.45)
		mat.albedo_color = colour
		mat.emission_enabled = entity_id == _selected
		mat.emission = Color(0.9, 0.8, 0.2)


func _on_entity_added(entity: SimEntity) -> void:
	var building := entity as BuildingState
	if building == null:
		return
	var style := PlaceholderStyle.building(building.def.id)
	var height: float = style[1]
	var box := BoxMesh.new()
	box.size = Vector3(building.rect.size.x * Coords.CELL * 0.92, height, building.rect.size.y * Coords.CELL * 0.92)
	var mesh := MeshInstance3D.new()
	mesh.mesh = box
	mesh.material_override = PlaceholderStyle.material(style[0])
	mesh.position.y = height * 0.5
	# Pivot at the base so scaling y grows the building out of the ground.
	var pivot := Node3D.new()
	pivot.name = "Building%d" % building.id
	pivot.position = Coords.rect_centre(building.rect)
	pivot.add_child(mesh)
	add_child(pivot)
	_views[building.id] = pivot


## A building changed def (upgrade): rebuild its placeholder for the new look.
func _on_entity_changed(entity: SimEntity) -> void:
	if _views.has(entity.id):
		_on_entity_removed(entity)
		_on_entity_added(entity)


func _on_entity_removed(entity: SimEntity) -> void:
	var view: Node3D = _views.get(entity.id)
	if view:
		view.queue_free()
		_views.erase(entity.id)

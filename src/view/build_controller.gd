class_name BuildController
extends Node3D
## Local player's build input: pick a root building, preview it under the mouse, place it,
## select and sell. Everything goes through World commands, exactly like a test would.
##
## Keys: 1 Wall, 2 Basic Tower, 3 Mill, 4 Barracks; LMB place (drag to paint walls);
## RMB / Esc cancel; LMB on a building selects it; X sells the selection.

const HOTKEYS := {KEY_1: &"wall", KEY_2: &"basic_tower", KEY_3: &"mill", KEY_4: &"barracks"}

signal selection_changed(entity_id: int)

var world: World
var camera: RtsCamera
var player_id := 0
var selected_def: StringName = &""
var selected_entity := 0
var hover_cell := Vector2i(-1, -1)

var _ghost: MeshInstance3D
var _ghost_ok_mat := PlaceholderStyle.material(PlaceholderStyle.GHOST_OK)
var _ghost_bad_mat := PlaceholderStyle.material(PlaceholderStyle.GHOST_BAD)
var _painting := false
var _last_painted := Vector2i(-1, -1)


func setup(target_world: World, rts_camera: RtsCamera, local_player: int) -> void:
	world = target_world
	camera = rts_camera
	player_id = local_player


func _ready() -> void:
	_ghost = MeshInstance3D.new()
	_ghost.name = "Ghost"
	_ghost.visible = false
	_ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ghost)


func select_def(def_id: StringName) -> void:
	var def := world.defs.building(def_id) if def_id else null
	selected_def = def_id if def else &""
	if def:
		var box := BoxMesh.new()
		var height: float = PlaceholderStyle.building(def_id)[1]
		box.size = Vector3(def.footprint.x * Coords.CELL, height, def.footprint.y * Coords.CELL)
		_ghost.mesh = box
	_ghost.visible = def != null


## Footprint origin when placing the selected building under `cell`.
func placement_origin(cell: Vector2i) -> Vector2i:
	var def := world.defs.building(selected_def)
	return Coords.footprint_origin(cell, def.footprint) if def else cell


func can_place_at(cell: Vector2i) -> bool:
	var def := world.defs.building(selected_def)
	if def == null:
		return false
	var rect := Rect2i(placement_origin(cell), def.footprint)
	return world.grid.check(rect).is_empty() and world.players[player_id].resource >= def.cost


## Submits a placement of the selected building centred under `cell`.
func request_place(cell: Vector2i) -> void:
	if selected_def:
		world.submit(Commands.place_building(player_id, selected_def, placement_origin(cell)))


func request_sell_selected() -> void:
	if selected_entity and world.entities.has(selected_entity):
		world.submit(Commands.sell_building(player_id, selected_entity))
		_select_entity(0)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo:
		if HOTKEYS.has(key.physical_keycode):
			select_def(HOTKEYS[key.physical_keycode])
		elif key.physical_keycode == KEY_ESCAPE:
			select_def(&"")
		elif key.physical_keycode == KEY_X:
			request_sell_selected()
		return
	var button := event as InputEventMouseButton
	if button == null:
		return
	if button.button_index == MOUSE_BUTTON_RIGHT and button.pressed:
		select_def(&"")
	elif button.button_index == MOUSE_BUTTON_LEFT:
		_painting = button.pressed and selected_def == &"wall"
		if button.pressed:
			if selected_def:
				request_place(hover_cell)
				_last_painted = hover_cell
			else:
				_select_entity(world.grid.occupant(hover_cell))


func _process(_delta: float) -> void:
	if world == null or camera == null:
		return
	var point: Variant = camera.ground_under_mouse()
	if point == null:
		_ghost.visible = false
		return
	hover_cell = Coords.world_to_cell(point)
	if _painting and hover_cell != _last_painted:
		request_place(hover_cell)
		_last_painted = hover_cell
	if selected_def:
		var def := world.defs.building(selected_def)
		_ghost.visible = true
		_ghost.position = Coords.rect_centre(Rect2i(placement_origin(hover_cell), def.footprint)) \
			+ Vector3.UP * (PlaceholderStyle.building(selected_def)[1] as float) * 0.5
		_ghost.material_override = _ghost_ok_mat if can_place_at(hover_cell) else _ghost_bad_mat


func _select_entity(entity_id: int) -> void:
	selected_entity = entity_id
	selection_changed.emit(entity_id)

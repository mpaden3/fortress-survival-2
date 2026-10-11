class_name BuildController
extends Node3D
## Local player's input: build (pick a root building, preview, place), select and sell,
## command the Survivor and trained units. Everything goes through World commands, exactly
## like a test would.
##
## Build: 1 Wall, 2 Basic Tower, 3 Mill, 4 Barracks; LMB place (drag paints walls); Esc or
## RMB cancels. Shift queues orders. LMB on a building selects it; X sells the selection.
## Units: LMB click or drag a box selects; RMB move, T then LMB attack-move, Z stop, V hold.
## With no units selected, RMB orders the Survivor: move (on own damaged building: repair).
## Survivor: F Blink at cursor, H Haste.
## Selected building: 7 / 8 / 9 / 0 run its actions: upgrades first, then units to train.

const HOTKEYS := {KEY_1: &"wall", KEY_2: &"basic_tower", KEY_3: &"mill", KEY_4: &"barracks"}
const ACTION_KEYS: Array[Key] = [KEY_7, KEY_8, KEY_9, KEY_0]
## Mouse travel (pixels) under which a press-release is a click, not a box.
const CLICK_SLOP := 6.0
## How close (cells) to a unit a click must land to pick it.
const PICK_RADIUS := 0.8

signal selection_changed(entity_id: int)
signal units_selected(unit_ids: Array[int])

var world: World
var camera: RtsCamera
var player_id := 0
var selected_def: StringName = &""
var selected_entity := 0
var hover_cell := Vector2i(-1, -1)
## Ground point under the mouse in cell units.
var hover_point := Vector2(-1, -1)
var selected_units: Array[int] = []
## Waiting for the LMB target of an attack-move.
var attack_move_armed := false
## Screen rect of the selection box being dragged (size 0 if none).
var drag_rect := Rect2()

var _ghost: MeshInstance3D
var _ghost_ok_mat := PlaceholderStyle.material(PlaceholderStyle.GHOST_OK)
var _ghost_bad_mat := PlaceholderStyle.material(PlaceholderStyle.GHOST_BAD)
var _painting := false
var _last_painted := Vector2i(-1, -1)
var _box_selecting := false
var _drag_start := Vector2.ZERO


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


## Submits a placement of the selected building centred under `cell` (a Survivor build order).
func request_place(cell: Vector2i, queue := false) -> void:
	if selected_def:
		world.submit(Commands.place_building(player_id, selected_def, placement_origin(cell), queue))


## Right-click: repair an own damaged building under the cursor, otherwise move there.
func request_smart_order(cell: Vector2i, queue := false) -> void:
	var building := world.entities.get(world.grid.occupant(cell)) as BuildingState
	if building and building.owner == player_id and building.hp < building.def.max_hp and not building.constructing:
		world.submit(Commands.repair(player_id, building.id, queue))
	else:
		world.submit(Commands.move_survivor(player_id, cell, queue, hover_point))


## Actions of a building, in key order: its upgrades (building ids), then the units it
## trains (unit ids).
static func building_actions(building: BuildingState) -> Array[StringName]:
	var actions: Array[StringName] = []
	actions.append_array(building.def.upgrades)
	actions.append_array(building.def.trains)
	return actions


## Runs the selected building's `option`-th action (upgrade or train).
func request_action_selected(option: int) -> void:
	var building := world.entities.get(selected_entity) as BuildingState
	if building == null:
		return
	var actions := building_actions(building)
	if option >= actions.size():
		return
	if option < building.def.upgrades.size():
		world.submit(Commands.upgrade_building(player_id, building.id, actions[option]))
	else:
		world.submit(Commands.train_unit(player_id, building.id, actions[option]))


## Orders the selected units (`order`: move, attack_move, stop, hold).
func request_unit_order(order: String, cell := Vector2i.ZERO, queue := false, point := Vector2(-1, -1)) -> void:
	_prune_selection()
	if not selected_units.is_empty():
		world.submit(Commands.order_units(player_id, selected_units.duplicate(), order, cell, queue, point))


func select_units(unit_ids: Array[int]) -> void:
	selected_units = unit_ids
	units_selected.emit(selected_units)
	if not unit_ids.is_empty():
		_select_entity(0)


## Own unit nearest to `point` (cell units) within PICK_RADIUS, or 0.
func unit_near(point: Vector2) -> int:
	var best := 0
	var best_distance := PICK_RADIUS
	for unit in world.units.living():
		var distance := unit.position.distance_to(point)
		if unit.owner == player_id and distance <= best_distance:
			best_distance = distance
			best = unit.id
	return best


## Own units whose screen position lies in `rect`.
func units_in_screen_rect(rect: Rect2) -> Array[int]:
	var out: Array[int] = []
	for unit in world.units.living():
		var at := Vector3(unit.position.x * Coords.CELL, 0.5, unit.position.y * Coords.CELL)
		if unit.owner == player_id and not camera.camera.is_position_behind(at) \
				and rect.has_point(camera.camera.unproject_position(at)):
			out.append(unit.id)
	return out


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
			if selected_def or attack_move_armed:
				select_def(&"")
				attack_move_armed = false
			else:
				select_units([] as Array[int])
				_select_entity(0)
		elif key.physical_keycode == KEY_X:
			request_sell_selected()
		elif key.physical_keycode in ACTION_KEYS:
			request_action_selected(ACTION_KEYS.find(key.physical_keycode))
		elif key.physical_keycode == KEY_T:
			attack_move_armed = not selected_units.is_empty()
		elif key.physical_keycode == KEY_Z:
			request_unit_order("stop")
		elif key.physical_keycode == KEY_V:
			request_unit_order("hold")
		elif key.physical_keycode == KEY_F:
			world.submit(Commands.blink(player_id, hover_cell))
		elif key.physical_keycode == KEY_H:
			world.submit(Commands.haste(player_id))
		return
	var button := event as InputEventMouseButton
	if button == null:
		return
	if button.button_index == MOUSE_BUTTON_RIGHT and button.pressed:
		_prune_selection()
		if selected_def or attack_move_armed:
			select_def(&"")
			attack_move_armed = false
		elif not selected_units.is_empty():
			request_unit_order("move", hover_cell, button.shift_pressed, hover_point)
		else:
			request_smart_order(hover_cell, button.shift_pressed)
	elif button.button_index == MOUSE_BUTTON_LEFT:
		_painting = button.pressed and selected_def == &"wall"
		if button.pressed:
			if selected_def:
				# Painting a wall line always queues, so the Survivor builds the whole line.
				request_place(hover_cell, button.shift_pressed or selected_def == &"wall")
				_last_painted = hover_cell
			elif attack_move_armed:
				request_unit_order("attack_move", hover_cell, button.shift_pressed, hover_point)
				attack_move_armed = false
			else:
				_box_selecting = true
				_drag_start = button.position
		elif _box_selecting:
			_box_selecting = false
			drag_rect = Rect2()
			_finish_selection(button.position)


func _process(_delta: float) -> void:
	if world == null or camera == null:
		return
	if _box_selecting:
		var mouse := get_viewport().get_mouse_position()
		drag_rect = Rect2(_drag_start, mouse - _drag_start).abs() \
			if _drag_start.distance_to(mouse) >= CLICK_SLOP else Rect2()
	var point: Variant = camera.ground_under_mouse()
	if point == null:
		_ghost.visible = false
		return
	hover_cell = Coords.world_to_cell(point)
	hover_point = Vector2(point.x, point.z) / Coords.CELL
	if _painting and hover_cell != _last_painted:
		request_place(hover_cell, true)
		_last_painted = hover_cell
	if selected_def:
		var def := world.defs.building(selected_def)
		_ghost.visible = true
		_ghost.position = Coords.rect_centre(Rect2i(placement_origin(hover_cell), def.footprint)) \
			+ Vector3.UP * (PlaceholderStyle.building(selected_def)[1] as float) * 0.5
		_ghost.material_override = _ghost_ok_mat if can_place_at(hover_cell) else _ghost_bad_mat


## LMB released: a click picks a unit (else a building); a drag selects own units in the box.
func _finish_selection(release: Vector2) -> void:
	if _drag_start.distance_to(release) < CLICK_SLOP:
		var unit_id := unit_near(hover_point)
		if unit_id:
			select_units([unit_id] as Array[int])
		else:
			select_units([] as Array[int])
			_select_entity(world.grid.occupant(hover_cell))
		return
	select_units(units_in_screen_rect(Rect2(_drag_start, release - _drag_start).abs()))


## Drops dead units from the selection.
func _prune_selection() -> void:
	var alive: Array[int] = []
	for unit_id in selected_units:
		if world.entities.has(unit_id):
			alive.append(unit_id)
	if alive.size() != selected_units.size():
		select_units(alive)


func _select_entity(entity_id: int) -> void:
	selected_entity = entity_id
	selection_changed.emit(entity_id)

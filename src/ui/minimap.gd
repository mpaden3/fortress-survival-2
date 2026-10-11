class_name Minimap
extends PanelContainer
## Bottom left: the whole map. Terrain is drawn once; buildings, units, the Survivor and enemies
## are redrawn a few times a second, with a marker where the camera looks.
## LMB (or drag) moves the camera there; RMB orders the selected units, else the Survivor.

const SIZE := 190.0
const REFRESH_SECONDS := 0.25
const ENEMY := Color(0.95, 0.20, 0.15)
const BUILDING := Color(0.45, 0.65, 0.95)
const UNIT := Color(0.35, 1.0, 0.45)
const SURVIVOR := Color(1.0, 1.0, 1.0)
const CAMERA := Color(1.0, 0.85, 0.3)

var game: Game
var texture_rect: TextureRect
var _base: Image
var _image: Image
var _texture: ImageTexture
var _since_refresh := 0.0


func setup(target: Game) -> void:
	game = target


func _ready() -> void:
	name = "Minimap"
	add_theme_stylebox_override("panel", HudStyle.panel_box())
	texture_rect = TextureRect.new()
	texture_rect.custom_minimum_size = Vector2(SIZE, SIZE)
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	texture_rect.gui_input.connect(_on_gui_input)
	add_child(texture_rect)


func _process(delta: float) -> void:
	if game == null or game.world == null:
		return
	if _base == null:
		_bake_terrain()
	_since_refresh += delta
	if _since_refresh >= REFRESH_SECONDS:
		_since_refresh = 0.0
		refresh()


## Redraws the dynamic layer now.
func refresh() -> void:
	var world := game.world
	_image.copy_from(_base)
	for entity: SimEntity in world.entities.values():
		var building := entity as BuildingState
		if building:
			_image.fill_rect(building.rect, BUILDING)
	var size := world.map.size
	for p in world.enemies.positions:
		var x := floori(p.x)
		var z := floori(p.y)
		if x >= 0 and z >= 0 and x < size.x and z < size.y:
			_image.set_pixel(x, z, ENEMY)
	for unit in world.units.living():
		_dot(unit.cell(), UNIT, 0)
	for survivor in world.survivors.living():
		_dot(survivor.cell(), SURVIVOR, 1)
	var look := Coords.world_to_cell(game.camera.position)
	_dot(look, CAMERA, 2, true)
	_texture.update(_image)


## Map cell under a point of the minimap control, or (-1, -1) outside the map.
func cell_at(local: Vector2) -> Vector2i:
	var size := Vector2(game.world.map.size)
	var area := texture_rect.size
	var scale := minf(area.x / size.x, area.y / size.y)
	var offset := (area - size * scale) * 0.5
	var cell := Vector2i(((local - offset) / scale).floor())
	return cell if game.world.map.in_bounds(cell) else Vector2i(-1, -1)


func _on_gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	var motion := event as InputEventMouseMotion
	if button and button.pressed and button.button_index == MOUSE_BUTTON_LEFT \
			or motion and motion.button_mask & MOUSE_BUTTON_MASK_LEFT:
		var cell := cell_at(event.position)
		if cell.x >= 0:
			game.follow_survivor = false
			game.camera.focus(Coords.cell_centre(cell))
	elif button and button.pressed and button.button_index == MOUSE_BUTTON_RIGHT:
		var cell := cell_at(button.position)
		if cell.x < 0:
			return
		var builder := game.builder
		if builder.selected_units.is_empty():
			builder.request_smart_order(cell, button.shift_pressed)
		else:
			builder.request_unit_order("move", cell, button.shift_pressed)


func _bake_terrain() -> void:
	var map := game.world.map
	_base = Image.create(map.size.x, map.size.y, false, Image.FORMAT_RGB8)
	for z in map.size.y:
		for x in map.size.x:
			var colour := PlaceholderStyle.GROUND.darkened(0.15)
			match map.terrain_at(Vector2i(x, z)):
				MapLayout.Terrain.BLOCKED:
					colour = PlaceholderStyle.BLOCKED
				MapLayout.Terrain.WATER:
					colour = PlaceholderStyle.WATER
				MapLayout.Terrain.TREE:
					colour = PlaceholderStyle.TREE
			_base.set_pixel(x, z, colour)
	for spawn in map.spawns:
		_base.fill_rect(spawn.rect, PlaceholderStyle.GROUND.darkened(0.15).lerp(Color(PlaceholderStyle.SPAWN, 1.0), 0.5))
	_image = _base.duplicate()
	_texture = ImageTexture.create_from_image(_image)
	texture_rect.texture = _texture


## A small square of `radius` cells around `cell` (hollow for the camera marker).
func _dot(cell: Vector2i, colour: Color, radius: int, hollow := false) -> void:
	var size := game.world.map.size
	for dz in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			if hollow and absi(dx) != radius and absi(dz) != radius:
				continue
			var x := cell.x + dx
			var z := cell.y + dz
			if x >= 0 and z >= 0 and x < size.x and z < size.y:
				_image.set_pixel(x, z, colour)

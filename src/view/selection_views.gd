class_name SelectionViews
extends Node3D
## What's selected, drawn on the ground: a ring under each selected unit, building and the
## Survivor; for selected movers, waypoint lines along their route and queued orders with a
## marker at each order's target; and a short ping where an order was clicked.

const RING_COLOUR := Color(0.35, 1.0, 0.45)
const ENEMY_RING := Color(1.0, 0.35, 0.3)
const LINE_COLOUR := Color(0.35, 1.0, 0.45, 0.8)
const ATTACK_COLOUR := Color(1.0, 0.4, 0.3, 0.9)
const BLINK_COLOUR := Color(0.45, 0.75, 1.0)
const RING_WIDTH := 0.14
## Waypoint lines, in cells.
const LINE_WIDTH := 0.14
const MARKER_RADIUS := 0.35
const PING_SECONDS := 0.5
const GROUND := 0.06

## Set by Game each frame, like the other views.
var alpha := 1.0
var _world: World
var _builder: BuildController
var _rings: Array[MeshInstance3D] = []
var _lines: MeshInstance3D
var _mesh := ImmediateMesh.new()
var _line_material: StandardMaterial3D
var _pings: Array[Dictionary] = []
var _ring_mesh: TorusMesh
var _materials := {}


func attach(world: World, builder: BuildController) -> void:
	_world = world
	_builder = builder
	builder.ordered.connect(ping)


func _ready() -> void:
	_ring_mesh = TorusMesh.new()
	_ring_mesh.inner_radius = 1.0 - RING_WIDTH
	_ring_mesh.outer_radius = 1.0
	_ring_mesh.rings = 32
	_ring_mesh.ring_segments = 4
	_line_material = _unshaded(Color.WHITE)
	_line_material.vertex_color_use_as_albedo = true
	_lines = MeshInstance3D.new()
	_lines.name = "Waypoints"
	_lines.mesh = _mesh
	_lines.material_override = _line_material
	_lines.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_lines)


## Shows a shrinking ring where an order was given.
func ping(point: Vector2, kind: String) -> void:
	_pings.append({"point": point, "kind": kind, "age": 0.0})


func ping_count() -> int:
	return _pings.size()


## Selected things, each {position (cell units), radius (cells), colour}.
func selected_rings() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for mover in selected_movers():
		var radius: float = mover.def.radius / SimConstants.CELL_SIZE + 0.3
		out.append({"position": mover.position_at(alpha), "radius": radius, "colour": RING_COLOUR})
	var building := _world.entities.get(_builder.selected_entity) as BuildingState
	if building:
		out.append({"position": building.centre(), "radius": Vector2(building.rect.size).length() * 0.5,
			"colour": RING_COLOUR if building.owner == _builder.player_id else ENEMY_RING})
	return out


## Selected units and Survivor (alive).
func selected_movers() -> Array:
	var out := []
	for unit_id in _builder.selected_units:
		var unit := _world.entities.get(unit_id) as UnitState
		if unit:
			out.append(unit)
	var survivor := _world.survivors.survivor_of(_builder.player_id)
	if _builder.survivor_selected and survivor and survivor.alive:
		out.append(survivor)
	return out


## Where a mover is going, in order (cell units): the rest of its current route, then the
## target of each queued order after it.
static func waypoints(world: World, mover: Object) -> PackedVector2Array:
	var out := PackedVector2Array()
	var orders: Array[Dictionary] = mover.orders
	out.append_array(mover.path)
	for k in orders.size():
		if k == 0 and not out.is_empty():
			continue  # the current route already ends at it
		out.append(order_target(world, orders[k]))
	return out


## The point an order heads for (cell units).
static func order_target(world: World, order: Dictionary) -> Vector2:
	match order.get("kind", ""):
		"build":
			var def := world.defs.building(order["def"])
			return Vector2(order["cell"]) + Vector2(def.footprint) * 0.5
		"repair":
			var building := world.entities.get(order["building"]) as BuildingState
			return building.centre() if building else Vector2.ZERO
	return GridPaths.point_in(order["cell"], order.get("point", Vector2(-1, -1)))


func _process(delta: float) -> void:
	if _world == null:
		return
	_draw_rings()
	_draw_waypoints_and_pings(delta)


func _draw_rings() -> void:
	var rings := selected_rings()
	while _rings.size() < rings.size():
		var ring := MeshInstance3D.new()
		ring.mesh = _ring_mesh
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ring)
		_rings.append(ring)
	for k in _rings.size():
		var ring := _rings[k]
		ring.visible = k < rings.size()
		if not ring.visible:
			continue
		var data := rings[k]
		var radius: float = data["radius"] * Coords.CELL
		ring.position = _ground(data["position"])
		ring.scale = Vector3(radius, 0.2, radius)
		ring.material_override = _material(data["colour"])


func _draw_waypoints_and_pings(delta: float) -> void:
	_mesh.clear_surfaces()
	var has_lines := false
	for mover in selected_movers():
		var points := waypoints(_world, mover)
		if points.is_empty():
			continue
		var attack: bool = not mover.orders.is_empty() and mover.orders[0].get("kind", "") == "attack_move"
		var colour := ATTACK_COLOUR if attack else LINE_COLOUR
		if not has_lines:
			_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
			has_lines = true
		var from: Vector2 = mover.position_at(alpha)
		for point in points:
			_line(from, point, colour)
			from = point
		for order in mover.orders:
			_circle(order_target(_world, order), MARKER_RADIUS, colour)
	for k in range(_pings.size() - 1, -1, -1):
		var ping_data := _pings[k]
		ping_data["age"] += delta
		if ping_data["age"] >= PING_SECONDS:
			_pings.remove_at(k)
			continue
		if not has_lines:
			_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
			has_lines = true
		var t: float = ping_data["age"] / PING_SECONDS
		var colour: Color = {"attack_move": ATTACK_COLOUR, "blink": BLINK_COLOUR}.get(ping_data["kind"], LINE_COLOUR)
		colour.a = 1.0 - t
		_circle(ping_data["point"], lerpf(0.9, 0.2, t), colour)
	if has_lines:
		_mesh.surface_end()


## A flat ribbon LINE_WIDTH cells wide from `a` to `b` (two triangles).
func _line(a: Vector2, b: Vector2, colour: Color) -> void:
	var along := b - a
	if along.length_squared() < 0.000001:
		return
	var side := along.normalized().orthogonal() * LINE_WIDTH * 0.5
	for corner in [a - side, a + side, b + side, a - side, b + side, b - side]:
		_mesh.surface_set_color(colour)
		_mesh.surface_add_vertex(_ground(corner))


func _circle(centre: Vector2, radius: float, colour: Color) -> void:
	var segments := 20
	for s in segments:
		var a := centre + Vector2.from_angle(TAU * s / segments) * radius
		var b := centre + Vector2.from_angle(TAU * (s + 1) / segments) * radius
		_line(a, b, colour)


static func _ground(cells: Vector2) -> Vector3:
	return Vector3(cells.x * Coords.CELL, GROUND, cells.y * Coords.CELL)


func _material(colour: Color) -> StandardMaterial3D:
	if not _materials.has(colour):
		_materials[colour] = _unshaded(colour)
	return _materials[colour]


static func _unshaded(colour: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = colour
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat

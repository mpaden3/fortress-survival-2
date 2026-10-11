class_name ProjectileViews
extends Node3D
## Draws in-flight projectiles as small spheres (one MultiMesh, raw buffer per frame),
## interpolated between the last two ticks by `alpha` (set by Game each frame).

const HEIGHT := 2.5

var alpha := 1.0
var _world: World
var _instance: MultiMeshInstance3D
var _buffer := PackedFloat32Array()


func attach(world: World) -> void:
	_world = world
	var sphere := SphereMesh.new()
	sphere.radius = 0.18
	sphere.height = 0.36
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = sphere
	_instance = MultiMeshInstance3D.new()
	_instance.multimesh = multimesh
	_instance.material_override = PlaceholderStyle.material(Color(1.0, 0.92, 0.55))
	_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_instance)


func _process(_delta: float) -> void:
	if _world == null:
		return
	var positions := _world.combat.proj_pos
	var n := positions.size()
	var previous := _world.combat.proj_prev if _world.combat.proj_prev.size() == n else positions
	var multimesh := _instance.multimesh
	if multimesh.instance_count < n:
		multimesh.instance_count = maxi(maxi(n, multimesh.instance_count * 2), 32)
		_buffer.resize(multimesh.instance_count * 12)
	multimesh.visible_instance_count = n
	if n == 0:
		return
	var cell := SimConstants.CELL_SIZE
	for i in n:
		var o := i * 12
		var p := previous[i] + (positions[i] - previous[i]) * alpha
		_buffer[o] = 1.0
		_buffer[o + 1] = 0.0
		_buffer[o + 2] = 0.0
		_buffer[o + 3] = p.x * cell
		_buffer[o + 4] = 0.0
		_buffer[o + 5] = 1.0
		_buffer[o + 6] = 0.0
		_buffer[o + 7] = HEIGHT
		_buffer[o + 8] = 0.0
		_buffer[o + 9] = 0.0
		_buffer[o + 10] = 1.0
		_buffer[o + 11] = p.y * cell
	multimesh.buffer = _buffer

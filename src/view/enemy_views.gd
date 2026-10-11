class_name EnemyViews
extends Node3D
## Draws every enemy with one MultiMesh per enemy type, refilled from the EnemyManager's
## arrays each frame through the raw transform buffer (one call per type, not per enemy).

const COLOURS := {
	"grunt": Color(0.62, 0.22, 0.16),
	"brute": Color(0.35, 0.08, 0.10),
	"runner": Color(0.90, 0.70, 0.15),
}

var _world: World
var _instances: Array[MultiMeshInstance3D] = []
var _buffers: Array[PackedFloat32Array] = []
var _counts := PackedInt32Array()


func attach(world: World) -> void:
	_world = world
	for def in world.defs.enemy_list:
		var mesh := CapsuleMesh.new()
		mesh.radius = def.radius
		mesh.height = maxf(def.radius * 2.0, def.radius * 4.5)
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = mesh
		var instance := MultiMeshInstance3D.new()
		instance.name = String(def.id)
		instance.multimesh = multimesh
		instance.material_override = PlaceholderStyle.material(COLOURS.get(String(def.id), Color.MAGENTA))
		add_child(instance)
		_instances.append(instance)
		_buffers.append(PackedFloat32Array())
	_counts.resize(world.defs.enemy_list.size())


func _process(_delta: float) -> void:
	if _world == null:
		return
	var enemies := _world.enemies
	var types := enemies.types
	var positions := enemies.positions
	var n := enemies.count()
	_counts.fill(0)
	for i in n:
		_counts[types[i]] += 1
	for t in _instances.size():
		var multimesh := _instances[t].multimesh
		if multimesh.instance_count < _counts[t]:
			multimesh.instance_count = maxi(maxi(_counts[t], multimesh.instance_count * 2), 64)
			_buffers[t].resize(multimesh.instance_count * 12)
		multimesh.visible_instance_count = _counts[t]
	var cell := SimConstants.CELL_SIZE
	for t in _instances.size():
		if _counts[t] == 0:
			continue
		var y := (_instances[t].multimesh.mesh as CapsuleMesh).height * 0.5
		# Rows of a 3x4 transform: identity basis, translation in each row's 4th column.
		var buffer := _buffers[t]
		var o := 0
		for i in n:
			if types[i] != t:
				continue
			var p := positions[i]
			buffer[o] = 1.0
			buffer[o + 1] = 0.0
			buffer[o + 2] = 0.0
			buffer[o + 3] = p.x * cell
			buffer[o + 4] = 0.0
			buffer[o + 5] = 1.0
			buffer[o + 6] = 0.0
			buffer[o + 7] = y
			buffer[o + 8] = 0.0
			buffer[o + 9] = 0.0
			buffer[o + 10] = 1.0
			buffer[o + 11] = p.y * cell
			o += 12
		_buffers[t] = buffer
		_instances[t].multimesh.buffer = buffer

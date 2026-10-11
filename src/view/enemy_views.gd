class_name EnemyViews
extends Node3D
## Draws every enemy with one MultiMesh per enemy type, refilled from the EnemyManager's
## arrays each frame through the raw transform buffer (one call per type, not per enemy).
## Positions are interpolated between the last two ticks by `alpha` (set by Game each frame).

const COLOURS := {
	"grunt": Color(0.62, 0.22, 0.16),
	"brute": Color(0.35, 0.08, 0.10),
	"runner": Color(0.90, 0.70, 0.15),
	"warlord": Color(0.55, 0.10, 0.55),
	"behemoth": Color(0.12, 0.05, 0.05),
}

## Fraction of a tick since the last one: 0 draws the previous tick, 1 the latest.
var alpha := 1.0
## Whose fog of war applies (set by Game).
var player_id := 0
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
	var previous := enemies.previous_positions if enemies.previous_positions.size() == positions.size() else positions
	var t_alpha := alpha
	var n := enemies.count()
	# Fog of war: hidden enemies aren't drawn (the mask is empty while everything is visible).
	var fog := _world.visibility.mask(player_id)
	var hidden := PackedByteArray()
	if not fog.is_empty():
		hidden.resize(n)
		for i in n:
			hidden[i] = 0 if VisibilitySystem.shown(fog, _world.map.size.x, positions[i]) else 1
	_counts.fill(0)
	for i in n:
		if hidden.is_empty() or hidden[i] == 0:
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
			if types[i] != t or (not hidden.is_empty() and hidden[i] == 1):
				continue
			var q := previous[i]
			var p := q + (positions[i] - q) * t_alpha
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

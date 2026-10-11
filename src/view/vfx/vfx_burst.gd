@tool
class_name VfxBurst
extends Node3D
## A one-shot effect (flash, impact, explosion). play() restarts every GPUParticles3D child,
## fades every Light3D child and drives the `progress` (0 -> 1) and `seed` instance uniforms
## of every shader mesh child over `duration`, then hides itself. Pooled: play() reuses it.
##
## In the editor it replays on a loop, so tweaks in the Inspector show up immediately.

## Seconds until the effect hides; keep it >= the longest particle lifetime.
@export var duration := 0.6
## Light energy (times its value in the scene) over normalized time; empty = linear fade.
@export var light_curve: Curve
## Editor preview only: pause between replays.
@export var editor_replay_gap := 0.6

var _time := 0.0
var _playing := false
var _lights: Array[Light3D] = []
var _energies := PackedFloat32Array()
var _particles: Array[GPUParticles3D] = []
var _meshes: Array[GeometryInstance3D] = []


func _ready() -> void:
	_collect(self)
	if Engine.is_editor_hint():
		play()
	else:
		_finish()


func play() -> void:
	_time = 0.0
	_playing = true
	visible = true
	for particles in _particles:
		particles.restart()
	var seed_value := randf() * TAU
	for mesh in _meshes:
		mesh.set_instance_shader_parameter(&"seed", seed_value)
	_apply(0.0)
	set_process(true)


func is_playing() -> bool:
	return _playing


func _process(delta: float) -> void:
	_time += delta
	if Engine.is_editor_hint():
		if _time >= duration + editor_replay_gap:
			play()
		elif _time >= duration:
			visible = false
		else:
			_apply(_time / duration)
		return
	if _time >= duration:
		_finish()
		return
	_apply(_time / duration)


func _apply(t: float) -> void:
	var fade := light_curve.sample_baked(t) if light_curve else 1.0 - t
	for i in _lights.size():
		_lights[i].light_energy = _energies[i] * fade
	for mesh in _meshes:
		mesh.set_instance_shader_parameter(&"progress", t)


func _finish() -> void:
	_playing = false
	visible = false
	set_process(false)


func _collect(node: Node) -> void:
	for child in node.get_children():
		if child is GPUParticles3D:
			_particles.append(child)
		elif child is Light3D:
			_lights.append(child)
			_energies.append(child.light_energy)
		elif child is GeometryInstance3D and child.material_override is ShaderMaterial:
			_meshes.append(child)
		_collect(child)

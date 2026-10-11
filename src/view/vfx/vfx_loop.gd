@tool
class_name VfxLoop
extends Node3D
## A looping effect (fire, smoke) whose strength follows `intensity` (0..1): it scales the
## amount of every GPUParticles3D child and the energy of every Light3D child, which also
## flickers. Set intensity from the view; tune the look in the scene.

@export_range(0.0, 1.0) var intensity := 1.0:
	set(value):
		intensity = clampf(value, 0.0, 1.0)
		_apply_amount()
## Below this intensity particles still run at this fraction, so a fire never looks empty.
@export_range(0.0, 1.0) var min_amount := 0.25
## Light flicker: fraction of energy that wobbles, and how fast.
@export_range(0.0, 1.0) var flicker := 0.35
@export var flicker_speed := 9.0

var _time := 0.0
var _lights: Array[Light3D] = []
var _energies := PackedFloat32Array()
var _particles: Array[GPUParticles3D] = []
var _offset := 0.0


func _ready() -> void:
	_offset = randf() * 100.0
	for child in find_children("*", "GPUParticles3D", true, false):
		_particles.append(child)
	for child in find_children("*", "Light3D", true, false):
		_lights.append(child)
		_energies.append(child.light_energy)
	_apply_amount()


func _process(delta: float) -> void:
	_time += delta
	var t := _time * flicker_speed + _offset
	# Two detuned sines read as an irregular flicker without a noise lookup.
	var wobble := 0.5 + 0.3 * sin(t) + 0.2 * sin(t * 2.37 + 1.3)
	for i in _lights.size():
		_lights[i].light_energy = _energies[i] * intensity * (1.0 - flicker * wobble)


func _apply_amount() -> void:
	for particles in _particles:
		particles.emitting = intensity > 0.0
		particles.amount_ratio = lerpf(min_amount, 1.0, intensity)

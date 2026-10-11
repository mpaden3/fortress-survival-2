extends Node3D
## VFX gallery (scenes/vfx/vfx_gallery.tscn): every effect side by side, replayed every
## `interval` seconds. Open it in the editor to tune effects (they also replay there), or run
## it with F6.
##
## Headless frame capture: `godot --path . scenes/vfx/vfx_gallery.tscn -- --screenshot=/tmp/vfx.png
## --at=0.05,0.3,0.8` saves /tmp/vfx_0.05.png etc., at those seconds after a replay (after
## a warm-up so looping fires are fully lit).

@export var interval := 2.5
## Seconds before captures start, so looping effects have filled in.
@export var warm_up := 3.0

var _time := 0.0
var _cycle_start := 0.0
var _shots := PackedFloat32Array()
var _shot_path := ""


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			_shot_path = arg.get_slice("=", 1)
		elif arg.begins_with("--at="):
			for part in arg.get_slice("=", 1).split(","):
				_shots.append(part.to_float())
	if _shot_path and _shots.is_empty():
		_shots.append(0.1)
	_replay()


func _process(delta: float) -> void:
	_time += delta
	if _time - _cycle_start >= interval:
		_replay()
	if _shot_path.is_empty() or _time < warm_up or _shots.is_empty():
		return
	var since := _time - _cycle_start
	if since >= _shots[0] and (_cycle_start >= warm_up):
		_capture(_shots[0])
		_shots.remove_at(0)
		if _shots.is_empty():
			get_tree().quit()


func _replay() -> void:
	_cycle_start = _time
	for child in find_children("*", "VfxBurst", true, false):
		(child as VfxBurst).play()


func _capture(at: float) -> void:
	var path := "%s_%s.%s" % [_shot_path.get_basename(), "%.2f" % at, _shot_path.get_extension()]
	get_viewport().get_texture().get_image().save_png(path)
	print("screenshot saved: ", path)

class_name RtsCamera
extends Node3D
## WC3-style camera: angled view of a pivot on the ground.
## Pan: WASD / arrows / screen edge. Zoom: mouse wheel. Rotate: Q / E.

@export var pan_speed := 40.0
@export var edge_margin := 8
@export var edge_pan := true
@export var min_distance := 12.0
@export var max_distance := 140.0
@export var pitch_degrees := 55.0
@export var rotate_speed := 90.0

var distance := 45.0
var bounds := Rect2(0, 0, 100, 100)
var camera: Camera3D


func _ready() -> void:
	camera = Camera3D.new()
	camera.far = 2000.0
	add_child(camera)
	_update_camera()


func focus(point: Vector3) -> void:
	position = Vector3(point.x, 0.0, point.z)
	_clamp()


func _unhandled_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button and button.pressed:
		if button.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = maxf(min_distance, distance * 0.9)
		elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = minf(max_distance, distance * 1.1)
		_update_camera()


func _process(delta: float) -> void:
	var move := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP): move.y -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN): move.y += 1
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT): move.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT): move.x += 1
	if edge_pan and DisplayServer.window_is_focused():
		var mouse := get_viewport().get_mouse_position()
		var screen := get_viewport().get_visible_rect().size
		if mouse.x <= edge_margin: move.x -= 1
		if mouse.x >= screen.x - edge_margin: move.x += 1
		if mouse.y <= edge_margin: move.y -= 1
		if mouse.y >= screen.y - edge_margin: move.y += 1
	if Input.is_physical_key_pressed(KEY_Q): rotation.y += deg_to_rad(rotate_speed) * delta
	if Input.is_physical_key_pressed(KEY_E): rotation.y -= deg_to_rad(rotate_speed) * delta
	if move != Vector2.ZERO:
		var step := move.normalized() * pan_speed * delta * (distance / 45.0)
		position += global_basis * Vector3(step.x, 0.0, step.y)
		_clamp()


## Point on the ground plane under the mouse, or null when looking past the horizon.
func ground_under_mouse() -> Variant:
	var mouse := get_viewport().get_mouse_position()
	var origin := camera.project_ray_origin(mouse)
	var direction := camera.project_ray_normal(mouse)
	return Plane(Vector3.UP, 0.0).intersects_ray(origin, direction)


func _update_camera() -> void:
	if camera == null:
		return
	var pitch := deg_to_rad(pitch_degrees)
	camera.position = Vector3(0.0, sin(pitch), cos(pitch)) * distance
	camera.look_at(global_position, Vector3.UP)


func _clamp() -> void:
	position.x = clampf(position.x, bounds.position.x, bounds.end.x)
	position.z = clampf(position.z, bounds.position.y, bounds.end.y)

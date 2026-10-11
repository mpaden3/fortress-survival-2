class_name Game
extends Node3D
## Entry scene: runs a World in real time and wires up views, camera, input and HUD.
##
## User args (after `--`): --map=<id> (default test_map), --screenshot=<png path> saves one
## frame and quits, --demo places a few sample buildings.

const LOCAL_PLAYER := 0
const DEFAULT_MAP := "test_map"

var world: World
var clock := SimClock.new()
var map_view: MapView
var building_views: BuildingViews
var camera: RtsCamera
var builder: BuildController
var hud: Hud

var _args := {}
var _frames := 0


func _ready() -> void:
	_args = _parse_user_args()
	var map_id: String = _args.get("map", DEFAULT_MAP)
	var layout := MapLayout.load_file("res://data/maps/%s.json" % map_id)
	world = World.new(layout, DefRegistry.load_default(), 1)
	world.add_player(LOCAL_PLAYER)
	_setup_environment()

	map_view = MapView.new()
	map_view.name = "MapView"
	add_child(map_view)
	map_view.build(layout)

	building_views = BuildingViews.new()
	building_views.name = "Buildings"
	add_child(building_views)
	building_views.attach(world)

	camera = RtsCamera.new()
	camera.name = "Camera"
	camera.bounds = Rect2(0, 0, layout.size.x * Coords.CELL, layout.size.y * Coords.CELL)
	add_child(camera)
	camera.focus(Coords.cell_centre(layout.start))

	builder = BuildController.new()
	builder.name = "Builder"
	builder.setup(world, camera, LOCAL_PLAYER)
	add_child(builder)
	builder.selection_changed.connect(building_views.set_selected)

	hud = Hud.new()
	hud.setup(world, builder, LOCAL_PLAYER)
	add_child(hud)

	if _args.has("demo"):
		_place_demo()


func _process(delta: float) -> void:
	for i in clock.consume(delta):
		step()
	_frames += 1
	if _args.has("screenshot") and _frames == 30:
		camera.edge_pan = false
		var image := get_viewport().get_texture().get_image()
		image.save_png(_args["screenshot"])
		print("screenshot saved: ", _args["screenshot"])
		get_tree().quit()


## One simulation tick, then hand the results to the HUD.
func step() -> void:
	world.step()
	hud.show_results(world.last_results)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.physical_keycode == KEY_P:
		map_view.show_plots = not map_view.show_plots


func _setup_environment() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.shadow_enabled = true
	add_child(sun)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.53, 0.66, 0.78)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.78, 0.85)
	env.ambient_light_energy = 0.6
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)


func _place_demo() -> void:
	var start := world.map.start
	for i in 6:
		world.submit(Commands.place_building(LOCAL_PLAYER, &"wall", start + Vector2i(-3 + i, -4)))
	world.submit(Commands.place_building(LOCAL_PLAYER, &"basic_tower", start + Vector2i(-4, 2)))
	world.submit(Commands.place_building(LOCAL_PLAYER, &"mill", start + Vector2i(3, 2)))
	world.submit(Commands.place_building(LOCAL_PLAYER, &"barracks", start + Vector2i(-1, 3)))
	world.run_seconds(1.0)


static func _parse_user_args() -> Dictionary:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--"):
			var parts := arg.substr(2).split("=", true, 1)
			args[parts[0]] = parts[1] if parts.size() > 1 else true
	return args

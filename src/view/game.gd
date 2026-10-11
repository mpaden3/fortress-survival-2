class_name Game
extends Node3D
## Entry scene: runs a World in real time and wires up views, camera, input and HUD.
##
## Options come from the main menu (Game.options) or user args after `--`:
## --map=<id> (default test_map), --no-waves (sandbox, no match), --host[=port] (co-op host),
## --join=<address>[:port] (co-op client), --screenshot=<png path> saves one frame and quits
## (--screenshot_frame=<n> picks it, default 30), --demo places sample buildings and a wave.
##
## Local or host: this process steps the World. Client: the World mirrors the host's
## snapshots and commands go to the host (NetClient).
## The HUD (src/ui/) has buttons for everything below; development builds add sandbox panels
## (F1 toggles them). Keys: Space centres on the Survivor, L follows it, P plots, M mute,
## F10 menu. Debug keys: G 50 grunts, B 5 brutes, R 30 runners; ] / [ speed x2 / x0.5;
## F5 quick save, F9 quick load.

const LOCAL_PLAYER := 0
const DEFAULT_MAP := "test_map"
const DEBUG_SPAWNS := {KEY_G: [&"grunt", 50], KEY_B: [&"brute", 5], KEY_R: [&"runner", 30]}
const QUICKSAVE := "user://quicksave.fssave"
const MENU_SCENE := "res://scenes/menu.tscn"

## Options chosen in the main menu for the next match (same keys as the user args).
static var options := {}
## A save to load when the scene starts (quick load).
static var pending_load := ""

var world: World
var clock := SimClock.new()
var map_view: MapView
var building_views: BuildingViews
var enemy_views: EnemyViews
var projectile_views: ProjectileViews
var fx_views: FxViews
var sfx_views: SfxViews
var camera: RtsCamera
var builder: BuildController
var hud: Hud
var survivor_views: SurvivorViews
var unit_views: UnitViews
var selection_views: SelectionViews
var net_host: NetHost
var net_client: NetClient
var local_player := LOCAL_PLAYER
## The local player's Survivor (null on a client until the host's first snapshot).
var survivor: SurvivorState:
	get:
		return world.survivors.survivor_of(local_player) if world else null
var follow_survivor := false
var speed := 1.0

var _args := {}
var _frames := 0
var _status: Label


func _ready() -> void:
	_args = _parse_user_args()
	_args.merge(options, true)
	_setup_environment()
	if _args.has("join"):
		_join(str(_args["join"]))
		return
	var layout: MapLayout
	var state := {}
	if pending_load != "":
		state = WorldState.from_bytes(FileAccess.get_file_as_bytes(pending_load))
		pending_load = ""
		layout = MapLayout.load_file("res://data/maps/%s.json" % state["map"])
	else:
		layout = MapLayout.load_file("res://data/maps/%s.json" % _args.get("map", DEFAULT_MAP))
	world = World.new(layout, DefRegistry.load_default(), 1)
	if not state.is_empty():
		WorldState.restore(world, state)
	else:
		world.add_player(LOCAL_PLAYER)
		world.survivors.spawn(world, LOCAL_PLAYER, SurvivorSystem.start_cell(world, LOCAL_PLAYER))
		if not _args.has("no-waves") and not _args.has("demo"):
			world.match_system.start(world, world.defs.schedule)
	_build_scene()
	if _args.has("host"):
		net_host = NetHost.new()
		net_host.name = "NetHost"
		add_child(net_host)
		var port := int(_args["host"]) if str(_args["host"]).is_valid_int() else NetProtocol.DEFAULT_PORT
		var error := net_host.start(world, port)
		hud.show_message("Hosting on port %d" % port if error == OK else "Can't host on port %d (%s)" % [port, error_string(error)])
	if _args.has("demo"):
		_place_demo()


## Co-op client: connect, and build the scene once the host welcomes us.
func _join(address: String) -> void:
	var host := address
	var port := NetProtocol.DEFAULT_PORT
	if ":" in address:
		host = address.get_slice(":", 0)
		port = int(address.get_slice(":", 1))
	_status = Label.new()
	_status.text = "Connecting to %s:%d ..." % [host, port]
	_status.add_theme_font_size_override("font_size", 28)
	_status.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	var layer := CanvasLayer.new()
	layer.add_child(_status)
	add_child(layer)
	net_client = NetClient.new()
	net_client.name = "NetClient"
	add_child(net_client)
	net_client.welcomed.connect(func(player_id: int) -> void:
		local_player = player_id
		world = net_client.world
		layer.queue_free()
		_build_scene())
	net_client.disconnected.connect(func() -> void:
		if hud:
			hud.show_message("Disconnected from the host")
		elif _status:
			_status.text = "Couldn't connect to %s:%d" % [host, port])
	if net_client.start(host, port) != OK:
		_status.text = "Couldn't connect to %s:%d" % [host, port]


func is_client() -> bool:
	return net_client != null


func _build_scene() -> void:
	var layout := world.map
	map_view = MapView.new()
	map_view.name = "MapView"
	add_child(map_view)
	map_view.build(layout)

	building_views = BuildingViews.new()
	building_views.name = "Buildings"
	add_child(building_views)
	building_views.attach(world)

	enemy_views = EnemyViews.new()
	enemy_views.name = "Enemies"
	add_child(enemy_views)
	enemy_views.attach(world)

	projectile_views = ProjectileViews.new()
	projectile_views.name = "Projectiles"
	add_child(projectile_views)
	projectile_views.attach(world)

	fx_views = FxViews.new()
	fx_views.name = "Fx"
	add_child(fx_views)
	fx_views.attach(world)

	sfx_views = SfxViews.new()
	sfx_views.name = "Sfx"
	add_child(sfx_views)
	sfx_views.attach(world)

	unit_views = UnitViews.new()
	unit_views.name = "Units"
	add_child(unit_views)
	unit_views.attach(world)

	survivor_views = SurvivorViews.new()
	survivor_views.name = "Survivors"
	add_child(survivor_views)
	survivor_views.attach(world)

	camera = RtsCamera.new()
	camera.name = "Camera"
	camera.bounds = Rect2(0, 0, layout.size.x * Coords.CELL, layout.size.y * Coords.CELL)
	add_child(camera)
	camera.edge_pan = not _args.has("screenshot")  # the mouse may sit at the window edge
	var own := survivor
	camera.focus(Coords.cell_centre(own.cell() if own else layout.start))

	builder = BuildController.new()
	builder.name = "Builder"
	builder.setup(world, camera, local_player)
	add_child(builder)
	builder.selection_changed.connect(building_views.set_selected)
	selection_views = SelectionViews.new()
	selection_views.name = "Selection"
	add_child(selection_views)
	selection_views.attach(world, builder)
	# Spectating after defeat: the camera no longer follows the dead Survivor.
	world.player_defeated.connect(func(player_id: int) -> void:
		if player_id == local_player:
			follow_survivor = false)

	for view: Node in [enemy_views, projectile_views, fx_views, sfx_views]:
		view.set("player_id", local_player)

	hud = Hud.new()
	hud.setup(self)
	add_child(hud)


func _process(delta: float) -> void:
	if world == null or hud == null:
		return
	var alpha := 1.0
	if is_client():
		alpha = net_client.alpha()
	else:
		for i in clock.consume(delta * speed):
			step()
		alpha = clock.alpha()
	# Views draw between the last two ticks (children process after this node).
	enemy_views.alpha = alpha
	projectile_views.alpha = alpha
	survivor_views.alpha = alpha
	unit_views.alpha = alpha
	selection_views.alpha = alpha
	if follow_survivor and survivor:
		camera.focus(_survivor_point())
	_frames += 1
	if _args.has("screenshot") and _frames == int(_args.get("screenshot_frame", "30")):
		var image := get_viewport().get_texture().get_image()
		image.save_png(_args["screenshot"])
		print("screenshot saved: ", _args["screenshot"])
		get_tree().quit()


## Saves the whole match to `path` (host or single player only).
func quicksave(path := QUICKSAVE) -> bool:
	if is_client():
		return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_buffer(WorldState.to_bytes(WorldState.capture(world)))
	file.close()
	hud.show_message("Saved")
	return true


## Restarts the scene from the save at `path`.
func quickload(path := QUICKSAVE) -> bool:
	if is_client() or not FileAccess.file_exists(path):
		return false
	pending_load = path
	get_tree().reload_current_scene()
	return true


## Back to the main menu.
func quit_to_menu() -> void:
	options = {}
	get_tree().change_scene_to_file(MENU_SCENE)


## One simulation tick, then hand the results to the HUD.
func step() -> void:
	world.step()
	hud.show_results(world.last_results)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or hud == null:
		return
	if key.physical_keycode == KEY_P:
		toggle_plots()
	elif key.physical_keycode == KEY_SPACE:
		camera.focus(_survivor_point())
	elif key.physical_keycode == KEY_L:
		follow_survivor = not follow_survivor
	elif key.physical_keycode == KEY_M:
		set_muted(not is_muted())
	elif key.physical_keycode == KEY_F1:
		hud.toggle_sandbox()
	elif key.physical_keycode == KEY_F10:
		hud.toggle_menu()
	elif OS.is_debug_build() and key.physical_keycode == KEY_F5:
		quicksave()
	elif OS.is_debug_build() and key.physical_keycode == KEY_F9:
		quickload()
	elif OS.is_debug_build() and key.physical_keycode == KEY_BRACKETRIGHT:
		speed = minf(maxf(speed, 0.5) * 2.0, 16.0)
	elif OS.is_debug_build() and key.physical_keycode == KEY_BRACKETLEFT:
		speed = maxf(speed / 2.0, 1.0)
	elif OS.is_debug_build() and DEBUG_SPAWNS.has(key.physical_keycode):
		var entry: Array = DEBUG_SPAWNS[key.physical_keycode]
		var spawn: MapLayout.Spawn = world.map.spawns.pick_random()
		world.submit(Commands.debug_spawn(local_player, entry[0], spawn.id, entry[1], &""))


func toggle_plots() -> void:
	map_view.show_plots = not map_view.show_plots


func is_muted() -> bool:
	return AudioServer.is_bus_mute(0)


func set_muted(muted: bool) -> void:
	AudioServer.set_bus_mute(0, muted)


## Reloads the scene: a fresh match with the same command-line options.
func restart() -> void:
	get_tree().reload_current_scene()


func survivor_point() -> Vector3:
	return _survivor_point()


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
	# Only over-bright pixels bloom: additive flashes and fire, not the scene itself.
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.0
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)


func _place_demo() -> void:
	var start := world.map.start
	for i in 6:
		world.submit(Commands.place_building(LOCAL_PLAYER, &"wall", start + Vector2i(-3 + i, -4), true))
	world.submit(Commands.place_building(LOCAL_PLAYER, &"basic_tower", start + Vector2i(-4, 2), true))
	world.submit(Commands.place_building(LOCAL_PLAYER, &"mill", start + Vector2i(3, 2), true))
	# Pre-built defence so the demo shows combat right away.
	world.players[LOCAL_PLAYER].resource += 200
	for offset in [Vector2i(-6, -2), Vector2i(5, -2), Vector2i(-1, 5)]:
		world.buildings.start_construction(world, LOCAL_PLAYER, &"basic_tower", start + offset)
	world.run_seconds(3.5)
	for entity in world.entities.values():
		var tower := entity as BuildingState
		if tower and tower.def.id == &"basic_tower":
			var branch: StringName = tower.def.upgrades[tower.id % tower.def.upgrades.size()]
			world.submit(Commands.upgrade_building(LOCAL_PLAYER, tower.id, branch))
	# A garrison: fighters around the start, a repairman by the walls.
	for i in 5:
		world.units.spawn(world, LOCAL_PLAYER, &"fighter", Vector2(start) + Vector2(-2.5 + i * 1.2, -2.0))
	world.units.spawn(world, LOCAL_PLAYER, &"repairman", Vector2(start) + Vector2(0.5, -2.5))
	world.buildings.start_construction(world, LOCAL_PLAYER, &"barracks", start + Vector2i(-8, 4))
	for spawn in world.map.spawns.slice(1):
		world.submit(Commands.debug_spawn(LOCAL_PLAYER, &"grunt", spawn.id, 60, &""))
	world.submit(Commands.debug_spawn(LOCAL_PLAYER, &"brute", world.map.spawns[1].id, 6, &""))
	world.submit(Commands.debug_spawn(LOCAL_PLAYER, &"runner", world.map.spawns[2].id, 30, &""))
	world.run_seconds(float(_args.get("demo_seconds", "4")))
	# Show the selection visuals: fighters and the Survivor selected, with queued orders.
	var fighters: Array[int] = []
	for unit in world.units.living():
		if unit.def.is_fighter():
			fighters.append(unit.id)
	builder.select_units(fighters, true)
	world.submit(Commands.order_units(LOCAL_PLAYER, fighters, "attack_move", start + Vector2i(6, 6)))
	world.submit(Commands.order_units(LOCAL_PLAYER, fighters, "attack_move", start + Vector2i(10, 2), true))
	world.submit(Commands.move_survivor(LOCAL_PLAYER, start + Vector2i(-5, 3)))
	world.submit(Commands.move_survivor(LOCAL_PLAYER, start + Vector2i(-5, 8), true))
	world.step()


func _survivor_point() -> Vector3:
	var at := survivor.position_at(net_client.alpha() if is_client() else clock.alpha())
	return Vector3(at.x * Coords.CELL, 0.0, at.y * Coords.CELL)


static func _parse_user_args() -> Dictionary:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--"):
			var parts := arg.substr(2).split("=", true, 1)
			args[parts[0]] = parts[1] if parts.size() > 1 else true
	return args

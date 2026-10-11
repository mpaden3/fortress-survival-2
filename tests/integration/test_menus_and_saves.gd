extends GutTest
## Main menu choices, the in-game menu, the end screen, quick save / load through the Game,
## and a Game joining a host as a co-op client.

const SAVE := "user://test_quicksave.fssave"


func after_each() -> void:
	Game.options = {}
	Game.pending_load = ""


func _game() -> Game:
	var game: Game = load("res://scenes/main.tscn").instantiate()
	add_child_autofree(game)
	return game


func test_main_menu_choices_become_game_options() -> void:
	var menu: MainMenu = load("res://scenes/menu.tscn").instantiate()
	add_child_autofree(menu)
	await wait_process_frames(1)
	var maps := MainMenu.available_maps().map(func(e: Array) -> String: return e[0])
	assert_true("test_map" in maps and "mvp_map" in maps, "lists the maps: %s" % [maps])
	(menu.find_child("map_mvp_map", true, false) as Button).emit_signal("pressed")
	assert_eq(menu.game_options(), {"map": "mvp_map"})
	(menu.find_child("mode_%d" % MainMenu.Mode.HOST, true, false) as Button).emit_signal("pressed")
	(menu.find_child("Waves", true, false) as Button).button_pressed = false
	assert_eq(menu.game_options(), {"map": "mvp_map", "no-waves": true, "host": str(NetProtocol.DEFAULT_PORT)})
	menu.address = "10.0.0.5"
	(menu.find_child("mode_%d" % MainMenu.Mode.JOIN, true, false) as Button).emit_signal("pressed")
	assert_eq(menu.game_options(), {"join": "10.0.0.5:%d" % NetProtocol.DEFAULT_PORT})


func test_game_uses_menu_options() -> void:
	Game.options = {"map": "mvp_map", "no-waves": true}
	var game := _game()
	await wait_process_frames(1)
	assert_eq(game.world.map.id, "mvp_map")
	assert_false(game.world.match_system.active, "sandbox: no waves")


func test_in_game_menu_pauses_and_resumes() -> void:
	var game := _game()
	await wait_process_frames(1)
	game.speed = 2.0
	game.hud.toggle_menu()
	assert_true(game.hud.game_menu.visible)
	assert_eq(game.speed, 0.0, "paused while open")
	game.hud.toggle_menu()
	assert_eq(game.speed, 2.0, "resumes at the speed it had")


func test_end_screen_on_defeat_with_stats() -> void:
	var game := _game()
	await wait_process_frames(1)
	game.world.enemies.spawn(game.world, &"grunt", game.world.map.spawns[1].rect, 3)
	game.world.combat.update(game.world)  # nothing yet
	game.world.survivors.damage(game.world, game.survivor, 100000.0)
	game.step()
	await wait_process_frames(1)
	assert_eq(game.hud.end_screen.outcome(), "Defeat")
	assert_true(game.hud.end_screen.visible)
	assert_string_contains(game.hud.end_screen.stats.text, "Enemies killed: 0")


func test_quick_save_and_load_restore_the_match() -> void:
	var game := _game()
	await wait_process_frames(1)
	var world := game.world
	SimFixtures.build_now(world, &"wall", world.map.start + Vector2i(3, 3))
	world.enemies.spawn(world, &"grunt", world.map.spawns[1].rect, 7)
	for i in 40:
		game.step()
	assert_true(game.quicksave(SAVE))
	var saved_tick := world.tick
	var saved_entities := world.entities.size()
	Game.pending_load = SAVE
	var loaded := _game()  # _ready restores the save
	assert_eq(loaded.world.tick, saved_tick)
	assert_eq(loaded.world.entities.size(), saved_entities)
	assert_eq(loaded.world.enemies.count(), 7)
	assert_eq(loaded.building_views.view_count(), 1, "views caught up with loaded buildings")
	assert_not_null(loaded.survivor)
	await wait_process_frames(1)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func test_game_joins_a_host_as_client() -> void:
	var host_world := World.new(MapLayout.load_file("res://data/maps/test_map.json"), DefRegistry.load_default(), 3)
	host_world.add_player(0)
	host_world.survivors.spawn(host_world, 0, SurvivorSystem.start_cell(host_world, 0))
	var host := NetHost.new()
	add_child_autofree(host)
	var port := 41000 + randi() % 8000
	assert_eq(host.start(host_world, port), OK)
	Game.options = {"join": "127.0.0.1:%d" % port}
	var game := _game()
	for i in 200:
		host_world.step()
		await get_tree().process_frame
		if game.hud and game.net_client.snapshots > 2:
			break
	assert_true(game.is_client())
	assert_eq(game.local_player, 1)
	assert_not_null(game.hud, "scene built after the welcome")
	assert_not_null(game.survivor, "own Survivor mirrored")
	assert_eq(game.survivor_views.get_child_count(), 2, "both Survivors drawn")
	var goal := game.survivor.cell() + Vector2i(-2, 1)
	game.builder.request_smart_order(goal)
	for i in 200:
		host_world.step()
		await get_tree().process_frame
		if host_world.survivors.survivor_of(1).cell() == goal:
			break
	assert_eq(host_world.survivors.survivor_of(1).cell(), goal, "the client's order ran on the host")
	game.net_client.stop()
	host.stop()

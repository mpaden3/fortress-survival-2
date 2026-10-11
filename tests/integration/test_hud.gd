extends GutTest
## The HUD drives the game through the same requests as the hotkeys: command card, selection
## panel, minimap and the sandbox panels.

var game: Game


func before_each() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	add_child_autofree(game)
	await wait_process_frames(2)


func _ids() -> Array:
	return game.hud.command_card.entries().map(func(e: Dictionary) -> String: return e["id"])


func _step(ticks := 1) -> void:
	for i in ticks:
		game.step()


func test_layout_parts_exist() -> void:
	var hud := game.hud
	for part: Control in [hud.top_bar, hud.minimap, hud.selection, hud.command_card, hud.sandbox, hud.sandbox_spawn]:
		assert_not_null(part)
		assert_true(part.is_visible_in_tree(), "%s visible" % part.name)


func test_command_card_for_the_survivor_builds_and_casts() -> void:
	assert_eq(_ids(), ["build:wall", "build:basic_tower", "build:mill", "build:barracks", "blink", "haste", "cancel"])
	assert_true(game.hud.command_card.press("build:basic_tower"))
	assert_eq(game.builder.selected_def, &"basic_tower", "build mode")
	assert_true(game.hud.command_card.press("cancel"))
	assert_eq(game.builder.selected_def, &"")
	assert_true(game.hud.command_card.press("haste"))
	_step()
	assert_gt(game.survivor.haste_until_tick, game.world.tick, "hasted")
	await wait_process_frames(1)
	assert_false(game.hud.command_card.press("haste"), "on cooldown: disabled")
	game.hud.command_card.press("blink")
	assert_true(game.builder.blink_armed, "blink waits for a target")


func test_command_card_for_a_barracks_trains_and_sells() -> void:
	var world := game.world
	world.players[Game.LOCAL_PLAYER].resource = 1000
	var barracks := SimFixtures.build_now(world, &"barracks", world.map.start + Vector2i(4, 4))
	game.builder._select_entity(barracks.id)
	assert_eq(_ids(), ["train:fighter", "train:repairman", "sell"])
	assert_true(game.hud.command_card.press("train:fighter"))
	_step()
	assert_eq(barracks.train_queue, [&"fighter"] as Array[StringName])
	await wait_process_frames(1)
	assert_string_contains(game.hud.selection.progress_label.text, "Training Fighter")
	assert_eq(game.hud.selection.title.text, "Barracks")
	assert_true(game.hud.command_card.press("sell"))
	_step()
	assert_false(world.entities.has(barracks.id))


func test_command_card_for_units() -> void:
	var unit := game.world.units.spawn(game.world, Game.LOCAL_PLAYER, &"fighter", Vector2(game.world.map.start) + Vector2(0.5, 3.5))
	game.builder.select_units([unit.id] as Array[int])
	assert_eq(_ids(), ["attack_move", "stop", "hold"])
	assert_true(game.hud.command_card.press("hold"))
	_step()
	assert_true(unit.holding)
	await wait_process_frames(1)
	assert_eq(game.hud.selection.title.text, "Fighter")


func test_sandbox_spawns_the_chosen_enemies() -> void:
	var spawn_panel := game.hud.sandbox_spawn
	(spawn_panel.find_child("enemy_brute", true, false) as Button).emit_signal("pressed")
	(spawn_panel.find_child("amount_50", true, false) as Button).emit_signal("pressed")
	(spawn_panel.find_child("spawn_north", true, false) as Button).emit_signal("pressed")
	(spawn_panel.find_child("Spawn", true, false) as Button).emit_signal("pressed")
	_step()
	assert_eq(game.world.enemies.count(), 50)
	assert_eq(game.world.defs.enemy_list[game.world.enemies.types[0]].id, &"brute")
	(spawn_panel.find_child("Clear", true, false) as Button).emit_signal("pressed")
	_step()
	assert_eq(game.world.enemies.count(), 0)


func test_sandbox_speed_resource_and_god_mode() -> void:
	var panel := game.hud.sandbox
	(panel.find_child("speed_0", true, false) as Button).emit_signal("pressed")
	assert_eq(game.speed, 0.0, "paused")
	(panel.find_child("speed_4", true, false) as Button).emit_signal("pressed")
	assert_eq(game.speed, 4.0)
	var before: int = game.world.players[Game.LOCAL_PLAYER].resource
	(panel.find_child("resource_1000", true, false) as Button).emit_signal("pressed")
	_step()
	assert_eq(game.world.players[Game.LOCAL_PLAYER].resource, before + 1000)
	(panel.find_child("God", true, false) as Button).button_pressed = true
	_step()
	assert_true(game.survivor.invulnerable)


func test_minimap_click_moves_the_camera() -> void:
	var minimap := game.hud.minimap
	var size := minimap.texture_rect.size
	var cell := minimap.cell_at(size * 0.5)
	assert_true(game.world.map.in_bounds(cell), "centre of the minimap is on the map")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(size.x * 0.1, size.y * 0.9)
	minimap._on_gui_input(click)
	var target := minimap.cell_at(click.position)
	assert_almost_eq(game.camera.position.x, Coords.cell_centre(target).x, 0.01)
	assert_almost_eq(game.camera.position.z, Coords.cell_centre(target).z, 0.01)


func test_selection_rings_hp_bars_and_waypoints() -> void:
	var world := game.world
	var start := Vector2(world.map.start)
	var a := world.units.spawn(world, Game.LOCAL_PLAYER, &"fighter", start + Vector2(0.5, 3.5))
	var b := world.units.spawn(world, Game.LOCAL_PLAYER, &"fighter", start + Vector2(1.5, 3.5))
	game.builder.select_units([a.id, b.id] as Array[int])
	assert_eq(game.selection_views.selected_rings().size(), 2, "a ring per selected unit")
	assert_eq(game.hud.health_bars.bars().size(), 2, "an HP bar per selected unit")
	game.builder.request_unit_order("move", world.map.start + Vector2i(-4, 3))
	assert_eq(game.selection_views.ping_count(), 1, "the click pings")
	_step()
	game.builder.request_unit_order("attack_move", world.map.start + Vector2i(-4, 8), true)
	_step()
	var points := SelectionViews.waypoints(world, a)
	assert_gte(points.size(), 2, "route to the first order, then the queued one")
	assert_eq(points[points.size() - 1], Vector2(world.map.start + Vector2i(-4, 8)) + Vector2(0.5, 0.5))


func test_click_selects_the_survivor() -> void:
	game.builder.hover_point = game.survivor.position + Vector2(0.2, 0.0)
	game.builder._drag_start = Vector2(100, 100)
	game.builder._finish_selection(Vector2(101, 100))
	assert_true(game.builder.survivor_selected)
	assert_eq(game.selection_views.selected_movers(), [game.survivor])
	assert_eq(game.hud.health_bars.bars().size(), 1)
	assert_eq(game.selection_views.selected_rings().size(), 1)


func test_selected_building_gets_a_ring_and_hp_bar() -> void:
	var tower := SimFixtures.build_now(game.world, &"basic_tower", game.world.map.start + Vector2i(3, -4))
	game.builder._select_entity(tower.id)
	assert_eq(game.selection_views.selected_rings().size(), 1)
	assert_eq(game.hud.health_bars.bars().size(), 1)
	assert_false(game.builder.survivor_selected, "a building selection replaces the Survivor's")

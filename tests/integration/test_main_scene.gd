extends GutTest
## Smoke test of the playable scene: it boots headless, and input-level requests reach the
## World and show up as views.

var game: Game


func before_each() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	add_child_autofree(game)
	await wait_physics_frames(1)


func test_boots_with_test_map() -> void:
	assert_eq(game.world.map.id, "test_map")
	assert_not_null(game.map_view.get_node_or_null("Blocked"), "terrain drawn")
	assert_eq(game.world.players[Game.LOCAL_PLAYER].resource, game.world.defs.rules.starting_resource)


func test_survivor_spawns_at_start() -> void:
	assert_not_null(game.survivor)
	assert_eq(game.survivor.cell(), game.world.map.start)
	assert_not_null(game.survivor_views.get_node_or_null("Survivor0"))


func test_build_controller_places_through_world() -> void:
	var cell := game.world.map.start + Vector2i(0, -4)
	game.builder.select_def(&"basic_tower")
	assert_true(game.builder.can_place_at(cell))
	game.builder.request_place(cell)
	for i in 3 * SimConstants.TICK_RATE:
		game.step()
	assert_eq(game.building_views.view_count(), 1, "survivor walked over and built it")
	var tower := game.world.entities.get(game.world.grid.occupant(cell)) as BuildingState
	assert_eq(tower.rect.position, Coords.footprint_origin(cell, Vector2i(2, 2)), "footprint centred on cursor")


func test_sell_selected_removes_view() -> void:
	var cell := game.world.map.start + Vector2i(0, -4)
	game.builder.select_def(&"wall")
	game.builder.request_place(cell)
	for i in 3 * SimConstants.TICK_RATE:
		game.step()
	game.builder.select_def(&"")
	game.builder._select_entity(game.world.grid.occupant(cell))
	game.builder.request_sell_selected()
	game.step()
	await wait_process_frames(1)
	assert_eq(game.building_views.view_count(), 0)
	assert_eq(game.world.grid.occupant(cell), BuildGrid.NONE)


func test_barracks_trains_and_units_take_orders() -> void:
	var world := game.world
	world.players[Game.LOCAL_PLAYER].resource = 1000
	var barracks := SimFixtures.build_now(world, &"barracks", world.map.start + Vector2i(4, 4))
	game.builder._select_entity(barracks.id)
	var actions := BuildController.building_actions(barracks)
	assert_eq(actions, [&"fighter", &"repairman"] as Array[StringName], "barracks actions: units to train")
	game.builder.request_action_selected(0)
	for i in roundi(world.defs.unit(&"fighter").train_time * SimConstants.TICK_RATE) + 2:
		game.step()
	assert_eq(world.units.living().size(), 1, "fighter trained")
	await wait_process_frames(1)
	assert_eq(game.unit_views.view_count(), 1)
	var fighter := world.units.living()[0]
	assert_eq(game.builder.unit_near(fighter.position + Vector2(0.3, 0.0)), fighter.id, "click picks it")
	game.builder.select_units([fighter.id] as Array[int])
	var goal := fighter.cell() + Vector2i(-3, 0)  # open ground (terrain to the east)
	game.builder.request_unit_order("move", goal)
	for i in 3 * SimConstants.TICK_RATE:
		game.step()
	assert_eq(fighter.cell(), goal, "moved where ordered")
	world.units.damage(world, fighter, 10000.0)
	await wait_process_frames(1)
	assert_eq(game.unit_views.view_count(), 0, "view removed with the unit")

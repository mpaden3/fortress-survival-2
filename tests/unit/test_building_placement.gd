extends GutTest

var world: World


func before_each() -> void:
	DebugLog.clear_captured()
	world = SimFixtures.world(SimFixtures.open_map(10, 10, [Vector2i(5, 5)] as Array[Vector2i]))


func _place(def_id: StringName, cell: Vector2i, player := 0) -> Dictionary:
	world.submit(Commands.place_building(player, def_id, cell))
	world.step()
	return world.last_results[0]


func _only_building() -> BuildingState:
	return world.entities.values()[0] as BuildingState


func test_place_pays_and_occupies_footprint() -> void:
	assert_true(_place(&"tower", Vector2i(2, 3))["ok"])
	var tower := _only_building()
	assert_eq(world.players[0].resource, 80)
	assert_eq(tower.rect, Rect2i(2, 3, 2, 2))
	assert_eq(tower.owner, 0)
	for cell in [Vector2i(2, 3), Vector2i(3, 3), Vector2i(2, 4), Vector2i(3, 4)]:
		assert_eq(world.grid.occupant(cell), tower.id)
	assert_eq(world.grid.occupant(Vector2i(4, 3)), BuildGrid.NONE)


func test_rejections_leave_state_unchanged() -> void:
	_place(&"tower", Vector2i(0, 0))
	var resource_after_first: int = world.players[0].resource
	var cases := [
		[&"wall", Vector2i(1, 1), "occupied"],
		[&"wall", Vector2i(5, 5), "terrain"],
		[&"tower", Vector2i(4, 4), "terrain"],
		[&"tower", Vector2i(9, 9), "out_of_bounds"],
		[&"wall", Vector2i(-1, 0), "out_of_bounds"],
		[&"tower_2", Vector2i(7, 0), "not_placeable"],
		[&"castle", Vector2i(7, 0), "unknown_def"],
	]
	for case in cases:
		assert_eq(_place(case[0], case[1])["reason"], case[2], "%s at %s" % [case[0], case[1]])
	assert_eq(world.entities.size(), 1)
	assert_eq(world.players[0].resource, resource_after_first)


func test_not_enough_resource() -> void:
	world.players[0].resource = 19
	assert_eq(_place(&"tower", Vector2i(0, 0))["reason"], "not_enough_resource")
	assert_eq(world.players[0].resource, 19)
	assert_eq(world.grid.occupant(Vector2i(0, 0)), BuildGrid.NONE)


func test_rejection_is_logged_with_reason() -> void:
	_place(&"wall", Vector2i(5, 5))
	var lines := DebugLog.captured_in(&"build")
	assert_eq(lines.size(), 1)
	assert_string_contains(lines[0], "rejected=place_building")
	assert_string_contains(lines[0], "reason=terrain")


func test_construction_takes_build_time_and_hp_rises_to_max() -> void:
	_place(&"tower", Vector2i(0, 0))  # 2 s build, 300 hp
	var tower := _only_building()
	assert_true(tower.constructing)
	assert_eq(tower.build_progress, 1, "first construction tick runs in the placement step")
	var last_hp := tower.hp
	for i in tower.def.build_ticks() - 2:
		world.step()
		assert_true(tower.hp >= last_hp, "hp never drops while building")
		last_hp = tower.hp
	assert_true(tower.constructing, "one tick left")
	world.step()
	assert_false(tower.constructing)
	assert_eq(tower.hp, 300)
	assert_eq(DebugLog.captured_in(&"build").size(), 2, "placed + completed")


func test_sell_refunds_half_and_frees_cells() -> void:
	_place(&"tower", Vector2i(0, 0))
	var tower := _only_building()
	world.submit(Commands.sell_building(0, tower.id))
	world.step()
	assert_true(world.last_results[0]["ok"])
	assert_eq(world.players[0].resource, 100 - 20 + 10)
	assert_eq(world.entities.size(), 0)
	assert_eq(world.grid.occupant(Vector2i(1, 1)), BuildGrid.NONE)
	assert_true(_place(&"wall", Vector2i(1, 1))["ok"], "cells can be reused")


func test_cannot_sell_others_or_missing_buildings() -> void:
	world.add_player(1)
	_place(&"wall", Vector2i(0, 0))
	var wall := _only_building()
	world.submit(Commands.sell_building(1, wall.id))
	world.submit(Commands.sell_building(0, 999))
	world.step()
	assert_eq(world.last_results[0]["reason"], "not_owner")
	assert_eq(world.last_results[1]["reason"], "unknown_building")
	assert_eq(world.entities.size(), 1)


func test_wall_closes_test_map_door() -> void:
	# The Cell plot on the test map has one 2-wide door at (26, 22..23). Two walls seal it.
	var layout := MapLayout.load_file("res://data/maps/test_map.json")
	world = SimFixtures.world(layout, DefRegistry.load_default())
	var cell_plot := layout.get_plot("cell")
	assert_eq(MapAnalysis.entrance_widths(layout, cell_plot.rects), [2] as Array[int])
	assert_true(_place(&"wall", Vector2i(26, 22))["ok"])
	assert_true(_place(&"wall", Vector2i(26, 23))["ok"])
	for cell in [Vector2i(26, 22), Vector2i(26, 23)]:
		assert_ne(world.grid.occupant(cell), BuildGrid.NONE)

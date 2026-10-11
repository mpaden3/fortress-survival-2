extends GutTest


func _field(map: MapLayout, target: Vector2i, world: World = null) -> FlowField:
	var w := world if world else SimFixtures.world(map)
	w.pathing.set_target(&"t", [target] as Array[Vector2i])
	w.step()
	return w.pathing.field(&"t")


func test_open_field_cost_and_direction() -> void:
	var flow := _field(SimFixtures.open_map(9, 9), Vector2i(4, 4))
	assert_eq(flow.cost_at(Vector2i(4, 4)), 0)
	assert_eq(flow.cost_at(Vector2i(7, 4)), 3 * FlowField.STRAIGHT)
	assert_eq(flow.cost_at(Vector2i(6, 6)), 2 * FlowField.DIAGONAL)
	assert_eq(flow.direction_at(Vector2i(7, 4)), Vector2(-1, 0))
	assert_eq(flow.direction_at(Vector2i(4, 4)), Vector2.ZERO, "no direction at the target")


func test_routes_around_terrain() -> void:
	var map := SimFixtures.map_from_rows([
		".......",
		".#####.",
		".......",
	] as Array[String])
	var flow := _field(map, Vector2i(3, 0))
	# From under the wall's middle the way round is 3 cells sideways + up + 3 back.
	assert_true(flow.cost_at(Vector2i(3, 2)) > 4 * FlowField.STRAIGHT)
	assert_eq(flow.cost_at(Vector2i(3, 1)), FlowField.UNREACHABLE, "terrain itself is unreachable")


func test_unreachable_when_sealed_by_terrain() -> void:
	var map := SimFixtures.map_from_rows([".#.", "##.", "..."] as Array[String])
	var flow := _field(map, Vector2i(0, 0))
	assert_eq(flow.cost_at(Vector2i(2, 2)), FlowField.UNREACHABLE)


func test_buildings_are_passable_at_break_cost() -> void:
	# Target sealed in a 1-cell pocket by a wall: the only way in is through the wall.
	var map := SimFixtures.map_from_rows([
		"#####",
		"#...#",
		"#####",
	] as Array[String])
	var world := SimFixtures.world(map)
	SimFixtures.build_now(world, &"wall", Vector2i(2, 1))  # 100 hp * 0.5 = 50 break cost
	var flow := _field(map, Vector2i(1, 1), world)
	assert_eq(flow.cost_at(Vector2i(3, 1)), 2 * FlowField.STRAIGHT + 50)
	assert_eq(flow.direction_at(Vector2i(3, 1)), Vector2(-1, 0), "points into the wall")


func test_prefers_detour_over_strong_wall_and_wall_over_long_detour() -> void:
	# Two routes from the right side to the target on the left: a short one blocked by a wall
	# in the middle row, and a long open one around the bottom.
	var map := SimFixtures.map_from_rows([
		"#########",
		"#.......#",
		"#.#####.#",
		"#.......#",
		"#########",
	] as Array[String])
	var world := SimFixtures.world(map)
	SimFixtures.build_now(world, &"wall", Vector2i(4, 1))
	var flow := _field(map, Vector2i(1, 1), world)
	# Through the wall: 6 cells + 50 = 110. Around the bottom: 2 + 6 + 2 = 10 cells = 100.
	assert_eq(flow.cost_at(Vector2i(7, 1)), 100, "takes the open detour")
	world.defs.rules.path_cost_per_building_hp = 0.1  # weak wall: 6 cells + 10 = 70
	world.pathing._extra_dirty = true
	world.step()
	assert_eq(flow.cost_at(Vector2i(7, 1)), 70, "breaks the cheap wall instead")


func test_rebuilds_when_buildings_change() -> void:
	var world := SimFixtures.world(SimFixtures.open_map(6, 1))
	var flow := _field(world.map, Vector2i(0, 0), world)
	assert_eq(flow.cost_at(Vector2i(5, 0)), 50)
	var wall := SimFixtures.build_now(world, &"wall", Vector2i(3, 0))
	assert_eq(flow.cost_at(Vector2i(5, 0)), 100, "wall adds its break cost")
	world.buildings.damage(world, wall.id, 1000.0)
	world.step()
	assert_eq(flow.cost_at(Vector2i(5, 0)), 50, "destroyed wall is gone from the field")


func test_sample_blends_between_cells() -> void:
	var flow := _field(SimFixtures.open_map(9, 9), Vector2i(4, 4))
	var d := flow.sample(Vector2(7.5, 7.0))
	assert_almost_eq(d.length(), 1.0, 0.001)
	assert_true(d.x < 0.0 and d.y < 0.0, "heads up-left toward the target")

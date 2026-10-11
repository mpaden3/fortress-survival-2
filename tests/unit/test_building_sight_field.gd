extends GutTest
## BuildingSightField: walking distance to the nearest building, capped, over open ground only.


## World whose grunts see `sight_range_m` meters (the field's range).
func _world(map: MapLayout, sight_range_m: float) -> World:
	var registry := SimFixtures.defs()
	registry.enemy(&"grunt").sight_range = sight_range_m
	return SimFixtures.world(map, registry)


func _sight(world: World) -> BuildingSightField:
	world.step()
	return world.pathing.sight


func test_cost_direction_and_id_of_nearest_building() -> void:
	var world := _world(SimFixtures.open_map(12, 12), 8.0)  # 4 cells
	var wall := SimFixtures.build_now(world, &"wall", Vector2i(5, 5))
	var sight := _sight(world)
	assert_eq(sight.cost_at(Vector2i(5, 5)), 0, "the building's own cell")
	assert_eq(sight.cost_at(Vector2i(8, 5)), 3 * FlowField.STRAIGHT)
	assert_eq(sight.cost_at(Vector2i(7, 7)), 2 * FlowField.DIAGONAL)
	assert_eq(sight.building_at(Vector2i(8, 5)), wall.id)
	assert_eq(sight.direction[5 * 12 + 8], Vector2(-1, 0), "points at the wall")


func test_range_is_capped_by_the_farthest_seeing_enemy() -> void:
	var world := _world(SimFixtures.open_map(12, 12), 8.0)
	SimFixtures.build_now(world, &"wall", Vector2i(1, 5))
	var sight := _sight(world)
	assert_eq(sight.cost_at(Vector2i(5, 5)), 4 * FlowField.STRAIGHT)
	assert_eq(sight.cost_at(Vector2i(6, 5)), BuildingSightField.UNSEEN)
	assert_eq(sight.building_at(Vector2i(6, 5)), 0)


func test_picks_the_nearer_of_two_buildings() -> void:
	var world := _world(SimFixtures.open_map(12, 3), 20.0)
	var left := SimFixtures.build_now(world, &"wall", Vector2i(0, 1))
	var right := SimFixtures.build_now(world, &"wall", Vector2i(11, 1))
	var sight := _sight(world)
	assert_eq(sight.building_at(Vector2i(3, 1)), left.id)
	assert_eq(sight.building_at(Vector2i(8, 1)), right.id)


func test_does_not_spread_through_terrain_or_buildings() -> void:
	var map := SimFixtures.map_from_rows([
		"..........",
		"..........",
		"..........",
		"..........",
		"..........",
		"#########.",
		"..........",
	] as Array[String])
	var world := _world(map, 6.0)  # 3 cells
	# A tower boxed in by walls: from outside only the walls are seen.
	var tower := SimFixtures.build_now(world, &"tower", Vector2i(4, 1))
	for cell: Vector2i in [Vector2i(3, 0), Vector2i(3, 1), Vector2i(3, 2), Vector2i(3, 3), Vector2i(4, 3),
			Vector2i(5, 3), Vector2i(6, 3), Vector2i(6, 2), Vector2i(6, 1), Vector2i(6, 0), Vector2i(4, 0), Vector2i(5, 0)]:
		SimFixtures.build_now(world, &"wall", cell)
	var sight := _sight(world)
	assert_ne(sight.building_at(Vector2i(4, 4)), tower.id, "the tower behind the wall isn't seen")
	assert_ne(sight.building_at(Vector2i(4, 4)), 0, "the wall in front is")
	assert_eq(sight.cost_at(Vector2i(4, 6)), BuildingSightField.UNSEEN, "nothing seen across the terrain ridge")

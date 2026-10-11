extends GutTest
## Horde behaviour on small maps: reaching the target, routing, separation, wall breaking.


func before_each() -> void:
	DebugLog.clear_captured()


func _world(map: MapLayout, target: Vector2i) -> World:
	var world := SimFixtures.world(map)
	world.pathing.set_target(&"t", [target] as Array[Vector2i])
	return world


func _cell(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x), floori(pos.y))


func _max_distance(world: World, target: Vector2i) -> float:
	var worst := 0.0
	for pos in world.enemies.positions:
		worst = maxf(worst, pos.distance_to(Vector2(target) + Vector2(0.5, 0.5)))
	return worst


func test_reaches_target_on_open_map_at_its_speed() -> void:
	var world := _world(SimFixtures.open_map(30, 5), Vector2i(2, 2))
	world.enemies.spawn(world, &"grunt", Rect2i(27, 2, 1, 1), 1, &"t")
	# 25 cells = 50 m at 4 m/s = 12.5 s.
	world.run_seconds(11.0)
	assert_gt(_max_distance(world, Vector2i(2, 2)), 2.0, "not there before its speed allows")
	world.run_seconds(2.5)
	# Arrived = stopped within one (diagonal) cell of the target, <= ~1.5 cells from its centre.
	assert_lt(_max_distance(world, Vector2i(2, 2)), 1.6, "arrived")


func test_never_enters_blocked_terrain_and_routes_around() -> void:
	var map := SimFixtures.map_from_rows([
		"....................",
		"....................",
		"..########.########.",
		"..#...............#.",
		"..#...............#.",
		"..#################.",
		"....................",
	] as Array[String])
	# Target inside the walled pocket; the only gap is at (10, 2).
	var world := _world(map, Vector2i(10, 4))
	world.enemies.spawn(world, &"grunt", Rect2i(0, 6, 20, 1), 40, &"t")
	for i in 30 * 20:
		world.step()
		for pos in world.enemies.positions:
			if not map.is_walkable(_cell(pos)):
				fail_test("enemy inside blocked cell %s at tick %d" % [pos, world.tick])
				return
	assert_lt(_max_distance(world, Vector2i(10, 4)), 4.0, "all 40 got into the pocket")


func test_separation_spreads_the_crowd() -> void:
	var world := _world(SimFixtures.open_map(20, 20), Vector2i(10, 10))
	world.enemies.spawn(world, &"grunt", Rect2i(10, 10, 1, 1), 30, &"t")
	world.run_seconds(3.0)
	var positions := world.enemies.positions
	var closest := INF
	for i in positions.size():
		for j in range(i + 1, positions.size()):
			closest = minf(closest, positions[i].distance_to(positions[j]))
	# Bodies are 0.4 m radius = 0.2 cells; allow some squeeze.
	assert_gt(closest, 0.2, "no two enemies stacked on one spot")


func test_breaks_the_wall_sealing_the_target() -> void:
	var map := SimFixtures.map_from_rows([
		"###########",
		"#.........#",
		"#.#######.#",
		"#.#.....#.#",
		"#.#.....#.#",
		"#.###.###.#",
		"#.........#",
		"###########",
	] as Array[String])
	var world := _world(map, Vector2i(5, 3))
	var wall := SimFixtures.build_now(world, &"wall", Vector2i(5, 5))  # the room's only door
	world.enemies.spawn(world, &"grunt", Rect2i(1, 1, 1, 1), 5, &"t")
	var destroyed_at := -1
	for i in 30 * 30:
		world.step()
		if not world.entities.has(wall.id):
			destroyed_at = world.tick
			break
	assert_gt(destroyed_at, 0, "door wall destroyed")
	var hits := 0
	for line in DebugLog.captured_in(&"combat"):
		if "hits_building=%d" % wall.id in line:
			hits += 1
	assert_gt(hits, 0, "combat log shows hits on the door")
	world.run_seconds(6.0)
	assert_lt(_max_distance(world, Vector2i(5, 3)), 3.0, "then walked in")


func test_takes_open_detour_instead_of_breaking_strong_wall() -> void:
	var map := SimFixtures.map_from_rows([
		"#########",
		"#.......#",
		"#.#####.#",
		"#.......#",
		"#########",
	] as Array[String])
	var world := _world(map, Vector2i(1, 1))
	var wall := SimFixtures.build_now(world, &"wall", Vector2i(4, 1))
	world.enemies.spawn(world, &"grunt", Rect2i(7, 1, 1, 1), 3, &"t")
	world.run_seconds(10.0)
	assert_true(world.entities.has(wall.id), "wall untouched")
	assert_eq(DebugLog.captured_in(&"combat").size(), 0, "no attacks")
	assert_lt(_max_distance(world, Vector2i(1, 1)), 2.0, "arrived around the bottom")


func test_damage_and_death() -> void:
	var world := _world(SimFixtures.open_map(5, 5), Vector2i(0, 0))
	var ids := world.enemies.spawn(world, &"grunt", Rect2i(4, 4, 1, 1), 2, &"t")
	assert_false(world.enemies.damage(world.enemies.index_of(ids[0]), 20.0))
	assert_true(world.enemies.damage(world.enemies.index_of(ids[0]), 40.0))
	assert_eq(world.enemies.count(), 1)
	assert_eq(world.enemies.ids[0], ids[1], "survivor keeps its id after swap-remove")


func test_same_seed_same_horde() -> void:
	var a := _world(SimFixtures.open_map(20, 20), Vector2i(2, 2))
	var b := _world(SimFixtures.open_map(20, 20), Vector2i(2, 2))
	for world in [a, b]:
		world.enemies.spawn(world, &"grunt", Rect2i(15, 15, 4, 4), 25, &"t")
		world.run_seconds(4.0)
	assert_eq(a.enemies.positions, b.enemies.positions)

extends GutTest
## GridPaths routes: A* straightened into natural walking routes that never clip anything.

const RADIUS := 0.225  # the Survivor's: 0.45 m in cells


func _world(rows: Array[String]) -> World:
	return SimFixtures.world(SimFixtures.map_from_rows(rows))


## Smallest distance from the body's centre to any blocked cell along the whole route.
func _min_clearance(world: World, from: Vector2, route: PackedVector2Array) -> float:
	var best := INF
	var a := from
	for b in route:
		var steps := maxi(1, ceili(a.distance_to(b) / 0.02))
		for s in steps + 1:
			var p := a.lerp(b, float(s) / steps)
			for z in range(floori(p.y) - 1, floori(p.y) + 2):
				for x in range(floori(p.x) - 1, floori(p.x) + 2):
					var blocked := x < 0 or z < 0 or x >= world.map.size.x or z >= world.map.size.y \
						or world.grid.blocked[z * world.map.size.x + x] != 0
					if blocked:
						var closest := Vector2(clampf(p.x, x, x + 1), clampf(p.y, z, z + 1))
						best = minf(best, p.distance_to(closest))
		a = b
	return best


func test_open_ground_is_one_straight_leg_to_the_exact_point() -> void:
	var world := SimFixtures.world(SimFixtures.open_map(20, 20))
	var route := world.pathing.paths.find_route(world, Vector2(1.3, 1.7), Vector2(14.6, 9.2), RADIUS)
	assert_eq(route, PackedVector2Array([Vector2(14.6, 9.2)]), "no cell centres, no zig-zag")


func test_goes_round_a_wall_with_few_turns() -> void:
	var world := _world([
		"............",
		"............",
		"......#.....",
		"......#.....",
		"......#.....",
		"......#.....",
		"............",
	] as Array[String])
	var from := Vector2(2.5, 3.5)
	var to := Vector2(10.5, 3.5)
	var route := world.pathing.paths.find_route(world, from, to, RADIUS)
	assert_lte(route.size(), 3, "a corner or two, then straight to the goal: %s" % route)
	assert_eq(route[route.size() - 1], to)
	assert_gte(_min_clearance(world, from, route), RADIUS - 0.001, "never clips the wall")


func test_destination_against_a_wall_is_nudged_off_it() -> void:
	var world := _world(["....#", "....#", "....#"] as Array[String])
	var route := world.pathing.paths.find_route(world, Vector2(0.5, 1.5), Vector2(3.99, 1.5), RADIUS)
	assert_almost_eq(route[route.size() - 1].x, 4.0 - RADIUS, 0.0001)


func test_unreachable_goal_ends_at_the_closest_reachable_cell() -> void:
	var world := _world([".....#....", ".....#....", ".....#...."] as Array[String])
	var route := world.pathing.paths.find_route(world, Vector2(1.5, 1.5), Vector2(8.5, 1.5), RADIUS)
	assert_false(route.is_empty())
	assert_lt(route[route.size() - 1].x, 5.0, "stays on its side of the ridge")


func test_routes_never_clip_blocked_cells_on_random_maps() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var checked := 0
	for map_index in 40:
		var rows: Array[String] = []
		for z in 24:
			var row := ""
			for x in 32:
				row += "#" if rng.randf() < 0.22 else "."
			rows.append(row)
		var world := _world(rows)
		for trial in 10:
			var from := Vector2(rng.randf_range(0.0, 32.0), rng.randf_range(0.0, 24.0))
			var to := Vector2(rng.randf_range(0.0, 32.0), rng.randf_range(0.0, 24.0))
			var from_cell := Vector2i(floori(from.x), floori(from.y))
			if world.grid.blocked[from_cell.y * 32 + from_cell.x] != 0:
				continue
			# Start like a body would stand: off the walls by its radius.
			from = world.pathing.paths._clear_point(world, from_cell, from, RADIUS)
			var route := world.pathing.paths.find_route(world, from, to, RADIUS)
			if route.is_empty():
				continue
			checked += 1
			assert_gte(_min_clearance(world, from, route), RADIUS - 0.001,
				"map %d route %s -> %s: %s" % [map_index, from, to, route])
	assert_gt(checked, 250, "enough routes checked")


func test_segment_clear_sees_walls_and_corners() -> void:
	var world := _world(["....", ".#..", "...."] as Array[String])
	var paths := world.pathing.paths
	assert_false(paths.segment_clear(world, Vector2(0.5, 1.5), Vector2(3.5, 1.5), RADIUS), "through the block")
	assert_false(paths.segment_clear(world, Vector2(0.5, 0.5), Vector2(2.5, 2.5), RADIUS), "across its corner")
	assert_true(paths.segment_clear(world, Vector2(0.5, 0.5), Vector2(3.5, 0.5), RADIUS), "past it with room")


static func _length(from: Vector2, route: PackedVector2Array) -> float:
	var total := 0.0
	var a := from
	for b in route:
		total += a.distance_to(b)
		a = b
	return total


func test_turns_hug_the_corner() -> void:
	# Round the top of a wall column (x = 6, rows 2-5): the shortest way passes its two top
	# corners, (6, 2) and (7, 2). Turning at cell centres instead would add about 7%.
	var world := _world([
		"............",
		"............",
		"......#.....",
		"......#.....",
		"......#.....",
		"......#.....",
		"......#.....",
		"......#.....",
	] as Array[String])
	var from := Vector2(2.5, 3.5)
	var to := Vector2(10.5, 3.5)
	var route := world.pathing.paths.find_route(world, from, to, RADIUS)
	var shortest := from.distance_to(Vector2(6, 2)) + 1.0 + Vector2(7, 2).distance_to(to)
	assert_lt(_length(from, route), shortest * 1.03, "hugs the corners: %s" % route)
	assert_gte(_min_clearance(world, from, route), RADIUS - 0.001, "still never clips")

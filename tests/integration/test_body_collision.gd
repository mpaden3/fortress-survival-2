extends GutTest
## Enemies don't walk through the Survivor or units: they stop at their edge.

var world: World


func before_each() -> void:
	world = SimFixtures.world(SimFixtures.open_map(30, 30))


## Smallest gap between any enemy's body and `body_pos` over `seconds` (negative = overlap).
func _closest_gap(body_pos: Callable, body_radius: float, seconds: float) -> float:
	var enemy_radius := world.defs.enemy(&"grunt").radius / SimConstants.CELL_SIZE
	var worst := INF
	for i in roundi(seconds * SimConstants.TICK_RATE):
		world.step()
		var at: Vector2 = body_pos.call()
		for p in world.enemies.positions:
			worst = minf(worst, p.distance_to(at) - enemy_radius - body_radius)
	return worst


func test_a_crowd_does_not_overlap_the_survivor() -> void:
	var survivor := world.survivors.spawn(world, 0, Vector2i(15, 15))
	survivor.invulnerable = true
	world.enemies.spawn(world, &"grunt", Rect2i(20, 13, 4, 4), 30)
	var gap := _closest_gap(func() -> Vector2: return survivor.position,
		survivor.def.radius / SimConstants.CELL_SIZE, 8.0)
	assert_gt(gap, -0.12, "at most a step of overlap while pressing in (gap %.3f)" % gap)


func test_enemies_go_round_a_unit_in_their_way() -> void:
	world.pathing.set_target(&"far", [Vector2i(2, 15)] as Array[Vector2i])
	world.defs.unit(&"repairman").repair_rate = 0.0
	var unit := world.units.spawn(world, 0, &"repairman", Vector2(15.5, 15.5))
	unit.holding = true
	world.enemies.spawn(world, &"grunt", Rect2i(26, 15, 1, 1), 12, &"far")
	var gap := _closest_gap(func() -> Vector2: return unit.position, unit.def.radius / SimConstants.CELL_SIZE, 8.0)
	assert_gt(gap, -0.12, "pushed round it, not through it (gap %.3f)" % gap)
	world.run_seconds(4.0)
	for p in world.enemies.positions:
		assert_lt(p.x, 12.0, "and they all got past")

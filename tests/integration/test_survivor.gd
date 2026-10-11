extends GutTest
## The Survivor: orders, movement, abilities, and being hunted.

var world: World
var survivor: SurvivorState


func before_each() -> void:
	DebugLog.clear_captured()
	world = SimFixtures.world(SimFixtures.open_map(30, 30))
	survivor = world.survivors.spawn(world, 0, Vector2i(5, 5))


func _submit(command: Dictionary) -> Dictionary:
	world.submit(command)
	world.step()
	return world.last_results[0]


func _run_until(condition: Callable, max_seconds: float) -> bool:
	for i in roundi(max_seconds * SimConstants.TICK_RATE):
		if condition.call():
			return true
		world.step()
	return condition.call()


func test_moves_to_cell_at_its_speed() -> void:
	_submit(Commands.move_survivor(0, Vector2i(25, 5)))
	# 20 cells = 40 m at 5 m/s = 8 s.
	world.run_seconds(7.0)
	assert_lt(survivor.position.x, 24.0, "not faster than its speed")
	world.run_seconds(1.5)
	assert_eq(survivor.cell(), Vector2i(25, 5))
	assert_true(survivor.orders.is_empty())


func test_walks_around_walls_and_never_through_them() -> void:
	world = SimFixtures.world(SimFixtures.map_from_rows([
		"..........",
		"..........",
		"#########.",
		"..........",
	] as Array[String]))
	survivor = world.survivors.spawn(world, 0, Vector2i(0, 0))
	_submit(Commands.move_survivor(0, Vector2i(0, 3)))
	var ok := _run_until(func() -> bool:
		assert_true(world.map.is_walkable(survivor.cell()), "never inside a wall")
		return survivor.cell() == Vector2i(0, 3), 15.0)
	assert_true(ok, "went around through the gap at the right")


func test_build_order_walks_first_then_builds() -> void:
	assert_true(_submit(Commands.place_building(0, &"tower", Vector2i(20, 20)))["ok"])
	assert_eq(world.grid.occupant(Vector2i(20, 20)), BuildGrid.NONE, "not built from afar")
	assert_eq(world.players[0].resource, 100, "not paid yet")
	assert_true(_run_until(func() -> bool: return world.grid.occupant(Vector2i(20, 20)) != BuildGrid.NONE, 15.0))
	assert_eq(world.players[0].resource, 80)
	assert_lt(SurvivorSystem._distance_to_rect(survivor.position, Rect2i(20, 20, 2, 2)), survivor.def.work_reach + 0.1,
		"built standing next to it")


func test_queued_build_orders_run_in_sequence() -> void:
	for x in [10, 11, 12]:
		_submit(Commands.place_building(0, &"wall", Vector2i(x, 8), true))
	assert_eq(survivor.orders.size(), 3)
	assert_true(_run_until(func() -> bool: return survivor.orders.is_empty(), 15.0))
	for x in [10, 11, 12]:
		assert_ne(world.grid.occupant(Vector2i(x, 8)), BuildGrid.NONE, "wall at %d" % x)


func test_invalid_build_rejected_immediately() -> void:
	SimFixtures.build_now(world, &"wall", Vector2i(10, 10))
	assert_eq(_submit(Commands.place_building(0, &"wall", Vector2i(10, 10)))["reason"], "occupied")
	assert_true(survivor.orders.is_empty())


func test_site_blocked_by_enemies_on_arrival() -> void:
	world.pathing.set_target(&"spot", [Vector2i(20, 20)] as Array[Vector2i])
	_submit(Commands.place_building(0, &"wall", Vector2i(20, 20)))
	world.enemies.spawn(world, &"grunt", Rect2i(20, 20, 1, 1), 1, &"spot")
	assert_true(_run_until(func() -> bool: return survivor.orders.is_empty(), 15.0))
	assert_eq(world.grid.occupant(Vector2i(20, 20)), BuildGrid.NONE)
	var reasons := "\n".join(DebugLog.captured_in(&"build"))
	assert_string_contains(reasons, "reason=blocked_by_enemies")


func test_repair_restores_hp_for_free() -> void:
	var wall := SimFixtures.build_now(world, &"wall", Vector2i(8, 5))
	wall.hp = 40
	var resource: int = world.players[0].resource
	_submit(Commands.repair(0, wall.id))
	assert_true(_run_until(func() -> bool: return wall.hp == wall.def.max_hp, 10.0), "repaired to max")
	assert_eq(world.players[0].resource, resource, "free")
	world.step()
	assert_true(survivor.orders.is_empty(), "stops when full")


func test_repair_rate() -> void:
	var wall := SimFixtures.build_now(world, &"wall", Vector2i(6, 5))  # adjacent: no walking
	wall.hp = 10
	_submit(Commands.repair(0, wall.id))
	world.run_seconds(2.0)
	# 25 hp/s for ~2 s.
	assert_almost_eq(float(wall.hp), 10.0 + 50.0, 2.0)


func test_blink_teleports_within_range_with_cooldown() -> void:
	assert_true(_submit(Commands.blink(0, Vector2i(10, 5)))["ok"])
	assert_eq(survivor.cell(), Vector2i(10, 5))
	assert_eq(_submit(Commands.blink(0, Vector2i(12, 5)))["reason"], "cooldown")
	world.run_seconds(12.0)
	assert_eq(_submit(Commands.blink(0, Vector2i(20, 5)))["reason"], "out_of_range")
	SimFixtures.build_now(world, &"wall", Vector2i(13, 5))
	assert_eq(_submit(Commands.blink(0, Vector2i(13, 5)))["reason"], "blocked")
	assert_true(_submit(Commands.blink(0, Vector2i(14, 5)))["ok"], "over the wall")


func test_haste_speeds_up_for_its_duration() -> void:
	_submit(Commands.haste(0))
	_submit(Commands.move_survivor(0, Vector2i(29, 5)))
	world.run_seconds(2.0)
	# 5 m/s * 1.6 = 8 m/s = 4 cells/s.
	assert_almost_eq(survivor.position.x, 5.5 + 2.0 * 4.0, 0.5)
	assert_eq(_submit(Commands.haste(0))["reason"], "cooldown")


func test_enemies_hunt_and_kill_the_survivor() -> void:
	var defeated := []
	world.player_defeated.connect(func(p: int) -> void: defeated.append(p))
	world.enemies.spawn(world, &"grunt", Rect2i(25, 25, 2, 2), 20)
	assert_true(_run_until(func() -> bool: return not survivor.alive, 60.0), "survivor killed")
	assert_eq(defeated, [0])
	assert_false(world.players[0].alive)
	assert_gt(DebugLog.captured_in(&"combat").size(), 0)
	assert_string_contains("\n".join(DebugLog.captured_in(&"state")), "survivor_died=")


func test_enemies_follow_a_moving_survivor() -> void:
	world.enemies.spawn(world, &"grunt", Rect2i(25, 25, 1, 1), 1)
	_submit(Commands.move_survivor(0, Vector2i(25, 2)))
	world.run_seconds(14.0)
	assert_eq(survivor.cell(), Vector2i(25, 2), "survivor got there first (it's faster)")
	var enemy := world.enemies.positions[0]
	assert_lt(enemy.distance_to(survivor.position), 1.5, "enemy followed it across the map")


func test_walled_in_survivor_gets_besieged() -> void:
	for x in range(3, 8):
		SimFixtures.build_now(world, &"wall", Vector2i(x, 3))
		SimFixtures.build_now(world, &"wall", Vector2i(x, 7))
	for z in range(4, 7):
		SimFixtures.build_now(world, &"wall", Vector2i(3, z))
		SimFixtures.build_now(world, &"wall", Vector2i(7, z))
	world.enemies.spawn(world, &"grunt", Rect2i(25, 5, 2, 2), 10)
	assert_true(_run_until(func() -> bool: return world.entities.size() < 17, 30.0), "a wall was broken")
	assert_true(_run_until(func() -> bool: return not survivor.alive, 30.0), "then they got in")


func test_groups_pick_random_living_survivors() -> void:
	world.add_player(1)
	var second := world.survivors.spawn(world, 1, Vector2i(25, 25))
	for i in 12:
		world.enemies.spawn(world, &"grunt", Rect2i(15, 15, 1, 1), 1)
	var keys := {}
	for t in world.enemies.targets:
		keys[world.enemies.target_keys[t]] = true
	assert_eq(keys.size(), 2, "both survivors are hunted")
	world.survivors.damage(world, second, 1e9)
	for t in world.enemies.targets:
		assert_eq(world.enemies.target_keys[t], survivor.target_key(), "dead survivor's hunters retarget")

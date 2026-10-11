extends GutTest
## Render interpolation: the simulation keeps each mover's previous-tick position, and views
## draw between it and the current one.

var world: World


func before_each() -> void:
	world = SimFixtures.world(SimFixtures.open_map(40, 20))
	world.pathing.set_target(&"far", [Vector2i(38, 10)] as Array[Vector2i])


func test_enemies_keep_their_previous_tick_position() -> void:
	world.enemies.spawn(world, &"grunt", Rect2i(2, 10, 2, 2), 5, &"far")
	assert_eq(world.enemies.previous_positions, world.enemies.positions, "spawned in place")
	var before := world.enemies.positions.duplicate()
	world.step()
	assert_eq(world.enemies.previous_positions, before)
	assert_ne(world.enemies.positions, before, "they moved")


func test_previous_positions_follow_slots_when_enemies_die() -> void:
	SimFixtures.armed(world.defs.building(&"tower"), 6.0, 1000.0, 0.2)
	SimFixtures.build_now(world, &"tower", Vector2i(8, 8))
	world.enemies.spawn(world, &"grunt", Rect2i(2, 8, 4, 4), 12, &"far")
	var enemies := world.enemies
	for i in 60:
		var before := {}
		for slot in enemies.count():
			before[enemies.ids[slot]] = enemies.positions[slot]
		world.step()
		assert_eq(enemies.previous_positions.size(), enemies.count())
		for slot in enemies.count():
			assert_eq(enemies.previous_positions[slot], before[enemies.ids[slot]], "enemy %d" % enemies.ids[slot])
	assert_lt(world.enemies.count(), 12, "some were killed")


func test_projectiles_keep_their_previous_tick_position() -> void:
	SimFixtures.armed(world.defs.building(&"tower"), 8.0, 1.0, 0.5, 6.0)
	SimFixtures.build_now(world, &"tower", Vector2i(10, 10))
	world.enemies.spawn(world, &"grunt", Rect2i(16, 10, 1, 1), 1, &"far")
	world.step()
	assert_eq(world.combat.projectile_count(), 1)
	var before := world.combat.proj_pos.duplicate()
	world.step()
	assert_eq(world.combat.proj_prev, before)
	assert_ne(world.combat.proj_pos, before)


func test_survivor_previous_position_and_blink_does_not_slide() -> void:
	var survivor := world.survivors.spawn(world, 0, Vector2i(5, 5))
	world.submit(Commands.move_survivor(0, Vector2i(15, 5)))
	world.run(10)
	var before := survivor.position
	world.step()
	assert_eq(survivor.previous_position, before)
	assert_eq(survivor.position_at(0.5), before.lerp(survivor.position, 0.5))
	world.submit(Commands.blink(0, Vector2i(5, 8)))
	world.step()
	assert_eq(survivor.previous_position, survivor.position, "drawn at the destination at once")


func test_enemy_views_draw_between_ticks() -> void:
	world.enemies.spawn(world, &"grunt", Rect2i(2, 10, 1, 1), 1, &"far")
	world.step()
	var views := EnemyViews.new()
	add_child_autofree(views)
	views.attach(world)
	var previous := world.enemies.previous_positions[0] * SimConstants.CELL_SIZE
	var current := world.enemies.positions[0] * SimConstants.CELL_SIZE
	for alpha: float in [0.0, 0.5, 1.0]:
		views.alpha = alpha
		views._process(0.0)
		var buffer := views.get_child(0).multimesh.buffer as PackedFloat32Array
		var drawn := Vector2(buffer[3], buffer[11])
		assert_almost_eq(drawn, previous.lerp(current, alpha), Vector2(0.001, 0.001), "alpha %.1f" % alpha)

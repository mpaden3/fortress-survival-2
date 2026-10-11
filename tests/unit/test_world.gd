extends GutTest


func before_each() -> void:
	DebugLog.clear_captured()


func test_step_advances_tick_and_log_tick() -> void:
	var world := SimFixtures.world()
	world.run(3)
	assert_eq(world.tick, 3)
	assert_eq(DebugLog.tick, 2, "log lines are stamped with the tick being processed")


func test_run_seconds_uses_tick_rate() -> void:
	var world := SimFixtures.world()
	world.run_seconds(2.0)
	assert_eq(world.tick, 2 * SimConstants.TICK_RATE)


func test_commands_run_next_step_in_order() -> void:
	var world := SimFixtures.world()
	world.submit(Commands.place_building(0, &"wall", Vector2i(1, 1)))
	world.submit(Commands.place_building(0, &"wall", Vector2i(1, 1)))
	assert_eq(world.entities.size(), 0, "nothing happens before step()")
	world.step()
	assert_eq(world.last_results.size(), 2)
	assert_true(world.last_results[0]["ok"])
	assert_eq(world.last_results[1]["reason"], "occupied")
	world.step()
	assert_eq(world.last_results.size(), 0, "results are per step")


func test_unknown_player_and_command_are_rejected() -> void:
	var world := SimFixtures.world()
	world.submit(Commands.place_building(7, &"wall", Vector2i(1, 1)))
	world.submit({"type": &"dance", "player": 0})
	world.step()
	assert_eq(world.last_results[0]["reason"], "unknown_player")
	assert_eq(world.last_results[1]["reason"], "unknown_command")


func test_entity_ids_are_never_reused() -> void:
	var world := SimFixtures.world()
	world.submit(Commands.place_building(0, &"wall", Vector2i(1, 1)))
	world.step()
	var first: int = world.entities.keys()[0]
	world.submit(Commands.sell_building(0, first))
	world.submit(Commands.place_building(0, &"wall", Vector2i(1, 1)))
	world.step()
	assert_eq(world.entities.keys(), [first + 1])


func test_same_seed_and_commands_give_same_result() -> void:
	var a := SimFixtures.world(null, null, 42)
	var b := SimFixtures.world(null, null, 42)
	for world in [a, b]:
		world.submit(Commands.place_building(0, &"tower", Vector2i(2, 2)))
		world.submit(Commands.place_building(0, &"wall", Vector2i(5, 5)))
		world.run(45)
	assert_eq(a.snapshot(), b.snapshot())
	assert_eq(a.rng.randi_range(0, 1_000_000), b.rng.randi_range(0, 1_000_000))

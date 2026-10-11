extends GutTest
## Sandbox commands: resource, clearing enemies, god mode.

var world: World


func before_each() -> void:
	world = SimFixtures.world(SimFixtures.open_map(20, 20))
	world.pathing.set_target(&"t", [Vector2i(10, 10)] as Array[Vector2i])


func _submit(command: Dictionary) -> Dictionary:
	world.submit(command)
	world.step()
	return world.last_results[0]


func test_add_resource_never_goes_below_zero() -> void:
	assert_true(_submit(Commands.debug_add_resource(0, 500))["ok"])
	assert_eq(world.players[0].resource, 600)
	_submit(Commands.debug_add_resource(0, -10000))
	assert_eq(world.players[0].resource, 0)


func test_clear_enemies() -> void:
	world.enemies.spawn(world, &"grunt", Rect2i(2, 2, 4, 4), 30, &"t")
	world.step()
	_submit(Commands.debug_clear_enemies(0))
	assert_eq(world.enemies.count(), 0)
	world.enemies.spawn(world, &"grunt", Rect2i(2, 2, 1, 1), 2, &"t")
	world.run(10)
	assert_eq(world.enemies.count(), 2, "spawning works again afterwards")


func test_god_mode_survivor_takes_no_damage() -> void:
	var survivor := world.survivors.spawn(world, 0, Vector2i(10, 10))
	assert_eq(_submit(Commands.debug_god(1, true))["reason"], "unknown_player")
	_submit(Commands.debug_god(0, true))
	world.enemies.spawn(world, &"grunt", Rect2i(11, 10, 1, 1), 5)
	world.run_seconds(3.0)
	assert_eq(survivor.hp, survivor.def.max_hp)
	_submit(Commands.debug_god(0, false))
	world.run_seconds(2.0)
	assert_lt(survivor.hp, survivor.def.max_hp, "takes damage again")

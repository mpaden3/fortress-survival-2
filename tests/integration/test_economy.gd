extends GutTest

var world: World


func before_each() -> void:
	var defs := SimFixtures.defs(0)
	defs.rules.passive_income_per_minute = 30.0
	defs.add_building(SimFixtures.building(&"mill", Vector2i(2, 2), 0, 1.0, 100))
	defs.building(&"mill").income_per_minute = 60.0
	world = SimFixtures.world(SimFixtures.open_map(10, 10), defs)


func test_passive_income() -> void:
	world.run_seconds(60.0)
	assert_eq(world.players[0].resource, 30)
	assert_eq(world.economy.income_per_minute(world, 0), 30.0)


func test_mill_adds_income_once_built_and_stops_when_sold() -> void:
	world.submit(Commands.place_building(0, &"mill", Vector2i(2, 2)))
	world.step()
	var mill_id := world.grid.occupant(Vector2i(2, 2))
	assert_eq(world.economy.income_per_minute(world, 0), 30.0, "not while constructing")
	world.run_seconds(1.0)
	assert_eq(world.economy.income_per_minute(world, 0), 90.0)
	var before: int = world.players[0].resource
	world.run_seconds(60.0)
	assert_almost_eq(world.players[0].resource - before, 90, 1)
	world.submit(Commands.sell_building(0, mill_id))
	world.step()
	assert_eq(world.economy.income_per_minute(world, 0), 30.0)


func test_dead_players_earn_nothing() -> void:
	var survivor := world.survivors.spawn(world, 0, Vector2i(8, 8))
	world.survivors.damage(world, survivor, 1e9)
	world.run_seconds(60.0)
	assert_eq(world.players[0].resource, 0)

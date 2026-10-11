extends GutTest
## Enemies go for the buildings they see while their Survivor is out of sight.

const SIGHT_M := 8.0  # 4 cells

var world: World
var survivor: SurvivorState


func before_each() -> void:
	DebugLog.clear_captured()
	var registry := SimFixtures.defs(1000)
	registry.enemy(&"grunt").sight_range = SIGHT_M
	world = SimFixtures.world(SimFixtures.open_map(40, 20), registry)


func _spawn_grunt(cell: Vector2i) -> int:
	return world.enemies.spawn(world, &"grunt", Rect2i(cell, Vector2i.ONE), 1)[0]


func _pos(enemy_id: int) -> Vector2:
	return world.enemies.positions[world.enemies.index_of(enemy_id)]


func test_attacks_a_building_in_sight_while_its_survivor_is_far() -> void:
	survivor = world.survivors.spawn(world, 0, Vector2i(36, 10))
	var tower := SimFixtures.build_now(world, &"tower", Vector2i(4, 13))
	var grunt := _spawn_grunt(Vector2i(4, 10))
	world.run_seconds(4.0)
	assert_lt(tower.hp, tower.def.max_hp, "tower damaged")
	assert_eq(world.enemies.attacking[world.enemies.index_of(grunt)], tower.id)
	assert_eq(survivor.hp, survivor.def.max_hp)
	var hits := 0
	for line in DebugLog.captured_in(&"combat"):
		if "hits_building=%d" % tower.id in line:
			hits += 1
	assert_gt(hits, 0, "combat log shows the hits")


func test_without_sight_range_it_keeps_hunting() -> void:
	world.defs.enemy(&"grunt").sight_range = 0.0
	survivor = world.survivors.spawn(world, 0, Vector2i(36, 10))
	var tower := SimFixtures.build_now(world, &"tower", Vector2i(4, 13))
	var grunt := _spawn_grunt(Vector2i(4, 10))
	world.run_seconds(2.0)
	assert_eq(tower.hp, tower.def.max_hp)
	assert_gt(_pos(grunt).x, 8.0, "walked on toward the Survivor")


func test_ignores_buildings_out_of_sight() -> void:
	survivor = world.survivors.spawn(world, 0, Vector2i(36, 2))
	var tower := SimFixtures.build_now(world, &"tower", Vector2i(4, 16))  # 6 cells away
	var grunt := _spawn_grunt(Vector2i(4, 2))
	world.run_seconds(2.0)
	assert_eq(tower.hp, tower.def.max_hp)
	assert_gt(_pos(grunt).x, 8.0, "walked on toward the Survivor")


func test_goes_for_the_survivor_when_it_is_in_sight() -> void:
	survivor = world.survivors.spawn(world, 0, Vector2i(7, 10))  # 3 cells away
	var tower := SimFixtures.build_now(world, &"tower", Vector2i(4, 12))  # 1 cell away
	_spawn_grunt(Vector2i(4, 10))
	world.run_seconds(3.0)
	assert_eq(tower.hp, tower.def.max_hp, "tower ignored")
	assert_lt(survivor.hp, survivor.def.max_hp, "Survivor attacked")


func test_resumes_the_hunt_after_destroying_the_building() -> void:
	survivor = world.survivors.spawn(world, 0, Vector2i(36, 10))
	var wall := SimFixtures.build_now(world, &"wall", Vector2i(4, 12))
	var grunt := _spawn_grunt(Vector2i(4, 10))
	var destroyed := false
	for i in 10 * SimConstants.TICK_RATE:
		world.step()
		if not world.entities.has(wall.id):
			destroyed = true
			break
	assert_true(destroyed, "wall destroyed")
	var x_then := _pos(grunt).x
	world.run_seconds(2.0)
	assert_gt(_pos(grunt).x, x_then + 3.0, "back on its way to the Survivor")

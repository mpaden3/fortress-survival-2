extends GutTest
## Towers vs enemies: range, rate of fire, projectiles, splash, slow, upgrades.

var world: World
var tower_def: BuildingDef


func before_each() -> void:
	DebugLog.clear_captured()
	world = SimFixtures.world(SimFixtures.open_map(40, 20))
	tower_def = world.defs.building(&"tower")
	SimFixtures.armed(tower_def, 5.0, 10.0, 1.0)
	# Static target far left so enemies walk along row 10, right to left.
	world.pathing.set_target(&"t", [Vector2i(0, 10)] as Array[Vector2i])


func _spawn(def_id: StringName, cell: Vector2i, amount := 1) -> Array[int]:
	return world.enemies.spawn(world, def_id, Rect2i(cell, Vector2i.ONE), amount, &"t")


func _hp_of(enemy_id: int) -> float:
	var index := world.enemies.index_of(enemy_id)
	return world.enemies.hp[index] if index >= 0 else 0.0


func test_ignores_enemies_out_of_range() -> void:
	world.pathing.set_target(&"stay", [Vector2i(30, 10)] as Array[Vector2i])
	SimFixtures.build_now(world, &"tower", Vector2i(10, 10))  # centre (11, 11)
	var enemy := world.enemies.spawn(world, &"grunt", Rect2i(30, 10, 1, 1), 1, &"stay")[0]
	world.run_seconds(3.0)
	assert_eq(_hp_of(enemy), 50.0, "19 cells away: untouched")
	assert_eq(DebugLog.captured_in(&"combat").size(), 0)


func test_kills_enemy_in_range_at_its_rate_of_fire() -> void:
	world.pathing.set_target(&"stay", [Vector2i(13, 11)] as Array[Vector2i])
	SimFixtures.build_now(world, &"tower", Vector2i(10, 10))
	var enemy := world.enemies.spawn(world, &"grunt", Rect2i(13, 11, 1, 1), 1, &"stay")[0]
	world.step()
	assert_eq(_hp_of(enemy), 40.0, "first shot right away (instant hit)")
	world.run(SimConstants.TICK_RATE - 1)
	assert_eq(_hp_of(enemy), 40.0, "1 s cooldown")
	world.step()
	assert_eq(_hp_of(enemy), 30.0)
	world.run_seconds(3.0)
	assert_eq(world.enemies.count(), 0, "50 hp = 5 shots")
	assert_string_contains("\\n".join(DebugLog.captured_in(&"combat")), "enemy_killed=%d" % enemy)


func test_damage_scales_with_armor_type() -> void:
	world.defs.rules.damage_multipliers = {&"pierce": {&"light": 1.5, &"heavy": 0.5}}
	world.defs.add_enemy(SimFixtures.enemy(&"light_one"))
	world.defs.add_enemy(SimFixtures.enemy(&"heavy_one"))
	world.defs.enemy(&"light_one").armor_type = &"light"
	world.defs.enemy(&"heavy_one").armor_type = &"heavy"
	tower_def.damage_type = &"pierce"
	world.pathing.set_target(&"stay", [Vector2i(13, 11)] as Array[Vector2i])
	SimFixtures.build_now(world, &"tower", Vector2i(10, 10))
	var light := world.enemies.spawn(world, &"light_one", Rect2i(13, 11, 1, 1), 1, &"stay")[0]
	world.step()
	assert_eq(_hp_of(light), 35.0, "10 x 1.5 against light armor")
	world.enemies.damage(world.enemies.index_of(light), 1000.0)
	var heavy := world.enemies.spawn(world, &"heavy_one", Rect2i(13, 11, 1, 1), 1, &"stay")[0]
	world.run(SimConstants.TICK_RATE)
	assert_eq(_hp_of(heavy), 45.0, "10 x 0.5 against heavy armor")
	var grunt := _spawn(&"grunt", Vector2i(13, 11))[0]
	assert_eq(world.defs.enemy(&"grunt").armor_type, &"medium")
	world.enemies.damage(world.enemies.index_of(heavy), 1000.0)
	world.run(SimConstants.TICK_RATE)
	assert_eq(_hp_of(grunt), 40.0, "no table entry: full damage")


func test_projectile_takes_time_to_arrive() -> void:
	SimFixtures.armed(tower_def, 8.0, 10.0, 5.0, 4.0)  # 4 m/s = 2 cells/s
	world.pathing.set_target(&"stay", [Vector2i(16, 11)] as Array[Vector2i])
	SimFixtures.build_now(world, &"tower", Vector2i(10, 10))
	var enemy := world.enemies.spawn(world, &"grunt", Rect2i(16, 11, 1, 1), 1, &"stay")[0]
	world.step()
	assert_eq(world.combat.projectile_count(), 1)
	world.run_seconds(2.0)
	assert_eq(_hp_of(enemy), 50.0, "still in flight (~5.5 cells at 2 cells/s)")
	world.run_seconds(1.5)
	assert_eq(_hp_of(enemy), 40.0, "landed")
	assert_eq(world.combat.projectile_count(), 0)


func test_splash_hits_every_enemy_in_radius() -> void:
	SimFixtures.armed(tower_def, 8.0, 10.0, 10.0, 0.0, 1.5)
	world.pathing.set_target(&"stay", [Vector2i(15, 11)] as Array[Vector2i])
	SimFixtures.build_now(world, &"tower", Vector2i(10, 10))
	var group := world.enemies.spawn(world, &"grunt", Rect2i(15, 11, 1, 1), 4, &"stay")
	var far := world.enemies.spawn(world, &"grunt", Rect2i(19, 11, 1, 1), 1, &"stay")[0]
	world.step()
	world.step()
	for enemy in group:
		assert_eq(_hp_of(enemy), 40.0, "splashed")
	assert_eq(_hp_of(far), 50.0, "outside the splash")


func test_slow_reduces_speed_then_wears_off() -> void:
	SimFixtures.armed(tower_def, 30.0, 1.0, 100.0, 0.0, 0.0, 0.5, 2.0)
	SimFixtures.build_now(world, &"tower", Vector2i(30, 2))
	var slowed := _spawn(&"grunt", Vector2i(35, 10))[0]
	world.step()  # tower shoots once (cooldown 100 s)
	var index := world.enemies.index_of(slowed)
	assert_lt(world.enemies.slow_multiplier[index], 1.0)
	var x0 := world.enemies.positions[index].x
	world.run_seconds(1.0)
	var slow_distance := x0 - world.enemies.positions[world.enemies.index_of(slowed)].x
	world.run_seconds(1.5)
	var x1 := world.enemies.positions[world.enemies.index_of(slowed)].x
	world.run_seconds(1.0)
	var fast_distance := x1 - world.enemies.positions[world.enemies.index_of(slowed)].x
	# grunt: 4 m/s = 2 cells/s; slowed to half.
	assert_almost_eq(slow_distance, 1.0, 0.15, "half speed while slowed")
	assert_almost_eq(fast_distance, 2.0, 0.15, "full speed after")


func test_constructing_tower_does_not_fire() -> void:
	world.pathing.set_target(&"stay", [Vector2i(13, 11)] as Array[Vector2i])
	world.submit(Commands.place_building(0, &"tower", Vector2i(10, 10)))
	world.step()
	var enemy := world.enemies.spawn(world, &"grunt", Rect2i(13, 11, 1, 1), 1, &"stay")[0]
	world.run_seconds(1.0)
	assert_eq(_hp_of(enemy), 50.0)


func test_upgrade_in_place() -> void:
	var tower := SimFixtures.build_now(world, &"tower", Vector2i(10, 10))
	tower.hp = 250  # damaged by 50
	var resource: int = world.players[0].resource
	world.submit(Commands.upgrade_building(0, tower.id, &"tower_2"))
	world.step()
	assert_true(world.last_results[0]["ok"])
	assert_eq(world.players[0].resource, resource - 30)
	assert_false(tower.can_attack(), "busy while upgrading")
	world.run_seconds(2.0)
	assert_eq(tower.def.id, &"tower_2")
	assert_eq(tower.hp, 450, "keeps its damage: 500 - 50")
	assert_eq(tower.invested, 50, "20 + 30, the base for sell refunds")
	assert_eq(tower.rect, Rect2i(10, 10, 2, 2), "same footprint")


func test_upgrade_rejections() -> void:
	var wall := SimFixtures.build_now(world, &"wall", Vector2i(2, 2))
	var tower := SimFixtures.build_now(world, &"tower", Vector2i(10, 10))
	world.add_player(1)
	var cases := [
		[Commands.upgrade_building(0, wall.id, &"tower_2"), "not_an_upgrade"],
		[Commands.upgrade_building(1, tower.id, &"tower_2"), "not_owner"],
		[Commands.upgrade_building(0, 999, &"tower_2"), "unknown_building"],
	]
	for case in cases:
		world.submit(case[0])
		world.step()
		assert_eq(world.last_results[0]["reason"], case[1])
	world.players[0].resource = 0
	world.submit(Commands.upgrade_building(0, tower.id, &"tower_2"))
	world.step()
	assert_eq(world.last_results[0]["reason"], "not_enough_resource")
	world.players[0].resource = 100
	world.submit(Commands.upgrade_building(0, tower.id, &"tower_2"))
	world.submit(Commands.upgrade_building(0, tower.id, &"tower_2"))
	world.step()
	assert_eq(world.last_results[1]["reason"], "busy")


func test_towers_defend_against_a_wave() -> void:
	# Real defs: a grunt wave walks into a kill zone covered by three arrow towers.
	# (Whether towers stop a wave *in transit* is balance, not mechanics; numbers are placeholders.)
	world = SimFixtures.world(SimFixtures.open_map(40, 20), DefRegistry.load_default())
	world.defs.enemy(&"grunt").sight_range = 0.0  # walk the lane; besieging towers is tested elsewhere
	world.pathing.set_target(&"t", [Vector2i(16, 10)] as Array[Vector2i])
	for x in [10, 16, 22]:
		var tower := SimFixtures.build_now(world, &"basic_tower", Vector2i(x, 7))
		world.submit(Commands.upgrade_building(0, tower.id, &"arrow_tower"))
	world.run_seconds(6.0)
	world.enemies.spawn(world, &"grunt", Rect2i(38, 9, 2, 3), 12, &"t")
	# ~14 s to walk in, then 720 total hp against ~2-3 towers in reach.
	world.run_seconds(40.0)
	assert_eq(world.enemies.count(), 0, "wave wiped out in the kill zone")

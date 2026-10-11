extends GutTest
## Fog-of-war hook: off, everything is visible; on, only what players' things can see, shared
## by allies, and views draw only that.

var world: World


func before_each() -> void:
	world = SimFixtures.world(SimFixtures.open_map(60, 20))
	world.pathing.set_target(&"stay", [Vector2i(50, 10)] as Array[Vector2i])


func _fog(on: bool) -> void:
	world.defs.rules.fog_of_war = on
	world.defs.rules.survivor_vision = 5.0
	world.defs.rules.building_vision = 4.0


func test_everything_visible_without_fog() -> void:
	_fog(false)
	world.step()
	assert_true(world.visibility.mask(0).is_empty())
	assert_true(world.visibility.can_see(0, world, Vector2i(59, 19)))


func test_fog_shows_only_what_players_see_and_allies_share_it() -> void:
	_fog(true)
	world.add_player(1)
	world.survivors.spawn(world, 0, Vector2i(5, 10))
	world.survivors.spawn(world, 1, Vector2i(30, 10))
	SimFixtures.build_now(world, &"wall", Vector2i(50, 2))
	world.step()
	assert_true(world.visibility.can_see(0, world, Vector2i(8, 10)), "near own Survivor")
	assert_false(world.visibility.can_see(0, world, Vector2i(18, 10)), "far from everything")
	assert_true(world.visibility.can_see(0, world, Vector2i(32, 10)), "an ally's Survivor shares vision")
	assert_true(world.visibility.can_see(0, world, Vector2i(52, 3)), "buildings see too")
	var unit := world.units.spawn(world, 0, &"fighter", Vector2(18.5, 15.5))
	world.run(VisibilitySystem.REFRESH_TICKS)
	assert_true(world.visibility.can_see(0, world, Vector2i(18, 12)), "units see their sight range")
	world.units.damage(world, unit, 1000.0)
	world.run(VisibilitySystem.REFRESH_TICKS)
	assert_false(world.visibility.can_see(0, world, Vector2i(18, 12)), "gone when the unit dies")


func test_enemy_views_draw_only_visible_enemies() -> void:
	_fog(true)
	world.survivors.spawn(world, 0, Vector2i(5, 10))
	world.enemies.spawn(world, &"grunt", Rect2i(7, 10, 1, 1), 3, &"stay")
	world.enemies.spawn(world, &"grunt", Rect2i(40, 10, 1, 1), 4, &"stay")
	world.step()
	var views := EnemyViews.new()
	add_child_autofree(views)
	views.attach(world)
	views._process(0.0)
	assert_eq((views.get_child(0) as MultiMeshInstance3D).multimesh.visible_instance_count, 3, "only the near ones")
	world.defs.rules.fog_of_war = false
	world.step()
	views._process(0.0)
	assert_eq((views.get_child(0) as MultiMeshInstance3D).multimesh.visible_instance_count, 7, "all without fog")

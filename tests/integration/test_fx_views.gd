extends GutTest
## FxViews turns simulation events into effects: the right effect per event, pooled, and fires
## that follow building HP.

var world: World
var fx: FxViews
var tower_def: BuildingDef


func before_each() -> void:
	world = SimFixtures.world(SimFixtures.open_map(40, 20))
	tower_def = world.defs.building(&"tower")
	world.pathing.set_target(&"stay", [Vector2i(13, 11)] as Array[Vector2i])
	fx = FxViews.new()
	add_child_autofree(fx)
	fx.attach(world)


func _shoot(splash := 0.0, slow := 1.0, damage := 10.0) -> void:
	SimFixtures.armed(tower_def, 5.0, damage, 1.0, 0.0, splash, slow, 1.0)
	SimFixtures.build_now(world, &"tower", Vector2i(10, 10))
	world.enemies.spawn(world, &"grunt", Rect2i(13, 11, 1, 1), 1, &"stay")
	world.step()


func test_plain_shot_flashes_and_sparks() -> void:
	_shoot()
	assert_eq(fx.playing_count(FxViews.MUZZLE_FLASH), 1)
	assert_eq(fx.playing_count(FxViews.HIT_SPARK), 1)
	assert_eq(fx.playing_count(FxViews.EXPLOSION), 0)


func test_splash_shot_explodes() -> void:
	_shoot(1.5)
	assert_eq(fx.playing_count(FxViews.EXPLOSION), 1)
	assert_eq(fx.playing_count(FxViews.HIT_SPARK), 0)


func test_slowing_shot_bursts_frost_even_with_splash() -> void:
	_shoot(1.0, 0.5)
	assert_eq(fx.playing_count(FxViews.FROST_BURST), 1)
	assert_eq(fx.playing_count(FxViews.EXPLOSION), 0)


func test_kill_plays_enemy_death() -> void:
	_shoot(0.0, 1.0, 100.0)
	assert_eq(fx.playing_count(FxViews.ENEMY_DEATH), 1)


func test_one_shots_finish_and_hide() -> void:
	_shoot()
	await wait_seconds(0.6)
	assert_eq(fx.playing_count(FxViews.MUZZLE_FLASH), 0)
	assert_eq(fx.playing_count(FxViews.HIT_SPARK), 0)


func test_pool_reuses_effects_instead_of_growing() -> void:
	var size: int = FxViews.POOL_SIZES[FxViews.ENEMY_DEATH]
	for i in size * 3:
		fx.play(FxViews.ENEMY_DEATH, Vector3(i, 0, 0))
	assert_eq(fx.get_child_count(), size)
	assert_eq(fx.playing_count(FxViews.ENEMY_DEATH), size)


func test_building_burns_below_threshold_and_grows_with_damage() -> void:
	var wall := SimFixtures.build_now(world, &"wall", Vector2i(3, 3))
	await wait_process_frames(1)
	assert_null(fx.fire_of(wall.id), "healthy")
	wall.hp = int(wall.def.max_hp * 0.5)
	await wait_process_frames(1)
	var fire := fx.fire_of(wall.id)
	assert_not_null(fire, "half HP burns")
	var weak := fire.intensity
	wall.hp = int(wall.def.max_hp * 0.1)
	await wait_process_frames(1)
	assert_gt(fire.intensity, weak, "burns harder as HP drops")
	wall.hp = wall.def.max_hp
	await wait_process_frames(2)
	assert_null(fx.fire_of(wall.id), "repaired: fire out")


func test_constructing_building_does_not_burn() -> void:
	world.buildings.start_construction(world, 0, &"wall", Vector2i(3, 3))
	world.step()
	await wait_process_frames(1)
	assert_null(fx.fire_of(world.grid.occupant(Vector2i(3, 3))), "low HP while building is not damage")


func test_destroyed_building_explodes_and_fire_goes_out() -> void:
	var wall := SimFixtures.build_now(world, &"wall", Vector2i(3, 3))
	wall.hp = 10
	await wait_process_frames(1)
	assert_not_null(fx.fire_of(wall.id))
	world.step()
	world.buildings.damage(world, wall.id, 1000.0)
	world.stepped.emit()
	assert_null(fx.fire_of(wall.id))
	assert_eq(fx.playing_count(FxViews.EXPLOSION), 1)

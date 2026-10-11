extends GutTest
## Presentation events: each tick records shots, impacts, kills and destroyed buildings for
## the views, and starts empty.

var world: World
var tower_def: BuildingDef


func before_each() -> void:
	world = SimFixtures.world(SimFixtures.open_map(40, 20))
	tower_def = world.defs.building(&"tower")
	world.pathing.set_target(&"stay", [Vector2i(13, 11)] as Array[Vector2i])


func _event(index: int) -> Dictionary:
	var events := world.events
	return {"kind": events.kinds[index], "pos": events.positions[index], "def": events.defs[index],
		"id": events.ids[index]}


func test_instant_shot_records_fired_and_impact() -> void:
	SimFixtures.armed(tower_def, 5.0, 10.0, 1.0)
	var tower := SimFixtures.build_now(world, &"tower", Vector2i(10, 10))
	world.enemies.spawn(world, &"grunt", Rect2i(13, 11, 1, 1), 1, &"stay")
	world.step()
	var fired := world.events.of_kind(SimEvents.Kind.FIRED)
	assert_eq(fired.size(), 1)
	assert_eq(_event(fired[0]), {"kind": SimEvents.Kind.FIRED, "pos": tower.centre(), "def": &"tower", "id": tower.id})
	var impacts := world.events.of_kind(SimEvents.Kind.IMPACT)
	assert_eq(impacts.size(), 1)
	assert_eq(world.events.ids[impacts[0]], tower.id)
	world.step()
	assert_eq(world.events.count(), 0, "cleared each tick: nothing happened during the cooldown")


func test_projectile_impact_happens_on_arrival() -> void:
	SimFixtures.armed(tower_def, 8.0, 10.0, 5.0, 4.0)
	SimFixtures.build_now(world, &"tower", Vector2i(10, 10))
	world.enemies.spawn(world, &"grunt", Rect2i(13, 11, 1, 1), 1, &"stay")
	world.step()
	assert_eq(world.events.of_kind(SimEvents.Kind.IMPACT).size(), 0, "in flight")
	var impact_ticks := 0
	for i in 2 * SimConstants.TICK_RATE:
		world.step()
		impact_ticks += world.events.of_kind(SimEvents.Kind.IMPACT).size()
	assert_eq(impact_ticks, 1)


func test_kill_records_enemy_death_where_it_died() -> void:
	SimFixtures.armed(tower_def, 5.0, 100.0, 1.0)
	SimFixtures.build_now(world, &"tower", Vector2i(10, 10))
	var enemy := world.enemies.spawn(world, &"grunt", Rect2i(13, 11, 1, 1), 1, &"stay")[0]
	var position := world.enemies.positions[world.enemies.index_of(enemy)]
	world.step()
	var kills := world.events.of_kind(SimEvents.Kind.ENEMY_KILLED)
	assert_eq(kills.size(), 1)
	assert_eq(world.events.ids[kills[0]], enemy)
	assert_eq(world.events.defs[kills[0]], &"grunt")
	assert_almost_eq(world.events.positions[kills[0]].distance_to(position), 0.0, 0.5)


func test_splash_kills_record_one_death_each() -> void:
	SimFixtures.armed(tower_def, 5.0, 100.0, 1.0, 0.0, 3.0)
	SimFixtures.build_now(world, &"tower", Vector2i(10, 10))
	world.enemies.spawn(world, &"grunt", Rect2i(13, 11, 1, 1), 4, &"stay")
	world.step()
	assert_eq(world.events.of_kind(SimEvents.Kind.ENEMY_KILLED).size(), 4)
	assert_eq(world.events.of_kind(SimEvents.Kind.IMPACT).size(), 1)


func test_destroyed_building_recorded_but_sold_one_not() -> void:
	var wall := SimFixtures.build_now(world, &"wall", Vector2i(3, 3))
	var other := SimFixtures.build_now(world, &"wall", Vector2i(5, 3))
	world.submit(Commands.sell_building(0, other.id))
	world.step()
	assert_eq(world.events.count(), 0, "selling isn't a destruction")
	world.buildings.damage(world, wall.id, 1000.0)
	var destroyed := world.events.of_kind(SimEvents.Kind.BUILDING_DESTROYED)
	assert_eq(destroyed.size(), 1)
	assert_eq(_event(destroyed[0]), {"kind": SimEvents.Kind.BUILDING_DESTROYED, "pos": wall.centre(), "def": &"wall",
		"id": wall.id})


func test_stepped_signal_fires_once_per_tick() -> void:
	watch_signals(world)
	world.run(3)
	assert_signal_emit_count(world, "stepped", 3)

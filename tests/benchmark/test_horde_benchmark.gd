extends GutTest
## Performance budget: 2000 enemies on the full-size map, hunting the start from all 5 spawns.
## Target (ROADMAP): 60 FPS with ~2000 enemies. The simulation runs at 30 ticks/s, so a tick
## must leave most of a 16.7 ms frame to rendering: budget 8 ms per tick on average.

const ENEMIES := 2000
const TICK_BUDGET_MS := 8.0
const FIELD_BUDGET_MS := 60.0
## Rebuilt on every building change, on top of the flow fields.
const SIGHT_BUDGET_MS := 10.0
## A rebuild after the Survivor moves is sliced over ticks; one slice must stay small.
const SLICE_BUDGET_MS := 3.0


func test_2000_enemies_on_mvp_map() -> void:
	DebugLog.active = false  # measure the game, not the logger
	var layout := MapLayout.load_file("res://data/maps/mvp_map.json")
	var world := World.new(layout, DefRegistry.load_default(), 7)
	world.add_player(0)
	world.pathing.set_target(&"survivor", [layout.start] as Array[Vector2i])
	for spawn in layout.spawns:
		world.enemies.spawn(world, &"grunt", spawn.rect, ENEMIES / layout.spawns.size(), &"survivor")
	world.step()  # builds the field
	var field_ms := world.pathing.field(&"survivor").build_usec / 1000.0
	var total_usec := 0
	var worst_usec := 0
	var ticks := 90
	for i in ticks:
		world.step()
		total_usec += world.enemies.update_usec
		worst_usec = maxi(worst_usec, world.enemies.update_usec)
	DebugLog.active = true
	var avg_ms := total_usec / 1000.0 / ticks
	gut.p("horde benchmark: %d enemies, avg %.2f ms/tick, worst %.2f ms, field build %.1f ms"
		% [world.enemies.count(), avg_ms, worst_usec / 1000.0, field_ms])
	assert_eq(world.enemies.count(), ENEMIES)
	assert_lt(field_ms, FIELD_BUDGET_MS, "flow field build within budget")
	assert_lt(avg_ms, TICK_BUDGET_MS, "enemy update within budget")


## The Survivor moves: the field rebuild is spread over ticks, each slice within budget.
func test_sliced_field_rebuild_on_mvp_map() -> void:
	DebugLog.active = false
	var layout := MapLayout.load_file("res://data/maps/mvp_map.json")
	var world := World.new(layout, DefRegistry.load_default(), 7)
	world.add_player(0)
	world.pathing.set_target(&"survivor", [layout.start] as Array[Vector2i])
	world.step()
	var flow := world.pathing.field(&"survivor")
	world.pathing.set_target(&"survivor", [layout.start + Vector2i(2, 0)] as Array[Vector2i])
	var ticks := 0
	var worst_usec := 0
	while flow.builds == 1 and ticks < 100:
		world.step()
		ticks += 1
		worst_usec = maxi(worst_usec, flow.advance_usec)
	DebugLog.active = true
	gut.p("sliced rebuild: %d ticks, worst slice %.2f ms, total %.1f ms"
		% [ticks, worst_usec / 1000.0, flow.build_usec / 1000.0])
	assert_eq(flow.builds, 2, "rebuild finished")
	assert_lt(worst_usec / 1000.0, SLICE_BUDGET_MS, "each slice within budget")


## Same horde, plus 32 towers around the start firing into it.
func test_2000_enemies_with_32_towers() -> void:
	DebugLog.active = false
	var layout := MapLayout.load_file("res://data/maps/mvp_map.json")
	var world := World.new(layout, DefRegistry.load_default(), 7)
	world.add_player(0)
	world.players[0].resource = 1_000_000
	world.pathing.set_target(&"survivor", [layout.start] as Array[Vector2i])
	var towers := 0
	var defs := [&"basic_tower"]
	for dz in range(-14, 15, 2):
		for dx in range(-14, 15, 2):
			if towers >= 32 or (absi(dx) < 6 and absi(dz) < 6):
				continue
			if world.buildings.start_construction(world, 0, defs[0], layout.start + Vector2i(dx, dz)).is_empty():
				towers += 1
	world.run_seconds(4.0)  # finish construction
	for entity in world.entities.values():
		var tower := entity as BuildingState
		var branch: StringName = [&"arrow_tower", &"cannon_tower", &"frost_tower"][tower.id % 3]
		world.submit(Commands.upgrade_building(0, tower.id, branch))
	world.run_seconds(7.0)
	for spawn in layout.spawns:
		world.enemies.spawn(world, &"grunt", spawn.rect, ENEMIES / layout.spawns.size(), &"survivor")
	world.run_seconds(8.0)  # let the horde reach the towers
	var enemy_usec := 0
	var combat_usec := 0
	var ticks := 90
	for i in ticks:
		world.step()
		enemy_usec += world.enemies.update_usec
		combat_usec += world.combat.update_usec
	DebugLog.active = true
	var enemy_ms := enemy_usec / 1000.0 / ticks
	var combat_ms := combat_usec / 1000.0 / ticks
	var sight_ms := world.pathing.sight.build_usec / 1000.0
	gut.p("combat benchmark: %d towers, %d enemies left, enemies %.2f ms + combat %.2f ms per tick, %d projectiles, sight field %.1f ms"
		% [towers, world.enemies.count(), enemy_ms, combat_ms, world.combat.projectile_count(), sight_ms])
	assert_eq(towers, 32)
	assert_lt(sight_ms, SIGHT_BUDGET_MS, "building sight field rebuild within budget")
	assert_lt(enemy_ms + combat_ms, TICK_BUDGET_MS, "enemies + combat within budget")


## The horde against a garrison of 60 fighters around the start (units + enemies seeing them).
func test_2000_enemies_with_60_fighters() -> void:
	DebugLog.active = false
	var layout := MapLayout.load_file("res://data/maps/mvp_map.json")
	var world := World.new(layout, DefRegistry.load_default(), 7)
	world.add_player(0)
	world.pathing.set_target(&"survivor", [layout.start] as Array[Vector2i])
	var fighters := 0
	for dz in range(-14, 15, 2):
		for dx in range(-14, 15, 2):
			var cell := layout.start + Vector2i(dx, dz)
			if fighters < 60 and world.grid.check(Rect2i(cell, Vector2i.ONE)).is_empty():
				world.units.spawn(world, 0, &"fighter", Vector2(cell) + Vector2(0.5, 0.5))
				fighters += 1
	for spawn in layout.spawns:
		world.enemies.spawn(world, &"grunt", spawn.rect, ENEMIES / layout.spawns.size(), &"survivor")
	# Measure the whole fight, on ticks where fighters are still standing.
	var total_usec := 0
	var worst_usec := 0
	var ticks := 0
	var contact_tick := -1
	for i in 30 * SimConstants.TICK_RATE:
		world.step()
		if world.units.living().is_empty():
			break
		var usec := world.enemies.update_usec + world.units.update_usec
		total_usec += usec
		worst_usec = maxi(worst_usec, usec)
		ticks += 1
		if contact_tick < 0 and world.units.living().size() < fighters:
			contact_tick = world.tick
	DebugLog.active = true
	var avg_ms := total_usec / 1000.0 / ticks
	gut.p("garrison benchmark: %d fighters, first loss at tick %d, %d ticks with fighters, enemies + units avg %.2f ms, worst %.2f ms"
		% [fighters, contact_tick, ticks, avg_ms, worst_usec / 1000.0])
	assert_eq(fighters, 60)
	assert_gt(contact_tick, 0, "the horde reached the garrison")
	assert_lt(avg_ms, TICK_BUDGET_MS, "enemies + units within budget")


## Straightened A* routes across the full map must stay cheap (units re-route while chasing).
func test_long_route_on_mvp_map() -> void:
	var layout := MapLayout.load_file("res://data/maps/mvp_map.json")
	var world := World.new(layout, DefRegistry.load_default(), 7)
	var from := Vector2(layout.start) + Vector2(0.5, 0.5)
	var worst_usec := 0
	var longest := 0
	var goals: Array[Vector2] = []
	for spawn in layout.spawns:
		goals.append(Vector2(spawn.rect.get_center()))
	for plot in layout.plots:  # into enclosed plots: many turns
		goals.append(Vector2(plot.rects[0].get_center()))
	for to in goals:
		var started := Time.get_ticks_usec()
		var route := world.pathing.paths.find_route(world, from, to, 0.2)
		worst_usec = maxi(worst_usec, Time.get_ticks_usec() - started)
		longest = maxi(longest, route.size())
	gut.p("long routes: worst %.2f ms, at most %d waypoints" % [worst_usec / 1000.0, longest])
	assert_gt(longest, 3, "some routes turn several times")
	assert_lt(worst_usec / 1000.0, 5.0, "route within budget")

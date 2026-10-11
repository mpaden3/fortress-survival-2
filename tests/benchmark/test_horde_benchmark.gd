extends GutTest
## Performance budget: 2000 enemies on the full-size map, hunting the start from all 5 spawns.
## Target (ROADMAP): 60 FPS with ~2000 enemies. The simulation runs at 30 ticks/s, so a tick
## must leave most of a 16.7 ms frame to rendering: budget 8 ms per tick on average.

const ENEMIES := 2000
const TICK_BUDGET_MS := 8.0
const FIELD_BUDGET_MS := 60.0


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

extends GutTest
## Match flow: grace period, spawn streams, timed events, win and loss.

var world: World


func before_each() -> void:
	DebugLog.clear_captured()
	world = SimFixtures.world(SimFixtures.map_from_rows([
		"##########################",
		"#........................#",
		"#........................#",
		"#........................#",
		"##########################",
	] as Array[String]))
	# Spawn far from the Survivor so enemies don't reach it in short tests.
	world.map.spawns.clear()
	var spawn := MapLayout.Spawn.new()
	spawn.id = "east"
	spawn.rect = Rect2i(24, 1, 1, 3)
	world.map.spawns.append(spawn)


func _schedule(duration := 60.0, grace := 5.0) -> WaveSchedule:
	var schedule := WaveSchedule.new()
	schedule.duration = duration
	schedule.grace_period = grace
	return schedule


func _stream(rate_start: float, rate_end: float, start := 0.0, end := 60.0, group := 1) -> SpawnStream:
	var stream := SpawnStream.new()
	stream.enemy = &"grunt"
	stream.rate_start = rate_start
	stream.rate_end = rate_end
	stream.start_time = start
	stream.end_time = end
	stream.group_size = group
	return stream


func test_nothing_spawns_during_grace_period() -> void:
	world.survivors.spawn(world, 0, Vector2i(1, 2))
	var schedule := _schedule(60.0, 10.0)
	schedule.streams.append(_stream(60.0, 60.0))
	world.match_system.start(world, schedule)
	world.run_seconds(9.9)
	assert_eq(world.enemies.count(), 0)
	world.run_seconds(1.2)
	assert_gt(world.enemies.count(), 0)


func test_stream_spawns_its_rate_integral() -> void:
	world.survivors.spawn(world, 0, Vector2i(1, 2)).hp = 1e12  # survives the whole stream
	var schedule := _schedule(120.0, 0.0)
	# Ramps 30 -> 90 per minute over 60 s: 60 enemies in the first minute, in groups of 3.
	schedule.streams.append(_stream(30.0, 90.0, 0.0, 60.0, 3))
	world.match_system.start(world, schedule)
	world.run_seconds(30.0)
	assert_almost_eq(world.enemies.count(), 22, 3, "first 30 s: (30 + 60) / 2 * 0.5 = 22.5")
	world.run_seconds(30.0)
	assert_almost_eq(world.enemies.count(), 60, 3)
	assert_eq(world.enemies.count() % 3, 0, "spawned in whole groups")
	world.run_seconds(10.0)
	assert_almost_eq(world.enemies.count(), 60, 3, "stream over")


func test_events_fire_once_at_their_time_with_announcement() -> void:
	world.survivors.spawn(world, 0, Vector2i(1, 2))
	var schedule := _schedule(60.0, 0.0)
	var event := SpawnEvent.new()
	event.time = 10.0
	event.enemy = &"grunt"
	event.count = 4
	event.announcement = "Boss!"
	schedule.events.append(event)
	world.match_system.start(world, schedule)
	world.run_seconds(9.9)
	assert_eq(world.enemies.count(), 0)
	world.run_seconds(0.2)
	assert_eq(world.enemies.count(), 4)
	assert_eq(world.match_system.announcement, "Boss!")
	world.run_seconds(5.0)
	assert_eq(world.enemies.count(), 4, "only once")


func test_win_when_timer_runs_out_with_survivor_alive() -> void:
	world.survivors.spawn(world, 0, Vector2i(1, 2))
	var results := []
	world.match_ended.connect(func(r: int) -> void: results.append(r))
	world.match_system.start(world, _schedule(10.0))
	world.run_seconds(9.9)
	assert_eq(world.match_system.result, MatchSystem.Result.RUNNING)
	world.run_seconds(0.2)
	assert_eq(world.match_system.result, MatchSystem.Result.WON)
	assert_eq(results, [MatchSystem.Result.WON])
	assert_string_contains("\n".join(DebugLog.captured_in(&"state")), "match_over=WON")


func test_loss_when_all_survivors_die_and_spawning_stops() -> void:
	var survivor := world.survivors.spawn(world, 0, Vector2i(1, 2))
	var schedule := _schedule(60.0, 0.0)
	schedule.streams.append(_stream(60.0, 60.0))
	world.match_system.start(world, schedule)
	world.run_seconds(2.0)
	world.survivors.damage(world, survivor, 1e9)
	world.step()
	assert_eq(world.match_system.result, MatchSystem.Result.LOST)
	var count := world.enemies.count()
	world.run_seconds(5.0)
	assert_eq(world.enemies.count(), count, "no more spawns after the match ends")


func test_default_schedule_is_valid() -> void:
	var defs := DefRegistry.load_default()
	var schedule := defs.schedule
	assert_eq(schedule.duration, 1200.0, "MVP match is 20 minutes")
	for stream in schedule.streams:
		assert_not_null(defs.enemy(stream.enemy), "stream enemy %s exists" % stream.enemy)
		assert_true(stream.start_time < stream.end_time and stream.end_time <= schedule.duration)
	var has_boss := false
	for event in schedule.events:
		assert_not_null(defs.enemy(event.enemy), "event enemy %s exists" % event.enemy)
		assert_true(event.time < schedule.duration)
		has_boss = has_boss or event.enemy == &"behemoth"
	assert_true(has_boss, "final boss scheduled")


func test_full_default_match_on_test_map_is_deterministic() -> void:
	# Smoke: the first 3 minutes of the real schedule on the real test map, twice.
	var snapshots := []
	for run in 2:
		var w := World.new(MapLayout.load_file("res://data/maps/test_map.json"), DefRegistry.load_default(), 99)
		w.add_player(0)
		w.survivors.spawn(w, 0, w.map.start)
		w.match_system.start(w, w.defs.schedule)
		w.run_seconds(180.0)
		snapshots.append([w.enemies.count(), w.enemies.positions, w.survivors.survivor_of(0).hp])
	assert_gt(snapshots[0][0], 0, "enemies spawned")
	assert_eq(snapshots[0], snapshots[1])

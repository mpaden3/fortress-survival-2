extends GutTest
## Co-op over ENet on localhost: a client joins, gets its own player and Survivor, commands it
## through the host and sees the host's world.

var host_world: World
var host: NetHost
var client: NetClient
var port := 0


func before_each() -> void:
	DebugLog.clear_captured()
	host_world = World.new(MapLayout.load_file("res://data/maps/test_map.json"), DefRegistry.load_default(), 3)
	host_world.add_player(0)
	host_world.survivors.spawn(host_world, 0, SurvivorSystem.start_cell(host_world, 0))
	host = NetHost.new()
	add_child_autofree(host)
	port = 41000 + randi() % 8000
	assert_eq(host.start(host_world, port), OK, "host listens")
	client = NetClient.new()
	add_child_autofree(client)
	assert_eq(client.start("127.0.0.1", port), OK)


func after_each() -> void:
	client.stop()
	host.stop()


## Runs the host simulation in real frames until `condition` holds.
func _until(condition: Callable, max_frames := 300) -> bool:
	for i in max_frames:
		if condition.call():
			return true
		host_world.step()
		await get_tree().process_frame
	return condition.call()


func test_client_joins_and_mirrors_the_host_world() -> void:
	assert_true(await _until(func() -> bool: return client.world != null), "welcomed")
	assert_eq(client.player_id, 1)
	assert_true(host_world.players.has(1), "host added the player")
	assert_not_null(host_world.survivors.survivor_of(1), "with its own Survivor")
	assert_ne(host_world.survivors.survivor_of(1).cell(), host_world.survivors.survivor_of(0).cell(), "on its own spot")
	assert_true(await _until(func() -> bool: return client.snapshots > 0))
	assert_eq(client.world.survivors.living().size(), 2, "client sees both Survivors")
	assert_almost_eq(client.world.tick, host_world.tick, NetProtocol.SNAPSHOT_TICKS + 1)


func test_client_commands_its_survivor_through_the_host() -> void:
	assert_true(await _until(func() -> bool: return client.snapshots > 0))
	var goal := host_world.survivors.survivor_of(1).cell() + Vector2i(-3, 2)
	client.world.submit(Commands.move_survivor(1, goal))
	assert_true(await _until(func() -> bool: return host_world.survivors.survivor_of(1).cell() == goal), "host moved it")
	assert_true(await _until(func() -> bool: return client.world.survivors.survivor_of(1).cell() == goal), "client sees it")
	assert_eq(host_world.survivors.survivor_of(0).cell(), SurvivorSystem.start_cell(host_world, 0), "host's own stayed")


func test_client_cannot_act_for_another_player() -> void:
	assert_true(await _until(func() -> bool: return client.snapshots > 0))
	var host_survivor := host_world.survivors.survivor_of(0)
	var start := host_survivor.cell()
	client.world.submit(Commands.move_survivor(0, start + Vector2i(4, 0)))  # pretends to be player 0
	await _until(func() -> bool: return false, 30)
	assert_eq(host_survivor.cell(), start, "player 0's Survivor didn't move")
	assert_ne(host_world.survivors.survivor_of(1).cell(), SurvivorSystem.start_cell(host_world, 1),
		"the command ran as the sender's own player instead")


func test_snapshots_carry_enemies_and_events() -> void:
	assert_true(await _until(func() -> bool: return client.snapshots > 0))
	host_world.enemies.spawn(host_world, &"grunt", host_world.map.spawns[1].rect, 500)
	var shots := [0]
	client.world.stepped.connect(func() -> void: shots[0] += client.world.events.count())
	assert_true(await _until(func() -> bool: return client.world.enemies.count() == 500), "enemies mirrored")
	gut.p("snapshot with 500 enemies: %.1f KB" % (host.last_snapshot_bytes / 1024.0))
	assert_lt(host.last_snapshot_bytes, 64 * 1024, "fits a reasonable packet budget")

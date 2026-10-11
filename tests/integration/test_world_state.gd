extends GutTest
## WorldState: a saved world restores into a fresh one that continues identically, and view
## snapshots update a client's world in place.


func _new_world(seed_value := 5) -> World:
	var world := World.new(MapLayout.load_file("res://data/maps/test_map.json"), DefRegistry.load_default(), seed_value)
	world.add_player(0)
	return world


## A busy match: waves, a bot building and training, towers firing.
func _busy_world(seconds: float) -> World:
	DebugLog.active = false
	var world := _new_world()
	world.survivors.spawn(world, 0, SurvivorSystem.start_cell(world, 0))
	world.players[0].resource = 2000
	world.match_system.start(world, world.defs.schedule)
	var bot := DefenceBot.new(world, 0, "keep")
	for i in roundi(seconds * SimConstants.TICK_RATE):
		bot.update(world)
		world.step()
	DebugLog.active = true
	return world


## The saved state minus timing measurements (which differ run to run).
static func _comparable(value: Variant) -> Variant:
	if value is Dictionary:
		var out := {}
		for key: Variant in value:
			if not str(key).ends_with("usec"):
				out[key] = _comparable(value[key])
		return out
	if value is Array:
		return (value as Array).map(func(v: Variant) -> Variant: return _comparable(v))
	return value


func _assert_same(a: World, b: World, label: String) -> void:
	var bytes_a := var_to_bytes(_comparable(WorldState.capture(a)))
	var bytes_b := var_to_bytes(_comparable(WorldState.capture(b)))
	assert_eq(bytes_a.size(), bytes_b.size(), "%s: same size" % label)
	assert_true(bytes_a == bytes_b, "%s: identical state" % label)


func test_restored_world_continues_identically() -> void:
	var original := _busy_world(150.0)
	assert_gt(original.enemies.count(), 0, "enemies in play")
	assert_gt(original.units.living().size() + original.entities.size(), 5, "a base in play")
	DebugLog.active = false
	for checkpoint in 3:
		var copy := _new_world(999)  # a different seed: everything must come from the save
		WorldState.restore(copy, WorldState.from_bytes(WorldState.to_bytes(WorldState.capture(original))))
		_assert_same(original, copy, "right after restore %d" % checkpoint)
		var survivor := original.survivors.survivor_of(0)
		var goal := survivor.cell() + Vector2i(1 - checkpoint, 1)
		for world: World in [original, copy]:
			world.submit(Commands.move_survivor(0, goal))
			world.submit(Commands.debug_spawn(0, &"grunt", "north", 10, &""))
		for i in 20 * SimConstants.TICK_RATE:
			original.step()
			copy.step()
		_assert_same(original, copy, "20 s after restore %d" % checkpoint)
	DebugLog.active = true


func test_save_survives_bytes_round_trip() -> void:
	var world := _busy_world(30.0)
	var state := WorldState.capture(world)
	var bytes := WorldState.to_bytes(state)
	gut.p("save size: %d KB compressed" % (bytes.size() / 1024))
	assert_true(var_to_bytes(_comparable(WorldState.from_bytes(bytes))) == var_to_bytes(_comparable(state)))


func test_view_snapshots_update_a_client_world_in_place() -> void:
	var host := _new_world()
	host.survivors.spawn(host, 0, SurvivorSystem.start_cell(host, 0))
	var wall := SimFixtures.build_now(host, &"wall", host.map.start + Vector2i(3, 3))
	host.enemies.spawn(host, &"grunt", host.map.spawns[1].rect, 5)
	host.step()
	var client := _new_world()
	var added := []
	var removed := []
	client.entity_added.connect(func(e: SimEntity) -> void: added.append(e.id))
	client.entity_removed.connect(func(e: SimEntity) -> void: removed.append(e.id))
	WorldState.apply_view(client, WorldState.capture_view(host))
	assert_eq(added.size(), 2, "survivor and wall appear")
	assert_eq(client.enemies.ids, host.enemies.ids)
	assert_eq(client.enemies.positions, host.enemies.positions)
	assert_eq(client.grid.occupant(wall.rect.position), wall.id, "the client's grid has the wall")
	var client_survivor := client.survivors.survivor_of(0)
	assert_not_null(client_survivor, "client knows the Survivor")
	var enemy_before := client.enemies.positions[0]
	var survivor_object := client_survivor
	host.submit(Commands.move_survivor(0, host.map.start + Vector2i(-4, 0)))
	host.run(10)
	host.buildings.damage(host, wall.id, 10000.0)  # its event goes out with this snapshot
	WorldState.apply_view(client, WorldState.capture_view(host))
	assert_eq(removed, [wall.id], "destroyed wall removed")
	assert_eq(client.grid.occupant(wall.rect.position), BuildGrid.NONE)
	assert_same(client.survivors.survivor_of(0), survivor_object, "same object, updated in place")
	assert_eq(client_survivor.position, host.survivors.survivor_of(0).position)
	assert_ne(client_survivor.previous_position, client_survivor.position, "interpolates from the last snapshot")
	assert_eq(client.enemies.previous_positions[client.enemies.index_of(host.enemies.ids[0])], enemy_before)
	assert_gt(client.events.of_kind(SimEvents.Kind.BUILDING_DESTROYED).size(), 0, "events come along")

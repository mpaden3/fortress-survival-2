extends GutTest
## Trained units: training at the barracks, orders, fighters, repairmen, and being attacked.

var world: World


func before_each() -> void:
	DebugLog.clear_captured()
	world = SimFixtures.world(SimFixtures.open_map(40, 30), SimFixtures.defs(1000))
	# Enemies in these tests stay where they spawn unless something else draws them.
	world.pathing.set_target(&"stay", [Vector2i(30, 15)] as Array[Vector2i])


func _submit(command: Dictionary) -> Dictionary:
	world.submit(command)
	world.step()
	return world.last_results[0]


## An enemy that stays on `cell` (its hunt target is that cell).
func _enemy(cell: Vector2i) -> int:
	var key := StringName("stay_%d_%d" % [cell.x, cell.y])
	world.pathing.set_target(key, [cell] as Array[Vector2i])
	return world.enemies.spawn(world, &"grunt", Rect2i(cell, Vector2i.ONE), 1, key)[0]


func _alive(enemy_id: int) -> bool:
	return world.enemies.index_of(enemy_id) >= 0


func _run_until(condition: Callable, max_seconds: float) -> bool:
	for i in roundi(max_seconds * SimConstants.TICK_RATE):
		if condition.call():
			return true
		world.step()
	return condition.call()


# --- Training -------------------------------------------------------------------------------

func test_barracks_trains_a_unit_next_to_it() -> void:
	var barracks := SimFixtures.build_now(world, &"barracks", Vector2i(10, 10))
	var resource: int = world.players[0].resource
	assert_true(_submit(Commands.train_unit(0, barracks.id, &"fighter"))["ok"])
	assert_eq(world.players[0].resource, resource - 10, "paid when queued")
	assert_eq(world.units.living().size(), 0)
	world.run_seconds(1.0)
	assert_eq(world.units.living().size(), 1, "trained after train_time")
	var unit := world.units.living()[0]
	assert_eq(unit.def.id, &"fighter")
	assert_true(Rect2i(9, 9, 4, 4).has_point(unit.cell()) and not barracks.rect.has_point(unit.cell()),
		"stands next to the barracks")
	assert_string_contains("\n".join(DebugLog.captured_in(&"units")), "unit_spawned=%d" % unit.id)


func test_training_queue_runs_in_order() -> void:
	var barracks := SimFixtures.build_now(world, &"barracks", Vector2i(10, 10))
	world.submit(Commands.train_unit(0, barracks.id, &"fighter"))
	world.submit(Commands.train_unit(0, barracks.id, &"repairman"))
	world.run_seconds(1.1)
	assert_eq(world.units.living().size(), 1)
	world.run_seconds(1.0)
	assert_eq(world.units.living().map(func(u: UnitState) -> StringName: return u.def.id), [&"fighter", &"repairman"])


func test_train_rejections() -> void:
	var barracks := SimFixtures.build_now(world, &"barracks", Vector2i(10, 10))
	var wall := SimFixtures.build_now(world, &"wall", Vector2i(2, 2))
	world.add_player(1)
	assert_eq(_submit(Commands.train_unit(0, wall.id, &"fighter"))["reason"], "cannot_train")
	assert_eq(_submit(Commands.train_unit(1, barracks.id, &"fighter"))["reason"], "not_owner")
	assert_eq(_submit(Commands.train_unit(0, barracks.id, &"dragon"))["reason"], "cannot_train")
	for i in world.defs.rules.max_train_queue:
		world.submit(Commands.train_unit(0, barracks.id, &"fighter"))
	world.step()
	assert_eq(_submit(Commands.train_unit(0, barracks.id, &"fighter"))["reason"], "queue_full")
	world.players[0].resource = 0
	var other := SimFixtures.build_now(world, &"barracks", Vector2i(20, 10))
	world.players[0].resource = 0
	assert_eq(_submit(Commands.train_unit(0, other.id, &"fighter"))["reason"], "not_enough_resource")


func test_unbuilt_barracks_cannot_train() -> void:
	world.buildings.start_construction(world, 0, &"barracks", Vector2i(10, 10))
	var barracks := world.entities.get(world.grid.occupant(Vector2i(10, 10))) as BuildingState
	assert_eq(_submit(Commands.train_unit(0, barracks.id, &"fighter"))["reason"], "not_built")


# --- Orders ---------------------------------------------------------------------------------

func test_move_order_walks_around_walls() -> void:
	for z in range(5, 15):
		SimFixtures.build_now(world, &"wall", Vector2i(10, z))
	var unit := world.units.spawn(world, 0, &"fighter", Vector2(5.5, 10.5))
	_submit(Commands.order_units(0, [unit.id] as Array[int], "move", Vector2i(15, 10)))
	assert_true(_run_until(func() -> bool: return unit.orders.is_empty(), 15.0), "arrived")
	assert_eq(unit.cell(), Vector2i(15, 10))
	for line in DebugLog.captured_in(&"units"):
		assert_false("pos=(10." in line and "unit=" in line, "never inside the wall column")
	assert_eq(unit.home, unit.position, "guards where it stopped")


func test_orders_only_own_units() -> void:
	world.add_player(1)
	var unit := world.units.spawn(world, 0, &"fighter", Vector2(5.5, 5.5))
	assert_eq(_submit(Commands.order_units(1, [unit.id] as Array[int], "move", Vector2i(9, 9)))["reason"], "no_units")
	assert_true(unit.orders.is_empty())


func test_stop_and_hold() -> void:
	var unit := world.units.spawn(world, 0, &"fighter", Vector2(5.5, 5.5))
	_submit(Commands.order_units(0, [unit.id] as Array[int], "move", Vector2i(20, 5)))
	world.run_seconds(1.0)
	_submit(Commands.order_units(0, [unit.id] as Array[int], "stop"))
	var stopped_at := unit.position
	world.run_seconds(1.0)
	assert_true(unit.orders.is_empty())
	assert_almost_eq(unit.position, stopped_at, Vector2(0.01, 0.01), "stays and guards there")
	_submit(Commands.order_units(0, [unit.id] as Array[int], "hold"))
	assert_true(unit.holding)
	var enemy := _enemy(Vector2i(unit.cell().x + 5, unit.cell().y))  # in sight, out of range
	world.run_seconds(2.0)
	assert_almost_eq(unit.position, stopped_at, Vector2(0.01, 0.01), "holding: doesn't chase")
	assert_eq(world.enemies.hp[world.enemies.index_of(enemy)], 50.0, "out of range: not hit")


# --- Fighters -------------------------------------------------------------------------------

func test_idle_fighter_kills_an_enemy_in_sight_then_returns() -> void:
	var unit := world.units.spawn(world, 0, &"fighter", Vector2(10.5, 10.5))
	var enemy := _enemy(Vector2i(14, 10))  # 4 cells: in sight (5), out of range (3)
	assert_true(_run_until(func() -> bool: return not _alive(enemy), 5.0), "killed (50 hp, 10 per 0.5 s)")
	assert_string_contains("\n".join(DebugLog.captured_in(&"combat")), "hits_enemy=%d" % enemy)
	assert_true(_run_until(func() -> bool: return unit.position.distance_to(unit.home) < 1.5, 5.0), "back home")


func test_idle_fighter_ignores_enemies_out_of_sight() -> void:
	var unit := world.units.spawn(world, 0, &"fighter", Vector2(10.5, 10.5))
	var enemy := _enemy(Vector2i(17, 10))
	world.run_seconds(2.0)
	assert_eq(world.enemies.hp[world.enemies.index_of(enemy)], 50.0)
	assert_almost_eq(unit.position, Vector2(10.5, 10.5), Vector2(0.01, 0.01))


func test_idle_fighter_gives_up_beyond_its_leash() -> void:
	var unit := world.units.spawn(world, 0, &"fighter", Vector2(10.5, 15.5))
	world.units.living()[0].def.attack_damage = 0.1  # can't kill it in time
	var enemy := world.enemies.spawn(world, &"grunt", Rect2i(14, 15, 1, 1), 1, &"stay")[0]
	world.pathing.set_target(&"stay", [Vector2i(38, 15)] as Array[Vector2i])  # it walks away east
	world.run_seconds(6.0)
	assert_true(_alive(enemy))
	assert_lt(unit.position.distance_to(unit.home), unit.def.leash_range + 1.0, "stayed on its leash")


func test_move_ignores_enemies_and_attack_move_fights() -> void:
	var mover := world.units.spawn(world, 0, &"fighter", Vector2(2.5, 10.5))
	var fighter := world.units.spawn(world, 0, &"fighter", Vector2(2.5, 20.5))
	var near_mover := _enemy(Vector2i(10, 12))
	var near_fighter := _enemy(Vector2i(10, 22))
	world.submit(Commands.order_units(0, [mover.id] as Array[int], "move", Vector2i(20, 10)))
	world.submit(Commands.order_units(0, [fighter.id] as Array[int], "attack_move", Vector2i(20, 20)))
	world.run_seconds(8.0)
	assert_true(_alive(near_mover), "move: walked past")
	assert_false(_alive(near_fighter), "attack-move: fought on the way")
	assert_true(_run_until(func() -> bool: return fighter.orders.is_empty(), 8.0), "then carried on")
	assert_eq(fighter.cell(), Vector2i(20, 20))


func test_attack_move_carries_on_after_a_fight_in_range() -> void:
	var fighter := world.units.spawn(world, 0, &"fighter", Vector2(2.5, 10.5))
	var enemy := _enemy(Vector2i(4, 10))  # already in range
	_submit(Commands.order_units(0, [fighter.id] as Array[int], "attack_move", Vector2i(20, 10)))
	assert_true(_run_until(func() -> bool: return not _alive(enemy), 5.0))
	assert_false(fighter.orders.is_empty(), "the order is still on")
	assert_true(_run_until(func() -> bool: return fighter.orders.is_empty(), 10.0))
	assert_eq(fighter.cell(), Vector2i(20, 10))


func test_damage_type_applies_to_unit_attacks() -> void:
	world.defs.rules.damage_multipliers = {&"pierce": {&"medium": 2.0}}
	world.defs.unit(&"fighter").damage_type = &"pierce"
	world.units.spawn(world, 0, &"fighter", Vector2(10.5, 10.5))
	var enemy := _enemy(Vector2i(12, 10))
	world.step()
	assert_eq(world.enemies.hp[world.enemies.index_of(enemy)], 30.0, "10 x 2 against medium armor")


# --- Repairmen ------------------------------------------------------------------------------

func test_repairman_repairs_damaged_buildings_in_sight_for_free() -> void:
	var near := SimFixtures.build_now(world, &"wall", Vector2i(14, 10))
	var far := SimFixtures.build_now(world, &"wall", Vector2i(30, 10))
	near.hp = 40
	far.hp = 40
	var unit := world.units.spawn(world, 0, &"repairman", Vector2(10.5, 10.5))
	var resource: int = world.players[0].resource
	assert_true(_run_until(func() -> bool: return near.hp == near.def.max_hp, 10.0), "repaired (60 hp at 10/s)")
	assert_eq(far.hp, 40, "out of sight")
	assert_eq(world.players[0].resource, resource, "free")
	assert_true(_run_until(func() -> bool: return unit.position.distance_to(unit.home) < 1.5, 5.0), "back home")


# --- Enemies vs units -----------------------------------------------------------------------

func test_enemies_attack_units_they_see_and_kill_them() -> void:
	var survivor := world.survivors.spawn(world, 0, Vector2i(38, 28))  # far away: out of sight
	world.defs.enemy(&"grunt").sight_range = 10.0  # 5 cells
	world.defs.unit(&"fighter").attack_damage = 0.0  # a sitting duck
	var unit := world.units.spawn(world, 0, &"fighter", Vector2(5.5, 5.5))
	var killed := []
	world.stepped.connect(func() -> void:
		for i in world.events.of_kind(SimEvents.Kind.UNIT_KILLED):
			killed.append(world.events.ids[i]))
	world.enemies.spawn(world, &"grunt", Rect2i(8, 5, 1, 1), 3)
	assert_true(_run_until(func() -> bool: return not world.entities.has(unit.id), 10.0), "unit killed")
	assert_eq(killed, [unit.id])
	assert_eq(world.units.living().size(), 0)
	assert_string_contains("\n".join(DebugLog.captured_in(&"combat")), "hits_unit=%d" % unit.id)
	assert_eq(survivor.hp, survivor.def.max_hp)


func test_enemies_ignore_units_out_of_sight() -> void:
	world.survivors.spawn(world, 0, Vector2i(38, 5))
	world.defs.enemy(&"grunt").sight_range = 6.0  # 3 cells
	var unit := world.units.spawn(world, 0, &"repairman", Vector2(10.5, 20.5))
	world.enemies.spawn(world, &"grunt", Rect2i(10, 14, 1, 1), 1)  # 6 cells north
	world.run_seconds(2.0)
	assert_eq(unit.hp, unit.def.max_hp)


func test_units_block_construction_on_their_cell() -> void:
	var unit := world.units.spawn(world, 0, &"repairman", Vector2(10.5, 10.5))
	assert_eq(world.buildings.start_construction(world, 0, &"wall", unit.cell()), "blocked_by_unit")


func test_repairman_skips_a_damaged_building_it_cannot_reach() -> void:
	var map := SimFixtures.map_from_rows([
		".....#......",
		".....#......",
		".....#......",
		".....#......",
		".....#......",
	] as Array[String])
	world = SimFixtures.world(map, SimFixtures.defs(1000))
	var across := SimFixtures.build_now(world, &"wall", Vector2i(7, 2))  # other side of the ridge
	var near := SimFixtures.build_now(world, &"wall", Vector2i(1, 0))
	across.hp = 40
	near.hp = 40
	var unit := world.units.spawn(world, 0, &"repairman", Vector2(4.5, 2.5))  # nearer the unreachable wall
	assert_true(_run_until(func() -> bool: return near.hp == near.def.max_hp, 10.0), "repairs the reachable one")
	assert_eq(across.hp, 40)
	world.run_seconds(2.0)
	assert_eq(unit.target_building, 0, "doesn't hang on the unreachable one")

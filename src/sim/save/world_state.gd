class_name WorldState
## Whole-world save and restore, plus the lighter view snapshot co-op clients draw from.
##
## capture() / restore(): everything the simulation needs to continue exactly where it was
## (entities, every system's state, the RNG). Restore into a fresh World built with the same
## map and definitions; the restored world then runs identically to the original. The data is
## plain Variants, so var_to_bytes() turns it into a save file or a network message.
##
## capture_view() / apply_view(): only what's drawn (entities, enemies, projectiles, players,
## match timer, this tick's events), applied in place to a client's World that never steps.
## Entities keep their objects and the usual entity_added / removed / changed signals fire,
## so views and HUD work unchanged.

const FORMAT := 1


static func capture(world: World) -> Dictionary:
	return {
		"format": FORMAT, "map": world.map.id, "tick": world.tick, "next_id": world._next_id,
		"rng": world.rng.get_state(), "players": _players(world), "entities": _entities(world),
		"economy": world.economy.save_state(), "match": world.match_system.save_state(),
		"survivors": world.survivors.save_state(), "units": world.units.save_state(),
		"enemies": world.enemies.save_state(), "combat": world.combat.save_state(),
		"pathing": world.pathing.save_state(),
	}


## Loads `state` (from capture) into `world`, a fresh World on the same map and definitions.
static func restore(world: World, state: Dictionary) -> void:
	assert(state["format"] == FORMAT and state["map"] == world.map.id, "save doesn't match this world")
	world.tick = state["tick"]
	world._next_id = state["next_id"]
	world.rng.set_state(state["rng"])
	_load_players(world, state["players"])
	for data: Dictionary in state["entities"]:
		var entity := _new_entity(data)
		ObjectState.load_into(entity, data["state"], world.defs)
		world.entities[entity.id] = entity
		var building := entity as BuildingState
		if building:
			world.grid.occupy(building.rect, building.id)
		world.entity_added.emit(entity)
	world.buildings.load_state(world)
	world.survivors.load_state(world, state["survivors"])
	world.units.load_state(world, state["units"])
	world.economy.load_state(state["economy"])
	world.match_system.load_state(world, state["match"])
	world.enemies.load_state(world, state["enemies"])
	world.combat.load_state(world, state["combat"])
	world.pathing.load_state(world, state["pathing"])


static func to_bytes(state: Dictionary) -> PackedByteArray:
	return var_to_bytes(state).compress(FileAccess.COMPRESSION_GZIP)


static func from_bytes(bytes: PackedByteArray, size_hint := 64 * 1024 * 1024) -> Dictionary:
	return bytes_to_var(bytes.decompress_dynamic(size_hint, FileAccess.COMPRESSION_GZIP))


# --- View snapshots (co-op clients) ---------------------------------------------------------

static func capture_view(world: World) -> Dictionary:
	var match_system := world.match_system
	var events := world.events
	return {
		"tick": world.tick, "players": _players(world), "entities": _entities(world),
		"enemies": {"ids": world.enemies.ids.duplicate(), "types": world.enemies.types.duplicate(),
			"positions": world.enemies.positions.duplicate(), "hp": world.enemies.hp.duplicate(),
			"attacking": world.enemies.attacking.duplicate()},
		"projectiles": world.combat.proj_pos.duplicate(),
		"match": {"active": match_system.active, "result": match_system.result, "start_tick": match_system.start_tick,
			"announcement": match_system.announcement, "announcement_tick": match_system.announcement_tick},
		"events": {"kinds": events.kinds.duplicate(), "positions": events.positions.duplicate(),
			"defs": events.defs.duplicate(), "ids": events.ids.duplicate()},
	}


## Applies a view snapshot to a client's `world` in place. Movers keep where they were as
## their previous position, so views interpolate from the last snapshot to this one.
static func apply_view(world: World, view: Dictionary) -> void:
	world.tick = view["tick"]
	_load_players(world, view["players"])
	var seen := {}
	for data: Dictionary in view["entities"]:
		var entity_id: int = data["state"]["id"]
		seen[entity_id] = true
		var entity: SimEntity = world.entities.get(entity_id)
		if entity == null:
			entity = _new_entity(data)
			ObjectState.load_into(entity, data["state"], world.defs)
			_set_previous(entity)
			world.entities[entity_id] = entity
			_occupy(world, entity)
			world.entity_added.emit(entity)
			continue
		var old_position: Variant = entity.get("position")
		var old_def: Variant = entity.get("def")
		ObjectState.load_into(entity, data["state"], world.defs)
		if old_position != null:
			entity.set("previous_position", old_position)
		if old_def != entity.get("def"):
			world.entity_changed.emit(entity)
	for entity_id: int in world.entities.keys():
		if not seen.has(entity_id):
			var gone: SimEntity = world.entities[entity_id]
			if gone is BuildingState:
				world.grid.release((gone as BuildingState).rect)
			world.entities.erase(entity_id)
			world.entity_removed.emit(gone)
	world.survivors.load_state(world, {"field_cell": {}, "repair_carry": {}, "paths_version": -1})
	world.units.load_state(world, {"training": []})
	_apply_enemies(world, view["enemies"])
	var combat := world.combat
	var previous := combat.proj_pos
	combat.proj_pos = view["projectiles"].duplicate()
	combat.proj_prev = previous if previous.size() == combat.proj_pos.size() else combat.proj_pos.duplicate()
	var match_view: Dictionary = view["match"]
	var match_system := world.match_system
	match_system.active = match_view["active"]
	match_system.result = match_view["result"]
	match_system.start_tick = match_view["start_tick"]
	match_system.announcement = match_view["announcement"]
	match_system.announcement_tick = match_view["announcement_tick"]
	if match_system.active and match_system.schedule == null:
		match_system.schedule = world.defs.schedule
	var events := world.events
	events.clear()
	var event_view: Dictionary = view["events"]
	for i in event_view["kinds"].size():
		events.add(event_view["kinds"][i], event_view["positions"][i], event_view["defs"][i], event_view["ids"][i])


static func _apply_enemies(world: World, view: Dictionary) -> void:
	var enemies := world.enemies
	var old := {}
	for i in enemies.ids.size():
		old[enemies.ids[i]] = enemies.positions[i]
	enemies.ids = view["ids"].duplicate()
	enemies.types = view["types"].duplicate()
	enemies.positions = view["positions"].duplicate()
	enemies.hp = view["hp"].duplicate()
	enemies.attacking = view["attacking"].duplicate()
	var previous := PackedVector2Array()
	previous.resize(enemies.ids.size())
	for i in enemies.ids.size():
		previous[i] = old.get(enemies.ids[i], enemies.positions[i])
	enemies.previous_positions = previous
	enemies._slot.clear()
	for i in enemies.ids.size():
		enemies._slot[enemies.ids[i]] = i


# --- Helpers --------------------------------------------------------------------------------

static func _players(world: World) -> Array:
	var out := []
	for player_id in world.players:
		out.append(ObjectState.dump(world.players[player_id]))
	return out


static func _load_players(world: World, data: Array) -> void:
	for player_data: Dictionary in data:
		var player: PlayerState = world.players.get(player_data["id"])
		if player == null:
			player = world.add_player(player_data["id"])
		ObjectState.load_into(player, player_data, world.defs)


static func _entities(world: World) -> Array:
	var out := []
	var ids := world.entities.keys()
	ids.sort()
	for entity_id: int in ids:
		var entity: SimEntity = world.entities[entity_id]
		out.append({"class": String(entity.get_script().get_global_name()), "state": ObjectState.dump(entity)})
	return out


static func _new_entity(data: Dictionary) -> SimEntity:
	match data["class"]:
		"BuildingState":
			return BuildingState.new()
		"SurvivorState":
			return SurvivorState.new()
		"UnitState":
			return UnitState.new()
	assert(false, "unknown entity class %s" % data["class"])
	return null


static func _set_previous(entity: SimEntity) -> void:
	if entity.get("position") != null:
		entity.set("previous_position", entity.get("position"))


static func _occupy(world: World, entity: SimEntity) -> void:
	var building := entity as BuildingState
	if building:
		world.grid.occupy(building.rect, building.id)

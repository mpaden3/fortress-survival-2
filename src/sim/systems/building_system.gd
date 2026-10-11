class_name BuildingSystem
extends RefCounted
## Placing, constructing and selling buildings.
## Holds no reference to the World (it's passed in) so the two don't form a reference cycle.

var _constructing: Array[BuildingState] = []
var _upgrading: Array[BuildingState] = []


func register(world: World) -> void:
	world.register_command(Commands.PLACE_BUILDING, _place)
	world.register_command(Commands.SELL_BUILDING, _sell)
	world.register_command(Commands.UPGRADE_BUILDING, _upgrade)


func update(world: World) -> void:
	for i in range(_upgrading.size() - 1, -1, -1):
		var building := _upgrading[i]
		building.upgrade_progress += 1
		if building.upgrade_progress >= building.upgrading_to.build_ticks():
			var old := building.def
			building.def = building.upgrading_to
			building.hp += building.def.max_hp - old.max_hp
			building.upgrading_to = null
			building.upgrade_progress = 0
			_upgrading.remove_at(i)
			world.entity_changed.emit(building)
			if DebugLog.on(&"build"):
				DebugLog.event(&"build", {"upgraded": building.id, "from": old.id, "to": building.def.id, "hp": building.hp})
	for i in range(_constructing.size() - 1, -1, -1):
		var building := _constructing[i]
		var total := building.def.build_ticks()
		var start_hp := _start_hp(world, building.def)
		# HP rises linearly to max over the build; integer steps land exactly on max_hp.
		var before := (building.def.max_hp - start_hp) * building.build_progress / total
		building.build_progress += 1
		var after := (building.def.max_hp - start_hp) * building.build_progress / total
		building.hp = mini(building.def.max_hp, building.hp + after - before)
		if building.build_progress >= total:
			building.constructing = false
			_constructing.remove_at(i)
			if DebugLog.on(&"build"):
				DebugLog.event(&"build", {"completed": building.id, "def": building.def.id, "hp": building.hp})


## Damages a building; returns true if that destroyed it (it's removed immediately).
func damage(world: World, building_id: int, amount: float) -> bool:
	var building := world.entities.get(building_id) as BuildingState
	if building == null:
		return false
	building.hp -= ceili(amount)
	if building.hp > 0:
		return false
	if DebugLog.on(&"combat"):
		DebugLog.event(&"combat", {"building_destroyed": building.id, "def": building.def.id, "cell": building.rect.position})
	world.events.add(SimEvents.Kind.BUILDING_DESTROYED, building.centre(), building.def.id, building.id)
	_remove(world, building)
	return true


## Why `def_id` can't be built by `player_id` at `origin` right now, or "" if it can.
func validate(world: World, player_id: int, def_id: StringName, origin: Vector2i) -> String:
	var def := world.defs.building(def_id)
	if def == null:
		return "unknown_def"
	if not def.placeable:
		return "not_placeable"
	var rect := Rect2i(origin, def.footprint)
	var blocked := world.grid.check(rect)
	if not blocked.is_empty():
		return blocked
	if world.players[player_id].resource < def.cost:
		return "not_enough_resource"
	return ""


## Validates, pays and starts construction immediately. Units standing on the footprint
## block it. Returns "" or the rejection reason.
func start_construction(world: World, player_id: int, def_id: StringName, origin: Vector2i) -> String:
	var reason := validate(world, player_id, def_id, origin)
	var def := world.defs.building(def_id)
	if reason.is_empty():
		var rect := Rect2i(origin, def.footprint)
		if world.enemies.any_in_rect(rect):
			reason = "blocked_by_enemies"
		elif world.survivors.any_in_rect(rect):
			reason = "blocked_by_unit"
	if not reason.is_empty():
		return _reject({"type": Commands.PLACE_BUILDING, "player": player_id, "def": def_id, "cell": origin}, reason)
	var player := world.players[player_id]
	player.resource -= def.cost
	var building := BuildingState.new()
	building.owner = player.id
	building.def = def
	building.rect = Rect2i(origin, def.footprint)
	building.invested = def.cost
	building.hp = _start_hp(world, def)
	world.add_entity(building)
	world.grid.occupy(building.rect, building.id)
	_constructing.append(building)
	if DebugLog.on(&"build"):
		DebugLog.event(&"build", {"placed": building.id, "def": def.id, "player": player.id,
			"cell": building.rect.position, "size": building.rect.size, "cost": def.cost, "resource_left": player.resource})
	return ""


## Restores HP of a completed building; returns HP actually restored.
func repair(building: BuildingState, amount: float) -> float:
	if building.constructing:
		return 0.0
	var restored := mini(building.def.max_hp - building.hp, ceili(amount))
	building.hp += restored
	return restored


## Place command: a player with a living Survivor gets a build order (the Survivor walks to
## the site first); without one (tests, future AI) construction starts immediately.
func _place(world: World, command: Dictionary) -> String:
	var player_id: int = command["player"]
	var survivor := world.survivors.survivor_of(player_id)
	if survivor == null or not survivor.alive:
		return start_construction(world, player_id, command["def"], command["cell"])
	var reason := validate(world, player_id, command["def"], command["cell"])
	if not reason.is_empty():
		return _reject(command, reason)
	world.survivors.order_build(survivor, command["def"], command["cell"], command.get("queue", false))
	return ""


func _upgrade(world: World, command: Dictionary) -> String:
	var building := world.entities.get(command["building"]) as BuildingState
	if building == null:
		return _reject(command, "unknown_building")
	if building.owner != command["player"]:
		return _reject(command, "not_owner")
	if building.constructing or building.upgrading_to != null:
		return _reject(command, "busy")
	if not command["def"] in building.def.upgrades:
		return _reject(command, "not_an_upgrade")
	var target := world.defs.building(command["def"])
	var player := world.players[building.owner]
	if player.resource < target.cost:
		return _reject(command, "not_enough_resource")
	player.resource -= target.cost
	building.invested += target.cost
	building.upgrading_to = target
	building.upgrade_progress = 0
	_upgrading.append(building)
	if DebugLog.on(&"build"):
		DebugLog.event(&"build", {"upgrading": building.id, "from": building.def.id, "to": target.id, "cost": target.cost})
	return ""


func _sell(world: World, command: Dictionary) -> String:
	var building := world.entities.get(command["building"]) as BuildingState
	if building == null:
		return _reject(command, "unknown_building")
	if building.owner != command["player"]:
		return _reject(command, "not_owner")
	var refund := floori(building.invested * world.defs.rules.sell_refund_ratio)
	world.players[building.owner].resource += refund
	_remove(world, building)
	if DebugLog.on(&"build"):
		DebugLog.event(&"build", {"sold": building.id, "def": building.def.id, "refund": refund})
	return ""


func _remove(world: World, building: BuildingState) -> void:
	world.grid.release(building.rect)
	_constructing.erase(building)
	_upgrading.erase(building)
	world.remove_entity(building.id)


func _start_hp(world: World, def: BuildingDef) -> int:
	return maxi(1, roundi(def.max_hp * world.defs.rules.construction_start_hp_ratio))


func _reject(command: Dictionary, reason: String) -> String:
	if DebugLog.on(&"build"):
		DebugLog.event(&"build", {"rejected": command["type"], "player": command["player"], "reason": reason,
			"def": command.get("def", ""), "cell": command.get("cell", ""), "building": command.get("building", "")})
	return reason

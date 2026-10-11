class_name BuildingSystem
extends RefCounted
## Placing, constructing and selling buildings.
## Holds no reference to the World (it's passed in) so the two don't form a reference cycle.

var _constructing: Array[BuildingState] = []


func register(world: World) -> void:
	world.register_command(Commands.PLACE_BUILDING, _place)
	world.register_command(Commands.SELL_BUILDING, _sell)


func update(world: World) -> void:
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


func _place(world: World, command: Dictionary) -> String:
	var def := world.defs.building(command["def"])
	if def == null:
		return _reject(command, "unknown_def")
	if not def.placeable:
		return _reject(command, "not_placeable")
	var player := world.players[command["player"]]
	var rect := Rect2i(command["cell"], def.footprint)
	var blocked := world.grid.check(rect)
	if not blocked.is_empty():
		return _reject(command, blocked)
	if player.resource < def.cost:
		return _reject(command, "not_enough_resource")
	player.resource -= def.cost
	var building := BuildingState.new()
	building.owner = player.id
	building.def = def
	building.rect = rect
	building.invested = def.cost
	building.hp = _start_hp(world, def)
	world.add_entity(building)
	world.grid.occupy(rect, building.id)
	_constructing.append(building)
	if DebugLog.on(&"build"):
		DebugLog.event(&"build", {"placed": building.id, "def": def.id, "player": player.id,
			"cell": rect.position, "size": rect.size, "cost": def.cost, "resource_left": player.resource})
	return ""


func _sell(world: World, command: Dictionary) -> String:
	var building := world.entities.get(command["building"]) as BuildingState
	if building == null:
		return _reject(command, "unknown_building")
	if building.owner != command["player"]:
		return _reject(command, "not_owner")
	var refund := floori(building.invested * world.defs.rules.sell_refund_ratio)
	world.players[building.owner].resource += refund
	world.grid.release(building.rect)
	_constructing.erase(building)
	world.remove_entity(building.id)
	if DebugLog.on(&"build"):
		DebugLog.event(&"build", {"sold": building.id, "def": building.def.id, "refund": refund})
	return ""


func _start_hp(world: World, def: BuildingDef) -> int:
	return maxi(1, roundi(def.max_hp * world.defs.rules.construction_start_hp_ratio))


func _reject(command: Dictionary, reason: String) -> String:
	if DebugLog.on(&"build"):
		DebugLog.event(&"build", {"rejected": command["type"], "player": command["player"], "reason": reason,
			"def": command.get("def", ""), "cell": command.get("cell", ""), "building": command.get("building", "")})
	return reason

class_name EconomySystem
extends RefCounted
## Income: a passive trickle per living player plus income buildings (mills). Whole units are
## paid out as the fractional amount accumulates each tick, so totals are exact.

var _carry: Dictionary[int, float] = {}


## Resource per minute player `player_id` currently earns.
func income_per_minute(world: World, player_id: int) -> float:
	var player := world.players[player_id]
	if not player.alive:
		return 0.0
	var total := world.defs.rules.passive_income_per_minute
	for entity: SimEntity in world.entities.values():
		var building := entity as BuildingState
		if building and building.owner == player_id and not building.constructing:
			total += building.def.income_per_minute
	return total


func update(world: World) -> void:
	for player_id in world.players:
		var carry: float = _carry.get(player_id, 0.0) + income_per_minute(world, player_id) / 60.0 / SimConstants.TICK_RATE
		var whole := floori(carry)
		if whole > 0:
			world.players[player_id].resource += whole
			carry -= whole
		_carry[player_id] = carry


## Save/load (WorldState).
func save_state() -> Dictionary:
	return {"carry": _carry.duplicate()}


func load_state(data: Dictionary) -> void:
	_carry.assign(data["carry"])

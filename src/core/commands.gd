class_name Commands
## Player actions as plain dictionaries: the only way input (or a remote client, or a test)
## changes the simulation. Submitted with World.submit() and executed at the start of the next
## tick, in submission order.

const PLACE_BUILDING := &"place_building"
const SELL_BUILDING := &"sell_building"
## Development only: spawn enemies at a map spawn point. Removed from player input in release.
const DEBUG_SPAWN := &"debug_spawn"


## Start constructing building `def_id` with its footprint's top-left corner on `cell`.
static func place_building(player: int, def_id: StringName, cell: Vector2i) -> Dictionary:
	return {"type": PLACE_BUILDING, "player": player, "def": def_id, "cell": cell}


static func sell_building(player: int, building_id: int) -> Dictionary:
	return {"type": SELL_BUILDING, "player": player, "building": building_id}


static func debug_spawn(player: int, def_id: StringName, spawn_id: String, amount: int, target: StringName) -> Dictionary:
	return {"type": DEBUG_SPAWN, "player": player, "def": def_id, "spawn": spawn_id, "amount": amount, "target": target}

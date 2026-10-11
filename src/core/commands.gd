class_name Commands
## Player actions as plain dictionaries: the only way input (or a remote client, or a test)
## changes the simulation. Submitted with World.submit() and executed at the start of the next
## tick, in submission order.

const PLACE_BUILDING := &"place_building"
const SELL_BUILDING := &"sell_building"
const UPGRADE_BUILDING := &"upgrade_building"
const MOVE_SURVIVOR := &"move_survivor"
const REPAIR := &"repair"
const BLINK := &"blink"
const HASTE := &"haste"
## Development only: spawn enemies at a map spawn point. Removed from player input in release.
const DEBUG_SPAWN := &"debug_spawn"


## Build `def_id` with its footprint's top-left corner on `cell`. With a Survivor this is a
## build order (it walks there first); `queue` appends instead of replacing current orders.
static func place_building(player: int, def_id: StringName, cell: Vector2i, queue := false) -> Dictionary:
	return {"type": PLACE_BUILDING, "player": player, "def": def_id, "cell": cell, "queue": queue}


static func sell_building(player: int, building_id: int) -> Dictionary:
	return {"type": SELL_BUILDING, "player": player, "building": building_id}


## Upgrade a completed building in place into `def_id` (one of its def's `upgrades`).
static func upgrade_building(player: int, building_id: int, def_id: StringName) -> Dictionary:
	return {"type": UPGRADE_BUILDING, "player": player, "building": building_id, "def": def_id}


static func debug_spawn(player: int, def_id: StringName, spawn_id: String, amount: int, target: StringName) -> Dictionary:
	return {"type": DEBUG_SPAWN, "player": player, "def": def_id, "spawn": spawn_id, "amount": amount, "target": target}


static func move_survivor(player: int, cell: Vector2i, queue := false) -> Dictionary:
	return {"type": MOVE_SURVIVOR, "player": player, "cell": cell, "queue": queue}


static func repair(player: int, building_id: int, queue := false) -> Dictionary:
	return {"type": REPAIR, "player": player, "building": building_id, "queue": queue}


## Teleport the Survivor to `cell` (within range, onto free ground). Clears its orders.
static func blink(player: int, cell: Vector2i) -> Dictionary:
	return {"type": BLINK, "player": player, "cell": cell}


static func haste(player: int) -> Dictionary:
	return {"type": HASTE, "player": player}

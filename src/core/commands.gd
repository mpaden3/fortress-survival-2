class_name Commands
## Player actions as plain dictionaries: the only way input (or a remote client, or a test)
## changes the simulation. Submitted with World.submit() and executed at the start of the next
## tick, in submission order.

const PLACE_BUILDING := &"place_building"
const SELL_BUILDING := &"sell_building"


## Start constructing building `def_id` with its footprint's top-left corner on `cell`.
static func place_building(player: int, def_id: StringName, cell: Vector2i) -> Dictionary:
	return {"type": PLACE_BUILDING, "player": player, "def": def_id, "cell": cell}


static func sell_building(player: int, building_id: int) -> Dictionary:
	return {"type": SELL_BUILDING, "player": player, "building": building_id}

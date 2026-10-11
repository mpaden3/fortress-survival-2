class_name SurvivorState
extends SimEntity
## A player's Survivor. If it dies, that player is defeated.

var def: SurvivorDef
## Position in cell units (like enemies).
var position := Vector2.ZERO
## Position before this tick's movement (after commands, so a Blink doesn't slide), for
## render interpolation.
var previous_position := Vector2.ZERO
var hp := 0.0
var alive := true
## Queue of orders: {"kind": "move"|"build"|"repair", ...}. The first one is active.
var orders: Array[Dictionary] = []
## Remaining waypoints (cell centres, cell units) of the active order's path.
var path := PackedVector2Array()
var blink_ready_tick := 0
var haste_until_tick := 0
var haste_ready_tick := 0
## Sandbox god mode: takes no damage.
var invulnerable := false


## Where to draw it `alpha` (0..1) of the way from the previous tick to this one.
func position_at(alpha: float) -> Vector2:
	return previous_position.lerp(position, alpha)


func cell() -> Vector2i:
	return Vector2i(floori(position.x), floori(position.y))


## Pathing/hunt target key enemies use for this Survivor.
func target_key() -> StringName:
	return StringName("survivor_%d" % owner)


func snapshot() -> Dictionary:
	var data := super()
	data.merge({
		"kind": "survivor", "pos": [snappedf(position.x, 0.01), snappedf(position.y, 0.01)], "hp": hp,
		"alive": alive, "orders": orders.map(func(o: Dictionary) -> String: return o["kind"]),
	})
	return data

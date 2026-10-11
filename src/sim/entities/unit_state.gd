class_name UnitState
extends SimEntity
## A trained player unit (fighter, repairman). Removed from the World when it dies.

var def: UnitDef
## Position in cell units (like enemies).
var position := Vector2.ZERO
## Position before this tick's movement, for render interpolation.
var previous_position := Vector2.ZERO
var hp := 0.0
## Queue of orders: {"kind": "move"|"attack_move", "cell": Vector2i}. The first one is active.
var orders: Array[Dictionary] = []
## Remaining waypoints (cell centres) of the current walk.
var path := PackedVector2Array()
## Hold position: attack only what's in range, never move.
var holding := false
## Guard spot: idle units return here, and fighters leash to it.
var home := Vector2.ZERO
## Enemy id a fighter is engaging, 0 if none.
var target_enemy := 0
## Building id a repairman is working on, 0 if none.
var target_building := 0
var attack_cooldown := 0
## Tick after which a chase or approach path is recomputed.
var repath_tick := 0
## Cell the current `path` leads to and the GridPaths version it was computed on; (-1, -1)
## while the path follows something moving.
var walk_goal := Vector2i(-1, -1)
var walk_version := -1
var repair_carry := 0.0
## Where a repairman stands to work on `target_building`, and the GridPaths version that was
## checked on. A building found unreachable is skipped until the grid changes.
var repair_goal := Vector2i(-1, -1)
var repair_goal_version := -1
var unreachable_building := 0
var unreachable_version := -1


func cell() -> Vector2i:
	return Vector2i(floori(position.x), floori(position.y))


## Where to draw it `alpha` (0..1) of the way from the previous tick to this one.
func position_at(alpha: float) -> Vector2:
	return previous_position.lerp(position, alpha)


func snapshot() -> Dictionary:
	var data := super()
	data.merge({
		"kind": "unit", "def": String(def.id), "pos": [snappedf(position.x, 0.01), snappedf(position.y, 0.01)],
		"hp": hp, "holding": holding, "target_enemy": target_enemy, "target_building": target_building,
		"orders": orders.map(func(o: Dictionary) -> String: return o["kind"]),
	})
	return data

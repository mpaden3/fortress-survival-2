class_name BuildingState
extends SimEntity
## A placed building: under construction until `build_progress` reaches the def's build ticks.
## While upgrading, `upgrading_to` is set and the building keeps working as its current def
## except that it can't attack.

var def: BuildingDef
## Footprint in build cells.
var rect: Rect2i
var hp := 0
var constructing := true
var build_progress := 0
## Total resource spent on this building (placement + upgrades); the base for sell refunds.
var invested := 0
var upgrading_to: BuildingDef
var upgrade_progress := 0
## Ticks until the tower may fire again.
var attack_cooldown := 0


func is_complete() -> bool:
	return not constructing


## Can shoot right now (built, not upgrading, has an attack).
func can_attack() -> bool:
	return not constructing and upgrading_to == null and def.is_armed()


func centre() -> Vector2:
	return Vector2(rect.position) + Vector2(rect.size) * 0.5


func snapshot() -> Dictionary:
	var data := super()
	data.merge({
		"kind": "building", "def": String(def.id), "cell": [rect.position.x, rect.position.y],
		"hp": hp, "max_hp": def.max_hp, "constructing": constructing, "build_progress": build_progress,
		"upgrading_to": String(upgrading_to.id) if upgrading_to else "",
	})
	return data

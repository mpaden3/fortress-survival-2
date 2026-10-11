class_name BuildingState
extends SimEntity
## A placed building: under construction until `build_progress` reaches the def's build ticks.

var def: BuildingDef
## Footprint in build cells.
var rect: Rect2i
var hp := 0
var constructing := true
var build_progress := 0
## Total resource spent on this building (placement + upgrades); the base for sell refunds.
var invested := 0


func is_complete() -> bool:
	return not constructing


func snapshot() -> Dictionary:
	var data := super()
	data.merge({
		"kind": "building", "def": String(def.id), "cell": [rect.position.x, rect.position.y],
		"hp": hp, "max_hp": def.max_hp, "constructing": constructing, "build_progress": build_progress,
	})
	return data

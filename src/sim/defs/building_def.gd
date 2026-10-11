class_name BuildingDef
extends Resource
## Static data for one building type (one node of an upgrade tree). Files: data/defs/buildings/.

@export var id: StringName
@export var display_name: String
## Size in build cells; the placement cell is the footprint's top-left corner.
@export var footprint := Vector2i.ONE
## Root of an upgrade tree: the Survivor can place it directly. Others only via upgrades.
@export var placeable := false
@export var cost := 0
## Seconds to construct (or to upgrade into this building).
@export var build_time := 1.0
@export var max_hp := 100
## Buildings this one can be upgraded into, in place. More than one = a branch.
@export var upgrades: Array[StringName] = []


func build_ticks() -> int:
	return maxi(1, roundi(build_time * SimConstants.TICK_RATE))

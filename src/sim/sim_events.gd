class_name SimEvents
extends RefCounted
## What happened during the last tick, for presentation only (flashes, explosions, sounds).
## Cleared at the start of every step; game logic never reads it. Flat arrays so a busy
## horde tick doesn't allocate a dictionary per hit.

enum Kind { FIRED, IMPACT, ENEMY_KILLED, BUILDING_DESTROYED }

var kinds := PackedInt32Array()
## Cell units.
var positions := PackedVector2Array()
## Def id of the tower (FIRED, IMPACT), enemy (ENEMY_KILLED) or building (BUILDING_DESTROYED).
var defs: Array[StringName] = []
## Entity id of the tower or building; the enemy's id for ENEMY_KILLED.
var ids := PackedInt32Array()


func count() -> int:
	return kinds.size()


func add(kind: Kind, position: Vector2, def_id: StringName, entity_id: int) -> void:
	kinds.append(kind)
	positions.append(position)
	defs.append(def_id)
	ids.append(entity_id)


func clear() -> void:
	kinds.clear()
	positions.clear()
	defs.clear()
	ids.clear()


## Indices of the events of `kind`, in order (tests and tools; views loop the arrays).
func of_kind(kind: Kind) -> PackedInt32Array:
	var out := PackedInt32Array()
	for i in kinds.size():
		if kinds[i] == kind:
			out.append(i)
	return out

class_name SimEntity
extends RefCounted
## Base of every simulation object. Plain data (no Node), so the whole world can be stepped
## headless and snapshotted for co-op. Views observe entities; they never own them.

## Stable id, unique within a World, never reused.
var id := 0
## Owning player id; -1 = hostile/neutral.
var owner := -1


func snapshot() -> Dictionary:
	return {"id": id, "owner": owner}

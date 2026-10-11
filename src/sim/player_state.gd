class_name PlayerState
extends RefCounted

var id := 0
## Amount of the primary resource ("wood" placeholder).
var resource := 0


func snapshot() -> Dictionary:
	return {"id": id, "resource": resource}

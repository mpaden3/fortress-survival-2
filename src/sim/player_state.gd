class_name PlayerState
extends RefCounted

var id := 0
## Amount of the primary resource ("wood" placeholder).
var resource := 0
## False once the player's Survivor has died.
var alive := true


func snapshot() -> Dictionary:
	return {"id": id, "resource": resource, "alive": alive}

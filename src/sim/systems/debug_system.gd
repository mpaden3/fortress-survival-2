class_name DebugSystem
extends RefCounted
## Development-only commands behind the sandbox panels: resource, clearing enemies, god mode.
## (Spawning is EnemyManager's DEBUG_SPAWN.) Like every command, they run on the next tick.


func register(world: World) -> void:
	world.register_command(Commands.DEBUG_ADD_RESOURCE, _add_resource)
	world.register_command(Commands.DEBUG_CLEAR_ENEMIES, _clear_enemies)
	world.register_command(Commands.DEBUG_GOD, _god)


func _add_resource(world: World, command: Dictionary) -> String:
	var player := world.players[command["player"]]
	player.resource = maxi(0, player.resource + int(command["amount"]))
	_log(command, {"resource": player.resource})
	return ""


func _clear_enemies(world: World, command: Dictionary) -> String:
	var removed := world.enemies.count()
	world.enemies.clear()
	_log(command, {"removed": removed})
	return ""


func _god(world: World, command: Dictionary) -> String:
	var survivor := world.survivors.survivor_of(command["player"])
	if survivor == null:
		return "no_survivor"
	survivor.invulnerable = command["on"]
	_log(command, {"invulnerable": survivor.invulnerable})
	return ""


static func _log(command: Dictionary, data: Dictionary) -> void:
	if DebugLog.on(&"state"):
		data["debug"] = command["type"]
		DebugLog.event(&"state", data)

class_name World
extends RefCounted
## The whole simulation, advanced one fixed tick at a time with step(). No nodes, rendering
## or input: the game scene and the tests drive it the same way.
##
## Each step: commands submitted since the last step run in order, then the systems update.

signal entity_added(entity: SimEntity)
signal entity_removed(entity: SimEntity)
## An entity changed in a way other systems care about (e.g. a building finished upgrading).
signal entity_changed(entity: SimEntity)
## A player's Survivor died: that player is out.
signal player_defeated(player_id: int)
## The match is over (MatchSystem.Result.WON or LOST).
signal match_ended(result: int)

var tick := 0
var map: MapLayout
var defs: DefRegistry
var rng: SimRng
var grid: BuildGrid
var players: Dictionary[int, PlayerState] = {}
var entities: Dictionary[int, SimEntity] = {}
## Outcome of each command executed in the last step, in order: {command, ok, reason}.
var last_results: Array[Dictionary] = []

var buildings: BuildingSystem
var survivors: SurvivorSystem
var pathing: PathingSystem
var enemies: EnemyManager
var combat: CombatSystem
var economy: EconomySystem
var match_system: MatchSystem

var _next_id := 1
var _pending: Array[Dictionary] = []
var _handlers: Dictionary[StringName, Callable] = {}


func _init(map_layout: MapLayout, definitions: DefRegistry, seed_value: int = 0) -> void:
	map = map_layout
	defs = definitions
	rng = SimRng.new(seed_value)
	grid = BuildGrid.new(map)
	buildings = BuildingSystem.new()
	buildings.register(self)
	survivors = SurvivorSystem.new()
	survivors.register(self)
	pathing = PathingSystem.new()
	pathing.register(self)
	enemies = EnemyManager.new()
	enemies.register(self)
	combat = CombatSystem.new()
	economy = EconomySystem.new()
	match_system = MatchSystem.new()


func add_player(player_id: int) -> PlayerState:
	var player := PlayerState.new()
	player.id = player_id
	player.resource = defs.rules.starting_resource
	players[player_id] = player
	return player


## Systems register a handler per command type: handler(world, command) returns "" on
## success, otherwise the rejection reason.
func register_command(type: StringName, handler: Callable) -> void:
	_handlers[type] = handler


func submit(command: Dictionary) -> void:
	_pending.append(command)


func step() -> void:
	DebugLog.tick = tick
	last_results.clear()
	var commands := _pending
	_pending = []
	for command in commands:
		_execute(command)
	match_system.update(self)
	economy.update(self)
	buildings.update(self)
	survivors.update(self)
	pathing.update(self)
	enemies.update(self)
	combat.update(self)
	tick += 1


func run(ticks: int) -> void:
	for i in ticks:
		step()


func run_seconds(seconds: float) -> void:
	run(roundi(seconds * SimConstants.TICK_RATE))


## Next stable entity id (also used for enemies, which aren't SimEntity objects).
func new_id() -> int:
	_next_id += 1
	return _next_id - 1


func add_entity(entity: SimEntity) -> int:
	entity.id = new_id()
	entities[entity.id] = entity
	entity_added.emit(entity)
	return entity.id


func remove_entity(entity_id: int) -> void:
	var entity: SimEntity = entities.get(entity_id)
	if entity:
		entities.erase(entity_id)
		entity_removed.emit(entity)


func snapshot() -> Dictionary:
	var player_data := []
	for player_id in players.keys():
		player_data.append(players[player_id].snapshot())
	var entity_data := []
	var ids := entities.keys()
	ids.sort()
	for entity_id in ids:
		entity_data.append(entities[entity_id].snapshot())
	return {"tick": tick, "map": map.id, "players": player_data, "entities": entity_data,
		"enemies": enemies.snapshot()}


func _execute(command: Dictionary) -> void:
	var reason := ""
	if not players.has(command.get("player", -1)):
		reason = "unknown_player"
	elif not _handlers.has(command.get("type", &"")):
		reason = "unknown_command"
	else:
		reason = _handlers[command["type"]].call(self, command)
	last_results.append({"command": command, "ok": reason.is_empty(), "reason": reason})

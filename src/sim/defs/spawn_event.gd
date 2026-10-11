class_name SpawnEvent
extends Resource
## A one-off spawn at a set time: mini-bosses, the final boss, special waves.

@export var time := 300.0
@export var enemy: StringName
@export var count := 1
## Spawn point id; empty = random.
@export var spawn := ""
## Shown to players when it happens.
@export var announcement := ""

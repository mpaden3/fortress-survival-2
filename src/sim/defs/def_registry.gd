class_name DefRegistry
extends RefCounted
## All definitions the simulation needs, looked up by id. Tests can build one in code.

const BUILDINGS_DIR := "res://data/defs/buildings"
const ENEMIES_DIR := "res://data/defs/enemies"
const RULES_PATH := "res://data/defs/game_rules.tres"
const SURVIVOR_PATH := "res://data/defs/survivor.tres"

var rules: GameRules
var survivor: SurvivorDef
var buildings: Dictionary[StringName, BuildingDef] = {}
var enemies: Dictionary[StringName, EnemyDef] = {}
## Enemy defs by dense index, for the EnemyManager's per-enemy type array.
var enemy_list: Array[EnemyDef] = []


static func load_default() -> DefRegistry:
	var registry := DefRegistry.new()
	registry.rules = load(RULES_PATH)
	registry.survivor = load(SURVIVOR_PATH)
	for file in ResourceLoader.list_directory(BUILDINGS_DIR):
		if file.ends_with(".tres"):
			registry.add_building(load(BUILDINGS_DIR.path_join(file)))
	for file in ResourceLoader.list_directory(ENEMIES_DIR):
		if file.ends_with(".tres"):
			registry.add_enemy(load(ENEMIES_DIR.path_join(file)))
	return registry


func add_building(def: BuildingDef) -> void:
	assert(not buildings.has(def.id), "duplicate building id %s" % def.id)
	buildings[def.id] = def


func building(def_id: StringName) -> BuildingDef:
	return buildings.get(def_id)


func add_enemy(def: EnemyDef) -> void:
	assert(not enemies.has(def.id), "duplicate enemy id %s" % def.id)
	enemies[def.id] = def
	enemy_list.append(def)


func enemy(def_id: StringName) -> EnemyDef:
	return enemies.get(def_id)


func enemy_index(def_id: StringName) -> int:
	return enemy_list.find(enemies.get(def_id))

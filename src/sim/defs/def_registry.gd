class_name DefRegistry
extends RefCounted
## All definitions the simulation needs, looked up by id. Tests can build one in code.

const BUILDINGS_DIR := "res://data/defs/buildings"
const ENEMIES_DIR := "res://data/defs/enemies"
const RULES_PATH := "res://data/defs/game_rules.tres"
const SURVIVOR_PATH := "res://data/defs/survivor.tres"
const DEFAULT_SCHEDULE_PATH := "res://data/defs/waves/default.tres"

var rules: GameRules
var survivor: SurvivorDef
## Wave schedule used for matches (tests may leave it null).
var schedule: WaveSchedule
var buildings: Dictionary[StringName, BuildingDef] = {}
var enemies: Dictionary[StringName, EnemyDef] = {}
## Enemy defs by dense index, for the EnemyManager's per-enemy type array.
var enemy_list: Array[EnemyDef] = []
## Damage type -> multiplier per enemy_list index (cache for combat).
var _vs_enemies: Dictionary[StringName, PackedFloat32Array] = {}


static func load_default() -> DefRegistry:
	var registry := DefRegistry.new()
	registry.rules = load(RULES_PATH)
	registry.survivor = load(SURVIVOR_PATH)
	registry.schedule = load(DEFAULT_SCHEDULE_PATH)
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


## Multiplier of `damage_type` against each enemy type, indexed like enemy_list.
func damage_vs_enemies(damage_type: StringName) -> PackedFloat32Array:
	var cached: PackedFloat32Array = _vs_enemies.get(damage_type, PackedFloat32Array())
	if cached.size() == enemy_list.size() and not cached.is_empty():
		return cached
	cached = PackedFloat32Array()
	for def in enemy_list:
		cached.append(rules.damage_multiplier(damage_type, def.armor_type))
	_vs_enemies[damage_type] = cached
	return cached

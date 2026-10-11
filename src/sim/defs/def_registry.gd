class_name DefRegistry
extends RefCounted
## All definitions the simulation needs, looked up by id. Tests can build one in code.

const BUILDINGS_DIR := "res://data/defs/buildings"
const RULES_PATH := "res://data/defs/game_rules.tres"

var rules: GameRules
var buildings: Dictionary[StringName, BuildingDef] = {}


static func load_default() -> DefRegistry:
	var registry := DefRegistry.new()
	registry.rules = load(RULES_PATH)
	for file in ResourceLoader.list_directory(BUILDINGS_DIR):
		if file.ends_with(".tres"):
			registry.add_building(load(BUILDINGS_DIR.path_join(file)))
	return registry


func add_building(def: BuildingDef) -> void:
	assert(not buildings.has(def.id), "duplicate building id %s" % def.id)
	buildings[def.id] = def


func building(def_id: StringName) -> BuildingDef:
	return buildings.get(def_id)

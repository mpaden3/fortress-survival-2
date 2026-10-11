class_name GameRules
extends Resource
## Match-wide tuning values. File: data/defs/game_rules.tres.

## Display name of the primary resource; "wood" is a placeholder until its lore exists.
@export var primary_resource_name := "wood"
@export var starting_resource := 100
## Resource per minute every living player earns regardless of buildings.
@export var passive_income_per_minute := 30.0
## Share of a building's total invested cost returned when it's sold.
@export_range(0.0, 1.0) var sell_refund_ratio := 0.5
## HP a building has the moment construction starts, as a share of max HP.
@export_range(0.0, 1.0) var construction_start_hp_ratio := 0.1
## Path cost of breaking through a building, per HP, in "cells walked" (10 = one cell).
## Higher = enemies prefer longer detours over smashing walls.
@export var path_cost_per_building_hp := 0.5
## Fog of war: players only see around their own (and allies') Survivors, units and
## buildings. Off for now; the visibility query exists so views already respect it.
@export var fog_of_war := false
## How far (cells) Survivors and buildings see when fog is on; units use their sight_range.
@export var survivor_vision := 8.0
@export var building_vision := 6.0
## Most units a building can have queued for training.
@export var max_train_queue := 5
## Damage type -> {armor type -> multiplier}. Missing entries count as 1.
@export var damage_multipliers: Dictionary = {}


func damage_multiplier(damage_type: StringName, armor_type: StringName) -> float:
	var row: Dictionary = damage_multipliers.get(damage_type, {})
	return row.get(armor_type, 1.0)

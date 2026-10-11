class_name GameRules
extends Resource
## Match-wide tuning values. File: data/defs/game_rules.tres.

## Display name of the primary resource; "wood" is a placeholder until its lore exists.
@export var primary_resource_name := "wood"
@export var starting_resource := 100
## Share of a building's total invested cost returned when it's sold.
@export_range(0.0, 1.0) var sell_refund_ratio := 0.5
## HP a building has the moment construction starts, as a share of max HP.
@export_range(0.0, 1.0) var construction_start_hp_ratio := 0.1
## Path cost of breaking through a building, per HP, in "cells walked" (10 = one cell).
## Higher = enemies prefer longer detours over smashing walls.
@export var path_cost_per_building_hp := 0.5

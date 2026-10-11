class_name SurvivorDef
extends Resource
## The Survivor (builder hero). File: data/defs/survivor.tres.

@export var display_name := "Survivor"
@export var max_hp := 400.0
## Meters per second.
@export var speed := 5.0
## Body radius in meters (enemies attack when they touch it).
@export var radius := 0.45
## How close (cells, from the footprint/building edge) it must be to build or repair.
@export var work_reach := 1.6
## Repair speed in HP per second (repair is free).
@export var repair_rate := 25.0
## Blink: max distance in cells, cooldown in seconds.
@export var blink_range := 6.0
@export var blink_cooldown := 12.0
## Haste: speed multiplier for `haste_duration` seconds, then `haste_cooldown` seconds.
@export var haste_multiplier := 1.6
@export var haste_duration := 4.0
@export var haste_cooldown := 20.0

class_name EnemyDef
extends Resource
## Static data for one enemy type. Files: data/defs/enemies/.

@export var id: StringName
@export var display_name: String
@export var max_hp := 50.0
## Meters per second.
@export var speed := 3.0
## Body radius in meters, used for separation from other enemies.
@export var radius := 0.4
## Damage per hit.
@export var damage := 5.0
## Seconds between hits.
@export var attack_cooldown := 1.0
## Damage multiplier against buildings (siege units > 1).
@export var building_damage_multiplier := 1.0
## Meters. While its Survivor is farther than this, the enemy goes for the nearest building
## within this walking distance instead. 0 = never diverts.
@export var sight_range := 0.0


func cooldown_ticks() -> int:
	return maxi(1, roundi(attack_cooldown * SimConstants.TICK_RATE))
